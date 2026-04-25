create index if not exists idx_materials_created_at on public.materials (created_at desc);
create index if not exists idx_quizzes_created_at on public.quizzes (created_at desc);
create index if not exists idx_assignments_created_at on public.assignments (created_at desc);
create index if not exists idx_announcements_created_at on public.announcements (created_at desc);

create or replace function public.admin_optional_course_filter(p_course_id uuid)
returns boolean
language sql
stable
as $$
  select p_course_id is null
$$;

create or replace function public.get_admin_dashboard_summary()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then
      public.raise_admin_access_required()
    else jsonb_build_object(
      'total_users', (select count(*) from public.profiles where deleted_at is null),
      'students_count', (select count(*) from public.profiles where role = 'student' and deleted_at is null),
      'instructors_count', (select count(*) from public.profiles where role = 'instructor' and deleted_at is null),
      'admins_count', (select count(*) from public.profiles where role = 'admin' and deleted_at is null),
      'active_users', (select count(*) from public.profiles where account_status = 'active' and deleted_at is null),
      'suspended_users', (select count(*) from public.profiles where account_status = 'suspended' and deleted_at is null),
      'total_courses', (select count(*) from public.courses),
      'active_courses', (select count(*) from public.courses where status = 'published'),
      'total_materials', (select count(*) from public.materials),
      'total_quizzes', (select count(*) from public.quizzes),
      'published_quizzes', (select count(*) from public.quizzes where is_published),
      'total_assignments', (select count(*) from public.assignments),
      'published_assignments', (select count(*) from public.assignments where is_published),
      'total_announcements', (select count(*) from public.announcements),
      'recent_activity_count',
      (
        select count(*)
        from public.admin_activity_logs
        where created_at >= timezone('utc', now()) - interval '7 days'
      ),
      'ai_items_today', 0,
      'recent_registrations',
      coalesce((
        select jsonb_agg(item)
        from (
          select jsonb_build_object(
            'id', id,
            'name', full_name,
            'email', email,
            'role', initcap(role::text),
            'status', initcap(account_status),
            'time', public.admin_time_label(created_at)
          ) as item
          from public.profiles
          where deleted_at is null
          order by created_at desc
          limit 5
        ) registrations
      ), '[]'::jsonb),
      'recent_courses',
      coalesce((
        select jsonb_agg(item)
        from (
          select jsonb_build_object(
            'title', c.title,
            'subtitle', c.code || ' - ' || coalesce(p.full_name, 'No instructor'),
            'time', public.admin_time_label(c.created_at),
            'type', 'course'
          ) as item
          from public.courses c
          left join public.profiles p on p.id = c.instructor_id
          order by c.created_at desc
          limit 5
        ) courses
      ), '[]'::jsonb),
      'recent_materials',
      coalesce((
        select jsonb_agg(item)
        from (
          select jsonb_build_object(
            'title', m.title,
            'subtitle', c.code || ' - ' || coalesce(p.full_name, 'Unknown uploader'),
            'time', public.admin_time_label(m.created_at),
            'type', 'material'
          ) as item
          from public.materials m
          join public.courses c on c.id = m.course_id
          left join public.profiles p on p.id = m.uploaded_by
          order by m.created_at desc
          limit 5
        ) materials
      ), '[]'::jsonb),
      'recent_assessments',
      coalesce((
        select jsonb_agg(item)
        from (
          select jsonb_build_object(
            'title', q.title,
            'subtitle', c.code || ' - Quiz ' || case when q.is_published then 'published' else 'draft' end,
            'time', public.admin_time_label(coalesce(q.published_at, q.updated_at, q.created_at)),
            'type', 'quiz'
          ) as item,
          coalesce(q.published_at, q.updated_at, q.created_at) as sort_at
          from public.quizzes q
          join public.courses c on c.id = q.course_id
          union all
          select jsonb_build_object(
            'title', a.title,
            'subtitle', c.code || ' - Assignment ' || case when a.is_published then 'published' else 'draft' end,
            'time', public.admin_time_label(coalesce(a.published_at, a.updated_at, a.created_at)),
            'type', 'assignment'
          ),
          coalesce(a.published_at, a.updated_at, a.created_at)
          from public.assignments a
          join public.courses c on c.id = a.course_id
          order by sort_at desc
          limit 6
        ) assessments
      ), '[]'::jsonb),
      'system_activity',
      coalesce((
        select jsonb_agg(item)
        from (
          select jsonb_build_object(
            'title', summary,
            'subtitle', coalesce(actor.full_name, 'Admin action'),
            'time', public.admin_time_label(log.created_at),
            'type', log.action
          ) as item,
          log.created_at as sort_at
          from public.admin_activity_logs log
          left join public.profiles actor on actor.id = log.actor_id
          union all
          select jsonb_build_object(
            'title', 'New registration',
            'subtitle', full_name || ' joined as ' || initcap(role::text),
            'time', public.admin_time_label(created_at),
            'type', 'registration'
          ),
          created_at
          from public.profiles
          where deleted_at is null
          order by sort_at desc
          limit 8
        ) activity_items
      ), '[]'::jsonb),
      'alerts',
      jsonb_build_array(
        jsonb_build_object(
          'title', 'Archived courses',
          'body', (select count(*) from public.courses where status = 'archived') || ' courses are archived.',
          'level', 'info'
        ),
        jsonb_build_object(
          'title', 'Draft assessments',
          'body', (
            (select count(*) from public.quizzes where not is_published) +
            (select count(*) from public.assignments where not is_published)
          ) || ' quizzes or assignments are still drafts.',
          'level', 'warning'
        )
      )
    )
  end
