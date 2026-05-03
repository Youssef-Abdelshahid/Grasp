create or replace function public.validate_flashcard_set()
returns trigger
language plpgsql
as $$
begin
  if jsonb_typeof(new.cards) <> 'array' then
    raise exception 'Flashcards must be stored as an array.';
  end if;

  if cardinality(new.selected_material_ids) > 0 and exists (
    select 1
    from unnest(new.selected_material_ids) as selected_material(material_id)
    left join public.materials m on m.id = selected_material.material_id
    where m.id is null or m.course_id <> new.course_id
  ) then
    raise exception 'Flashcards can only use selected materials from the same course.';
  end if;

  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

create or replace function public.list_admin_flashcards(
  p_search text default '',
  p_course_id uuid default null,
  p_material_id uuid default null,
  p_created_range text default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  with material_names as (
    select
      fs.id as flashcard_set_id,
      coalesce(
        array_agg(m.title order by m.created_at desc)
          filter (where m.id is not null),
        '{}'::text[]
      ) as names
    from public.flashcard_sets fs
    left join lateral unnest(fs.selected_material_ids) as selected(material_id) on true
    left join public.materials m on m.id = selected.material_id
    group by fs.id
  )
  select case
    when not public.is_current_active_admin() then public.raise_admin_access_required()
    else coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', fs.id,
          'course_id', fs.course_id,
          'student_id', fs.student_id,
          'selected_material_ids', fs.selected_material_ids,
          'prompt', fs.prompt,
          'title', fs.title,
          'difficulty', fs.difficulty,
          'cards', fs.cards,
          'student_name', coalesce(sp.full_name, 'Unknown student'),
          'student_email', coalesce(sp.email, ''),
          'course_title', coalesce(c.title, 'Unknown course'),
          'course_code', coalesce(c.code, ''),
          'material_names', coalesce(mn.names, '{}'::text[]),
          'created_at', fs.created_at,
          'updated_at', fs.updated_at
        )
        order by fs.created_at desc
      )
      from public.flashcard_sets fs
      join public.courses c on c.id = fs.course_id
      left join public.profiles sp on sp.id = fs.student_id
      left join material_names mn on mn.flashcard_set_id = fs.id
      where (p_course_id is null or fs.course_id = p_course_id)
        and (p_material_id is null or p_material_id = any(fs.selected_material_ids))
        and (
          p_created_range is null
          or trim(p_created_range) = ''
          or lower(p_created_range) = 'all'
          or (lower(p_created_range) = 'today' and fs.created_at >= date_trunc('day', timezone('utc', now())))
          or (lower(p_created_range) = '7d' and fs.created_at >= timezone('utc', now()) - interval '7 days')
          or (lower(p_created_range) = '30d' and fs.created_at >= timezone('utc', now()) - interval '30 days')
        )
        and (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or fs.title ilike '%' || trim(p_search) || '%'
          or coalesce(sp.full_name, '') ilike '%' || trim(p_search) || '%'
          or coalesce(sp.email, '') ilike '%' || trim(p_search) || '%'
          or c.title ilike '%' || trim(p_search) || '%'
          or c.code ilike '%' || trim(p_search) || '%'
          or fs.created_at::text ilike '%' || trim(p_search) || '%'
          or exists (
            select 1
            from unnest(coalesce(mn.names, '{}'::text[])) as material_name(name)
            where material_name.name ilike '%' || trim(p_search) || '%'
          )
        )
    ), '[]'::jsonb)
  end
$$;
