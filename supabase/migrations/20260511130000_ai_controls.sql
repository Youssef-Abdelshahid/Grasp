create table if not exists public.ai_controls (
  id boolean primary key default true,
  config jsonb not null default '{}'::jsonb,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  constraint ai_controls_singleton check (id)
);

alter table public.ai_controls enable row level security;

drop policy if exists "ai_controls_no_direct_select" on public.ai_controls;
create policy "ai_controls_no_direct_select"
on public.ai_controls for select
using (false);

drop policy if exists "ai_controls_no_direct_insert" on public.ai_controls;
create policy "ai_controls_no_direct_insert"
on public.ai_controls for insert
with check (false);

drop policy if exists "ai_controls_no_direct_update" on public.ai_controls;
create policy "ai_controls_no_direct_update"
on public.ai_controls for update
using (false)
with check (false);

drop policy if exists "ai_controls_no_direct_delete" on public.ai_controls;
create policy "ai_controls_no_direct_delete"
on public.ai_controls for delete
using (false);

create table if not exists public.ai_request_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  role text not null,
  feature_type text not null,
  model_used text,
  fallback_used boolean not null default false,
  success boolean,
  error_category text,
  created_at timestamptz not null default timezone('utc', now()),
  completed_at timestamptz
);

create index if not exists idx_ai_request_logs_created_at
on public.ai_request_logs (created_at desc);

create index if not exists idx_ai_request_logs_user_day
on public.ai_request_logs (user_id, created_at desc);

alter table public.ai_request_logs enable row level security;

drop policy if exists "ai_request_logs_no_direct_select" on public.ai_request_logs;
create policy "ai_request_logs_no_direct_select"
on public.ai_request_logs for select
using (false);

drop policy if exists "ai_request_logs_no_direct_insert" on public.ai_request_logs;
create policy "ai_request_logs_no_direct_insert"
on public.ai_request_logs for insert
with check (false);

drop policy if exists "ai_request_logs_no_direct_update" on public.ai_request_logs;
create policy "ai_request_logs_no_direct_update"
on public.ai_request_logs for update
using (false)
with check (false);

drop policy if exists "ai_request_logs_no_direct_delete" on public.ai_request_logs;
create policy "ai_request_logs_no_direct_delete"
on public.ai_request_logs for delete
using (false);

create or replace function public.default_ai_controls_config()
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'enable_ai_features', true,
    'student_flashcard_generation', true,
    'student_study_notes_generation', true,
    'instructor_ai_quiz_generation', true,
    'instructor_ai_assignment_generation', true,
    'admin_ai_quiz_generation', true,
    'admin_ai_assignment_generation', true,
    'single_question_generation', true,
    'default_ai_model', 'Gemini 3 Flash',
    'enable_daily_ai_request_limit', true,
    'student_daily_ai_requests', 20,
    'instructor_daily_ai_requests', 40,
    'admin_daily_ai_requests', 100,
    'max_material_context_size', 16000,
    'max_generated_questions_per_quiz', 30,
    'max_generated_flashcards', 40,
    'max_generated_study_notes_length', 4000
  )
$$;

create or replace function public.ai_controls_config()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.default_ai_controls_config() || coalesce(
    (select config from public.ai_controls where id = true),
    '{}'::jsonb
  )
$$;

create or replace function public.seed_default_ai_controls()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.ai_controls (id, config)
  values (true, public.default_ai_controls_config())
  on conflict (id) do nothing;
end;
$$;

select public.seed_default_ai_controls();

create or replace function public.validate_ai_controls_config(p_config jsonb)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  key_name text;
  default_config jsonb := public.default_ai_controls_config();
  bool_keys text[] := array[
    'enable_ai_features',
    'student_flashcard_generation',
    'student_study_notes_generation',
    'instructor_ai_quiz_generation',
    'instructor_ai_assignment_generation',
    'admin_ai_quiz_generation',
    'admin_ai_assignment_generation',
    'single_question_generation',
    'enable_daily_ai_request_limit'
  ];
  int_keys text[] := array[
    'student_daily_ai_requests',
    'instructor_daily_ai_requests',
    'admin_daily_ai_requests',
    'max_material_context_size',
    'max_generated_questions_per_quiz',
    'max_generated_flashcards',
    'max_generated_study_notes_length'
  ];