$$;

create or replace function public.list_admin_courses(
  p_search text default '',
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
      select jsonb_agg(item order by created_at desc)
      from (
        select
          c.created_at,
          jsonb_build_object(
            'id', c.id,
            'title', c.title,
            'code', c.code,
            'description', c.description,
            'status', c.status::text,
            'semester', c.semester,
            'max_students', c.max_students,
            'allow_self_enrollment', c.allow_self_enrollment,
            'is_visible', c.is_visible,
            'instructor_id', c.instructor_id,
            'instructor_name', coalesce(p.full_name, 'Unknown instructor'),
            'created_at', c.created_at,
            'updated_at', c.updated_at,
            'students_count', (select count(*) from public.enrollments e where e.course_id = c.id and e.status = 'active'),
            'materials_count', (select count(*) from public.materials m where m.course_id = c.id),
            'quizzes_count', (select count(*) from public.quizzes q where q.course_id = c.id),
            'assignments_count', (select count(*) from public.assignments a where a.course_id = c.id),
            'announcements_count', (select count(*) from public.announcements an where an.course_id = c.id)
          ) as item
        from public.courses c
        left join public.profiles p on p.id = c.instructor_id
        where (
            coalesce(nullif(trim(p_search), ''), '') = ''
            or c.title ilike '%' || trim(p_search) || '%'
            or c.code ilike '%' || trim(p_search) || '%'
            or coalesce(p.full_name, '') ilike '%' || trim(p_search) || '%'
          )
          and (
            p_status is null
            or trim(p_status) = ''
            or lower(p_status) = 'all'
            or c.status::text = lower(p_status)
          )
          and (p_instructor_id is null or c.instructor_id = p_instructor_id)
      ) rows
    ), '[]'::jsonb)
  end
$$;

