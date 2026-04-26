create or replace function public.require_admin()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_current_active_admin() then
    perform public.raise_admin_access_required();
  end if;
end;
$$;
