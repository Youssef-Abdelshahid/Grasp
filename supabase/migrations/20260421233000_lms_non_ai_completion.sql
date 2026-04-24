alter table public.profiles
  add column if not exists student_id text default '',
  add column if not exists program text default '',
  add column if not exists academic_year text default '',
  add column if not exists department text default '',
  add column if not exists employee_id text default '',
  add column if not exists bio text default '',
  add column if not exists preferences jsonb not null default '{}'::jsonb;

alter table public.submissions
  add column if not exists file_name text,
  add column if not exists file_size_bytes bigint,
  add column if not exists storage_path text,
  add column if not exists attempt_number integer not null default 1,
  add column if not exists graded_at timestamptz;

create index if not exists idx_submissions_quiz_student
on public.submissions (quiz_id, student_id, submitted_at desc);

create index if not exists idx_submissions_assignment_student
on public.submissions (assignment_id, student_id, submitted_at desc);

create or replace function public.is_student_enrolled(course_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.enrollments
    where course_id = course_uuid
      and student_id = auth.uid()
      and status = 'active'
  )
$$;

create or replace function public.create_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_category text default 'general'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, title, body, category)
  values (p_user_id, p_title, p_body, p_category);
end;
$$;

create or replace function public.notify_announcement_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
begin
  select title into course_title
  from public.courses
  where id = new.course_id;

  insert into public.notifications (user_id, title, body, category)
  select
    e.student_id,
    'New announcement in ' || coalesce(course_title, 'your course'),
    new.title,
    'announcement'
  from public.enrollments e
  where e.course_id = new.course_id
    and e.status = 'active';

  return new;
end;
$$;

drop trigger if exists on_announcement_created_notify on public.announcements;
create trigger on_announcement_created_notify
after insert on public.announcements
for each row execute procedure public.notify_announcement_created();

create or replace function public.notify_quiz_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
begin
  if not new.is_published or (tg_op = 'UPDATE' and coalesce(old.is_published, false) = true) then
    return new;
  end if;

  select title into course_title
  from public.courses
  where id = new.course_id;

  insert into public.notifications (user_id, title, body, category)
  select
    e.student_id,
    'Quiz published in ' || coalesce(course_title, 'your course'),
    new.title,
    'quiz'
  from public.enrollments e
  where e.course_id = new.course_id
    and e.status = 'active';

  return new;
end;
$$;

drop trigger if exists on_quiz_published_notify on public.quizzes;
create trigger on_quiz_published_notify
after insert or update of is_published on public.quizzes
for each row execute procedure public.notify_quiz_published();

create or replace function public.notify_assignment_published()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
begin
  if not new.is_published or (tg_op = 'UPDATE' and coalesce(old.is_published, false) = true) then
    return new;
  end if;

  select title into course_title
  from public.courses
  where id = new.course_id;

  insert into public.notifications (user_id, title, body, category)
  select
    e.student_id,
    'Assignment published in ' || coalesce(course_title, 'your course'),
    new.title,
    'assignment'
  from public.enrollments e
  where e.course_id = new.course_id
    and e.status = 'active';

  return new;
end;
$$;

drop trigger if exists on_assignment_published_notify on public.assignments;
create trigger on_assignment_published_notify
after insert or update of is_published on public.assignments
for each row execute procedure public.notify_assignment_published();

create or replace function public.notify_submission_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  instructor_user_id uuid;
  item_title text;
  category_name text;
begin
  if new.quiz_id is not null then
    select c.instructor_id, q.title
    into instructor_user_id, item_title
    from public.quizzes q
    join public.courses c on c.id = q.course_id
    where q.id = new.quiz_id;
    category_name := 'quiz_submission';
  else
    select c.instructor_id, a.title
    into instructor_user_id, item_title
    from public.assignments a
    join public.courses c on c.id = a.course_id
    where a.id = new.assignment_id;
    category_name := 'assignment_submission';
  end if;

  if instructor_user_id is not null then
    perform public.create_notification(
      instructor_user_id,
      'New student submission',
      coalesce(item_title, 'A submission') || ' was submitted.',
      category_name
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_submission_created_notify on public.submissions;
create trigger on_submission_created_notify
after insert on public.submissions
for each row execute procedure public.notify_submission_created();

drop policy if exists "submissions_insert_student" on public.submissions;
create policy "submissions_insert_student"
on public.submissions for insert
with check (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
  and (
    (quiz_id is not null and exists (
      select 1
      from public.quizzes q
      where q.id = submissions.quiz_id
        and q.is_published = true
        and public.is_student_enrolled(q.course_id)
    ))
    or
    (assignment_id is not null and exists (
      select 1
      from public.assignments a
      where a.id = submissions.assignment_id
        and a.is_published = true
        and public.is_student_enrolled(a.course_id)
    ))
  )
);

insert into storage.buckets (id, name, public)
values ('assignment-submissions', 'assignment-submissions', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('user-avatars', 'user-avatars', false)
on conflict (id) do nothing;

drop policy if exists "assignment_submissions_select_related" on storage.objects;
create policy "assignment_submissions_select_related"
on storage.objects for select
using (
  bucket_id = 'assignment-submissions'
  and (
    public.current_user_role() = 'admin'
    or exists (
      select 1
      from public.submissions s
      where s.storage_path = name
        and (
          s.student_id = auth.uid()
          or exists (
            select 1
            from public.assignments a
            where a.id = s.assignment_id
              and public.is_course_instructor(a.course_id)
          )
        )
    )
  )
);

drop policy if exists "assignment_submissions_insert_student" on storage.objects;
create policy "assignment_submissions_insert_student"
on storage.objects for insert
with check (
  bucket_id = 'assignment-submissions'
  and public.current_user_role() = 'student'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "assignment_submissions_delete_related" on storage.objects;
create policy "assignment_submissions_delete_related"
on storage.objects for delete
using (
  bucket_id = 'assignment-submissions'
  and (
    public.current_user_role() = 'admin'
    or exists (
      select 1
      from public.submissions s
      where s.storage_path = name
        and (
          s.student_id = auth.uid()
          or exists (
            select 1
            from public.assignments a
            where a.id = s.assignment_id
              and public.is_course_instructor(a.course_id)
          )
        )
    )
  )
);

drop policy if exists "user_avatars_select_authenticated" on storage.objects;
create policy "user_avatars_select_authenticated"
on storage.objects for select
using (
  bucket_id = 'user-avatars'
  and auth.role() = 'authenticated'
);

drop policy if exists "user_avatars_insert_owner_or_admin" on storage.objects;
create policy "user_avatars_insert_owner_or_admin"
on storage.objects for insert
with check (
  bucket_id = 'user-avatars'
  and (
    public.current_user_role() = 'admin'
    or split_part(name, '/', 1) = auth.uid()::text
  )
);

drop policy if exists "user_avatars_update_owner_or_admin" on storage.objects;
create policy "user_avatars_update_owner_or_admin"
on storage.objects for update
using (
  bucket_id = 'user-avatars'
  and (
    public.current_user_role() = 'admin'
    or split_part(name, '/', 1) = auth.uid()::text
  )
)
with check (
  bucket_id = 'user-avatars'
  and (
    public.current_user_role() = 'admin'
    or split_part(name, '/', 1) = auth.uid()::text
  )
);

drop policy if exists "user_avatars_delete_owner_or_admin" on storage.objects;
create policy "user_avatars_delete_owner_or_admin"
on storage.objects for delete
using (
  bucket_id = 'user-avatars'
  and (
    public.current_user_role() = 'admin'
    or split_part(name, '/', 1) = auth.uid()::text
  )
);
