create table if not exists public.course_instructors (
  course_id uuid not null references public.courses (id) on delete cascade,
  instructor_id uuid not null references public.profiles (id) on delete restrict,
  assigned_by uuid references public.profiles (id) on delete set null,
  assigned_at timestamptz not null default timezone('utc', now()),
  primary key (course_id, instructor_id)
);

create index if not exists idx_course_instructors_instructor_id
on public.course_instructors (instructor_id);

insert into public.course_instructors (course_id, instructor_id, assigned_by)
select c.id, c.instructor_id, c.instructor_id
from public.courses c
join public.profiles p on p.id = c.instructor_id
where p.role = 'instructor'
on conflict (course_id, instructor_id) do nothing;

create or replace function public.validate_course_instructor_assignment()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.profiles
    where id = new.instructor_id
      and role = 'instructor'
      and account_status = 'active'
      and deleted_at is null
  ) then
    raise exception 'Only active instructors can be assigned to a course.' using errcode = '22023';
  end if;

  return new;
end;
$$;

drop trigger if exists validate_course_instructor_assignment on public.course_instructors;
create trigger validate_course_instructor_assignment
before insert or update on public.course_instructors
for each row execute function public.validate_course_instructor_assignment();

alter table public.course_instructors enable row level security;

create or replace function public.is_course_instructor(course_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.course_instructors ci
    where ci.course_id = course_uuid
      and ci.instructor_id = auth.uid()
  )
  or exists(
    select 1
    from public.courses c
    where c.id = course_uuid
      and c.instructor_id = auth.uid()
  )
$$;

drop policy if exists "course_instructors_select_related" on public.course_instructors;
create policy "course_instructors_select_related"
on public.course_instructors for select
using (
  public.current_user_role() = 'admin'
  or instructor_id = auth.uid()
  or public.is_course_instructor(course_id)
  or exists (
    select 1 from public.enrollments e
    where e.course_id = course_instructors.course_id
      and e.student_id = auth.uid()
      and e.status = 'active'
  )
);

drop policy if exists "course_instructors_insert_admin" on public.course_instructors;
create policy "course_instructors_insert_admin"
on public.course_instructors for insert
with check (
  public.current_user_role() = 'admin'
  or (
    public.current_user_role() = 'instructor'
    and instructor_id = auth.uid()
    and exists (
      select 1 from public.courses c
      where c.id = course_id and c.instructor_id = auth.uid()
    )
  )
);

drop policy if exists "course_instructors_delete_admin" on public.course_instructors;
create policy "course_instructors_delete_admin"
on public.course_instructors for delete
using (public.current_user_role() = 'admin');

drop policy if exists "courses_select_related" on public.courses;
create policy "courses_select_related"
on public.courses for select
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(id)
  or exists (
    select 1 from public.enrollments
    where course_id = courses.id
      and student_id = auth.uid()
      and status = 'active'
  )
);

drop policy if exists "courses_update_instructor_or_admin" on public.courses;
create policy "courses_update_instructor_or_admin"
on public.courses for update
using (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(id)
)
with check (
  public.current_user_role() = 'admin'
  or public.is_course_instructor(id)
);

create or replace function public.can_manage_course_activity(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or public.is_course_instructor(p_course_id)
$$;

create or replace function public.course_instructor_summary(p_course_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', p.id,
        'name', p.full_name,
        'email', p.email,
        'role', p.role::text,
        'status', p.account_status,
        'is_primary', p.id = c.instructor_id,
        'assigned_at', ci.assigned_at
      )
      order by case when p.id = c.instructor_id then 0 else 1 end, p.full_name
    )
    from public.courses c
    join public.course_instructors ci on ci.course_id = c.id
    join public.profiles p on p.id = ci.instructor_id
    where c.id = p_course_id
      and p.deleted_at is null
  ), '[]'::jsonb)
$$;