begin
  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception 'Invalid AI controls configuration.' using errcode = '22023';
  end if;

  for key_name in select jsonb_object_keys(p_config)
  loop
    if not default_config ? key_name then
      raise exception 'Unknown AI setting key: %.', key_name using errcode = '22023';
    end if;
  end loop;

  foreach key_name in array bool_keys
  loop
    if p_config ? key_name and jsonb_typeof(p_config -> key_name) <> 'boolean' then
      raise exception 'Invalid AI boolean setting: %.', key_name using errcode = '22023';
    end if;
  end loop;

  if p_config ? 'default_ai_model' then
    if jsonb_typeof(p_config -> 'default_ai_model') <> 'string'
      or (p_config ->> 'default_ai_model') not in (
        'Gemini 3 Flash',
        'Gemini 2.5 Flash',
        'Gemini 3.1 Flash Lite'
      )
    then
      raise exception 'Invalid AI model.' using errcode = '22023';
    end if;
  end if;

  foreach key_name in array int_keys
  loop
    if p_config ? key_name then
      if jsonb_typeof(p_config -> key_name) <> 'number'
        or (p_config ->> key_name)::integer < 0
      then
        raise exception 'Invalid AI limit setting: %.', key_name using errcode = '22023';
      end if;
    end if;
  end loop;
end;
$$;

create or replace function public.get_admin_ai_controls_config()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.require_admin();
  return public.ai_controls_config();
end;
$$;

