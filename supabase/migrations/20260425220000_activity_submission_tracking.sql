create or replace function public.can_manage_course_activity(p_course_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_current_active_admin()
    or exists (
      select 1
      from public.courses
      where id = p_course_id
        and instructor_id = auth.uid()
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
    raise exception 'Course activity access required.' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.get_course_students_activity(p_course_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_course_activity_access(p_course_id);

  return coalesce((
    select jsonb_agg(item order by student_name)
    from (
      select jsonb_build_object(
        'student_id', p.id,
        'student_name', p.full_name,
        'student_email', p.email,
        'enrolled_at', e.enrolled_at,
        'total_quizzes', (select count(*) from public.quizzes q where q.course_id = p_course_id and q.is_published),
        'quizzes_completed', (
          select count(distinct s.quiz_id)
          from public.submissions s
          join public.quizzes q on q.id = s.quiz_id
          where q.course_id = p_course_id and s.student_id = p.id
        ),
        'total_assignments', (select count(*) from public.assignments a where a.course_id = p_course_id and a.is_published),
        'assignments_submitted', (
          select count(distinct s.assignment_id)
          from public.submissions s
          join public.assignments a on a.id = s.assignment_id
          where a.course_id = p_course_id and s.student_id = p.id
        ),
        'overdue_count', (
          select count(*)
          from (
            select q.id
            from public.quizzes q
            where q.course_id = p_course_id
              and q.is_published
              and q.due_at is not null
              and q.due_at < timezone('utc', now())
              and not exists (
                select 1 from public.submissions s
                where s.quiz_id = q.id and s.student_id = p.id
              )
            union all
            select a.id
            from public.assignments a
            where a.course_id = p_course_id
              and a.is_published
              and a.due_at is not null
              and a.due_at < timezone('utc', now())
              and not exists (
                select 1 from public.submissions s
                where s.assignment_id = a.id and s.student_id = p.id
              )
          ) overdue_items
        ),
        'latest_activity_at', (
          select max(s.submitted_at)
          from public.submissions s
          left join public.quizzes q on q.id = s.quiz_id
          left join public.assignments a on a.id = s.assignment_id
          where s.student_id = p.id
            and (q.course_id = p_course_id or a.course_id = p_course_id)
        )
      ) as item,
      p.full_name as student_name
      from public.enrollments e
      join public.profiles p on p.id = e.student_id
      where e.course_id = p_course_id
        and e.status = 'active'
        and p.deleted_at is null
    ) rows
  ), '[]'::jsonb);
end;
$$;

create or replace function public.get_student_course_activity(
  p_course_id uuid,
  p_student_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_course_activity_access(p_course_id);

  return jsonb_build_object(
    'student',
    (
      select jsonb_build_object(
        'student_id', p.id,
        'student_name', p.full_name,
        'student_email', p.email,
        'enrolled_at', e.enrolled_at
      )
      from public.profiles p
      left join public.enrollments e on e.student_id = p.id and e.course_id = p_course_id
      where p.id = p_student_id
    ),
    'quizzes',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', q.id,
          'title', q.title,
          'type', 'quiz',
          'due_at', q.due_at,
          'submitted_at', s.submitted_at,
          'score', s.score,
          'status', case
            when s.id is not null and q.due_at is not null and s.submitted_at > q.due_at then 'late'
            when s.id is not null then 'submitted'
            when q.due_at is not null and q.due_at < timezone('utc', now()) then 'overdue'
            else 'missing'
          end,
          'submission_id', s.id
        )
        order by q.due_at nulls last, q.created_at desc
      )
      from public.quizzes q
      left join lateral (
        select *
        from public.submissions s
        where s.quiz_id = q.id and s.student_id = p_student_id
        order by s.submitted_at desc
        limit 1
      ) s on true
      where q.course_id = p_course_id
        and q.is_published
    ), '[]'::jsonb),
    'assignments',
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'title', a.title,
          'type', 'assignment',
          'due_at', a.due_at,
          'submitted_at', s.submitted_at,
          'score', s.score,
          'status', case
            when s.id is not null and a.due_at is not null and s.submitted_at > a.due_at then 'late'
            when s.id is not null then 'submitted'
            when a.due_at is not null and a.due_at < timezone('utc', now()) then 'overdue'
            else 'missing'
          end,
          'submission_id', s.id
        )
        order by a.due_at nulls last, a.created_at desc
      )
      from public.assignments a
      left join lateral (
        select *
        from public.submissions s
        where s.assignment_id = a.id and s.student_id = p_student_id
        order by s.submitted_at desc
        limit 1
      ) s on true
      where a.course_id = p_course_id
        and a.is_published
    ), '[]'::jsonb),
    'timeline',
    coalesce((
      select jsonb_agg(item order by submitted_at desc)
      from (
        select jsonb_build_object(
          'title', coalesce(q.title, a.title),
          'type', case when s.quiz_id is not null then 'quiz' else 'assignment' end,
          'submitted_at', s.submitted_at,
          'score', s.score,
          'submission_id', s.id
        ) as item,
        s.submitted_at
        from public.submissions s
        left join public.quizzes q on q.id = s.quiz_id
        left join public.assignments a on a.id = s.assignment_id
        where s.student_id = p_student_id
          and (q.course_id = p_course_id or a.course_id = p_course_id)
        order by s.submitted_at desc
        limit 10
      ) timeline_rows
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.get_quiz_activity(p_quiz_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  course_uuid uuid;
begin
  select course_id into course_uuid from public.quizzes where id = p_quiz_id;
  perform public.require_course_activity_access(course_uuid);

  return (
    with quiz_row as (
      select * from public.quizzes where id = p_quiz_id
    ),
    enrolled as (
      select p.id, p.full_name, p.email, e.enrolled_at
      from public.enrollments e
      join public.profiles p on p.id = e.student_id
      where e.course_id = course_uuid and e.status = 'active'
    ),
    latest as (
      select distinct on (s.student_id) s.*
      from public.submissions s
      where s.quiz_id = p_quiz_id
      order by s.student_id, s.submitted_at desc
    )
    select jsonb_build_object(
      'stats', jsonb_build_object(
        'total_students', (select count(*) from enrolled),
        'submitted_count', (select count(*) from latest),
        'missing_count', (select count(*) from enrolled) - (select count(*) from latest),
        'average_score', (select round(avg(score)::numeric, 2) from latest where score is not null),
        'highest_score', (select max(score) from latest),
        'lowest_score', (select min(score) from latest),
        'overdue_count', (
          select count(*)
          from enrolled e
          cross join quiz_row q
          left join latest l on l.student_id = e.id
          where l.id is null and q.due_at is not null and q.due_at < timezone('utc', now())
        )
      ),
      'items', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'student_id', e.id,
            'student_name', e.full_name,
            'student_email', e.email,
            'submission_id', l.id,
            'submitted_at', l.submitted_at,
            'score', l.score,
            'status', case
              when l.id is not null and q.due_at is not null and l.submitted_at > q.due_at then 'late'
              when l.id is not null then 'submitted'
              when q.due_at is not null and q.due_at < timezone('utc', now()) then 'overdue'
              else 'not_attempted'
            end
          )
          order by e.full_name
        )
        from enrolled e
        cross join quiz_row q
        left join latest l on l.student_id = e.id
      ), '[]'::jsonb)
    )
  );