create or replace function public.course_instructor_names(p_course_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select string_agg(p.full_name, ', ' order by case when p.id = c.instructor_id then 0 else 1 end, p.full_name)
    from public.courses c
    join public.course_instructors ci on ci.course_id = c.id
    join public.profiles p on p.id = ci.instructor_id
    where c.id = p_course_id
      and p.deleted_at is null
  ), (
    select coalesce(p.full_name, 'Unknown instructor')
    from public.courses c
    left join public.profiles p on p.id = c.instructor_id
    where c.id = p_course_id
  ), 'Unknown instructor')
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
            'instructor_name', public.course_instructor_names(c.id),
            'instructors', public.course_instructor_summary(c.id),
            'created_at', c.created_at,
            'updated_at', c.updated_at,
            'students_count', (select count(*) from public.enrollments e where e.course_id = c.id and e.status = 'active'),
            'materials_count', (select count(*) from public.materials m where m.course_id = c.id),
            'quizzes_count', (select count(*) from public.quizzes q where q.course_id = c.id),
            'assignments_count', (select count(*) from public.assignments a where a.course_id = c.id),
            'announcements_count', (select count(*) from public.announcements an where an.course_id = c.id)
          ) as item
        from public.courses c
        where (
            coalesce(nullif(trim(p_search), ''), '') = ''
            or c.title ilike '%' || trim(p_search) || '%'
            or c.code ilike '%' || trim(p_search) || '%'
            or exists (
              select 1
              from public.course_instructors ci
              join public.profiles p on p.id = ci.instructor_id
              where ci.course_id = c.id
                and (
                  p.full_name ilike '%' || trim(p_search) || '%'
                  or p.email ilike '%' || trim(p_search) || '%'
                )
            )
          )
          and (
            p_status is null
            or trim(p_status) = ''
            or lower(p_status) = 'all'
            or c.status::text = lower(p_status)
          )
          and (
            p_instructor_id is null
            or c.instructor_id = p_instructor_id
            or exists (
              select 1 from public.course_instructors ci
              where ci.course_id = c.id and ci.instructor_id = p_instructor_id
            )
          )
      ) rows
    ), '[]'::jsonb)
  end
$$;

drop function if exists public.admin_save_course(
  uuid,
  text,
  text,
  text,
  uuid,
  text,
  text,
  integer,
  boolean,
  boolean
);

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
  p_is_visible boolean default false,
  p_instructor_ids uuid[] default null
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
  instructor_ids uuid[];
  primary_instructor uuid;
  distinct_count integer;
  instructor_count integer;
