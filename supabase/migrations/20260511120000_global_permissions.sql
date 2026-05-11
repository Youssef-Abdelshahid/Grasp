create table if not exists public.app_permissions (
  permission_key text primary key,
  enabled boolean not null,
  description text not null default '',
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.app_permissions enable row level security;

drop policy if exists "app_permissions_no_direct_select" on public.app_permissions;
create policy "app_permissions_no_direct_select"
on public.app_permissions for select
using (false);

drop policy if exists "app_permissions_no_direct_insert" on public.app_permissions;
create policy "app_permissions_no_direct_insert"
on public.app_permissions for insert
with check (false);

drop policy if exists "app_permissions_no_direct_update" on public.app_permissions;
create policy "app_permissions_no_direct_update"
on public.app_permissions for update
using (false)
with check (false);

drop policy if exists "app_permissions_no_direct_delete" on public.app_permissions;
create policy "app_permissions_no_direct_delete"
on public.app_permissions for delete
using (false);

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

create or replace function public.seed_default_permissions()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  item record;
begin
  for item in select key, value from jsonb_each(public.default_permissions_config())
  loop
    insert into public.app_permissions (permission_key, enabled)
    values (item.key, (item.value #>> '{}')::boolean)
    on conflict (permission_key) do nothing;
  end loop;
end;
$$;

select public.seed_default_permissions();

create or replace function public.validate_permissions_config(p_config jsonb)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  key_name text;
  default_config jsonb := public.default_permissions_config();
begin
  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception 'Invalid permissions configuration.' using errcode = '22023';
  end if;

  for key_name in select jsonb_object_keys(p_config)
  loop
    if not default_config ? key_name then
      raise exception 'Unknown permission key: %.', key_name using errcode = '22023';
    end if;
    if jsonb_typeof(p_config -> key_name) <> 'boolean' then
      raise exception 'Invalid permission value for key: %.', key_name using errcode = '22023';
    end if;
  end loop;
end;
$$;

create or replace function public.permissions_config()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.default_permissions_config() || coalesce(
    (
      select jsonb_object_agg(permission_key, to_jsonb(enabled))
      from public.app_permissions
    ),
    '{}'::jsonb
  )
$$;

create or replace function public.app_permission_enabled(p_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select enabled from public.app_permissions where permission_key = p_key),
    (public.default_permissions_config() ->> p_key)::boolean,
    false
  )
$$;

create or replace function public.get_effective_permissions()
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

  return public.permissions_config();
end;
$$;

create or replace function public.get_public_registration_permissions()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'allow_public_student_registration',
    public.app_permission_enabled('allow_public_student_registration'),
    'allow_public_instructor_registration',
    public.app_permission_enabled('allow_public_instructor_registration')
  )
$$;

create or replace function public.get_admin_permissions_config()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.require_admin();
  return public.permissions_config();
end;
$$;

create or replace function public.update_admin_permissions_config(p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  item record;
  old_enabled boolean;
begin
  perform public.require_admin();
  perform public.validate_permissions_config(p_config);

  for item in select key, value from jsonb_each(p_config)
  loop
    select enabled into old_enabled
    from public.app_permissions
    where permission_key = item.key;

    insert into public.app_permissions (
      permission_key,
      enabled,
      updated_by,
      updated_at
    )
    values (
      item.key,
      (item.value #>> '{}')::boolean,
      auth.uid(),
      timezone('utc', now())
    )
    on conflict (permission_key) do update
    set enabled = excluded.enabled,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;

    if old_enabled is distinct from (item.value #>> '{}')::boolean then
      insert into public.admin_activity_logs (
        actor_id,
        action,
        summary,
        metadata
      )
      values (
        auth.uid(),
        'permission_changed',
        'Updated permission ' || item.key,
        jsonb_build_object(
          'permission_key', item.key,
          'old_value', old_enabled,
          'new_value', (item.value #>> '{}')::boolean
        )
      );
    end if;
  end loop;

  return public.permissions_config();
end;
$$;

create or replace function public.reset_admin_permissions_config()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_admin();
  perform public.update_admin_permissions_config(public.default_permissions_config());
  return public.permissions_config();
end;
$$;

create or replace function public.raise_permission_denied()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  raise exception 'You do not currently have permission to perform this action.'
    using errcode = '42501';
end;
$$;

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
      and public.app_permission_enabled('create_courses')
      and public.app_permission_enabled('allow_instructors_to_create_courses')
    )
$$;

create or replace function public.can_instructor_manage_course_permission(
  p_course_id uuid,
  p_permission_key text
)
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
      and public.app_permission_enabled(p_permission_key)
    )
$$;

create or replace function public.can_student_submit_quiz(p_quiz_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or (
      public.current_user_role() = 'student'
      and public.app_permission_enabled('take_quizzes')
      and exists (
        select 1
        from public.quizzes q
        join public.enrollments e on e.course_id = q.course_id
        where q.id = p_quiz_id
          and q.is_published
          and e.student_id = auth.uid()
          and e.status = 'active'
      )
    )
$$;

create or replace function public.can_student_submit_assignment(p_assignment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or (
      public.current_user_role() = 'student'
      and public.app_permission_enabled('submit_assignments')
      and exists (
        select 1
        from public.assignments a
        join public.enrollments e on e.course_id = a.course_id
        where a.id = p_assignment_id
          and a.is_published
          and e.student_id = auth.uid()
          and e.status = 'active'
      )
    )
$$;

create or replace function public.can_student_view_course_people(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or public.can_instructor_manage_course_permission(p_course_id, 'view_student_activity')
    or (
      public.current_user_role() = 'student'
      and public.app_permission_enabled('view_course_student_list')
      and exists (
        select 1
        from public.enrollments e
        where e.course_id = p_course_id
          and e.student_id = auth.uid()
          and e.status = 'active'
      )
    )
$$;

create or replace function public.can_view_course_people(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.can_student_view_course_people(p_course_id)
$$;

create or replace function public.can_manage_course_activity(p_course_id uuid)
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
      and public.app_permission_enabled('view_student_activity')
    )
$$;

create or replace function public.can_grade_course_submission(p_course_id uuid)
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
      and public.app_permission_enabled('grade_student_work')
    )
$$;

create or replace function public.require_course_activity_access(p_course_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_manage_course_activity(p_course_id) then
    perform public.raise_permission_denied();
  end if;
end;
$$;

create or replace function public.require_course_grade_access(p_course_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.can_grade_course_submission(p_course_id) then
    perform public.raise_permission_denied();
  end if;
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
  requested_role := lower(coalesce(new.raw_user_meta_data ->> 'role', 'student'));
  if requested_role not in ('student', 'instructor') then
    requested_role := 'student';
  end if;

  if requested_role = 'student'
     and not public.app_permission_enabled('allow_public_student_registration') then
    raise exception 'Student registration is currently disabled.'
      using errcode = '42501';
  end if;

  if requested_role = 'instructor'
     and not public.app_permission_enabled('allow_public_instructor_registration') then
    raise exception 'Instructor registration is currently disabled.'
      using errcode = '42501';
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

drop policy if exists "materials_insert_instructor_or_admin" on public.materials;
create policy "materials_insert_instructor_or_admin"
on public.materials for insert
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'upload_materials')
);

drop policy if exists "materials_update_instructor_or_admin" on public.materials;
create policy "materials_update_instructor_or_admin"
on public.materials for update
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'upload_materials')
)
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'upload_materials')
);

drop policy if exists "materials_delete_instructor_or_admin" on public.materials;
create policy "materials_delete_instructor_or_admin"
on public.materials for delete
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'upload_materials')
);

