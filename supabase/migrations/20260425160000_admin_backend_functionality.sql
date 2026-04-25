alter table public.profiles
  add column if not exists account_status text not null default 'active',
  add column if not exists phone text not null default '',
  add column if not exists deleted_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_account_status_check'
  ) then
    alter table public.profiles
      add constraint profiles_account_status_check
      check (account_status in ('active', 'inactive', 'suspended', 'removed'));
  end if;
end $$;

update public.profiles
set account_status = 'active'
where account_status is null or account_status = '';

create index if not exists idx_profiles_role on public.profiles (role);
create index if not exists idx_profiles_account_status on public.profiles (account_status);
create index if not exists idx_profiles_created_at on public.profiles (created_at desc);

create table if not exists public.admin_activity_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id) on delete set null,
  target_user_id uuid references public.profiles (id) on delete set null,
  action text not null,
  summary text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_admin_activity_logs_actor_id
on public.admin_activity_logs (actor_id, created_at desc);

create index if not exists idx_admin_activity_logs_target_user_id
on public.admin_activity_logs (target_user_id, created_at desc);

alter table public.admin_activity_logs enable row level security;

drop policy if exists "admin_activity_logs_select_admin" on public.admin_activity_logs;
create policy "admin_activity_logs_select_admin"
on public.admin_activity_logs for select
using (public.current_user_role() = 'admin');

drop policy if exists "admin_activity_logs_insert_admin" on public.admin_activity_logs;
create policy "admin_activity_logs_insert_admin"
on public.admin_activity_logs for insert
with check (public.current_user_role() = 'admin');

create or replace function public.is_current_active_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
      and account_status = 'active'
      and deleted_at is null
  )
$$;

create or replace function public.require_active_admin()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_current_active_admin() then
    raise exception 'Admin access required.' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.raise_admin_access_required()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  raise exception 'Admin access required.' using errcode = '42501';
end;
$$;

create or replace function public.current_user_account_status()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select account_status from public.profiles where id = auth.uid()
$$;

drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin"
on public.profiles for update
using (
  auth.uid() = id
  or public.is_current_active_admin()
)
with check (
  public.is_current_active_admin()
  or (
    auth.uid() = id
    and role = public.current_user_role()
    and account_status = public.current_user_account_status()
    and deleted_at is null
  )
);

create or replace function public.admin_log_activity(
  p_action text,
  p_summary text,
  p_target_user_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_active_admin();

  insert into public.admin_activity_logs (
    actor_id,
    target_user_id,
    action,
    summary,
    metadata
  )
  values (
    auth.uid(),
    p_target_user_id,
    p_action,
    p_summary,
    coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

create or replace function public.admin_time_label(p_timestamp timestamptz)
returns text
language sql
stable
as $$
  select case
    when p_timestamp is null then ''
    when p_timestamp > timezone('utc', now()) - interval '1 minute' then 'Just now'
    when p_timestamp > timezone('utc', now()) - interval '1 hour'
      then floor(extract(epoch from (timezone('utc', now()) - p_timestamp)) / 60)::int || ' min ago'
    when p_timestamp > timezone('utc', now()) - interval '1 day'
      then floor(extract(epoch from (timezone('utc', now()) - p_timestamp)) / 3600)::int || ' hours ago'
    when p_timestamp > timezone('utc', now()) - interval '7 days'
      then floor(extract(epoch from (timezone('utc', now()) - p_timestamp)) / 86400)::int || ' days ago'
    else to_char(p_timestamp at time zone 'utc', 'Mon DD, YYYY')
  end
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
            'title', c.title,
            'subtitle', p.full_name || ' created course ' || c.code,
            'time', public.admin_time_label(c.created_at),
            'type', 'course_created'
          ),
          c.created_at
          from public.courses c
          join public.profiles p on p.id = c.instructor_id
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
          'title', 'Suspended accounts',
          'body', (
            select count(*)
            from public.profiles
            where account_status = 'suspended'
              and deleted_at is null
          ) || ' accounts are currently suspended.',
          'level', 'warning'
        ),
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
        )
      )
    )
  end
$$;

create or replace function public.list_admin_users(
  p_search text default '',
  p_role text default null,
  p_status text default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then
      public.raise_admin_access_required()
    else coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', p.id,
          'name', p.full_name,
          'email', p.email,
          'role', p.role::text,
          'status', p.account_status,
          'avatar_url', p.avatar_url,
          'phone', p.phone,
          'department', p.department,
          'created_at', p.created_at,
          'updated_at', p.updated_at,
          'last_active_at', greatest(p.updated_at, p.created_at),
          'courses_count',
          case
            when p.role = 'instructor' then (
              select count(*) from public.courses c where c.instructor_id = p.id
            )
            when p.role = 'student' then (
              select count(*) from public.enrollments e where e.student_id = p.id and e.status = 'active'
            )
            else 0
          end,
          'submissions_count',
          (select count(*) from public.submissions s where s.student_id = p.id),
          'admin_actions_count',
          (select count(*) from public.admin_activity_logs l where l.actor_id = p.id)
        )
        order by p.created_at desc
      )
      from public.profiles p
      where p.deleted_at is null
        and (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or p.full_name ilike '%' || trim(p_search) || '%'
          or p.email ilike '%' || trim(p_search) || '%'
        )
        and (
          p_role is null
          or trim(p_role) = ''
          or lower(p_role) = 'all'
          or p.role::text = lower(p_role)
        )
        and (
          p_status is null
          or trim(p_status) = ''
          or lower(p_status) = 'all'
          or p.account_status = lower(p_status)
        )
    ), '[]'::jsonb)
  end
