alter table public.courses
  add column if not exists semester text not null default '',
  add column if not exists max_students integer not null default 50,
  add column if not exists allow_self_enrollment boolean not null default false,
  add column if not exists is_visible boolean not null default false,
  add column if not exists archived_at timestamptz;

alter table public.materials
  add column if not exists file_name text not null default '',
  add column if not exists file_type text not null default '',
  add column if not exists file_size_bytes bigint not null default 0,
  add column if not exists mime_type text not null default 'application/octet-stream';

update public.materials
set
  file_name = case when file_name = '' then title else file_name end,
  file_type = case when file_type = '' then 'FILE' else file_type end
where file_name = '' or file_type = '';

create or replace function public.current_user_email()
returns text
language sql
stable
as $$
  select email from public.profiles where id = auth.uid()
$$;

drop policy if exists "enrollments_delete_instructor_or_admin" on public.enrollments;
create policy "enrollments_delete_instructor_or_admin"
on public.enrollments for delete
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "enrollments_update_instructor_or_admin" on public.enrollments;
create policy "enrollments_update_instructor_or_admin"
on public.enrollments for update
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
)
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "materials_delete_instructor_or_admin" on public.materials;
create policy "materials_delete_instructor_or_admin"
on public.materials for delete
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "announcements_update_instructor_or_admin" on public.announcements;
create policy "announcements_update_instructor_or_admin"
on public.announcements for update
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
)
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "announcements_delete_instructor_or_admin" on public.announcements;
create policy "announcements_delete_instructor_or_admin"
on public.announcements for delete
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);
