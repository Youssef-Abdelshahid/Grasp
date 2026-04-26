alter table public.quizzes
  add column if not exists show_correct_answers boolean not null default false,
  add column if not exists allow_retakes boolean not null default false;

create or replace function public.enforce_quiz_retake_policy()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  retakes_allowed boolean;
begin
  if new.quiz_id is null then
    return new;
  end if;

  select allow_retakes
  into retakes_allowed
  from public.quizzes
  where id = new.quiz_id;

  if not coalesce(retakes_allowed, false)
    and exists (
      select 1
      from public.submissions
      where quiz_id = new.quiz_id
        and student_id = new.student_id
    ) then
    raise exception 'You have already submitted this quiz.' using errcode = '23505';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_quiz_retake_policy_before_insert on public.submissions;
create trigger enforce_quiz_retake_policy_before_insert
before insert on public.submissions
for each row
execute function public.enforce_quiz_retake_policy();

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
          'show_correct_answers', q.show_correct_answers,
          'allow_retakes', q.allow_retakes,
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
  p_allow_retakes boolean default false
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

create or replace function public.get_submission_detail(p_submission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  course_uuid uuid;
begin
  select coalesce(q.course_id, a.course_id)
  into course_uuid
  from public.submissions s
  left join public.quizzes q on q.id = s.quiz_id
  left join public.assignments a on a.id = s.assignment_id
  where s.id = p_submission_id;

  perform public.require_course_activity_access(course_uuid);

  return (
    select jsonb_build_object(
      'id', s.id,
      'student_id', p.id,
      'student_name', p.full_name,
      'student_email', p.email,
      'quiz_id', s.quiz_id,
      'assignment_id', s.assignment_id,
      'title', coalesce(q.title, a.title),
      'type', case when s.quiz_id is not null then 'quiz' else 'assignment' end,
      'due_at', coalesce(q.due_at, a.due_at),
      'submitted_at', s.submitted_at,
      'score', s.score,
      'status', s.status,
      'content', s.content,
      'feedback', s.feedback,
      'grading_details', s.grading_details,
      'grade_visible', s.grade_visible,
      'feedback_visible', s.feedback_visible,
      'attempt_visible', s.attempt_visible,
      'show_correct_answers', coalesce(q.show_correct_answers, false),
      'graded_at', s.graded_at,
      'attempt_number', s.attempt_number,
      'file_name', s.file_name,
      'file_size_bytes', s.file_size_bytes,
      'storage_path', s.storage_path,
      'question_schema', q.question_schema,
      'rubric', a.rubric
    )
    from public.submissions s
    join public.profiles p on p.id = s.student_id
    left join public.quizzes q on q.id = s.quiz_id
    left join public.assignments a on a.id = s.assignment_id
    where s.id = p_submission_id
  );
end;
$$;

create or replace function public.get_my_submission_result(p_submission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.submissions
    where id = p_submission_id and student_id = auth.uid()
  ) then
    raise exception 'Submission not found.' using errcode = '42501';
  end if;

  return (
    select jsonb_build_object(
      'id', s.id,
      'student_id', p.id,
      'student_name', p.full_name,
      'student_email', p.email,
      'quiz_id', s.quiz_id,
      'assignment_id', s.assignment_id,
      'title', coalesce(q.title, a.title),
      'type', case when s.quiz_id is not null then 'quiz' else 'assignment' end,
      'due_at', coalesce(q.due_at, a.due_at),
      'submitted_at', s.submitted_at,
      'score', case
        when s.quiz_id is not null and not s.attempt_visible then null
        when s.grade_visible then s.score
        else null
      end,
      'status', s.status,
      'content', case
        when s.quiz_id is not null and not s.attempt_visible then '{}'::jsonb
        when s.quiz_id is not null and not coalesce(q.show_correct_answers, false) then jsonb_set(
          s.content,
          '{answers}',
          coalesce((
            select jsonb_agg(answer - 'correct_option' - 'is_correct' order by ord)
            from jsonb_array_elements(s.content -> 'answers') with ordinality as answers(answer, ord)
          ), '[]'::jsonb)
        )
        else s.content
      end,
      'feedback', case
        when s.feedback_visible and (s.assignment_id is not null or s.attempt_visible) then s.feedback
        else ''
      end,
      'grading_details', case
        when s.feedback_visible and (s.assignment_id is not null or s.attempt_visible) then s.grading_details
        else '{}'::jsonb
      end,
      'grade_visible', s.grade_visible,
      'feedback_visible', s.feedback_visible,
      'attempt_visible', case when s.assignment_id is not null then true else s.attempt_visible end,
      'show_correct_answers', coalesce(q.show_correct_answers, false),
      'graded_at', case
        when (s.grade_visible or s.feedback_visible) and (s.assignment_id is not null or s.attempt_visible) then s.graded_at
        else null
      end,
      'attempt_number', s.attempt_number,
      'file_name', s.file_name,
      'file_size_bytes', s.file_size_bytes,
      'storage_path', s.storage_path,
      'question_schema', case
        when s.assignment_id is not null then null
        when not s.attempt_visible then '[]'::jsonb
        when coalesce(q.show_correct_answers, false) then q.question_schema
        else coalesce((
          select jsonb_agg(question - 'correct_option' - 'explanation' - 'sample_answer' order by ord)
          from jsonb_array_elements(q.question_schema) with ordinality as questions(question, ord)
        ), '[]'::jsonb)
      end,
      'rubric', a.rubric
    )
    from public.submissions s
    join public.profiles p on p.id = s.student_id
    left join public.quizzes q on q.id = s.quiz_id
    left join public.assignments a on a.id = s.assignment_id
    where s.id = p_submission_id
      and s.student_id = auth.uid()
  );
end;
$$;