create or replace function public.update_admin_ai_controls_config(p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  merged_config jsonb;
begin
  perform public.require_admin();
  perform public.validate_ai_controls_config(p_config);

  merged_config := public.default_ai_controls_config() || p_config;

  insert into public.ai_controls (id, config, updated_by, updated_at)
  values (true, merged_config, auth.uid(), timezone('utc', now()))
  on conflict (id) do update
  set config = excluded.config,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;

  return public.ai_controls_config();
end;
$$;

create or replace function public.reset_admin_ai_controls_config()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_admin();
  insert into public.ai_controls (id, config, updated_by, updated_at)
  values (true, public.default_ai_controls_config(), auth.uid(), timezone('utc', now()))
  on conflict (id) do update
  set config = excluded.config,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;
  return public.ai_controls_config();
end;
$$;

create or replace function public.get_admin_ai_usage_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  month_start timestamptz := date_trunc('month', timezone('utc', now()));
begin
  perform public.require_admin();

  return jsonb_build_object(
    'total_ai_requests', (
      select count(*) from public.ai_request_logs where created_at >= month_start
    ),
    'quiz_drafts_generated', (
      select count(*) from public.ai_request_logs
      where created_at >= month_start and feature_type = 'quiz_draft' and success is true
    ),
    'assignment_drafts_generated', (
      select count(*) from public.ai_request_logs
      where created_at >= month_start and feature_type = 'assignment_draft' and success is true
    ),
    'flashcard_sets_generated', (
      select count(*) from public.ai_request_logs
      where created_at >= month_start and feature_type = 'flashcards' and success is true
    ),
    'study_notes_generated', (
      select count(*) from public.ai_request_logs
      where created_at >= month_start and feature_type = 'study_notes' and success is true
    ),
    'failed_ai_requests', (
      select count(*) from public.ai_request_logs
      where created_at >= month_start and success is false
    ),
    'gemini_fallbacks_used', (
      select count(*) from public.ai_request_logs
      where created_at >= month_start and fallback_used is true
    )
  );
end;
$$;

create or replace function public.get_effective_ai_controls()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  return public.ai_controls_config();
end;
$$;

create or replace function public.begin_ai_generation_request(
  p_feature_type text,
  p_requested_count integer default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  config jsonb := public.ai_controls_config();
  user_role text := public.current_user_role();
  feature_key text;
  limit_key text;
  daily_limit integer;
  used_today integer;
  log_id uuid;
  day_start timestamptz := date_trunc('day', timezone('utc', now()));
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  if coalesce((config ->> 'enable_ai_features')::boolean, true) is not true then
    raise exception 'AI features are currently disabled by the administrator.' using errcode = '42501';
  end if;

  if p_requested_count is not null and p_requested_count < 0 then
    raise exception 'Invalid AI generation request count.' using errcode = '22023';
  end if;

  case p_feature_type
    when 'quiz_draft' then
      if user_role = 'admin' then
        feature_key := 'admin_ai_quiz_generation';
      else
        feature_key := 'instructor_ai_quiz_generation';
      end if;
      if p_requested_count is not null
        and p_requested_count > (config ->> 'max_generated_questions_per_quiz')::integer
      then
        raise exception 'The requested quiz exceeds the configured AI question limit.' using errcode = '22023';
      end if;
    when 'assignment_draft' then
      if user_role = 'admin' then
        feature_key := 'admin_ai_assignment_generation';
      else
        feature_key := 'instructor_ai_assignment_generation';
      end if;
    when 'single_question' then
      feature_key := 'single_question_generation';
    when 'flashcards' then
      feature_key := 'student_flashcard_generation';
      if p_requested_count is not null
        and p_requested_count > (config ->> 'max_generated_flashcards')::integer
      then
        raise exception 'The requested flashcard set exceeds the configured AI card limit.' using errcode = '22023';
      end if;
    when 'study_notes' then
      feature_key := 'student_study_notes_generation';
    else
      raise exception 'Unknown AI feature type.' using errcode = '22023';
  end case;

  if coalesce((config ->> feature_key)::boolean, false) is not true then
    raise exception 'You do not currently have permission to use this AI feature.' using errcode = '42501';
  end if;

  if user_role = 'student' and p_feature_type not in ('flashcards', 'study_notes') then
    raise exception 'You do not currently have permission to use this AI feature.' using errcode = '42501';
  end if;

  if user_role = 'instructor' and p_feature_type not in ('quiz_draft', 'assignment_draft', 'single_question') then
    raise exception 'You do not currently have permission to use this AI feature.' using errcode = '42501';
  end if;

  if coalesce((config ->> 'enable_daily_ai_request_limit')::boolean, true) then
    limit_key := case user_role
      when 'admin' then 'admin_daily_ai_requests'
      when 'instructor' then 'instructor_daily_ai_requests'
      else 'student_daily_ai_requests'
    end;
    daily_limit := (config ->> limit_key)::integer;

    select count(*) into used_today
    from public.ai_request_logs
    where user_id = auth.uid()
      and created_at >= day_start;

    if used_today >= daily_limit then
      raise exception 'You have reached your daily AI generation limit.' using errcode = '42501';
    end if;
  end if;

  insert into public.ai_request_logs (
    user_id,
    role,
    feature_type
  )
  values (
    auth.uid(),
    coalesce(user_role, 'unknown'),
    p_feature_type
  )
  returning id into log_id;

  return jsonb_build_object(
    'log_id', log_id,
    'config', config
  );
end;
$$;

create or replace function public.finish_ai_generation_request(
  p_log_id uuid,
  p_model_used text default null,
  p_fallback_used boolean default false,
  p_success boolean default true,
  p_error_category text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  update public.ai_request_logs
  set model_used = p_model_used,
      fallback_used = coalesce(p_fallback_used, false),
      success = p_success,
      error_category = p_error_category,
      completed_at = timezone('utc', now())
  where id = p_log_id
    and user_id = auth.uid();
end;
$$;
