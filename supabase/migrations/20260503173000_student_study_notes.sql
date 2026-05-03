create table if not exists public.study_notes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  selected_material_ids uuid[] not null default '{}'::uuid[],
  prompt text not null default '',
  title text not null default 'Study Notes',
  content text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_study_notes_student_course
on public.study_notes (student_id, course_id, created_at desc);

create index if not exists idx_study_notes_course_id
on public.study_notes (course_id);

alter table public.study_notes enable row level security;

create or replace function public.validate_study_note()
returns trigger
language plpgsql
as $$
begin
  if trim(coalesce(new.title, '')) = '' then
    raise exception 'Study note title is required.';
  end if;

  if length(trim(coalesce(new.content, ''))) < 40 then
    raise exception 'Study note content is too short.';
  end if;

  if cardinality(new.selected_material_ids) = 0 then
    raise exception 'Select at least one material.';
  end if;

  if exists (
    select 1
    from unnest(new.selected_material_ids) as selected_material(material_id)
    left join public.materials m on m.id = selected_material.material_id
    where m.id is null or m.course_id <> new.course_id
  ) then
    raise exception 'Study notes can only use selected materials from the same course.';
  end if;

  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists validate_study_note_before_save on public.study_notes;
create trigger validate_study_note_before_save
before insert or update on public.study_notes
for each row execute function public.validate_study_note();

drop policy if exists "study_notes_select_owner_or_admin" on public.study_notes;
create policy "study_notes_select_owner_or_admin"
on public.study_notes for select
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
);

drop policy if exists "study_notes_insert_student_owner" on public.study_notes;
create policy "study_notes_insert_student_owner"
on public.study_notes for insert
with check (
  public.current_user_role() = 'student'
  and student_id = auth.uid()
  and exists (
    select 1
    from public.enrollments e
    where e.course_id = study_notes.course_id
      and e.student_id = auth.uid()
      and e.status = 'active'
  )
);

drop policy if exists "study_notes_update_owner_or_admin" on public.study_notes;
create policy "study_notes_update_owner_or_admin"
on public.study_notes for update
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
)
with check (
  public.current_user_role() = 'admin'
  or (
    public.current_user_role() = 'student'
    and student_id = auth.uid()
    and exists (
      select 1
      from public.enrollments e
      where e.course_id = study_notes.course_id
        and e.student_id = auth.uid()
        and e.status = 'active'
    )
  )
);

drop policy if exists "study_notes_delete_owner_or_admin" on public.study_notes;
create policy "study_notes_delete_owner_or_admin"
on public.study_notes for delete
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
);

create or replace function public.list_admin_study_notes(
  p_search text default '',
  p_created_range text default null
)
returns jsonb
language sql
security definer
set search_path = public
as $$
  with material_names as (
    select
      sn.id as note_id,
      coalesce(
        array_agg(m.title order by m.created_at desc)
          filter (where m.id is not null),
        '{}'::text[]
      ) as names
    from public.study_notes sn
    left join lateral unnest(sn.selected_material_ids) as selected(material_id) on true
    left join public.materials m on m.id = selected.material_id
    group by sn.id
  )
  select case
    when not public.is_current_active_admin() then public.raise_admin_access_required()
    else coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', sn.id,
          'course_id', sn.course_id,
          'student_id', sn.student_id,
          'selected_material_ids', sn.selected_material_ids,
          'prompt', sn.prompt,
          'title', sn.title,
          'content', sn.content,
          'student_name', coalesce(sp.full_name, 'Unknown student'),
          'student_email', coalesce(sp.email, ''),
          'course_title', coalesce(c.title, 'Unknown course'),
          'course_code', coalesce(c.code, ''),
          'material_names', coalesce(mn.names, '{}'::text[]),
          'created_at', sn.created_at,
          'updated_at', sn.updated_at
        )
        order by sn.created_at desc
      )
      from public.study_notes sn
      join public.courses c on c.id = sn.course_id
      left join public.profiles sp on sp.id = sn.student_id
      left join material_names mn on mn.note_id = sn.id
      where (
          p_created_range is null
          or trim(p_created_range) = ''
          or lower(p_created_range) = 'all'
          or (lower(p_created_range) = 'today' and sn.created_at >= date_trunc('day', timezone('utc', now())))
          or (lower(p_created_range) = '7d' and sn.created_at >= timezone('utc', now()) - interval '7 days')
          or (lower(p_created_range) = '30d' and sn.created_at >= timezone('utc', now()) - interval '30 days')
        )
        and (
          coalesce(nullif(trim(p_search), ''), '') = ''
          or sn.title ilike '%' || trim(p_search) || '%'
          or sn.content ilike '%' || trim(p_search) || '%'
          or coalesce(sp.full_name, '') ilike '%' || trim(p_search) || '%'
          or coalesce(sp.email, '') ilike '%' || trim(p_search) || '%'
          or c.title ilike '%' || trim(p_search) || '%'
          or c.code ilike '%' || trim(p_search) || '%'
          or sn.created_at::text ilike '%' || trim(p_search) || '%'
          or exists (
            select 1
            from unnest(coalesce(mn.names, '{}'::text[])) as material_name(name)
            where material_name.name ilike '%' || trim(p_search) || '%'
          )
        )
    ), '[]'::jsonb)
  end
$$;
