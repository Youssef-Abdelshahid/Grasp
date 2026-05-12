create or replace function public.default_user_settings(p_role public.app_role)
returns jsonb
language sql
stable
as $$
  select case p_role
    when 'student'::public.app_role then jsonb_build_object(
      'theme_mode', 'light',
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
      'theme_mode', 'light',
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
  theme_mode text;
begin
  if p_settings is null or jsonb_typeof(p_settings) <> 'object' then
    raise exception 'Settings payload must be an object.' using errcode = '22023';
  end if;

  if p_role = 'student'::public.app_role then
    if exists (
      select 1
      from jsonb_object_keys(p_settings) as key
      where key not in (
        'theme_mode',
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
      where key not in ('default_deadline_reminder_time', 'theme_mode')
        and jsonb_typeof(value) <> 'boolean'
    ) then
      raise exception 'Student notification settings must be booleans.' using errcode = '22023';
    end if;

    theme_mode := lower(coalesce(p_settings ->> 'theme_mode', public.default_user_settings(p_role) ->> 'theme_mode'));
    if theme_mode not in ('light', 'dark') then
      raise exception 'Theme mode must be light or dark.' using errcode = '22023';
    end if;

    reminder_time := coalesce(p_settings ->> 'default_deadline_reminder_time', public.default_user_settings(p_role) ->> 'default_deadline_reminder_time');
    if reminder_time !~ '^(?:[01][0-9]|2[0-3]):[0-5][0-9]$' then
      raise exception 'Reminder time must use HH:MM 24-hour format.' using errcode = '22023';
    end if;

    return public.default_user_settings(p_role)
      || p_settings
      || jsonb_build_object('theme_mode', theme_mode);
  end if;

  if p_role = 'instructor'::public.app_role then
    if exists (
      select 1
      from jsonb_object_keys(p_settings) as key
      where key not in (
        'theme_mode',
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

    theme_mode := lower(coalesce(p_settings ->> 'theme_mode', public.default_user_settings(p_role) ->> 'theme_mode'));
    if theme_mode not in ('light', 'dark') then
      raise exception 'Theme mode must be light or dark.' using errcode = '22023';
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
        'theme_mode', theme_mode,
        'default_quiz_difficulty', difficulty,
        'default_assignment_difficulty', assignment_difficulty,
        'default_question_count', question_count,
        'default_question_types', normalized_types
      );
  end if;

  return '{}'::jsonb;
end;
$$;

update public.user_settings
set settings = public.validate_user_settings(role, public.default_user_settings(role) || settings),
    updated_at = timezone('utc', now())
where role in ('student', 'instructor');

update public.profiles
set preferences = public.validate_user_settings(role, public.default_user_settings(role) || coalesce(preferences, '{}'::jsonb)),
    updated_at = timezone('utc', now())
where role in ('student', 'instructor');