create or replace function public.admin_save_course(
  p_course_id uuid default null,
  p_title text default '',
  p_code text default '',
  p_description text default '',
  p_instructor_id uuid default null,
  p_status text default 'draft',
  p_semester text default '',
  p_max_students integer default 50,
  p_allow_self_enrollment boolean default false,
  p_is_visible boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  saved_id uuid;
  saved_title text;
  action_name text;
begin
  perform public.require_active_admin();

  if trim(coalesce(p_title, '')) = '' or trim(coalesce(p_code, '')) = '' then
    raise exception 'Course title and code are required.' using errcode = '22023';
  end if;

  if lower(p_status) not in ('draft', 'published', 'archived') then
    raise exception 'Invalid course status.' using errcode = '22023';
  end if;

  if p_instructor_id is null or not exists (
    select 1 from public.profiles
    where id = p_instructor_id and role in ('instructor', 'admin') and deleted_at is null
  ) then
    raise exception 'A valid instructor is required.' using errcode = '22023';
  end if;

  if p_course_id is null then
    insert into public.courses (
      title, code, description, instructor_id, status, semester, max_students,
      allow_self_enrollment, is_visible
    )
    values (
      trim(p_title), upper(trim(p_code)), trim(coalesce(p_description, '')),
      p_instructor_id, lower(p_status)::public.course_status, trim(coalesce(p_semester, '')),
      greatest(coalesce(p_max_students, 50), 1), coalesce(p_allow_self_enrollment, false),
      coalesce(p_is_visible, false)
    )
    returning id, title into saved_id, saved_title;
    action_name := 'course_created';
  else
    update public.courses
    set
      title = trim(p_title),
      code = upper(trim(p_code)),
      description = trim(coalesce(p_description, '')),
      instructor_id = p_instructor_id,
      status = lower(p_status)::public.course_status,
      semester = trim(coalesce(p_semester, '')),
      max_students = greatest(coalesce(p_max_students, 50), 1),
      allow_self_enrollment = coalesce(p_allow_self_enrollment, false),
      is_visible = coalesce(p_is_visible, false),
      archived_at = case when lower(p_status) = 'archived' then coalesce(archived_at, timezone('utc', now())) else null end,
      updated_at = timezone('utc', now())
    where id = p_course_id
    returning id, title into saved_id, saved_title;
    action_name := 'course_edited';
  end if;

  if saved_id is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity(action_name, initcap(replace(action_name, '_', ' ')) || ': ' || saved_title, null, jsonb_build_object('course_id', saved_id));

  return (select public.list_admin_courses(saved_title, null, null)->0);
end;
$$;

create or replace function public.admin_archive_course(p_course_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
begin
  perform public.require_active_admin();

  update public.courses
  set status = 'archived', is_visible = false, archived_at = timezone('utc', now()), updated_at = timezone('utc', now())
  where id = p_course_id
  returning title into course_title;

  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity('course_archived', 'Archived course: ' || course_title, null, jsonb_build_object('course_id', p_course_id));
end;
$$;

create or replace function public.list_admin_materials(
  p_search text default '',
  p_course_id uuid default null,
  p_file_type text default null,
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
          'id', m.id,
          'course_id', m.course_id,
          'course_title', c.title,
          'course_code', c.code,
          'instructor_id', c.instructor_id,
          'instructor_name', coalesce(ip.full_name, 'Unknown instructor'),
          'title', m.title,
          'description', m.description,
          'file_name', m.file_name,
          'file_type', m.file_type,
          'file_size_bytes', m.file_size_bytes,
          'mime_type', m.mime_type,
          'storage_path', m.storage_path,
          'uploaded_by', m.uploaded_by,
          'uploaded_by_name', coalesce(up.full_name, 'Unknown uploader'),
          'created_at', m.created_at,
          'updated_at', m.updated_at
        )
        order by m.created_at desc
      )
      from public.materials m
      join public.courses c on c.id = m.course_id
      left join public.profiles ip on ip.id = c.instructor_id
      left join public.profiles up on up.id = m.uploaded_by
      where (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or m.title ilike '%' || trim(p_search) || '%'
          or m.file_name ilike '%' || trim(p_search) || '%'
          or c.title ilike '%' || trim(p_search) || '%'
          or c.code ilike '%' || trim(p_search) || '%'
        )
        and (p_course_id is null or m.course_id = p_course_id)
        and (p_instructor_id is null or c.instructor_id = p_instructor_id)
        and (
          p_file_type is null
          or trim(p_file_type) = ''
          or lower(p_file_type) = 'all'
          or lower(m.file_type) = lower(p_file_type)
        )
    ), '[]'::jsonb)
  end
$$;

create or replace function public.admin_update_material(p_material_id uuid, p_title text, p_description text default '')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  material_title text;
begin
  perform public.require_active_admin();

  if trim(coalesce(p_title, '')) = '' then
    raise exception 'Material title is required.' using errcode = '22023';
  end if;

  update public.materials
  set title = trim(p_title), description = trim(coalesce(p_description, '')), updated_at = timezone('utc', now())
  where id = p_material_id
  returning title into material_title;

  if material_title is null then
    raise exception 'Material not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity('material_edited', 'Edited material: ' || material_title, null, jsonb_build_object('material_id', p_material_id));
end;
$$;

