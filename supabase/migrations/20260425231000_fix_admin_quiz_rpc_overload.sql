drop function if exists public.list_admin_quizzes(text, text);
drop function if exists public.list_admin_quizzes(text, uuid, text);

create or replace function public.list_admin_quizzes(
  p_search text default '',
  p_course_id uuid default null,
  p_status text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_admin();

  return coalesce((
    select jsonb_agg(item order by due_at nulls last, created_at desc)
    from (
      select jsonb_build_object(
          'id', q.id,
          'course_id', q.course_id,
          'course_title', c.title,
          'course_code', c.code,
          'instructor_name', instructor.full_name,
          'title', q.title,
          'description', q.description,
          'instructions', q.instructions,
          'due_at', q.due_at,
          'max_points', q.max_points,
          'duration_minutes', q.duration_minutes,
          'is_published', q.is_published,
          'show_correct_answers', coalesce(q.show_correct_answers, false),
          'allow_retakes', coalesce(q.allow_retakes, false),
          'question_schema', q.question_schema,
          'question_count', jsonb_array_length(q.question_schema),
          'created_by_name', creator.full_name,
          'created_at', q.created_at,
          'published_at', q.published_at
        ) as item,
        q.due_at,
        q.created_at
      from public.quizzes q
      join public.courses c on c.id = q.course_id
      left join public.profiles instructor on instructor.id = c.instructor_id
      left join public.profiles creator on creator.id = q.created_by
      where (coalesce(p_search, '') = ''
        or q.title ilike '%' || p_search || '%'
        or c.title ilike '%' || p_search || '%'
        or c.code ilike '%' || p_search || '%')
        and (p_course_id is null or q.course_id = p_course_id)
        and (p_status is null
          or (p_status = 'published' and q.is_published)
          or (p_status = 'draft' and not q.is_published))
    ) rows
  ), '[]'::jsonb);
end;
$$;
