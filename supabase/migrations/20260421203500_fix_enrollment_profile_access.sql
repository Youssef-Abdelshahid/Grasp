drop policy if exists "profiles_select_self_or_admin" on public.profiles;

create policy "profiles_select_access"
on public.profiles for select
using (
  auth.uid() = id
  or public.current_user_role() = 'admin'
  or (
    public.current_user_role() = 'instructor'
    and role = 'student'
  )
);
