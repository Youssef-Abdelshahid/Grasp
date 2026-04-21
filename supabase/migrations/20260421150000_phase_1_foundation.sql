create extension if not exists "pgcrypto";

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('student', 'instructor', 'admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'course_status') then
    create type public.course_status as enum ('draft', 'published', 'archived');
  end if;

  if not exists (select 1 from pg_type where typname = 'submission_status') then
    create type public.submission_status as enum ('submitted', 'graded', 'returned');
  end if;

  if not exists (select 1 from pg_type where typname = 'ai_content_status') then
    create type public.ai_content_status as enum ('draft', 'approved', 'rejected');
  end if;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique not null,
  full_name text not null,
  role public.app_role not null default 'student',
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  code text not null unique,
  description text default '',
  instructor_id uuid not null references public.profiles (id) on delete restrict,
  status public.course_status not null default 'draft',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'active',
  enrolled_at timestamptz not null default timezone('utc', now()),
  unique (course_id, student_id)
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null,
  description text default '',
  storage_path text,
  uploaded_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null,
  description text default '',
  due_at timestamptz,
  max_points integer not null default 100,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null,
  instructions text default '',
  due_at timestamptz,
  max_points integer not null default 100,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title text not null,
  body text not null,
  is_pinned boolean not null default false,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  quiz_id uuid references public.quizzes (id) on delete cascade,
  assignment_id uuid references public.assignments (id) on delete cascade,
  content jsonb not null default '{}'::jsonb,
  score numeric(5, 2),
  status public.submission_status not null default 'submitted',
  submitted_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint submissions_target_check check (
    (quiz_id is not null and assignment_id is null) or
    (quiz_id is null and assignment_id is not null)
  )
);

create table if not exists public.ai_generated_content (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  material_id uuid not null references public.materials (id) on delete cascade,
  generated_by uuid not null references public.profiles (id) on delete restrict,
  content_type text not null,
  status public.ai_content_status not null default 'draft',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text default '',
  category text not null default 'general',
  is_read boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_courses_instructor_id on public.courses (instructor_id);
create index if not exists idx_enrollments_student_id on public.enrollments (student_id);
create index if not exists idx_materials_course_id on public.materials (course_id);
create index if not exists idx_quizzes_course_id on public.quizzes (course_id);
create index if not exists idx_assignments_course_id on public.assignments (course_id);
create index if not exists idx_announcements_course_id on public.announcements (course_id);
create index if not exists idx_submissions_student_id on public.submissions (student_id);
create index if not exists idx_notifications_user_id on public.notifications (user_id);
create index if not exists idx_ai_generated_content_course_id on public.ai_generated_content (course_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text;
begin
  requested_role := lower(coalesce(new.raw_user_meta_data ->> 'role', 'student'));
  if requested_role not in ('student', 'instructor') then
    requested_role := 'student';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, ''), '@', 1)),
    requested_role::public.app_role
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = excluded.full_name;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.current_user_role()
returns public.app_role
language sql
stable
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_course_instructor(course_uuid uuid)
returns boolean
language sql
stable
as $$
  select exists(
    select 1
    from public.courses
    where id = course_uuid
      and instructor_id = auth.uid()
  )
$$;

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.enrollments enable row level security;
alter table public.materials enable row level security;
alter table public.quizzes enable row level security;
alter table public.assignments enable row level security;
alter table public.announcements enable row level security;
alter table public.submissions enable row level security;
alter table public.ai_generated_content enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "profiles_select_self_or_admin" on public.profiles;
create policy "profiles_select_self_or_admin"
on public.profiles for select
using (auth.uid() = id or public.current_user_role() = 'admin');

drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin"
on public.profiles for update
using (auth.uid() = id or public.current_user_role() = 'admin')
with check (auth.uid() = id or public.current_user_role() = 'admin');

drop policy if exists "courses_select_related" on public.courses;
create policy "courses_select_related"
on public.courses for select
using (
  public.current_user_role() = 'admin'
  or instructor_id = auth.uid()
  or exists (
    select 1 from public.enrollments
    where course_id = courses.id
      and student_id = auth.uid()
  )
);

drop policy if exists "courses_insert_instructor_or_admin" on public.courses;
create policy "courses_insert_instructor_or_admin"
on public.courses for insert
with check (
  public.current_user_role() = 'admin'
  or (public.current_user_role() = 'instructor' and instructor_id = auth.uid())
);

