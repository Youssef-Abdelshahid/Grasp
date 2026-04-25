create or replace function public.admin_update_assignment_full(
  p_assignment_id uuid,
  p_title text,
  p_instructions text default '',
  p_attachment_requirements text default '',
  p_due_at timestamptz default null,
  p_max_points integer default 100,
  p_is_published boolean default false,
  p_rubric jsonb default '[]'::jsonb
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
  set
    title = trim(p_title),
    instructions = trim(coalesce(p_instructions, '')),
    attachment_requirements = trim(coalesce(p_attachment_requirements, '')),
    due_at = p_due_at,
    max_points = greatest(coalesce(p_max_points, 100), 1),
    is_published = coalesce(p_is_published, false),
    published_at = case
      when coalesce(p_is_published, false) then coalesce(published_at, timezone('utc', now()))
      else null
    end,
    rubric = coalesce(p_rubric, '[]'::jsonb),
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

create or replace function public.admin_update_quiz_full(
  p_quiz_id uuid,
  p_title text,
  p_description text default '',
  p_instructions text default '',
  p_due_at timestamptz default null,
  p_max_points integer default 100,
  p_duration_minutes integer default null,
  p_is_published boolean default false,
  p_question_schema jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  row_data public.quizzes%rowtype;
begin
  perform public.require_active_admin();

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'Quiz title is required.' using errcode = '22023';
  end if;

  update public.quizzes
  set
    title = trim(p_title),
    description = trim(coalesce(p_description, '')),
    instructions = trim(coalesce(p_instructions, '')),
    due_at = p_due_at,
    max_points = greatest(coalesce(p_max_points, 100), 1),
    duration_minutes = p_duration_minutes,
    is_published = coalesce(p_is_published, false),
    published_at = case
      when coalesce(p_is_published, false) then coalesce(published_at, timezone('utc', now()))
      else null
    end,
    question_schema = coalesce(p_question_schema, '[]'::jsonb),
    updated_at = timezone('utc', now())
  where id = p_quiz_id
  returning * into row_data;

  if row_data.id is null then
    raise exception 'Quiz not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity(
    'quiz_edited',
    'Edited quiz: ' || row_data.title,
    null,
    jsonb_build_object('quiz_id', row_data.id, 'course_id', row_data.course_id)
  );

  return to_jsonb(row_data);
end;
$$;
