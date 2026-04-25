create or replace function public.get_admin_course_members(p_course_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then public.raise_admin_access_required()
    else jsonb_build_object(
      'instructor',
      (
        select jsonb_build_object(
          'id', p.id,
          'name', p.full_name,
          'email', p.email,
          'role', p.role::text,
          'status', p.account_status,
          'created_at', p.created_at
        )
        from public.courses c
        join public.profiles p on p.id = c.instructor_id
        where c.id = p_course_id
      ),
      'students',
      coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', p.id,
            'name', p.full_name,
            'email', p.email,
            'role', p.role::text,
            'status', p.account_status,
            'created_at', p.created_at,
            'enrolled_at', e.enrolled_at
          )
          order by e.enrolled_at desc
        )
        from public.enrollments e
        join public.profiles p on p.id = e.student_id
        where e.course_id = p_course_id
          and e.status = 'active'
          and p.deleted_at is null
      ), '[]'::jsonb)
    )
  end
$$;

create or replace function public.admin_assign_course_instructor(
  p_course_id uuid,
  p_instructor_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
  instructor_name text;
begin
  perform public.require_active_admin();

  select full_name into instructor_name
  from public.profiles
  where id = p_instructor_id
    and role in ('instructor', 'admin')
    and account_status = 'active'
    and deleted_at is null;

  if instructor_name is null then
    raise exception 'A valid active instructor is required.' using errcode = '22023';
  end if;

  update public.courses
  set
    instructor_id = p_instructor_id,
    updated_at = timezone('utc', now())
  where id = p_course_id
  returning title into course_title;

  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity(
    'course_instructor_assigned',
    'Assigned ' || instructor_name || ' as instructor for ' || course_title,
    p_instructor_id,
    jsonb_build_object('course_id', p_course_id)
  );
end;
$$;

create or replace function public.admin_add_course_student(
  p_course_id uuid,
  p_student_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
  student_name text;
begin
  perform public.require_active_admin();

  select title into course_title from public.courses where id = p_course_id;
  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  select full_name into student_name
  from public.profiles
  where id = p_student_id
    and role = 'student'
    and account_status = 'active'
    and deleted_at is null;

  if student_name is null then
    raise exception 'A valid active student is required.' using errcode = '22023';
  end if;

  insert into public.enrollments (course_id, student_id, status)
  values (p_course_id, p_student_id, 'active')
  on conflict (course_id, student_id)
  do update set status = 'active', enrolled_at = timezone('utc', now());

  perform public.admin_log_activity(
    'course_student_added',
    'Added ' || student_name || ' to ' || course_title,
    p_student_id,
    jsonb_build_object('course_id', p_course_id)
  );
end;
$$;

create or replace function public.admin_remove_course_student(
  p_course_id uuid,
  p_student_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
  student_name text;
begin
  perform public.require_active_admin();

  select title into course_title from public.courses where id = p_course_id;
  select full_name into student_name from public.profiles where id = p_student_id;

  update public.enrollments
  set status = 'removed'
  where course_id = p_course_id
    and student_id = p_student_id;

  perform public.admin_log_activity(
    'course_student_removed',
    'Removed ' || coalesce(student_name, 'student') || ' from ' || coalesce(course_title, 'course'),
    p_student_id,
    jsonb_build_object('course_id', p_course_id)
  );
end;
$$;

create or replace function public.admin_delete_course_safe(p_course_id uuid)
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
  set
    status = 'archived',
    is_visible = false,
    archived_at = timezone('utc', now()),
    updated_at = timezone('utc', now())
  where id = p_course_id
  returning title into course_title;

  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity(
    'course_deleted',
    'Removed course from active management: ' || course_title,
    null,
    jsonb_build_object('course_id', p_course_id, 'mode', 'safe_archive')
  );
end;
$$;
