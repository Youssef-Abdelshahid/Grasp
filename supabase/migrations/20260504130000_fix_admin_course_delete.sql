create or replace function public.admin_delete_course_safe(p_course_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  course_title text;
  deleted_count integer;
begin
  perform public.require_active_admin();

  select title
  into course_title
  from public.courses
  where id = p_course_id
  for update;

  if course_title is null then
    raise exception 'Course not found.' using errcode = 'P0002';
  end if;

  delete from public.courses
  where id = p_course_id;

  get diagnostics deleted_count = row_count;
  if deleted_count = 0 then
    raise exception 'Course could not be deleted.' using errcode = 'P0001';
  end if;

  perform public.admin_log_activity(
    'course_deleted',
    'Deleted course: ' || course_title,
    null,
    jsonb_build_object('course_id', p_course_id, 'mode', 'hard_delete')
  );
end;
$$;
