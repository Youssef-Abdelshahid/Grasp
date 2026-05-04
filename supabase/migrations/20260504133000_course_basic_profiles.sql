create or replace function public.can_view_course_people(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or public.is_course_instructor(p_course_id)
    or public.is_student_enrolled(p_course_id)
$$;

create or replace function public.list_course_students_basic(p_course_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case
    when not exists (select 1 from public.courses where id = p_course_id) then
      public.raise_admin_access_required()
    when not public.can_view_course_people(p_course_id) then
      public.raise_admin_access_required()
    else coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'name', p.full_name,
          'email', p.email
        )
        order by p.full_name
      )
      from public.enrollments e
      join public.profiles p on p.id = e.student_id
      where e.course_id = p_course_id
        and e.status = 'active'
        and p.role = 'student'
        and p.account_status = 'active'
        and p.deleted_at is null
    ), '[]'::jsonb)
  end
$$;

drop function if exists public.get_course_basic_profile(uuid, uuid);