create or replace function public.admin_delete_material(p_material_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  material_title text;
  material_path text;
begin
  perform public.require_active_admin();

  delete from public.materials
  where id = p_material_id
  returning title, storage_path into material_title, material_path;

  if material_title is null then
    raise exception 'Material not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity('material_removed', 'Removed material: ' || material_title, null, jsonb_build_object('material_id', p_material_id));
  return material_path;
end;
$$;

create or replace function public.list_admin_quizzes(
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
          'id', q.id,
          'course_id', q.course_id,
          'course_title', c.title,
          'course_code', c.code,
          'instructor_id', c.instructor_id,
          'instructor_name', coalesce(ip.full_name, 'Unknown instructor'),
          'title', q.title,
          'description', q.description,
          'instructions', q.instructions,
          'due_at', q.due_at,
          'max_points', q.max_points,
          'duration_minutes', q.duration_minutes,
          'is_published', q.is_published,
          'question_schema', q.question_schema,
          'question_count', jsonb_array_length(q.question_schema),
          'created_by', q.created_by,
          'created_by_name', coalesce(cp.full_name, 'Unknown creator'),
          'created_at', q.created_at,
          'updated_at', q.updated_at,
          'published_at', q.published_at
        )
        order by q.created_at desc
      )
      from public.quizzes q
      join public.courses c on c.id = q.course_id
      left join public.profiles ip on ip.id = c.instructor_id
      left join public.profiles cp on cp.id = q.created_by
      where (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or q.title ilike '%' || trim(p_search) || '%'
          or c.title ilike '%' || trim(p_search) || '%'
          or c.code ilike '%' || trim(p_search) || '%'
        )
        and (p_course_id is null or q.course_id = p_course_id)
        and (p_instructor_id is null or c.instructor_id = p_instructor_id)
        and (
          p_status is null
          or trim(p_status) = ''
          or lower(p_status) = 'all'
          or (lower(p_status) = 'published' and q.is_published)
          or (lower(p_status) = 'draft' and not q.is_published)
        )
    ), '[]'::jsonb)
  end
$$;

create or replace function public.admin_update_quiz(
  p_quiz_id uuid,
  p_title text,
  p_description text default '',
  p_instructions text default '',
  p_due_at timestamptz default null,
  p_max_points integer default 100,
  p_duration_minutes integer default null,
  p_is_published boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  quiz_title text;
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
    published_at = case when coalesce(p_is_published, false) then coalesce(published_at, timezone('utc', now())) else null end,
    updated_at = timezone('utc', now())
  where id = p_quiz_id
  returning title into quiz_title;

  if quiz_title is null then
    raise exception 'Quiz not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity('quiz_edited', 'Edited quiz: ' || quiz_title, null, jsonb_build_object('quiz_id', p_quiz_id));
end;
$$;

create or replace function public.admin_set_quiz_published(p_quiz_id uuid, p_is_published boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  quiz_title text;
begin
  perform public.require_active_admin();
  update public.quizzes
  set is_published = p_is_published, published_at = case when p_is_published then timezone('utc', now()) else null end, updated_at = timezone('utc', now())
  where id = p_quiz_id
  returning title into quiz_title;
  if quiz_title is null then raise exception 'Quiz not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity(case when p_is_published then 'quiz_published' else 'quiz_unpublished' end, (case when p_is_published then 'Published quiz: ' else 'Unpublished quiz: ' end) || quiz_title, null, jsonb_build_object('quiz_id', p_quiz_id));
end;
$$;

create or replace function public.admin_delete_quiz(p_quiz_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  quiz_title text;
begin
  perform public.require_active_admin();
  delete from public.quizzes where id = p_quiz_id returning title into quiz_title;
  if quiz_title is null then raise exception 'Quiz not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity('quiz_deleted', 'Deleted quiz: ' || quiz_title, null, jsonb_build_object('quiz_id', p_quiz_id));
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
          or (lower(p_status) = 'overdue' and a.due_at < timezone('utc', now()))
        )
    ), '[]'::jsonb)
  end
$$;

