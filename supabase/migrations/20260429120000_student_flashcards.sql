create table if not exists public.flashcard_sets (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  selected_material_ids uuid[] not null default '{}'::uuid[],
  prompt text not null default '',
  title text not null default 'Study Flashcards',
  difficulty text not null default '',
  cards jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_flashcard_sets_student_course
on public.flashcard_sets (student_id, course_id, created_at desc);

create index if not exists idx_flashcard_sets_course_id
on public.flashcard_sets (course_id);

alter table public.flashcard_sets enable row level security;

create or replace function public.validate_flashcard_set()
returns trigger
language plpgsql
as $$
begin
  if jsonb_typeof(new.cards) <> 'array' then
    raise exception 'Flashcards must be stored as an array.';
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
    raise exception 'Flashcards can only use selected materials from the same course.';
  end if;

  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists validate_flashcard_set_before_save on public.flashcard_sets;
create trigger validate_flashcard_set_before_save
before insert or update on public.flashcard_sets
for each row execute function public.validate_flashcard_set();

drop policy if exists "flashcard_sets_select_owner_or_admin" on public.flashcard_sets;
create policy "flashcard_sets_select_owner_or_admin"
on public.flashcard_sets for select
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
);

drop policy if exists "flashcard_sets_insert_student_owner" on public.flashcard_sets;
create policy "flashcard_sets_insert_student_owner"
on public.flashcard_sets for insert
with check (
  public.current_user_role() = 'student'
  and student_id = auth.uid()
  and exists (
    select 1
    from public.enrollments e
    where e.course_id = flashcard_sets.course_id
      and e.student_id = auth.uid()
      and e.status = 'active'
  )
);

drop policy if exists "flashcard_sets_update_owner_or_admin" on public.flashcard_sets;
create policy "flashcard_sets_update_owner_or_admin"
on public.flashcard_sets for update
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
      where e.course_id = flashcard_sets.course_id
        and e.student_id = auth.uid()
        and e.status = 'active'
    )
  )
);

drop policy if exists "flashcard_sets_delete_owner_or_admin" on public.flashcard_sets;
create policy "flashcard_sets_delete_owner_or_admin"
on public.flashcard_sets for delete
using (
  public.current_user_role() = 'admin'
  or student_id = auth.uid()
);