drop policy if exists "quizzes_insert_instructor_or_admin" on public.quizzes;
create policy "quizzes_insert_instructor_or_admin"
on public.quizzes for insert
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_quizzes')
);

drop policy if exists "quizzes_update_instructor_or_admin" on public.quizzes;
create policy "quizzes_update_instructor_or_admin"
on public.quizzes for update
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_quizzes')
)
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_quizzes')
);

drop policy if exists "quizzes_delete_instructor_or_admin" on public.quizzes;
create policy "quizzes_delete_instructor_or_admin"
on public.quizzes for delete
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_quizzes')
);

drop policy if exists "assignments_insert_instructor_or_admin" on public.assignments;
create policy "assignments_insert_instructor_or_admin"
on public.assignments for insert
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_assignments')
);

drop policy if exists "assignments_update_instructor_or_admin" on public.assignments;
create policy "assignments_update_instructor_or_admin"
on public.assignments for update
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_assignments')
)
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_assignments')
);

drop policy if exists "assignments_delete_instructor_or_admin" on public.assignments;
create policy "assignments_delete_instructor_or_admin"
on public.assignments for delete
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'manage_assignments')
);

drop policy if exists "announcements_insert_instructor_or_admin" on public.announcements;
create policy "announcements_insert_instructor_or_admin"
on public.announcements for insert
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'post_announcements')
);

drop policy if exists "announcements_update_instructor_or_admin" on public.announcements;
create policy "announcements_update_instructor_or_admin"
on public.announcements for update
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'post_announcements')
)
with check (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'post_announcements')
);

