alter table public.quizzes
  add column if not exists instructions text not null default '',
  add column if not exists is_published boolean not null default false,
  add column if not exists published_at timestamptz,
  add column if not exists duration_minutes integer,
  add column if not exists question_schema jsonb not null default '[]'::jsonb;

alter table public.assignments
  add column if not exists attachment_requirements text not null default '',
  add column if not exists is_published boolean not null default false,
  add column if not exists published_at timestamptz,
  add column if not exists rubric jsonb not null default '[]'::jsonb;

create index if not exists idx_quizzes_course_id_is_published
on public.quizzes (course_id, is_published);

create index if not exists idx_assignments_course_id_is_published
on public.assignments (course_id, is_published);

drop policy if exists "quizzes_select_related" on public.quizzes;
create policy "quizzes_select_related"
on public.quizzes for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
  or (
    is_published = true
    and exists (
      select 1
      from public.enrollments
      where enrollments.course_id = quizzes.course_id
        and enrollments.student_id = auth.uid()
        and enrollments.status = 'active'
    )
  )
);

drop policy if exists "quizzes_update_instructor_or_admin" on public.quizzes;
create policy "quizzes_update_instructor_or_admin"
on public.quizzes for update
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
)
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "quizzes_delete_instructor_or_admin" on public.quizzes;
create policy "quizzes_delete_instructor_or_admin"
on public.quizzes for delete
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "assignments_select_related" on public.assignments;
create policy "assignments_select_related"
on public.assignments for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
  or (
    is_published = true
    and exists (
      select 1
      from public.enrollments
      where enrollments.course_id = assignments.course_id
        and enrollments.student_id = auth.uid()
        and enrollments.status = 'active'
    )
  )
);

drop policy if exists "assignments_update_instructor_or_admin" on public.assignments;
create policy "assignments_update_instructor_or_admin"
on public.assignments for update
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
)
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "assignments_delete_instructor_or_admin" on public.assignments;
create policy "assignments_delete_instructor_or_admin"
on public.assignments for delete
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);