drop policy if exists "courses_update_instructor_or_admin" on public.courses;
create policy "courses_update_instructor_or_admin"
on public.courses for update
using (
  public.current_user_role() = 'admin'
  or instructor_id = auth.uid()
)
with check (
  public.current_user_role() = 'admin'
  or instructor_id = auth.uid()
);

drop policy if exists "enrollments_select_related" on public.enrollments;
create policy "enrollments_select_related"
on public.enrollments for select
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
  or public.is_course_instructor(course_id)
);

drop policy if exists "enrollments_insert_instructor_or_admin" on public.enrollments;
create policy "enrollments_insert_instructor_or_admin"
on public.enrollments for insert
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "materials_select_related" on public.materials;
create policy "materials_select_related"
on public.materials for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
  or exists (
    select 1 from public.enrollments
    where enrollments.course_id = materials.course_id
      and enrollments.student_id = auth.uid()
  )
);

drop policy if exists "materials_insert_instructor_or_admin" on public.materials;
create policy "materials_insert_instructor_or_admin"
on public.materials for insert
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "materials_update_instructor_or_admin" on public.materials;
create policy "materials_update_instructor_or_admin"
on public.materials for update
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
)
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "quizzes_select_related" on public.quizzes;
create policy "quizzes_select_related"
on public.quizzes for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
  or exists (
    select 1 from public.enrollments
    where enrollments.course_id = quizzes.course_id
      and enrollments.student_id = auth.uid()
  )
);

drop policy if exists "quizzes_insert_instructor_or_admin" on public.quizzes;
create policy "quizzes_insert_instructor_or_admin"
on public.quizzes for insert
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "assignments_select_related" on public.assignments;
create policy "assignments_select_related"
on public.assignments for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
  or exists (
    select 1 from public.enrollments
    where enrollments.course_id = assignments.course_id
      and enrollments.student_id = auth.uid()
  )
);

drop policy if exists "assignments_insert_instructor_or_admin" on public.assignments;
create policy "assignments_insert_instructor_or_admin"
on public.assignments for insert
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "announcements_select_related" on public.announcements;
create policy "announcements_select_related"
on public.announcements for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
  or exists (
    select 1 from public.enrollments
    where enrollments.course_id = announcements.course_id
      and enrollments.student_id = auth.uid()
  )
);

drop policy if exists "announcements_insert_instructor_or_admin" on public.announcements;
create policy "announcements_insert_instructor_or_admin"
on public.announcements for insert
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "submissions_select_related" on public.submissions;
create policy "submissions_select_related"
on public.submissions for select
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
  or exists (
    select 1
    from public.quizzes q
    where q.id = submissions.quiz_id
      and public.is_course_instructor(q.course_id)
  )
  or exists (
    select 1
    from public.assignments a
    where a.id = submissions.assignment_id
      and public.is_course_instructor(a.course_id)
  )
);

drop policy if exists "submissions_insert_student" on public.submissions;
create policy "submissions_insert_student"
on public.submissions for insert
with check (
  student_id = auth.uid()
  and public.current_user_role() = 'student'
);

drop policy if exists "submissions_update_owner_or_instructor_or_admin" on public.submissions;
create policy "submissions_update_owner_or_instructor_or_admin"
on public.submissions for update
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
  or exists (
    select 1
    from public.quizzes q
    where q.id = submissions.quiz_id
      and public.is_course_instructor(q.course_id)
  )
  or exists (
    select 1
    from public.assignments a
    where a.id = submissions.assignment_id
      and public.is_course_instructor(a.course_id)
  )
)
with check (true);

drop policy if exists "ai_generated_content_select_related" on public.ai_generated_content;
create policy "ai_generated_content_select_related"
on public.ai_generated_content for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "ai_generated_content_insert_instructor_or_admin" on public.ai_generated_content;
create policy "ai_generated_content_insert_instructor_or_admin"
on public.ai_generated_content for insert
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(course_id)
);

drop policy if exists "notifications_select_owner_or_admin" on public.notifications;
create policy "notifications_select_owner_or_admin"
on public.notifications for select
using (
  public.current_user_role() = 'admin'
  or user_id = auth.uid()
);

drop policy if exists "notifications_update_owner_or_admin" on public.notifications;
create policy "notifications_update_owner_or_admin"
on public.notifications for update
using (
  public.current_user_role() = 'admin'
  or user_id = auth.uid()
)
with check (
  public.current_user_role() = 'admin'
  or user_id = auth.uid()
);