$$;

create or replace function public.get_admin_user_detail(p_user_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then
      public.raise_admin_access_required()
    else (
      select jsonb_build_object(
        'user',
        jsonb_build_object(
          'id', p.id,
          'name', p.full_name,
          'email', p.email,
          'role', p.role::text,
          'status', p.account_status,
          'avatar_url', p.avatar_url,
          'phone', p.phone,
          'department', p.department,
          'student_id', p.student_id,
          'program', p.program,
          'academic_year', p.academic_year,
          'employee_id', p.employee_id,
          'bio', p.bio,
          'created_at', p.created_at,
          'updated_at', p.updated_at,
          'last_active_at', greatest(p.updated_at, p.created_at),
          'courses_count',
          case
            when p.role = 'instructor' then (
              select count(*) from public.courses c where c.instructor_id = p.id
            )
            when p.role = 'student' then (
              select count(*) from public.enrollments e where e.student_id = p.id and e.status = 'active'
            )
            else 0
          end,
          'submissions_count',
          (select count(*) from public.submissions s where s.student_id = p.id),
          'admin_actions_count',
          (select count(*) from public.admin_activity_logs l where l.actor_id = p.id)
        ),
        'courses',
        coalesce((
          select jsonb_agg(item order by sort_at desc)
          from (
            select jsonb_build_object(
              'title', c.title,
              'subtitle', c.code || ' - ' || initcap(c.status::text),
              'status', c.status::text,
              'created_at', c.created_at
            ) as item,
            c.created_at as sort_at
            from public.courses c
            where p.role = 'instructor'
              and c.instructor_id = p.id
            union all
            select jsonb_build_object(
              'title', c.title,
              'subtitle', c.code || ' - Enrolled ' || public.admin_time_label(e.enrolled_at),
              'status', e.status,
              'created_at', e.enrolled_at
            ),
            e.enrolled_at
            from public.enrollments e
            join public.courses c on c.id = e.course_id
            where p.role = 'student'
              and e.student_id = p.id
            limit 5
          ) course_items
        ), '[]'::jsonb),
        'activity',
        coalesce((
          select jsonb_agg(item order by sort_at desc)
          from (
            select jsonb_build_object(
              'title', log.summary,
              'subtitle', initcap(replace(log.action, '_', ' ')),
              'time', public.admin_time_label(log.created_at),
              'type', log.action
            ) as item,
            log.created_at as sort_at
            from public.admin_activity_logs log
            where log.actor_id = p.id or log.target_user_id = p.id
            union all
            select jsonb_build_object(
              'title', 'Account created',
              'subtitle', 'System registration',
              'time', public.admin_time_label(p.created_at),
              'type', 'registration'
            ),
            p.created_at
            limit 8
          ) activity_items
        ), '[]'::jsonb)
      )
      from public.profiles p
      where p.id = p_user_id
        and p.deleted_at is null
    )
  end
$$;

create or replace function public.admin_update_user(
  p_user_id uuid,
  p_full_name text default null,
  p_role text default null,
  p_status text default null,
  p_department text default null,
  p_phone text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  old_profile public.profiles%rowtype;
  new_profile public.profiles%rowtype;
  requested_role text;
  requested_status text;
  summaries text[] := array[]::text[];
  i integer;
begin
  perform public.require_active_admin();

  select * into old_profile
  from public.profiles
  where id = p_user_id
    and deleted_at is null
  for update;

  if old_profile.id is null then
    raise exception 'User not found.' using errcode = 'P0002';
  end if;

  requested_role := lower(nullif(trim(coalesce(p_role, old_profile.role::text)), ''));
  requested_status := lower(nullif(trim(coalesce(p_status, old_profile.account_status)), ''));

  if requested_role not in ('student', 'instructor', 'admin') then
    raise exception 'Invalid role.' using errcode = '22023';
  end if;

  if requested_status not in ('active', 'inactive', 'suspended') then
    raise exception 'Invalid account status.' using errcode = '22023';
  end if;

  if p_user_id = auth.uid() and requested_role <> 'admin' then
    raise exception 'You cannot remove your own admin role.' using errcode = '42501';
  end if;

  if p_user_id = auth.uid() and requested_status <> 'active' then
    raise exception 'You cannot disable your own admin account.' using errcode = '42501';
  end if;

  update public.profiles
  set
    full_name = coalesce(nullif(trim(p_full_name), ''), full_name),
    role = requested_role::public.app_role,
    account_status = requested_status,
    department = coalesce(trim(p_department), department),
    phone = coalesce(trim(p_phone), phone),
    updated_at = timezone('utc', now())
  where id = p_user_id
  returning * into new_profile;

  if old_profile.role <> new_profile.role then
    summaries := array_append(
      summaries,
      'Changed role for ' || new_profile.full_name || ' from ' ||
      initcap(old_profile.role::text) || ' to ' || initcap(new_profile.role::text)
    );
  end if;

  if old_profile.account_status <> new_profile.account_status then
    summaries := array_append(
      summaries,
      'Changed status for ' || new_profile.full_name || ' from ' ||
      initcap(old_profile.account_status) || ' to ' || initcap(new_profile.account_status)
    );
  end if;

  if old_profile.full_name <> new_profile.full_name then
    summaries := array_append(summaries, 'Updated profile for ' || new_profile.full_name);
  end if;

  if array_length(summaries, 1) is null then
    summaries := array['Updated profile for ' || new_profile.full_name];
  end if;

  for i in 1..array_length(summaries, 1) loop
    perform public.admin_log_activity(
      case
        when summaries[i] ilike 'Changed role%' then 'user_role_changed'
        when summaries[i] ilike 'Changed status%' then 'user_status_changed'
        else 'user_profile_updated'
      end,
      summaries[i],
      p_user_id,
      jsonb_build_object(
        'old_role', old_profile.role::text,
        'new_role', new_profile.role::text,
        'old_status', old_profile.account_status,
        'new_status', new_profile.account_status
      )
    );
  end loop;

  return public.get_admin_user_detail(p_user_id);
end;
$$;

create or replace function public.admin_remove_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_profile public.profiles%rowtype;
begin
  perform public.require_active_admin();

  if p_user_id = auth.uid() then
    raise exception 'You cannot remove your own account.' using errcode = '42501';
  end if;

  select * into target_profile
  from public.profiles
  where id = p_user_id
    and deleted_at is null
  for update;

  if target_profile.id is null then
    raise exception 'User not found.' using errcode = 'P0002';
  end if;

  update public.profiles
  set
    account_status = 'removed',
    deleted_at = timezone('utc', now()),
    updated_at = timezone('utc', now())
  where id = p_user_id;

  perform public.admin_log_activity(
    'user_removed',
    'Removed user ' || target_profile.full_name,
    p_user_id,
    jsonb_build_object('email', target_profile.email, 'role', target_profile.role::text)
  );
end;
$$;

create or replace function public.get_current_admin_profile()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select case
    when not public.is_current_active_admin() then
      public.raise_admin_access_required()
    else (
      select jsonb_build_object(
        'profile',
        jsonb_build_object(
          'id', p.id,
          'name', p.full_name,
          'email', p.email,
          'role', p.role::text,
          'status', p.account_status,
          'avatar_url', p.avatar_url,
          'phone', p.phone,
          'department', p.department,
          'employee_id', p.employee_id,
          'bio', p.bio,
          'created_at', p.created_at,
          'updated_at', p.updated_at,
          'last_active_at', greatest(p.updated_at, p.created_at),
          'admin_actions_count',
          (select count(*) from public.admin_activity_logs l where l.actor_id = p.id),
          'managed_users_count',
          (select count(distinct target_user_id) from public.admin_activity_logs l where l.actor_id = p.id and target_user_id is not null)
        ),
        'activity',
        coalesce((
          select jsonb_agg(item)
          from (
            select jsonb_build_object(
              'title', summary,
              'subtitle', initcap(replace(action, '_', ' ')),
              'time', public.admin_time_label(created_at),
              'type', action
            ) as item
            from public.admin_activity_logs
            where actor_id = p.id
            order by created_at desc
            limit 8
          ) profile_activity
        ), '[]'::jsonb)
      )
      from public.profiles p
      where p.id = auth.uid()
    )
  end
$$;

create or replace function public.admin_update_own_profile(
  p_full_name text,
  p_email text default '',
  p_phone text default '',
  p_department text default '',
  p_bio text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_profile public.profiles%rowtype;
begin
  perform public.require_active_admin();

  if trim(coalesce(p_full_name, '')) = '' then
    raise exception 'Full name is required.' using errcode = '22023';
  end if;

  update public.profiles
  set
    full_name = trim(p_full_name),
    email = coalesce(nullif(trim(p_email), ''), email),
    phone = trim(coalesce(p_phone, '')),
    department = trim(coalesce(p_department, '')),
    bio = trim(coalesce(p_bio, '')),
    updated_at = timezone('utc', now())
  where id = auth.uid()
  returning * into updated_profile;

  perform public.admin_log_activity(
    'admin_profile_updated',
    'Updated admin profile',
    auth.uid(),
    '{}'::jsonb
  );

  return public.get_current_admin_profile();
end;
$$;
