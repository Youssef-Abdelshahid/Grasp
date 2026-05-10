create table if not exists public.user_settings (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  role public.app_role not null,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_user_settings_role on public.user_settings (role);

alter table public.user_settings enable row level security;

drop policy if exists "user_settings_select_owner_or_admin" on public.user_settings;
create policy "user_settings_select_owner_or_admin"
on public.user_settings for select
using (
  user_id = auth.uid()
  or public.current_user_role() = 'admin'
);

drop policy if exists "user_settings_insert_owner" on public.user_settings;
create policy "user_settings_insert_owner"
on public.user_settings for insert
with check (user_id = auth.uid());

drop policy if exists "user_settings_update_owner" on public.user_settings;
create policy "user_settings_update_owner"
on public.user_settings for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create or replace function public.default_user_settings(p_role public.app_role)
returns jsonb
language sql
stable
as $$
  select case p_role
    when 'student'::public.app_role then jsonb_build_object(
      'email_notifications', true,
      'push_notifications', true,
      'assignment_alerts', true,
      'quiz_alerts', true,
      'announcement_alerts', true,
      'deadline_reminder_24h', true,
      'deadline_reminder_1h', false,
      'study_reminders', true,
      'daily_study_reminder', true,
      'weekly_study_summary', true,
      'show_overdue_first', true,
      'default_deadline_reminder_time', '09:00'
    )
    when 'instructor'::public.app_role then jsonb_build_object(
      'email_notifications', true,
      'push_notifications', true,
      'quiz_submission_alerts', true,
      'assignment_submission_alerts', true,
      'announcement_alerts', true,
      'deadline_reminders', true,
      'default_quiz_difficulty', 'medium',
      'default_question_count', 10,
      'default_question_types', jsonb_build_array('MCQ', 'True/False', 'Short Answer', 'Matching'),
      'default_assignment_difficulty', 'medium'
    )
    else '{}'::jsonb
  end
$$;

create or replace function public.validate_user_settings(
  p_role public.app_role,
  p_settings jsonb
)
returns jsonb
language plpgsql
stable
as $$
declare
  allowed_question_types text[] := array['MCQ', 'True/False', 'Short Answer', 'Matching'];
  normalized_types jsonb := '[]'::jsonb;
  question_type text;
  difficulty text;
  assignment_difficulty text;
  question_count integer;
  reminder_time text;
begin
  if p_settings is null or jsonb_typeof(p_settings) <> 'object' then
    raise exception 'Settings payload must be an object.' using errcode = '22023';
  end if;

  if p_role = 'student'::public.app_role then
    if exists (
      select 1
      from jsonb_object_keys(p_settings) as key
      where key not in (
        'email_notifications',
        'push_notifications',
        'assignment_alerts',
        'quiz_alerts',
        'announcement_alerts',
        'deadline_reminder_24h',
        'deadline_reminder_1h',
        'study_reminders',
        'daily_study_reminder',
        'weekly_study_summary',
        'show_overdue_first',
        'default_deadline_reminder_time'
      )
    ) then
      raise exception 'Invalid student settings field.' using errcode = '22023';
    end if;

    if exists (
      select 1
      from jsonb_each(p_settings) as item(key, value)
      where key <> 'default_deadline_reminder_time'
        and jsonb_typeof(value) <> 'boolean'
    ) then
      raise exception 'Student notification settings must be booleans.' using errcode = '22023';
    end if;

    reminder_time := coalesce(p_settings ->> 'default_deadline_reminder_time', public.default_user_settings(p_role) ->> 'default_deadline_reminder_time');
    if reminder_time !~ '^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' then
      raise exception 'Reminder time must use HH:MM 24-hour format.' using errcode = '22023';
    end if;

    return public.default_user_settings(p_role) || p_settings;
  end if;

  if p_role = 'instructor'::public.app_role then
    if exists (
      select 1
      from jsonb_object_keys(p_settings) as key
      where key not in (
        'email_notifications',
        'push_notifications',
        'quiz_submission_alerts',
        'assignment_submission_alerts',
        'announcement_alerts',
        'deadline_reminders',
        'default_quiz_difficulty',
        'default_question_count',
        'default_question_types',
        'default_assignment_difficulty'
      )
    ) then
      raise exception 'Invalid instructor settings field.' using errcode = '22023';
    end if;

    if exists (
      select 1
      from jsonb_each(p_settings) as item(key, value)
      where key in (
        'email_notifications',
        'push_notifications',
        'quiz_submission_alerts',
        'assignment_submission_alerts',
        'announcement_alerts',
        'deadline_reminders'
      )
      and jsonb_typeof(value) <> 'boolean'
    ) then
      raise exception 'Instructor notification settings must be booleans.' using errcode = '22023';
    end if;

    difficulty := lower(coalesce(p_settings ->> 'default_quiz_difficulty', public.default_user_settings(p_role) ->> 'default_quiz_difficulty'));
    assignment_difficulty := lower(coalesce(p_settings ->> 'default_assignment_difficulty', public.default_user_settings(p_role) ->> 'default_assignment_difficulty'));
    if difficulty not in ('easy', 'medium', 'hard') or assignment_difficulty not in ('easy', 'medium', 'hard') then
      raise exception 'Difficulty must be easy, medium, or hard.' using errcode = '22023';
    end if;

    question_count := coalesce((p_settings ->> 'default_question_count')::integer, 10);
    if question_count < 1 or question_count > 50 then
      raise exception 'Default question count must be between 1 and 50.' using errcode = '22023';
    end if;

    if p_settings ? 'default_question_types' then
      if jsonb_typeof(p_settings -> 'default_question_types') <> 'array' then
        raise exception 'Default question types must be a list.' using errcode = '22023';
      end if;

      for question_type in
        select jsonb_array_elements_text(p_settings -> 'default_question_types')
      loop
        if not question_type = any(allowed_question_types) then
          raise exception 'Invalid default question type: %', question_type using errcode = '22023';
        end if;
        if not normalized_types ? question_type then
          normalized_types := normalized_types || to_jsonb(question_type);
        end if;
      end loop;

      if jsonb_array_length(normalized_types) = 0 then
        raise exception 'Select at least one default question type.' using errcode = '22023';
      end if;
    else
      normalized_types := public.default_user_settings(p_role) -> 'default_question_types';
    end if;

    return public.default_user_settings(p_role)
      || p_settings
      || jsonb_build_object(
        'default_quiz_difficulty', difficulty,
        'default_assignment_difficulty', assignment_difficulty,
        'default_question_count', question_count,
        'default_question_types', normalized_types
      );
  end if;

  return '{}'::jsonb;
end;
$$;

create or replace function public.ensure_user_settings(
  p_user_id uuid,
  p_role public.app_role,
  p_existing jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  merged jsonb;
begin
  merged := public.validate_user_settings(
    p_role,
    public.default_user_settings(p_role) || coalesce(p_existing, '{}'::jsonb)
  );

  insert into public.user_settings (user_id, role, settings)
  values (p_user_id, p_role, merged)
  on conflict (user_id) do update
  set role = excluded.role,
      settings = public.validate_user_settings(excluded.role, public.default_user_settings(excluded.role) || public.user_settings.settings),
      updated_at = timezone('utc', now());

  return (
    select settings
    from public.user_settings
    where user_id = p_user_id
  );
end;
$$;

insert into public.user_settings (user_id, role, settings)
select
  p.id,
  p.role,
  public.validate_user_settings(p.role, public.default_user_settings(p.role) || coalesce(p.preferences, '{}'::jsonb))
from public.profiles p
where p.role in ('student', 'instructor')
on conflict (user_id) do update
set role = excluded.role,
    settings = public.validate_user_settings(excluded.role, public.default_user_settings(excluded.role) || public.user_settings.settings),
    updated_at = timezone('utc', now());

create or replace function public.handle_profile_settings_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role in ('student', 'instructor') then
    perform public.ensure_user_settings(new.id, new.role, coalesce(new.preferences, '{}'::jsonb));
  end if;
  return new;
end;
$$;

drop trigger if exists on_profile_settings_defaults on public.profiles;
create trigger on_profile_settings_defaults
after insert or update of role, preferences on public.profiles
for each row execute procedure public.handle_profile_settings_defaults();

create or replace function public.get_current_user_settings()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_role public.app_role;
  user_settings jsonb;
begin
  select role into user_role
  from public.profiles
  where id = auth.uid();

  if user_role is null then
    raise exception 'Profile not found.' using errcode = 'P0002';
  end if;

  if user_role not in ('student', 'instructor') then
    raise exception 'Settings are not available for this role.' using errcode = '22023';
  end if;

  user_settings := public.ensure_user_settings(auth.uid(), user_role);

  return jsonb_build_object(
    'user_id', auth.uid(),
    'role', user_role,
    'settings', user_settings,
    'defaults', public.default_user_settings(user_role)
  );
end;
$$;

create or replace function public.update_current_user_settings(p_settings jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_role public.app_role;
  sanitized jsonb;
begin
  select role into user_role
  from public.profiles
  where id = auth.uid();

  if user_role is null then
    raise exception 'Profile not found.' using errcode = 'P0002';
  end if;

  if user_role not in ('student', 'instructor') then
    raise exception 'Settings are not available for this role.' using errcode = '22023';
  end if;

  sanitized := public.validate_user_settings(user_role, coalesce(p_settings, '{}'::jsonb));

  insert into public.user_settings (user_id, role, settings)
  values (auth.uid(), user_role, sanitized)
  on conflict (user_id) do update
  set role = excluded.role,
      settings = excluded.settings,
      updated_at = timezone('utc', now());

  update public.profiles
  set preferences = sanitized,
      updated_at = timezone('utc', now())
  where id = auth.uid();

  return public.get_current_user_settings();
end;
$$;

create or replace function public.reset_current_user_settings()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  user_role public.app_role;
  defaults jsonb;
begin
  select role into user_role
  from public.profiles
  where id = auth.uid();

  if user_role is null then
    raise exception 'Profile not found.' using errcode = 'P0002';
  end if;

  if user_role not in ('student', 'instructor') then
    raise exception 'Settings are not available for this role.' using errcode = '22023';
  end if;

  defaults := public.default_user_settings(user_role);

  insert into public.user_settings (user_id, role, settings)
  values (auth.uid(), user_role, defaults)
  on conflict (user_id) do update
  set role = excluded.role,
      settings = excluded.settings,
      updated_at = timezone('utc', now());

  update public.profiles
  set preferences = defaults,
      updated_at = timezone('utc', now())
  where id = auth.uid();

  return public.get_current_user_settings();
end;
$$;

create or replace function public.user_notification_enabled(
  p_user_id uuid,
  p_category text
)
returns boolean
language sql
stable
as $$
  select case
    when p_category = 'quiz' then coalesce(us.settings ->> 'quiz_alerts', 'true')::boolean
    when p_category = 'assignment' then coalesce(us.settings ->> 'assignment_alerts', 'true')::boolean
    when p_category = 'announcement' then coalesce(us.settings ->> 'announcement_alerts', 'true')::boolean
    when p_category = 'quiz_submission' then coalesce(us.settings ->> 'quiz_submission_alerts', 'true')::boolean
    when p_category = 'assignment_submission' then coalesce(us.settings ->> 'assignment_submission_alerts', 'true')::boolean
    else true
  end
  from public.profiles p
  left join public.user_settings us on us.user_id = p.id
  where p.id = p_user_id
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
  if coalesce(public.user_notification_enabled(p_user_id, p_category), true) then
    insert into public.notifications (user_id, title, body, category)
    values (p_user_id, p_title, p_body, p_category);
  end if;
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
    and e.status = 'active'
    and coalesce(public.user_notification_enabled(e.student_id, 'announcement'), true);

  return new;
end;
$$;

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
    and e.status = 'active'
    and coalesce(public.user_notification_enabled(e.student_id, 'quiz'), true);

  return new;
end;
$$;

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
    and e.status = 'active'
    and coalesce(public.user_notification_enabled(e.student_id, 'assignment'), true);

  return new;
end;
$$;

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