drop policy if exists "announcements_delete_instructor_or_admin" on public.announcements;
create policy "announcements_delete_instructor_or_admin"
on public.announcements for delete
using (
  public.is_current_active_admin()
  or public.can_instructor_manage_course_permission(course_id, 'post_announcements')
);

drop policy if exists "submissions_insert_student" on public.submissions;
create policy "submissions_insert_student"
on public.submissions for insert
with check (
  public.is_current_active_admin()
  or (
    student_id = auth.uid()
    and public.current_user_role() = 'student'
    and (
      (quiz_id is not null and public.can_student_submit_quiz(quiz_id))
      or (assignment_id is not null and public.can_student_submit_assignment(assignment_id))
    )
  )
);

drop policy if exists "submissions_select_related" on public.submissions;
create policy "submissions_select_related"
on public.submissions for select
using (
  public.is_current_active_admin()
  or student_id = auth.uid()
  or exists (
    select 1
    from public.quizzes q
    where q.id = submissions.quiz_id
      and public.can_manage_course_activity(q.course_id)
  )
  or exists (
    select 1
    from public.assignments a
    where a.id = submissions.assignment_id
      and public.can_manage_course_activity(a.course_id)
  )
);

drop policy if exists "submissions_update_owner_or_instructor_or_admin" on public.submissions;
create policy "submissions_update_owner_or_instructor_or_admin"
on public.submissions for update
using (
  public.is_current_active_admin()
  or exists (
    select 1
    from public.quizzes q
    where q.id = submissions.quiz_id
      and public.can_grade_course_submission(q.course_id)
  )
  or exists (
    select 1
    from public.assignments a
    where a.id = submissions.assignment_id
      and public.can_grade_course_submission(a.course_id)
  )
)
with check (true);

drop policy if exists "course_materials_select_related" on storage.objects;
create policy "course_materials_select_related"
on storage.objects for select
using (
  bucket_id = 'course-materials'
  and (
    public.is_current_active_admin()
    or public.current_user_role() = 'instructor'
    or (
      public.current_user_role() = 'student'
      and public.app_permission_enabled('download_materials')
      and exists (
        select 1
        from public.materials m
        join public.enrollments e on e.course_id = m.course_id
        where m.storage_path = storage.objects.name
          and e.student_id = auth.uid()
          and e.status = 'active'
      )
    )
  )
);

drop policy if exists "course_materials_insert_instructor_or_admin" on storage.objects;
create policy "course_materials_insert_instructor_or_admin"
on storage.objects for insert
with check (
  bucket_id = 'course-materials'
  and (
    public.is_current_active_admin()
    or (
      public.current_user_role() = 'instructor'
      and public.app_permission_enabled('upload_materials')
    )
  )
);

drop policy if exists "assignment_submissions_insert_student" on storage.objects;
create policy "assignment_submissions_insert_student"
on storage.objects for insert
with check (
  bucket_id = 'assignment-submissions'
  and public.current_user_role() = 'student'
  and public.app_permission_enabled('submit_assignments')
);

drop policy if exists "flashcard_sets_insert_student_owner" on public.flashcard_sets;
create policy "flashcard_sets_insert_student_owner"
on public.flashcard_sets for insert
with check (
  public.current_user_role() = 'student'
  and public.app_permission_enabled('generate_flashcards')
  and student_id = auth.uid()
  and exists (
    select 1
    from public.enrollments e
    where e.course_id = flashcard_sets.course_id
      and e.student_id = auth.uid()
      and e.status = 'active'
  )
);

drop policy if exists "study_notes_insert_student_owner" on public.study_notes;
create policy "study_notes_insert_student_owner"
on public.study_notes for insert
with check (
  public.current_user_role() = 'student'
  and public.app_permission_enabled('generate_study_notes')
  and student_id = auth.uid()
  and exists (
    select 1
    from public.enrollments e
    where e.course_id = study_notes.course_id
      and e.student_id = auth.uid()
      and e.status = 'active'
  )
);

drop policy if exists "ai_generated_content_insert_instructor_or_admin" on public.ai_generated_content;
create policy "ai_generated_content_insert_instructor_or_admin"
on public.ai_generated_content for insert
with check (
  public.is_current_active_admin()
  or (
    public.current_user_role() = 'instructor'
    and public.is_course_instructor(course_id)
    and (
      (content_type = 'quiz' and public.app_permission_enabled('use_ai_quiz_generation'))
      or (content_type = 'assignment' and public.app_permission_enabled('use_ai_assignment_generation'))
    )
  )
  or (
    public.current_user_role() = 'student'
    and exists (
      select 1
      from public.enrollments e
      where e.course_id = ai_generated_content.course_id
        and e.student_id = auth.uid()
        and e.status = 'active'
    )
    and (
      (content_type = 'flashcards' and public.app_permission_enabled('generate_flashcards'))
      or (content_type = 'study_notes' and public.app_permission_enabled('generate_study_notes'))
    )
  )
);