create or replace function public.get_instructor_dashboard_summary()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'courses_count',
    (select count(*) from public.courses where instructor_id = auth.uid()),
    'students_count',
    (
      select count(distinct e.student_id)
      from public.enrollments e
      join public.courses c on c.id = e.course_id
      where c.instructor_id = auth.uid()
    ),
    'pending_ai_drafts',
    (
      select count(*)
      from public.ai_generated_content a
      join public.courses c on c.id = a.course_id
      where c.instructor_id = auth.uid()
        and a.status = 'draft'
    ),
    'average_score',
    coalesce((
      select round(avg(s.score)::numeric, 2)
      from public.submissions s
      left join public.quizzes q on q.id = s.quiz_id
      left join public.assignments a on a.id = s.assignment_id
      left join public.courses cq on cq.id = q.course_id
      left join public.courses ca on ca.id = a.course_id
      where s.score is not null
        and (cq.instructor_id = auth.uid() or ca.instructor_id = auth.uid())
    ), 0),
    'recent_activity',
    coalesce((
      select jsonb_agg(item)
      from (
        select jsonb_build_object(
          'title', m.title,
          'subtitle', c.title || ' - Material uploaded',
          'time', to_char(m.created_at at time zone 'utc', 'Mon DD'),
          'type', 'material'
        ) as item,
        m.created_at as sort_at
        from public.materials m
        join public.courses c on c.id = m.course_id
        where c.instructor_id = auth.uid()
        union all
        select jsonb_build_object(
          'title', a.title,
          'subtitle', c.title || ' - Assignment created',
          'time', to_char(a.created_at at time zone 'utc', 'Mon DD'),
          'type', 'assignment'
        ),
        a.created_at
        from public.assignments a
        join public.courses c on c.id = a.course_id
        where c.instructor_id = auth.uid()
        union all
        select jsonb_build_object(
          'title', 'New enrollment',
          'subtitle', p.full_name || ' joined ' || c.title,
          'time', to_char(e.enrolled_at at time zone 'utc', 'Mon DD'),
          'type', 'enrollment'
        ),
        e.enrolled_at
        from public.enrollments e
        join public.courses c on c.id = e.course_id
        join public.profiles p on p.id = e.student_id
        where c.instructor_id = auth.uid()
        order by sort_at desc
        limit 5
      ) items
    ), '[]'::jsonb)
  )
$$;

create or replace function public.get_student_dashboard_summary()
returns jsonb
language sql
security definer
set search_path = public
as $$
  with student_courses as (
    select c.id, c.title, c.code
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    where e.student_id = auth.uid()
      and e.status = 'active'
  )
  select jsonb_build_object(
    'enrolled_courses',
    (select count(*) from student_courses),
    'pending_tasks',
    (
      select count(*)
      from (
        select q.id
        from public.quizzes q
        join student_courses sc on sc.id = q.course_id
        where q.due_at is not null
          and q.due_at >= timezone('utc', now())
          and not exists (
            select 1 from public.submissions s
            where s.quiz_id = q.id and s.student_id = auth.uid()
          )
        union all
        select a.id
        from public.assignments a
        join student_courses sc on sc.id = a.course_id
        where a.due_at is not null
          and a.due_at >= timezone('utc', now())
          and not exists (
            select 1 from public.submissions s
            where s.assignment_id = a.id and s.student_id = auth.uid()
          )
      ) pending
    ),
    'average_score',
    coalesce((
      select round(avg(score)::numeric, 2)
      from public.submissions
      where student_id = auth.uid()
        and score is not null
    ), 0),
    'completed_submissions',
    (
      select count(*)
      from public.submissions
      where student_id = auth.uid()
    ),
    'upcoming_deadlines',
    coalesce((
      select jsonb_agg(item)
      from (
        select jsonb_build_object(
          'title', title,
          'course', course,
          'due', due,
          'type', type
        ) as item
        from (
          select
            q.title as title,
            sc.title || ' - ' || sc.code as course,
            to_char(q.due_at at time zone 'utc', 'Mon DD') as due,
            'Quiz' as type,
            q.due_at as sort_due
          from public.quizzes q
          join student_courses sc on sc.id = q.course_id
          where q.due_at is not null
            and q.due_at >= timezone('utc', now())
            and not exists (
              select 1 from public.submissions s
              where s.quiz_id = q.id and s.student_id = auth.uid()
            )
          union all
          select
            a.title,
            sc.title || ' - ' || sc.code,
            to_char(a.due_at at time zone 'utc', 'Mon DD'),
            'Assignment',
            a.due_at
          from public.assignments a
          join student_courses sc on sc.id = a.course_id
          where a.due_at is not null
            and a.due_at >= timezone('utc', now())
            and not exists (
              select 1 from public.submissions s
              where s.assignment_id = a.id and s.student_id = auth.uid()
            )
          order by sort_due
          limit 4
        ) deadline_items
      ) deadlines
    ), '[]'::jsonb),
    'recent_announcements',
    coalesce((
      select jsonb_agg(item)
      from (
        select jsonb_build_object(
          'title', a.title,
          'course', sc.title || ' - ' || sc.code,
          'time', to_char(a.created_at at time zone 'utc', 'Mon DD'),
          'is_pinned', a.is_pinned
        ) as item
        from public.announcements a
        join student_courses sc on sc.id = a.course_id
        order by a.is_pinned desc, a.created_at desc
        limit 3
      ) announcement_items
    ), '[]'::jsonb)
  )
