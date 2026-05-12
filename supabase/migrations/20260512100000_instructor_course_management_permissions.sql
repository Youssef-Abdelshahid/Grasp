create or replace function public.default_permissions_config()
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'download_materials', true,
    'take_quizzes', true,
    'submit_assignments', true,
    'generate_flashcards', true,
    'generate_study_notes', true,
    'view_course_student_list', true,
    'create_courses', true,
    'manage_courses', true,
    'manage_course_students', true,
    'upload_materials', true,
    'manage_quizzes', true,
    'manage_assignments', true,
    'post_announcements', true,
    'use_ai_quiz_generation', true,
    'use_ai_assignment_generation', true,
    'grade_student_work', true,
    'view_student_activity', true,
    'allow_public_student_registration', true,
    'allow_public_instructor_registration', false,
    'allow_instructors_to_create_courses', true,
    'require_review_before_ai_content_published', true
  )
$$;

insert into public.app_permissions (permission_key, enabled, description)
values (
  'manage_courses',
  coalesce(
    (select enabled from public.app_permissions where permission_key = 'create_courses'),
    true
  ),
  'Allow instructors to create, edit, and delete courses'
)
on conflict (permission_key) do nothing;

insert into public.app_permissions (permission_key, enabled, description)
values (
  'manage_course_students',
  true,
  'Allow instructors to add and remove students from their assigned courses'
)
on conflict (permission_key) do nothing;

select public.seed_default_permissions();

create or replace function public.can_instructor_create_courses()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or (
      public.current_user_role() = 'instructor'
      and public.app_permission_enabled('manage_courses')
      and public.app_permission_enabled('allow_instructors_to_create_courses')
    )
$$;

create or replace function public.can_instructor_manage_courses(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or (
      public.current_user_role() = 'instructor'
      and public.is_course_instructor(p_course_id)
      and public.app_permission_enabled('manage_courses')
    )
$$;

drop policy if exists "courses_insert_instructor_or_admin" on public.courses;
create policy "courses_insert_instructor_or_admin"
on public.courses for insert
with check (
  public.is_current_active_admin()
  or (
    public.can_instructor_create_courses()
    and instructor_id = auth.uid()
  )
);

drop policy if exists "courses_update_instructor_or_admin" on public.courses;
create policy "courses_update_instructor_or_admin"
on public.courses for update
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_courses(id)
)
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_courses(id)
);

drop policy if exists "courses_delete_instructor_or_admin" on public.courses;
create policy "courses_delete_instructor_or_admin"
on public.courses for delete
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_courses(id)
);

drop policy if exists "enrollments_insert_instructor_or_admin" on public.enrollments;
create policy "enrollments_insert_instructor_or_admin"
on public.enrollments for insert
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(
    course_id,
    'manage_course_students'
  )
);

drop policy if exists "enrollments_update_instructor_or_admin" on public.enrollments;
create policy "enrollments_update_instructor_or_admin"
on public.enrollments for update
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(
    course_id,
    'manage_course_students'
  )
)
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(
    course_id,
    'manage_course_students'
  )
);

drop policy if exists "enrollments_delete_instructor_or_admin" on public.enrollments;
create policy "enrollments_delete_instructor_or_admin"
on public.enrollments for delete
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(
    course_id,
    'manage_course_students'
  )
);