create or replace function public.admin_update_assignment(
  p_assignment_id uuid,
  p_title text,
  p_instructions text default '',
  p_attachment_requirements text default '',
  p_due_at timestamptz default null,
  p_max_points integer default 100,
  p_is_published boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  assignment_title text;
begin
  perform public.require_active_admin();
  if trim(coalesce(p_title, '')) = '' then raise exception 'Assignment title is required.' using errcode = '22023'; end if;
  update public.assignments
  set title = trim(p_title), instructions = trim(coalesce(p_instructions, '')), attachment_requirements = trim(coalesce(p_attachment_requirements, '')), due_at = p_due_at, max_points = greatest(coalesce(p_max_points, 100), 1), is_published = coalesce(p_is_published, false), published_at = case when coalesce(p_is_published, false) then coalesce(published_at, timezone('utc', now())) else null end, updated_at = timezone('utc', now())
  where id = p_assignment_id
  returning title into assignment_title;
  if assignment_title is null then raise exception 'Assignment not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity('assignment_edited', 'Edited assignment: ' || assignment_title, null, jsonb_build_object('assignment_id', p_assignment_id));
end;
$$;

create or replace function public.admin_set_assignment_published(p_assignment_id uuid, p_is_published boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  assignment_title text;
begin
  perform public.require_active_admin();
  update public.assignments
  set is_published = p_is_published, published_at = case when p_is_published then timezone('utc', now()) else null end, updated_at = timezone('utc', now())
  where id = p_assignment_id
  returning title into assignment_title;
  if assignment_title is null then raise exception 'Assignment not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity(case when p_is_published then 'assignment_published' else 'assignment_unpublished' end, (case when p_is_published then 'Published assignment: ' else 'Unpublished assignment: ' end) || assignment_title, null, jsonb_build_object('assignment_id', p_assignment_id));
end;
$$;

create or replace function public.admin_delete_assignment(p_assignment_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  assignment_title text;
begin
  perform public.require_active_admin();
  delete from public.assignments where id = p_assignment_id returning title into assignment_title;
  if assignment_title is null then raise exception 'Assignment not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity('assignment_deleted', 'Deleted assignment: ' || assignment_title, null, jsonb_build_object('assignment_id', p_assignment_id));
end;
$$;

create or replace function public.list_admin_announcements(
  p_search text default '',
  p_course_id uuid default null,
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
          'id', an.id,
          'course_id', an.course_id,
          'course_title', c.title,
          'course_code', c.code,
          'instructor_id', c.instructor_id,
          'instructor_name', coalesce(ip.full_name, 'Unknown instructor'),
          'title', an.title,
          'body', an.body,
          'is_pinned', an.is_pinned,
          'created_by', an.created_by,
          'created_by_name', coalesce(cp.full_name, 'Unknown creator'),
          'created_at', an.created_at,
          'updated_at', an.updated_at
        )
        order by an.created_at desc
      )
      from public.announcements an
      join public.courses c on c.id = an.course_id
      left join public.profiles ip on ip.id = c.instructor_id
      left join public.profiles cp on cp.id = an.created_by
      where (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or an.title ilike '%' || trim(p_search) || '%'
          or an.body ilike '%' || trim(p_search) || '%'
          or c.title ilike '%' || trim(p_search) || '%'
          or c.code ilike '%' || trim(p_search) || '%'
        )
        and (p_course_id is null or an.course_id = p_course_id)
        and (p_instructor_id is null or c.instructor_id = p_instructor_id)
    ), '[]'::jsonb)
  end
$$;

create or replace function public.admin_save_announcement(
  p_announcement_id uuid default null,
  p_course_id uuid default null,
  p_title text default '',
  p_body text default '',
  p_is_pinned boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  saved_id uuid;
  saved_title text;
  action_name text;
begin
  perform public.require_active_admin();
  if p_course_id is null or not exists (select 1 from public.courses where id = p_course_id) then raise exception 'A valid course is required.' using errcode = '22023'; end if;
  if trim(coalesce(p_title, '')) = '' or trim(coalesce(p_body, '')) = '' then raise exception 'Announcement title and body are required.' using errcode = '22023'; end if;

  if p_announcement_id is null then
    insert into public.announcements (course_id, title, body, is_pinned, created_by)
    values (p_course_id, trim(p_title), trim(p_body), coalesce(p_is_pinned, false), auth.uid())
    returning id, title into saved_id, saved_title;
    action_name := 'announcement_created';
  else
    update public.announcements
    set course_id = p_course_id, title = trim(p_title), body = trim(p_body), is_pinned = coalesce(p_is_pinned, false), updated_at = timezone('utc', now())
    where id = p_announcement_id
    returning id, title into saved_id, saved_title;
    action_name := 'announcement_edited';
  end if;

  if saved_id is null then raise exception 'Announcement not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity(action_name, initcap(replace(action_name, '_', ' ')) || ': ' || saved_title, null, jsonb_build_object('announcement_id', saved_id, 'course_id', p_course_id));
end;
$$;

create or replace function public.admin_delete_announcement(p_announcement_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  announcement_title text;
begin
  perform public.require_active_admin();
  delete from public.announcements where id = p_announcement_id returning title into announcement_title;
  if announcement_title is null then raise exception 'Announcement not found.' using errcode = 'P0002'; end if;
  perform public.admin_log_activity('announcement_deleted', 'Deleted announcement: ' || announcement_title, null, jsonb_build_object('announcement_id', p_announcement_id));
end;
$$;