end;
$$;

create or replace function public.get_assignment_activity(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  course_uuid uuid;
begin
  select course_id into course_uuid from public.assignments where id = p_assignment_id;
  perform public.require_course_activity_access(course_uuid);

  return (
    with assignment_row as (
      select * from public.assignments where id = p_assignment_id
    ),
    enrolled as (
      select p.id, p.full_name, p.email, e.enrolled_at
      from public.enrollments e
      join public.profiles p on p.id = e.student_id
      where e.course_id = course_uuid and e.status = 'active'
    ),
    latest as (
      select distinct on (s.student_id) s.*
      from public.submissions s
      where s.assignment_id = p_assignment_id
      order by s.student_id, s.submitted_at desc
    )
    select jsonb_build_object(
      'stats', jsonb_build_object(
        'total_students', (select count(*) from enrolled),
        'submitted_count', (select count(*) from latest),
        'missing_count', (select count(*) from enrolled) - (select count(*) from latest),
        'average_score', (select round(avg(score)::numeric, 2) from latest where score is not null),
        'highest_score', (select max(score) from latest),
        'lowest_score', (select min(score) from latest),
        'overdue_count', (
          select count(*)
          from enrolled e
          cross join assignment_row a
          left join latest l on l.student_id = e.id
          where l.id is null and a.due_at is not null and a.due_at < timezone('utc', now())
        )
      ),
      'items', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'student_id', e.id,
            'student_name', e.full_name,
            'student_email', e.email,
            'submission_id', l.id,
            'submitted_at', l.submitted_at,
            'score', l.score,
            'status', case
              when l.id is not null and a.due_at is not null and l.submitted_at > a.due_at then 'late'
              when l.id is not null then 'submitted'
              when a.due_at is not null and a.due_at < timezone('utc', now()) then 'overdue'
              else 'missing'
            end,
            'file_name', l.file_name,
            'storage_path', l.storage_path
          )
          order by e.full_name
        )
        from enrolled e
        cross join assignment_row a
        left join latest l on l.student_id = e.id
      ), '[]'::jsonb)
    )
  );
end;
$$;

create or replace function public.get_submission_detail(p_submission_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  course_uuid uuid;
begin
  select coalesce(q.course_id, a.course_id)
  into course_uuid
  from public.submissions s
  left join public.quizzes q on q.id = s.quiz_id
  left join public.assignments a on a.id = s.assignment_id
  where s.id = p_submission_id;

  perform public.require_course_activity_access(course_uuid);

  return (
    select jsonb_build_object(
      'id', s.id,
      'student_id', p.id,
      'student_name', p.full_name,
      'student_email', p.email,
      'quiz_id', s.quiz_id,
      'assignment_id', s.assignment_id,
      'title', coalesce(q.title, a.title),
      'type', case when s.quiz_id is not null then 'quiz' else 'assignment' end,
      'due_at', coalesce(q.due_at, a.due_at),
      'submitted_at', s.submitted_at,
      'score', s.score,
      'status', s.status,
      'content', s.content,
      'attempt_number', s.attempt_number,
      'file_name', s.file_name,
      'file_size_bytes', s.file_size_bytes,
      'storage_path', s.storage_path,
      'question_schema', q.question_schema,
      'rubric', a.rubric
    )
    from public.submissions s
    join public.profiles p on p.id = s.student_id
    left join public.quizzes q on q.id = s.quiz_id
    left join public.assignments a on a.id = s.assignment_id
    where s.id = p_submission_id
  );
end;
$$;
