create table if not exists public.platform_settings (
  id boolean primary key default true check (id),
  settings jsonb not null default '{}'::jsonb,
  session_invalidated_at timestamptz,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.platform_settings enable row level security;

drop policy if exists "platform_settings_select_admin" on public.platform_settings;
create policy "platform_settings_select_admin"
on public.platform_settings for select
using (public.is_current_active_admin());

drop policy if exists "platform_settings_update_admin" on public.platform_settings;
create policy "platform_settings_update_admin"
on public.platform_settings for update
using (public.is_current_active_admin())
with check (public.is_current_active_admin());

create or replace function public.default_platform_settings()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'platform_name', 'Grasp',
    'landing_page_registration', true,
    'default_dashboard_time_range', 'last_30_days',
    'default_list_sorting', 'newest_first',
    'require_strong_passwords', true,
    'allow_password_change', true,
    'admin_user_creation_enabled', true,
    'prevent_deleting_last_admin', true,
    'admin_notifications', true,
    'new_user_notifications', true,
    'course_activity_notifications', true,
    'ai_generation_failure_notifications', true,
    'require_relogin_after_password_change', true,
    'auto_logout_inactive_users', true,
    'timeout_duration_minutes', 30
  )
$$;

create or replace function public.seed_platform_settings()
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.platform_settings (id, settings)
  values (true, public.default_platform_settings())
  on conflict (id) do update
  set settings = public.default_platform_settings() || public.platform_settings.settings
$$;

select public.seed_platform_settings();

create or replace function public.platform_setting(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(ps.settings, '{}'::jsonb) -> p_key
  from public.platform_settings ps
  where ps.id = true
$$;

create or replace function public.platform_setting_bool(p_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select ps.settings ->> p_key
      from public.platform_settings ps
      where ps.id = true
    ),
    public.default_platform_settings() ->> p_key
  )::boolean
$$;

create or replace function public.platform_setting_text(p_key text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select ps.settings ->> p_key
      from public.platform_settings ps
      where ps.id = true
    ),
    public.default_platform_settings() ->> p_key
  )
$$;

create or replace function public.platform_settings_payload()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.default_platform_settings()
    || coalesce(
      (select ps.settings from public.platform_settings ps where ps.id = true),
      '{}'::jsonb
    )
    || jsonb_build_object(
      'platform_session_invalidated_at',
      (
        select case
          when ps.session_invalidated_at is null then null
          else to_jsonb(ps.session_invalidated_at)
        end
        from public.platform_settings ps
        where ps.id = true
      )
    )
$$;

create or replace function public.validate_platform_settings(p_settings jsonb)
returns jsonb
language plpgsql
stable
as $$
declare
  merged jsonb := public.default_platform_settings() || coalesce(p_settings, '{}'::jsonb);
  key text;
  boolean_keys text[] := array[
    'landing_page_registration',
    'require_strong_passwords',
    'allow_password_change',
    'admin_user_creation_enabled',
    'prevent_deleting_last_admin',
    'admin_notifications',
    'new_user_notifications',
    'course_activity_notifications',
    'ai_generation_failure_notifications',
    'require_relogin_after_password_change',
    'auto_logout_inactive_users'
  ];
  allowed_keys text[] := array[
    'platform_name',
    'landing_page_registration',
    'default_dashboard_time_range',
    'default_list_sorting',
    'require_strong_passwords',
    'allow_password_change',
    'admin_user_creation_enabled',
    'prevent_deleting_last_admin',
    'admin_notifications',
    'new_user_notifications',
    'course_activity_notifications',
    'ai_generation_failure_notifications',
    'require_relogin_after_password_change',
    'auto_logout_inactive_users',
    'timeout_duration_minutes'
  ];