create or replace function public.grade_submission(
  p_submission_id uuid,
  p_score numeric,
  p_feedback text default '',
  p_grading_details jsonb default '{}'::jsonb,
  p_grade_visible boolean default false,
  p_feedback_visible boolean default false,
  p_attempt_visible boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  course_uuid uuid;
  quiz_schema jsonb;
  answers_schema jsonb;
  question jsonb;
  answer_row jsonb;
  grade_row jsonb;
  question_type text;
  question_marks numeric;
  awarded numeric;
  calculated_score numeric := 0;
  is_quiz boolean := false;
  question_count integer := 0;
  idx integer := 0;
  expected_total integer;
  correct_total integer;
  sanitized_grades jsonb := '[]'::jsonb;
  raw_answer jsonb;
begin
  select coalesce(q.course_id, a.course_id), q.question_schema, s.content -> 'answers', s.quiz_id is not null
  into course_uuid, quiz_schema, answers_schema, is_quiz
  from public.submissions s
  left join public.quizzes q on q.id = s.quiz_id
  left join public.assignments a on a.id = s.assignment_id
  where s.id = p_submission_id;

  perform public.require_course_grade_access(course_uuid);

  if is_quiz then
    question_count := jsonb_array_length(coalesce(quiz_schema, '[]'::jsonb));

    while idx < question_count loop
      question := quiz_schema -> idx;
      answer_row := coalesce(answers_schema -> idx, '{}'::jsonb);
      raw_answer := answer_row -> 'answer';
      grade_row := coalesce(p_grading_details -> 'question_grades' -> idx, '{}'::jsonb);
      question_type := lower(coalesce(question ->> 'type', ''));
      question_marks := greatest(coalesce((question ->> 'marks')::numeric, 0), 0);
      awarded := 0;

      if question_type in ('short answer', 'essay') then
        awarded := coalesce((grade_row ->> 'marks')::numeric, 0);
        if awarded < 0 or awarded > question_marks then
          raise exception 'Question % grade must be between 0 and %.', idx + 1, question_marks
            using errcode = '22023';
        end if;
        if awarded * 4 <> trunc(awarded * 4) then
          raise exception 'Question % grade must use 0.25 increments.', idx + 1
            using errcode = '22023';
        end if;
      elsif question_type = 'matching' then
        select count(*), count(*) filter (
          where raw_answer is not null
            and jsonb_typeof(raw_answer) = 'object'
            and raw_answer ->> key = value
        )
        into expected_total, correct_total
        from jsonb_each_text(coalesce(question -> 'correct_mapping', '{}'::jsonb)) as expected(key, value);

        awarded := case
          when expected_total > 0 then correct_total * (question_marks / expected_total)
          else 0
        end;
      else
        if jsonb_typeof(raw_answer) = 'number'
          and (raw_answer #>> '{}')::integer = coalesce((question ->> 'correct_option')::integer, -1)
        then
          awarded := question_marks;
        end if;
      end if;

      awarded := least(greatest(awarded, 0), question_marks);
      calculated_score := calculated_score + awarded;
      sanitized_grades := sanitized_grades || jsonb_build_array(jsonb_build_object(
        'question_index', idx,
        'marks', awarded,
        'feedback', case
          when question_type in ('short answer', 'essay') then coalesce(grade_row ->> 'feedback', '')
          else ''
        end
      ));
      idx := idx + 1;
    end loop;

    update public.submissions
    set score = calculated_score,
        feedback = coalesce(p_feedback, ''),
        grading_details = jsonb_build_object('question_grades', sanitized_grades),
        grade_visible = coalesce(p_grade_visible, false),
        feedback_visible = coalesce(p_feedback_visible, false),
        attempt_visible = coalesce(p_attempt_visible, false),
        status = 'graded',
        graded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_submission_id;
  else
    update public.submissions
    set score = greatest(0, coalesce(p_score, 0)),
        feedback = coalesce(p_feedback, ''),
        grading_details = coalesce(p_grading_details, '{}'::jsonb),
        grade_visible = coalesce(p_grade_visible, false),
        feedback_visible = coalesce(p_feedback_visible, false),
        status = 'graded',
        graded_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_submission_id;
  end if;

  return public.get_submission_detail(p_submission_id);
end;
$$;
