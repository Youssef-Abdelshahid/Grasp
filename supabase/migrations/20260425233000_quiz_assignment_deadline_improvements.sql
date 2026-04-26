alter table public.quizzes
  add column if not exists show_question_marks boolean not null default true;

alter table public.assignments
  add column if not exists attachments jsonb not null default '[]'::jsonb;

update public.quizzes
set question_schema = (
  select coalesce(jsonb_agg(
    case
      when lower(question ->> 'type') = 'essay'
      then jsonb_set(question, '{type}', '"Short Answer"'::jsonb)
      else question
    end
    order by ord
  ), '[]'::jsonb)
  from jsonb_array_elements(question_schema) with ordinality as questions(question, ord)
)
where question_schema::text ilike '%essay%';

drop function if exists public.admin_update_quiz_full(uuid, text, text, text, timestamptz, integer, integer, boolean, jsonb, boolean, boolean);

create or replace function public.admin_update_quiz_full(
  p_quiz_id uuid,
  p_title text,
  p_description text default '',
  p_instructions text default '',
  p_due_at timestamptz default null,
  p_max_points integer default 100,
  p_duration_minutes integer default null,
  p_is_published boolean default false,
  p_question_schema jsonb default '[]'::jsonb,
  p_show_correct_answers boolean default false,
  p_allow_retakes boolean default false,
  p_show_question_marks boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  row_data public.quizzes%rowtype;
begin
  perform public.require_admin();

  update public.quizzes
  set title = trim(p_title),
      description = trim(coalesce(p_description, '')),
      instructions = trim(coalesce(p_instructions, '')),
      due_at = p_due_at,
      max_points = greatest(coalesce(p_max_points, 100), 1),
      duration_minutes = p_duration_minutes,
      is_published = coalesce(p_is_published, false),
      published_at = case when coalesce(p_is_published, false) then coalesce(published_at, timezone('utc', now())) else null end,
      question_schema = coalesce(p_question_schema, '[]'::jsonb),
      show_correct_answers = coalesce(p_show_correct_answers, false),
      allow_retakes = coalesce(p_allow_retakes, false),
      show_question_marks = coalesce(p_show_question_marks, true),
      updated_at = timezone('utc', now())
  where id = p_quiz_id
  returning * into row_data;

  if row_data.id is null then
    raise exception 'Quiz not found.' using errcode = 'PGRST116';
  end if;

  perform public.log_admin_action(
    'quiz_edited',
    'Edited quiz ' || row_data.title,
    jsonb_build_object('quiz_id', row_data.id, 'course_id', row_data.course_id)
  );

  return to_jsonb(row_data);
end;
$$;

create or replace function public.admin_update_assignment_full(
  p_assignment_id uuid,
  p_title text,
  p_instructions text default '',
  p_attachment_requirements text default '',
  p_due_at timestamptz default null,
  p_max_points integer default 100,
  p_is_published boolean default false,
  p_rubric jsonb default '[]'::jsonb,
  p_attachments jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  row_data public.assignments%rowtype;
begin
  perform public.require_active_admin();

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'Assignment title is required.' using errcode = '22023';
  end if;

  update public.assignments
  set title = trim(p_title),
      instructions = trim(coalesce(p_instructions, '')),
      attachment_requirements = trim(coalesce(p_attachment_requirements, '')),
      due_at = p_due_at,
      max_points = greatest(coalesce(p_max_points, 100), 1),
      is_published = coalesce(p_is_published, false),
      published_at = case when coalesce(p_is_published, false) then coalesce(published_at, timezone('utc', now())) else null end,
      rubric = coalesce(p_rubric, '[]'::jsonb),
      attachments = coalesce(p_attachments, '[]'::jsonb),
      updated_at = timezone('utc', now())
  where id = p_assignment_id
  returning * into row_data;

  if row_data.id is null then
    raise exception 'Assignment not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity(
    'assignment_edited',
    'Edited assignment: ' || row_data.title,
    null,
    jsonb_build_object('assignment_id', row_data.id, 'course_id', row_data.course_id)
  );

  return to_jsonb(row_data);
end;
$$;

create or replace function public.list_admin_quizzes(
  p_search text default '',
  p_course_id uuid default null,
  p_status text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_admin();

  return coalesce((
    select jsonb_agg(item order by due_at nulls last, created_at desc)
    from (
      select jsonb_build_object(
          'id', q.id,
          'course_id', q.course_id,
          'course_title', c.title,
          'course_code', c.code,
          'instructor_name', instructor.full_name,
          'title', q.title,
          'description', q.description,
          'instructions', q.instructions,
          'due_at', q.due_at,
          'max_points', q.max_points,
          'duration_minutes', q.duration_minutes,
          'is_published', q.is_published,
          'show_correct_answers', coalesce(q.show_correct_answers, false),
          'allow_retakes', coalesce(q.allow_retakes, false),
          'show_question_marks', coalesce(q.show_question_marks, true),
          'question_schema', q.question_schema,
          'question_count', jsonb_array_length(q.question_schema),
          'created_by_name', creator.full_name,
          'created_at', q.created_at,
          'published_at', q.published_at
        ) as item,
        q.due_at,
        q.created_at
      from public.quizzes q
      join public.courses c on c.id = q.course_id
      left join public.profiles instructor on instructor.id = c.instructor_id
      left join public.profiles creator on creator.id = q.created_by
      where (coalesce(p_search, '') = ''
        or q.title ilike '%' || p_search || '%'
        or c.title ilike '%' || p_search || '%'
        or c.code ilike '%' || p_search || '%')
        and (p_course_id is null or q.course_id = p_course_id)
        and (p_status is null
          or (p_status = 'published' and q.is_published)
          or (p_status = 'draft' and not q.is_published))
    ) rows
  ), '[]'::jsonb);
end;
$$;

create or replace function public.list_admin_assignments(
  p_search text default '',
  p_course_id uuid default null,
  p_status text default null,
  p_instructor_id uuid default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then public.raise_admin_access_required()
    else coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'course_id', a.course_id,
          'course_title', c.title,
          'course_code', c.code,
          'instructor_id', c.instructor_id,
          'instructor_name', coalesce(ip.full_name, 'Unknown instructor'),
          'title', a.title,
          'instructions', a.instructions,
          'attachment_requirements', a.attachment_requirements,
          'attachments', coalesce(a.attachments, '[]'::jsonb),
          'due_at', a.due_at,
          'max_points', a.max_points,
          'is_published', a.is_published,
          'rubric', a.rubric,
          'rubric_count', jsonb_array_length(a.rubric),
          'created_by', a.created_by,
          'created_by_name', coalesce(cp.full_name, 'Unknown creator'),
          'created_at', a.created_at,
          'updated_at', a.updated_at,
          'published_at', a.published_at
        )
        order by a.created_at desc
      )
      from public.assignments a
      join public.courses c on c.id = a.course_id
      left join public.profiles ip on ip.id = c.instructor_id
      left join public.profiles cp on cp.id = a.created_by
      where (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or a.title ilike '%' || trim(p_search) || '%'
          or c.title ilike '%' || trim(p_search) || '%'
          or c.code ilike '%' || trim(p_search) || '%'
        )
        and (p_course_id is null or a.course_id = p_course_id)
        and (p_instructor_id is null or c.instructor_id = p_instructor_id)
        and (
          p_status is null
          or trim(p_status) = ''
          or lower(p_status) = 'all'
          or (lower(p_status) = 'published' and a.is_published)
          or (lower(p_status) = 'draft' and not a.is_published)
          or (lower(p_status) = 'overdue' and a.due_at is not null and a.due_at < timezone('utc', now()))
        )
    ), '[]'::jsonb)
  end;
$$;

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
      grade_row := coalesce(p_grading_details -> 'question_grades' -> idx, '{}'::jsonb);
      question_type := lower(coalesce(question ->> 'type', ''));
      question_marks := greatest(coalesce((question ->> 'marks')::numeric, 0), 0);
      awarded := coalesce((grade_row ->> 'marks')::numeric, 0);

      if awarded < 0 or awarded > question_marks then
        raise exception 'Question % grade must be between 0 and %.', idx + 1, question_marks
          using errcode = '22023';
      end if;

      if question_type = 'short answer' then
        if awarded * 4 <> trunc(awarded * 4) then
          raise exception 'Question % grade must use 0.25 increments.', idx + 1
            using errcode = '22023';
        end if;
      elsif question_type in ('drag and drop', 'matching', 'classification') then
        null;
      else
        if awarded <> 0 and awarded <> question_marks then
          raise exception 'Question % objective grade must be 0 or full marks.', idx + 1
            using errcode = '22023';
        end if;
      end if;

      calculated_score := calculated_score + awarded;
      idx := idx + 1;
    end loop;

    update public.submissions
    set score = calculated_score,
        feedback = coalesce(p_feedback, ''),
        grading_details = coalesce(p_grading_details, '{}'::jsonb),
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
