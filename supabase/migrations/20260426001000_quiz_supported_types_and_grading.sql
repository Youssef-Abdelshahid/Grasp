create or replace function public.sanitize_quiz_question_schema(p_schema jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce(jsonb_agg(
    case
      when lower(coalesce(question ->> 'type', '')) in ('short answer', 'essay') then
        (question - 'categories') || jsonb_build_object('type', 'Short Answer')
      when lower(coalesce(question ->> 'type', '')) in ('matching', 'drag and drop', 'classification') then
        (question - 'categories') || jsonb_build_object(
          'type', 'Matching',
          'targets', coalesce(
            nullif(question -> 'targets', '[]'::jsonb),
            nullif(question -> 'categories', '[]'::jsonb),
            (
              select coalesce(jsonb_agg(distinct value), '[]'::jsonb)
              from jsonb_each_text(coalesce(question -> 'correct_mapping', '{}'::jsonb)) as mappings(key, value)
            )
          )
        )
      when lower(coalesce(question ->> 'type', '')) in ('mcq', 'true / false', 'true/false') then
        (question - 'categories') || jsonb_build_object(
          'type',
          case
            when lower(coalesce(question ->> 'type', '')) = 'mcq' then 'MCQ'
            else 'True / False'
          end
        )
      else
        (question - 'categories') || jsonb_build_object('type', 'MCQ')
    end
    order by ord
  ), '[]'::jsonb)
  from jsonb_array_elements(coalesce(p_schema, '[]'::jsonb)) with ordinality as questions(question, ord);
$$;

drop trigger if exists enforce_supported_quiz_schema_before_save on public.quizzes;

update public.quizzes
set question_schema = public.sanitize_quiz_question_schema(question_schema),
    max_points = greatest(ceil((
      select coalesce(sum(greatest(coalesce((question ->> 'marks')::numeric, 0), 0)), 0)
      from jsonb_array_elements(public.sanitize_quiz_question_schema(question_schema)) as questions(question)
    ))::integer, 1)
where question_schema::text ilike '%essay%'
   or question_schema::text ilike '%drag and drop%'
   or question_schema::text ilike '%classification%';

create or replace function public.enforce_supported_quiz_schema()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  question_row jsonb;
  raw_type text;
  total_marks numeric;
begin
  for question_row in
    select value from jsonb_array_elements(coalesce(new.question_schema, '[]'::jsonb))
  loop
    raw_type := lower(coalesce(question_row ->> 'type', ''));
    if raw_type not in (
      'mcq',
      'true / false',
      'true/false',
      'short answer',
      'essay',
      'matching',
      'drag and drop',
      'classification'
    ) then
      raise exception 'Unsupported quiz question type: %.', coalesce(question_row ->> 'type', '')
        using errcode = '22023';
    end if;
  end loop;

  new.question_schema := public.sanitize_quiz_question_schema(new.question_schema);

  select coalesce(sum(greatest(coalesce((schema_question ->> 'marks')::numeric, 0), 0)), 0)
  into total_marks
  from jsonb_array_elements(coalesce(new.question_schema, '[]'::jsonb)) as questions(schema_question);

  new.max_points := greatest(ceil(total_marks)::integer, 1);
  return new;
end;
$$;

create trigger enforce_supported_quiz_schema_before_save
before insert or update of question_schema, max_points on public.quizzes
for each row
execute function public.enforce_supported_quiz_schema();

create or replace function public.grade_submission(
  p_submission_id uuid,
  p_score numeric,
  p_feedback text default '',
  p_grading_details jsonb default '{}'::jsonb,
  p_grade_visible boolean default false,
  p_feedback_visible boolean default false,
  p_attempt_visible boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  course_uuid uuid;
  quiz_schema jsonb;
  answers_schema jsonb;
  question jsonb;
  answer_row jsonb;
  grade_row jsonb;
  question_type text;
  question_marks numeric;
  awarded numeric;
  calculated_score numeric := 0;
  is_quiz boolean := false;
  question_count integer := 0;
  idx integer := 0;
  expected_total integer;
  correct_total integer;
  sanitized_grades jsonb := '[]'::jsonb;
  raw_answer jsonb;
begin
  select coalesce(q.course_id, a.course_id), q.question_schema, s.content -> 'answers', s.quiz_id is not null
  into course_uuid, quiz_schema, answers_schema, is_quiz
  from public.submissions s
  left join public.quizzes q on q.id = s.quiz_id
  left join public.assignments a on a.id = s.assignment_id
  where s.id = p_submission_id;

  perform public.require_course_activity_access(course_uuid);

  if is_quiz then
    question_count := jsonb_array_length(coalesce(quiz_schema, '[]'::jsonb));

    while idx < question_count loop
      question := quiz_schema -> idx;
      answer_row := coalesce(answers_schema -> idx, '{}'::jsonb);
      raw_answer := answer_row -> 'answer';
      grade_row := coalesce(p_grading_details -> 'question_grades' -> idx, '{}'::jsonb);
      question_type := lower(coalesce(question ->> 'type', ''));
      question_marks := greatest(coalesce((question ->> 'marks')::numeric, 0), 0);
      awarded := 0;

      if question_type in ('short answer', 'essay') then
        awarded := coalesce((grade_row ->> 'marks')::numeric, 0);
        if awarded < 0 or awarded > question_marks then
          raise exception 'Question % grade must be between 0 and %.', idx + 1, question_marks
            using errcode = '22023';
        end if;
        if awarded * 4 <> trunc(awarded * 4) then
          raise exception 'Question % grade must use 0.25 increments.', idx + 1
            using errcode = '22023';
        end if;
      elsif question_type = 'matching' then
        select count(*), count(*) filter (
          where raw_answer is not null
            and jsonb_typeof(raw_answer) = 'object'
            and raw_answer ->> key = value
        )
        into expected_total, correct_total
        from jsonb_each_text(coalesce(question -> 'correct_mapping', '{}'::jsonb)) as expected(key, value);

        awarded := case
          when expected_total > 0 then correct_total * (question_marks / expected_total)
          else 0
        end;
      else
        if jsonb_typeof(raw_answer) = 'number'
          and (raw_answer #>> '{}')::integer = coalesce((question ->> 'correct_option')::integer, -1)
        then
          awarded := question_marks;
        end if;
      end if;

      awarded := least(greatest(awarded, 0), question_marks);
      calculated_score := calculated_score + awarded;
      sanitized_grades := sanitized_grades || jsonb_build_array(jsonb_build_object(
        'question_index', idx,
        'marks', awarded,
        'feedback', case
          when question_type in ('short answer', 'essay') then coalesce(grade_row ->> 'feedback', '')
          else ''
        end
      ));
      idx := idx + 1;
    end loop;

    update public.submissions
    set score = calculated_score,
        feedback = coalesce(p_feedback, ''),
        grading_details = jsonb_build_object('question_grades', sanitized_grades),
        grade_visible = coalesce(p_grade_visible, false),
        feedback_visible = coalesce(p_feedback_visible, false),
        attempt_visible = coalesce(p_attempt_visible, false),
        status = 'graded',
        graded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_submission_id;
  else
    update public.submissions
    set score = greatest(0, coalesce(p_score, 0)),
        feedback = coalesce(p_feedback, ''),
        grading_details = coalesce(p_grading_details, '{}'::jsonb),
        grade_visible = coalesce(p_grade_visible, false),
        feedback_visible = coalesce(p_feedback_visible, false),
        status = 'graded',
        graded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_submission_id;
  end if;

  return public.get_submission_detail(p_submission_id);
end;
$$;