begin
  for key in select jsonb_object_keys(coalesce(p_settings, '{}'::jsonb)) loop
    if not key = any(allowed_keys) then
      raise exception 'Unknown platform setting: %', key using errcode = '22023';
    end if;
  end loop;

  if jsonb_typeof(merged -> 'platform_name') <> 'string'
     or length(trim(merged ->> 'platform_name')) < 1
     or length(trim(merged ->> 'platform_name')) > 80 then
    raise exception 'Platform name must be 1 to 80 characters.' using errcode = '22023';
  end if;

  foreach key in array boolean_keys loop
    if jsonb_typeof(merged -> key) <> 'boolean' then
      raise exception 'Invalid value for %.', key using errcode = '22023';
    end if;
  end loop;

  if merged ->> 'default_dashboard_time_range' not in ('last_7_days', 'last_30_days', 'this_semester', 'all_time') then
    raise exception 'Select a valid dashboard time range.' using errcode = '22023';
  end if;

  if merged ->> 'default_list_sorting' not in ('newest_first', 'oldest_first', 'a_z') then
    raise exception 'Select a valid default list sorting option.' using errcode = '22023';
  end if;

  if jsonb_typeof(merged -> 'timeout_duration_minutes') <> 'number'
     or (merged ->> 'timeout_duration_minutes')::int not in (15, 30, 60, 120) then
    raise exception 'Select a valid timeout duration.' using errcode = '22023';
  end if;

  return jsonb_build_object(
    'platform_name', trim(merged ->> 'platform_name'),
    'landing_page_registration', (merged ->> 'landing_page_registration')::boolean,
    'default_dashboard_time_range', merged ->> 'default_dashboard_time_range',
    'default_list_sorting', merged ->> 'default_list_sorting',
    'require_strong_passwords', (merged ->> 'require_strong_passwords')::boolean,
    'allow_password_change', (merged ->> 'allow_password_change')::boolean,
    'admin_user_creation_enabled', (merged ->> 'admin_user_creation_enabled')::boolean,
    'prevent_deleting_last_admin', (merged ->> 'prevent_deleting_last_admin')::boolean,
    'admin_notifications', (merged ->> 'admin_notifications')::boolean,
    'new_user_notifications', (merged ->> 'new_user_notifications')::boolean,
    'course_activity_notifications', (merged ->> 'course_activity_notifications')::boolean,
    'ai_generation_failure_notifications', (merged ->> 'ai_generation_failure_notifications')::boolean,
    'require_relogin_after_password_change', (merged ->> 'require_relogin_after_password_change')::boolean,
    'auto_logout_inactive_users', (merged ->> 'auto_logout_inactive_users')::boolean,
    'timeout_duration_minutes', (merged ->> 'timeout_duration_minutes')::int
  );
end;
$$;

create or replace function public.get_public_platform_settings()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'platform_name', public.platform_settings_payload() ->> 'platform_name',
    'landing_page_registration', (public.platform_settings_payload() ->> 'landing_page_registration')::boolean,
    'require_strong_passwords', (public.platform_settings_payload() ->> 'require_strong_passwords')::boolean,
    'platform_session_invalidated_at', public.platform_settings_payload() -> 'platform_session_invalidated_at'
  )
$$;

create or replace function public.get_effective_platform_settings()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return public.get_public_platform_settings();
  end if;

  return public.platform_settings_payload();
end;
$$;

create or replace function public.get_admin_platform_settings()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_active_admin();
  return public.platform_settings_payload();
end;
$$;