$$;

create or replace function public.get_admin_dashboard_summary()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'total_users', (select count(*) from public.profiles),
    'students_count', (select count(*) from public.profiles where role = 'student'),
    'instructors_count', (select count(*) from public.profiles where role = 'instructor'),
    'total_courses', (select count(*) from public.courses),
    'active_courses', (select count(*) from public.courses where status = 'published'),
    'ai_items_today',
    (
      select count(*)
      from public.ai_generated_content
      where created_at >= date_trunc('day', timezone('utc', now()))
    ),
    'recent_registrations',
    coalesce((
      select jsonb_agg(item)
      from (
        select jsonb_build_object(
          'name', full_name,
          'email', email,
          'role', initcap(role::text),
          'time', to_char(created_at at time zone 'utc', 'Mon DD')
        ) as item
        from public.profiles
        order by created_at desc
        limit 5
      ) registrations
    ), '[]'::jsonb),
    'system_activity',
    coalesce((
      select jsonb_agg(item)
      from (
        select jsonb_build_object(
          'title', c.title,
          'subtitle', p.full_name || ' created course ' || c.code,
          'time', to_char(c.created_at at time zone 'utc', 'Mon DD'),
          'type', 'course'
        ) as item,
        c.created_at as sort_at
        from public.courses c
        join public.profiles p on p.id = c.instructor_id
        union all
        select jsonb_build_object(
          'title', 'New enrollment',
          'subtitle', p.full_name || ' joined ' || c.title,
          'time', to_char(e.enrolled_at at time zone 'utc', 'Mon DD'),
          'type', 'enrollment'
        ),
        e.enrolled_at
        from public.enrollments e
        join public.profiles p on p.id = e.student_id
        join public.courses c on c.id = e.course_id
        union all
        select jsonb_build_object(
          'title', 'AI draft generated',
          'subtitle', c.title || ' - ' || agc.content_type,
          'time', to_char(agc.created_at at time zone 'utc', 'Mon DD'),
          'type', 'ai'
        ),
        agc.created_at
        from public.ai_generated_content agc
        join public.courses c on c.id = agc.course_id
        order by sort_at desc
        limit 5
      ) activity_items
    ), '[]'::jsonb),
    'alerts',
    jsonb_build_array(
      jsonb_build_object(
        'title', 'Published courses without enrollments',
        'body', (
          select count(*)
          from public.courses c
          where c.status = 'published'
            and not exists (
              select 1 from public.enrollments e where e.course_id = c.id
            )
        ) || ' published courses currently have no student enrollments.',
        'level', 'info'
      ),
      jsonb_build_object(
        'title', 'Pending AI drafts',
        'body', (
          select count(*) from public.ai_generated_content where status = 'draft'
        ) || ' AI-generated items are still waiting for review.',
        'level', 'warning'
      )
    )
  )
$$;

insert into storage.buckets (id, name, public)
values ('course-materials', 'course-materials', false)
on conflict (id) do nothing;

drop policy if exists "course_materials_select_related" on storage.objects;
create policy "course_materials_select_related"
on storage.objects for select
using (
  bucket_id = 'course-materials'
  and (
    public.current_user_role() = 'admin'
    or public.current_user_role() = 'instructor'
    or public.current_user_role() = 'student'
  )
);

drop policy if exists "course_materials_insert_instructor_or_admin" on storage.objects;
create policy "course_materials_insert_instructor_or_admin"
on storage.objects for insert
with check (
  bucket_id = 'course-materials'
  and (
    public.current_user_role() = 'admin'
    or public.current_user_role() = 'instructor'
  )
);
