create or replace function public.get_admin_course_members(p_course_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then public.raise_admin_access_required()
    when not exists (select 1 from public.courses where id = p_course_id) then
      jsonb_build_object('instructor', null, 'instructors', '[]'::jsonb, 'students', '[]'::jsonb)
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
      'instructors',
      public.course_instructor_summary(p_course_id),
      'students',
      coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', p.id,
            'name', p.full_name,
            'email', p.email,
            'role', p.role::text,
            'status', p.account_status,
            'enrollment_status', e.status,
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

create or replace function public.admin_add_course_students(
  p_course_id uuid,
  p_student_ids uuid[]
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
  clean_student_ids uuid[];
  provided_count integer;
  distinct_count integer;
  valid_count integer;
begin
  perform public.require_active_admin();

  select title into course_title from public.courses where id = p_course_id;
  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  select array_agg(distinct id), count(*), count(distinct id)
  into clean_student_ids, provided_count, distinct_count
  from unnest(coalesce(p_student_ids, array[]::uuid[])) as selected(id)
  where id is not null;

  if coalesce(provided_count, 0) = 0 then
    raise exception 'Select at least one student.' using errcode = '22023';
  end if;

  if provided_count <> distinct_count then
    raise exception 'Each student can only be selected once.' using errcode = '22023';
  end if;

  select count(*)
  into valid_count
  from public.profiles p
  where p.id = any(clean_student_ids)
    and p.role = 'student'
    and p.account_status = 'active'
    and p.deleted_at is null;

  if valid_count <> distinct_count then
    raise exception 'Only active student accounts can be added to a course.' using errcode = '22023';
  end if;

  insert into public.enrollments (course_id, student_id, status, enrolled_at)
  select p_course_id, id, 'active', timezone('utc', now())
  from unnest(clean_student_ids) as selected(id)
  on conflict (course_id, student_id)
  do update set status = 'active', enrolled_at = timezone('utc', now());

  perform public.admin_log_activity(
    'course_students_added',
    'Added ' || distinct_count || ' student' || case when distinct_count = 1 then '' else 's' end || ' to ' || course_title,
    null,
    jsonb_build_object('course_id', p_course_id, 'student_ids', clean_student_ids)
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
begin
  perform public.admin_add_course_students(p_course_id, array[p_student_id]);
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
  affected_count integer;
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
    and deleted_at is null;

  if student_name is null then
    raise exception 'Student not found.' using errcode = 'P0002';
  end if;

  update public.enrollments
  set status = 'removed'
  where course_id = p_course_id
    and student_id = p_student_id
    and status = 'active';

  get diagnostics affected_count = row_count;
  if affected_count = 0 then
    raise exception 'Student is not actively enrolled in this course.' using errcode = 'P0002';
  end if;

  perform public.admin_log_activity(
    'course_student_removed',
    'Removed ' || student_name || ' from ' || course_title,
    p_student_id,
    jsonb_build_object('course_id', p_course_id)
  );
end;
$$;
