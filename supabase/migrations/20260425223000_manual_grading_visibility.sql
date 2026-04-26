alter table public.submissions
  add column if not exists feedback text not null default '',
  add column if not exists grading_details jsonb not null default '{}'::jsonb,
  add column if not exists grade_visible boolean not null default false,
  add column if not exists feedback_visible boolean not null default false;

create or replace function public.grade_submission(
  p_submission_id uuid,
  p_score numeric,
  p_feedback text default '',
  p_grading_details jsonb default '{}'::jsonb,
  p_grade_visible boolean default false,
  p_feedback_visible boolean default false
)
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

  return public.get_submission_detail(p_submission_id);
end;
$$;

create or replace function public.set_submission_visibility(
  p_submission_id uuid,
  p_grade_visible boolean,
  p_feedback_visible boolean
)
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

  update public.submissions
  set grade_visible = coalesce(p_grade_visible, false),
      feedback_visible = coalesce(p_feedback_visible, false),
      updated_at = timezone('utc', now())
  where id = p_submission_id;

  return public.get_submission_detail(p_submission_id);
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
      'score', case when s.grade_visible then s.score else null end,
      'status', s.status,
      'content', s.content,
      'feedback', case when s.feedback_visible then s.feedback else '' end,
      'grading_details', case when s.feedback_visible then s.grading_details else '{}'::jsonb end,
      'grade_visible', s.grade_visible,
      'feedback_visible', s.feedback_visible,
      'graded_at', case when s.grade_visible or s.feedback_visible then s.graded_at else null end,
      'attempt_number', s.attempt_number,
      'file_name', s.file_name,
      'file_size_bytes', s.file_size_bytes,
      'storage_path', s.storage_path,
      'question_schema', case when s.feedback_visible then q.question_schema else '[]'::jsonb end,
      'rubric', case when s.feedback_visible then a.rubric else '[]'::jsonb end
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