begin
  perform public.require_active_admin();

  if trim(coalesce(p_title, '')) = '' or trim(coalesce(p_code, '')) = '' then
    raise exception 'Course title and code are required.' using errcode = '22023';
  end if;

  if lower(p_status) not in ('draft', 'published', 'archived') then
    raise exception 'Invalid course status.' using errcode = '22023';
  end if;

  instructor_ids := coalesce(p_instructor_ids, case when p_instructor_id is null then array[]::uuid[] else array[p_instructor_id] end);
  select array_agg(id order by ordinal), count(*), count(distinct id)
  into instructor_ids, instructor_count, distinct_count
  from unnest(instructor_ids) with ordinality as selected(id, ordinal);

  if coalesce(instructor_count, 0) = 0 then
    raise exception 'Select at least one instructor.' using errcode = '22023';
  end if;

  if instructor_count <> distinct_count then
    raise exception 'Each instructor can only be assigned once.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from unnest(instructor_ids) selected(id)
    left join public.profiles p on p.id = selected.id
    where p.id is null
      or p.role <> 'instructor'
      or p.account_status <> 'active'
      or p.deleted_at is not null
  ) then
    raise exception 'Only active instructors can be assigned to a course.' using errcode = '22023';
  end if;

  primary_instructor := coalesce(p_instructor_id, instructor_ids[1]);
  if not (primary_instructor = any(instructor_ids)) then
    primary_instructor := instructor_ids[1];
  end if;

  if p_course_id is null then
    insert into public.courses (
      title, code, description, instructor_id, status, semester, max_students,
      allow_self_enrollment, is_visible
    )
    values (
      trim(p_title), upper(trim(p_code)), trim(coalesce(p_description, '')),
      primary_instructor, lower(p_status)::public.course_status, trim(coalesce(p_semester, '')),
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
      instructor_id = primary_instructor,
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

  delete from public.course_instructors where course_id = saved_id;
  insert into public.course_instructors (course_id, instructor_id, assigned_by)
  select saved_id, id, auth.uid()
  from unnest(instructor_ids) as selected(id);

  perform public.admin_log_activity(action_name, initcap(replace(action_name, '_', ' ')) || ': ' || saved_title, null, jsonb_build_object('course_id', saved_id));

  return (select public.list_admin_courses(saved_title, null, null)->0);
end;
$$;

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

create or replace function public.admin_add_course_instructor(
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

  select title into course_title from public.courses where id = p_course_id;
  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  select full_name into instructor_name
  from public.profiles
  where id = p_instructor_id
    and role = 'instructor'
    and account_status = 'active'
    and deleted_at is null;

  if instructor_name is null then
    raise exception 'A valid active instructor is required.' using errcode = '22023';
  end if;

  insert into public.course_instructors (course_id, instructor_id, assigned_by)
  values (p_course_id, p_instructor_id, auth.uid())
  on conflict (course_id, instructor_id) do nothing;

  update public.courses
  set instructor_id = coalesce(instructor_id, p_instructor_id),
      updated_at = timezone('utc', now())
  where id = p_course_id;

  perform public.admin_log_activity(
    'course_instructor_added',
    'Added ' || instructor_name || ' to ' || course_title,
    p_instructor_id,
    jsonb_build_object('course_id', p_course_id)
  );
end;
$$;

create or replace function public.admin_remove_course_instructor(
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
  remaining_count integer;
  replacement_id uuid;
begin
  perform public.require_active_admin();

  select title into course_title from public.courses where id = p_course_id;
  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  select count(*) into remaining_count
  from public.course_instructors
  where course_id = p_course_id
    and instructor_id <> p_instructor_id;

  if remaining_count < 1 then
    raise exception 'A course must have at least one instructor.' using errcode = '22023';
  end if;

  select full_name into instructor_name from public.profiles where id = p_instructor_id;

  delete from public.course_instructors
  where course_id = p_course_id
    and instructor_id = p_instructor_id;

  select instructor_id into replacement_id
  from public.course_instructors
  where course_id = p_course_id
  order by assigned_at
  limit 1;

  update public.courses
  set instructor_id = case when instructor_id = p_instructor_id then replacement_id else instructor_id end,
      updated_at = timezone('utc', now())
  where id = p_course_id;

  perform public.admin_log_activity(
    'course_instructor_removed',
    'Removed ' || coalesce(instructor_name, 'instructor') || ' from ' || course_title,
    p_instructor_id,
    jsonb_build_object('course_id', p_course_id)
  );
end;
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
begin
  perform public.admin_add_course_instructor(p_course_id, p_instructor_id);

  update public.courses
  set instructor_id = p_instructor_id,
      updated_at = timezone('utc', now())
  where id = p_course_id;
end;
$$;

create or replace function public.get_instructor_dashboard_summary()
returns jsonb
language sql
security definer
set search_path = public
as $$
  with instructor_courses as (
    select c.id, c.title
    from public.courses c
    where public.is_course_instructor(c.id)
  )
  select jsonb_build_object(
    'courses_count',
    (select count(*) from instructor_courses),
    'students_count',
    (
      select count(distinct e.student_id)
      from public.enrollments e
      join instructor_courses c on c.id = e.course_id
      where e.status = 'active'
    ),
    'pending_ai_drafts',
    (
      select count(*)
      from public.ai_generated_content a
      join instructor_courses c on c.id = a.course_id
      where a.status = 'draft'
    ),
    'average_score',
    coalesce((
      select round(avg(s.score)::numeric, 2)
      from public.submissions s
      left join public.quizzes q on q.id = s.quiz_id
      left join public.assignments a on a.id = s.assignment_id
      where s.score is not null
        and (
          q.course_id in (select id from instructor_courses)
          or a.course_id in (select id from instructor_courses)
        )
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
        join instructor_courses c on c.id = m.course_id
        union all
        select jsonb_build_object(
          'title', a.title,
          'subtitle', c.title || ' - Assignment created',
          'time', to_char(a.created_at at time zone 'utc', 'Mon DD'),
          'type', 'assignment'
        ),
        a.created_at
        from public.assignments a
        join instructor_courses c on c.id = a.course_id
        union all
        select jsonb_build_object(
          'title', 'New enrollment',
          'subtitle', p.full_name || ' joined ' || c.title,
          'time', to_char(e.enrolled_at at time zone 'utc', 'Mon DD'),
          'type', 'enrollment'
        ),
        e.enrolled_at
        from public.enrollments e
        join instructor_courses c on c.id = e.course_id
        join public.profiles p on p.id = e.student_id
        where e.status = 'active'
        order by sort_at desc
        limit 5
      ) items
    ), '[]'::jsonb)
  )
$$;