create or replace function public.update_admin_platform_settings(p_settings jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  sanitized jsonb;
  old_settings jsonb;
  changed_key text;
begin
  perform public.require_active_admin();
  sanitized := public.validate_platform_settings(p_settings);

  select public.platform_settings_payload() into old_settings;

  insert into public.platform_settings (id, settings, updated_by, updated_at)
  values (true, sanitized, auth.uid(), timezone('utc', now()))
  on conflict (id) do update
  set settings = excluded.settings,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;

  for changed_key in select jsonb_object_keys(sanitized) loop
    if old_settings -> changed_key is distinct from sanitized -> changed_key then
      perform public.admin_log_activity(
        'platform_setting_changed',
        'Updated platform setting: ' || changed_key,
        null,
        jsonb_build_object(
          'setting', changed_key,
          'old_value', old_settings -> changed_key,
          'new_value', sanitized -> changed_key
        )
      );
    end if;
  end loop;

  return public.platform_settings_payload();
end;
$$;

create or replace function public.reset_admin_platform_settings()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_active_admin();

  update public.platform_settings
  set settings = public.default_platform_settings(),
      updated_by = auth.uid(),
      updated_at = timezone('utc', now())
  where id = true;

  perform public.admin_log_activity(
    'platform_settings_reset',
    'Reset platform settings to defaults',
    null,
    '{}'::jsonb
  );

  return public.platform_settings_payload();
end;
$$;

create or replace function public.force_logout_all_users()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  invalidated_at timestamptz := timezone('utc', now());
begin
  perform public.require_active_admin();

  update public.platform_settings
  set session_invalidated_at = invalidated_at,
      updated_by = auth.uid(),
      updated_at = invalidated_at
  where id = true;

  perform public.admin_log_activity(
    'force_logout_all_users',
    'Forced all users to sign in again',
    null,
    jsonb_build_object('session_invalidated_at', invalidated_at)
  );

  return jsonb_build_object('platform_session_invalidated_at', invalidated_at);
end;
$$;

create or replace function public.platform_validate_password(p_password text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.platform_setting_bool('require_strong_passwords') then
    if length(coalesce(p_password, '')) < 6 then
      raise exception 'Password must be at least 6 characters.' using errcode = '22023';
    end if;
    return;
  end if;

  if length(coalesce(p_password, '')) < 8
     or p_password !~ '[A-Z]'
     or p_password !~ '[a-z]'
     or p_password !~ '[0-9]'
     or p_password !~ '[^A-Za-z0-9]' then
    raise exception 'Password must be at least 8 characters and include uppercase, lowercase, number, and special character.' using errcode = '22023';
  end if;
end;
$$;

create or replace function public.ensure_password_change_allowed(p_password text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.platform_setting_bool('allow_password_change') then
    raise exception 'Password changes are currently disabled by the administrator.' using errcode = '42501';
  end if;

  perform public.platform_validate_password(p_password);
end;
$$;

create or replace function public.ensure_admin_user_creation_allowed(p_password text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.require_active_admin();

  if not public.platform_setting_bool('admin_user_creation_enabled') then
    raise exception 'Admin user creation is currently disabled.' using errcode = '42501';
  end if;

  perform public.platform_validate_password(p_password);
end;
$$;

create or replace function public.ensure_admin_user_update_allowed(
  p_user_id uuid,
  p_role text,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target public.profiles%rowtype;
  active_admins int;
begin
  perform public.require_active_admin();

  if not public.platform_setting_bool('prevent_deleting_last_admin') then
    return;
  end if;

  select * into target
  from public.profiles
  where id = p_user_id
  for update;

  if target.id is null then
    raise exception 'User not found.' using errcode = 'P0002';
  end if;

  if target.role <> 'admin'::public.app_role or target.account_status <> 'active' or target.deleted_at is not null then
    return;
  end if;

  if lower(coalesce(p_role, target.role::text)) = 'admin'
     and lower(coalesce(p_status, target.account_status)) = 'active' then
    return;
  end if;

  select count(*) into active_admins
  from public.profiles
  where role = 'admin'
    and account_status = 'active'
    and deleted_at is null;

  if active_admins <= 1 then
    raise exception 'At least one active admin account must remain.' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.ensure_admin_user_remove_allowed(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ensure_admin_user_update_allowed(p_user_id, 'removed', 'removed');
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_role text;
begin
  if not public.platform_setting_bool('landing_page_registration') then
    raise exception 'Public registration is currently disabled.' using errcode = '42501';
  end if;

  requested_role := lower(coalesce(new.raw_user_meta_data ->> 'role', 'student'));
  if requested_role not in ('student', 'instructor') then
    requested_role := 'student';
  end if;

  if requested_role = 'student'
     and not public.app_permission_enabled('allow_public_student_registration'::text) then
    raise exception 'Student registration is currently disabled.' using errcode = '42501';
  end if;

  if requested_role = 'instructor'
     and not public.app_permission_enabled('allow_public_instructor_registration'::text) then
    raise exception 'Instructor registration is currently disabled.' using errcode = '42501';
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    requested_role::public.app_role
  )
  on conflict (id) do nothing;

  return new;
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

  perform public.ensure_admin_user_remove_allowed(p_user_id);

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

grant execute on function public.get_public_platform_settings() to anon, authenticated;
grant execute on function public.get_effective_platform_settings() to authenticated;
grant execute on function public.get_admin_platform_settings() to authenticated;
grant execute on function public.update_admin_platform_settings(jsonb) to authenticated;
grant execute on function public.reset_admin_platform_settings() to authenticated;
grant execute on function public.force_logout_all_users() to authenticated;
grant execute on function public.ensure_password_change_allowed(text) to authenticated;
grant execute on function public.ensure_admin_user_creation_allowed(text) to authenticated;
grant execute on function public.ensure_admin_user_update_allowed(uuid, text, text) to authenticated;
