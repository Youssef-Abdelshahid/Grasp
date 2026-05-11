create table if not exists public.upload_limits (
  id boolean primary key default true,
  config jsonb not null default '{}'::jsonb,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  constraint upload_limits_singleton check (id)
);

alter table public.upload_limits enable row level security;

drop policy if exists "upload_limits_no_direct_select" on public.upload_limits;
create policy "upload_limits_no_direct_select"
on public.upload_limits for select using (false);

drop policy if exists "upload_limits_no_direct_insert" on public.upload_limits;
create policy "upload_limits_no_direct_insert"
on public.upload_limits for insert with check (false);

drop policy if exists "upload_limits_no_direct_update" on public.upload_limits;
create policy "upload_limits_no_direct_update"
on public.upload_limits for update using (false) with check (false);

drop policy if exists "upload_limits_no_direct_delete" on public.upload_limits;
create policy "upload_limits_no_direct_delete"
on public.upload_limits for delete using (false);

create table if not exists public.upload_file_metadata (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  source text not null,
  file_name text not null,
  file_extension text not null,
  mime_type text not null default 'application/octet-stream',
  size_bytes bigint not null default 0,
  storage_path text not null,
  uploader_id uuid references public.profiles (id) on delete set null,
  course_id uuid references public.courses (id) on delete set null,
  material_id uuid references public.materials (id) on delete set null,
  assignment_id uuid references public.assignments (id) on delete set null,
  submission_id uuid references public.submissions (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_upload_file_metadata_source
on public.upload_file_metadata (source, created_at desc);

create index if not exists idx_upload_file_metadata_uploader
on public.upload_file_metadata (uploader_id, source);

alter table public.upload_file_metadata enable row level security;

drop policy if exists "upload_file_metadata_no_direct_select" on public.upload_file_metadata;
create policy "upload_file_metadata_no_direct_select"
on public.upload_file_metadata for select using (false);

drop policy if exists "upload_file_metadata_no_direct_insert" on public.upload_file_metadata;
create policy "upload_file_metadata_no_direct_insert"
on public.upload_file_metadata for insert with check (false);

drop policy if exists "upload_file_metadata_no_direct_update" on public.upload_file_metadata;
create policy "upload_file_metadata_no_direct_update"
on public.upload_file_metadata for update using (false) with check (false);

drop policy if exists "upload_file_metadata_no_direct_delete" on public.upload_file_metadata;
create policy "upload_file_metadata_no_direct_delete"
on public.upload_file_metadata for delete using (false);

create or replace function public.default_upload_limits_config()
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'max_material_file_size_mb', 50,
    'max_assignment_submission_file_size_mb', 25,
    'max_files_per_material_upload', 10,
    'max_files_per_assignment_submission', 5,
    'material_file_types', jsonb_build_array('PDF', 'PPT', 'PPTX', 'DOCX', 'DOC', 'TXT'),
    'image_file_types', jsonb_build_array('PNG', 'JPG', 'JPEG'),
    'assignment_submission_file_types', jsonb_build_array('PDF', 'DOCX', 'DOC', 'TXT', 'PNG', 'JPG', 'JPEG', 'ZIP'),
    'instructor_material_storage_quota_gb', 10,
    'student_submission_storage_quota_mb', 750,
    'admin_upload_storage_quota_gb', 50,
    'allow_multiple_file_uploads', true,
    'allow_file_replacement', true,
    'require_file_type_validation', true
  )
$$;

create or replace function public.upload_limits_config()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select public.default_upload_limits_config() || coalesce(
    (select config from public.upload_limits where id = true),
    '{}'::jsonb
  )
$$;

create or replace function public.seed_default_upload_limits()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.upload_limits (id, config)
  values (true, public.default_upload_limits_config())
  on conflict (id) do nothing;
end;
$$;

select public.seed_default_upload_limits();

create or replace function public.validate_upload_limits_config(p_config jsonb)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  key_name text;
  ext text;
  default_config jsonb := public.default_upload_limits_config();
  allowed_exts text[] := array['PDF','PPT','PPTX','DOCX','DOC','TXT','PNG','JPG','JPEG','ZIP'];
  int_keys text[] := array[
    'max_material_file_size_mb',
    'max_assignment_submission_file_size_mb',
    'max_files_per_material_upload',
    'max_files_per_assignment_submission',
    'instructor_material_storage_quota_gb',
    'student_submission_storage_quota_mb',
    'admin_upload_storage_quota_gb'
  ];
  bool_keys text[] := array[
    'allow_multiple_file_uploads',
    'allow_file_replacement',
    'require_file_type_validation'
  ];
  array_keys text[] := array[
    'material_file_types',
    'image_file_types',
    'assignment_submission_file_types'
  ];
begin
  if p_config is null or jsonb_typeof(p_config) <> 'object' then
    raise exception 'Invalid upload limits configuration.' using errcode = '22023';
  end if;

  for key_name in select jsonb_object_keys(p_config)
  loop
    if not default_config ? key_name then
      raise exception 'Unknown upload setting key: %.', key_name using errcode = '22023';
    end if;
  end loop;

  foreach key_name in array int_keys
  loop
    if p_config ? key_name then
      if jsonb_typeof(p_config -> key_name) <> 'number'
        or (p_config ->> key_name)::integer <= 0 then
        raise exception 'Invalid upload limit value: %.', key_name using errcode = '22023';
      end if;
    end if;
  end loop;

  foreach key_name in array bool_keys
  loop
    if p_config ? key_name and jsonb_typeof(p_config -> key_name) <> 'boolean' then
      raise exception 'Invalid upload behavior value: %.', key_name using errcode = '22023';
    end if;
  end loop;

  foreach key_name in array array_keys
  loop
    if p_config ? key_name then
      if jsonb_typeof(p_config -> key_name) <> 'array'
        or jsonb_array_length(p_config -> key_name) = 0 then
        raise exception 'Upload file type groups cannot be empty.' using errcode = '22023';
      end if;
      for ext in select upper(value) from jsonb_array_elements_text(p_config -> key_name)
      loop
        if not ext = any(allowed_exts) then
          raise exception 'Unknown file extension: %.', ext using errcode = '22023';
        end if;
      end loop;
    end if;
  end loop;
end;
$$;

create or replace function public.get_admin_upload_limits_config()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.require_admin();
  return public.upload_limits_config();
end;
$$;

create or replace function public.get_effective_upload_limits()
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
  return public.upload_limits_config();
end;
$$;

create or replace function public.update_admin_upload_limits_config(p_config jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  merged_config jsonb;
begin
  perform public.require_admin();
  perform public.validate_upload_limits_config(p_config);
  merged_config := public.default_upload_limits_config() || p_config;
  insert into public.upload_limits (id, config, updated_by, updated_at)
  values (true, merged_config, auth.uid(), timezone('utc', now()))
  on conflict (id) do update
  set config = excluded.config,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;
  return public.upload_limits_config();
end;
$$;

create or replace function public.reset_admin_upload_limits_config()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_admin();
  insert into public.upload_limits (id, config, updated_by, updated_at)
  values (true, public.default_upload_limits_config(), auth.uid(), timezone('utc', now()))
  on conflict (id) do update
  set config = excluded.config,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;
  return public.upload_limits_config();
end;
$$;

create or replace function public.upload_file_extension(p_name text)
returns text
language sql
immutable
as $$
  select upper(coalesce(nullif(split_part(reverse(split_part(reverse(p_name), '/', 1)), '.', 1), ''), ''))
$$;

create or replace function public.upload_array_contains(p_array jsonb, p_ext text)
returns boolean
language sql
immutable
as $$
  select exists (
    select 1
    from jsonb_array_elements_text(p_array) item
    where upper(item) = upper(p_ext)
  )
$$;

create or replace function public.validate_upload_request(
  p_source text,
  p_file_name text,
  p_file_size_bytes bigint,
  p_file_count integer default 1,
  p_uploader_id uuid default null,
  p_course_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  config jsonb := public.upload_limits_config();
  ext text := public.upload_file_extension(p_file_name);
  max_size bigint;
  allowed jsonb;
  quota_bytes bigint;
  used_bytes bigint := 0;
  effective_uploader uuid := coalesce(p_uploader_id, auth.uid());
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  if p_file_count is null or p_file_count <= 0 then
    raise exception 'Invalid file count.' using errcode = '22023';
  end if;

  if coalesce((config ->> 'allow_multiple_file_uploads')::boolean, true) is not true
    and p_file_count > 1 then
    raise exception 'You can only upload one file at a time.' using errcode = '42501';
  end if;

  case p_source
    when 'material', 'admin_material' then
      if p_file_count > (config ->> 'max_files_per_material_upload')::integer then
        raise exception 'You can only upload up to % files at once.', (config ->> 'max_files_per_material_upload') using errcode = '42501';
      end if;
      max_size := (config ->> 'max_material_file_size_mb')::bigint * 1024 * 1024;
      allowed := (config -> 'material_file_types') || (config -> 'image_file_types');
      quota_bytes := case when public.current_user_role() = 'admin'
        then (config ->> 'admin_upload_storage_quota_gb')::bigint * 1024 * 1024 * 1024
        else (config ->> 'instructor_material_storage_quota_gb')::bigint * 1024 * 1024 * 1024
      end;
      select coalesce(sum(file_size_bytes), 0) into used_bytes
      from public.materials
      where uploaded_by = effective_uploader;
    when 'assignment_submission' then
      if p_file_count > (config ->> 'max_files_per_assignment_submission')::integer then
        raise exception 'You can only upload up to % files at once.', (config ->> 'max_files_per_assignment_submission') using errcode = '42501';
      end if;
      max_size := (config ->> 'max_assignment_submission_file_size_mb')::bigint * 1024 * 1024;
      allowed := (config -> 'assignment_submission_file_types') || (config -> 'image_file_types');
      quota_bytes := (config ->> 'student_submission_storage_quota_mb')::bigint * 1024 * 1024;
      select coalesce(sum(file_size_bytes), 0) into used_bytes
      from public.submissions
      where student_id = effective_uploader
        and file_size_bytes is not null;
    when 'assignment_attachment' then
      max_size := (config ->> 'max_assignment_submission_file_size_mb')::bigint * 1024 * 1024;
      allowed := (config -> 'assignment_submission_file_types') || (config -> 'image_file_types');
      quota_bytes := case when public.current_user_role() = 'admin'
        then (config ->> 'admin_upload_storage_quota_gb')::bigint * 1024 * 1024 * 1024
        else (config ->> 'instructor_material_storage_quota_gb')::bigint * 1024 * 1024 * 1024
      end;
      select coalesce(sum(size_bytes), 0) into used_bytes
      from public.upload_file_metadata
      where uploader_id = effective_uploader
        and source in ('assignment_attachment', 'question_image', 'profile_image');
    when 'question_image', 'profile_image' then
      max_size := (config ->> 'max_assignment_submission_file_size_mb')::bigint * 1024 * 1024;
      allowed := config -> 'image_file_types';
      quota_bytes := case when public.current_user_role() = 'admin'
        then (config ->> 'admin_upload_storage_quota_gb')::bigint * 1024 * 1024 * 1024
        else (config ->> 'student_submission_storage_quota_mb')::bigint * 1024 * 1024
      end;
      select coalesce(sum(size_bytes), 0) into used_bytes
      from public.upload_file_metadata
      where uploader_id = effective_uploader
        and source in ('profile_image', 'question_image');
    else
      raise exception 'Unknown upload source.' using errcode = '22023';
  end case;

  if p_file_size_bytes is null or p_file_size_bytes < 0 then
    raise exception 'Invalid file size.' using errcode = '22023';
  end if;

  if p_file_size_bytes > max_size then
    raise exception 'This file exceeds the maximum allowed size.' using errcode = '42501';
  end if;

  if coalesce((config ->> 'require_file_type_validation')::boolean, true)
    and not public.upload_array_contains(allowed, ext) then
    raise exception 'This file type is not allowed.' using errcode = '42501';
  end if;

  if quota_bytes is not null and used_bytes + p_file_size_bytes > quota_bytes then
    raise exception 'This upload would exceed the storage quota.' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.record_upload_file_metadata(
  p_bucket text,
  p_source text,
  p_file_name text,
  p_mime_type text,
  p_size_bytes bigint,
  p_storage_path text,
  p_course_id uuid default null,
  p_material_id uuid default null,
  p_assignment_id uuid default null,
  p_submission_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_id uuid;
begin
  perform public.validate_upload_request(
    p_source,
    p_file_name,
    p_size_bytes,
    1,
    auth.uid(),
    p_course_id
  );

  insert into public.upload_file_metadata (
    bucket,
    source,
    file_name,
    file_extension,
    mime_type,
    size_bytes,
    storage_path,
    uploader_id,
    course_id,
    material_id,
    assignment_id,
    submission_id
  )
  values (
    p_bucket,
    p_source,
    p_file_name,
    public.upload_file_extension(p_file_name),
    coalesce(p_mime_type, 'application/octet-stream'),
    coalesce(p_size_bytes, 0),
    p_storage_path,
    auth.uid(),
    p_course_id,
    p_material_id,
    p_assignment_id,
    p_submission_id
  )
  returning id into inserted_id;

  return inserted_id;
end;
$$;

create or replace function public.validate_material_upload_metadata()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.validate_upload_request(
    case when public.current_user_role() = 'admin' then 'admin_material' else 'material' end,
    new.file_name,
    coalesce(new.file_size_bytes, 0),
    1,
    new.uploaded_by,
    new.course_id
  );
  return new;
end;
$$;

drop trigger if exists validate_material_upload_metadata_before_save on public.materials;
create trigger validate_material_upload_metadata_before_save
before insert or update of file_name, file_size_bytes, file_type, storage_path
on public.materials
for each row execute function public.validate_material_upload_metadata();

create or replace function public.validate_submission_upload_metadata()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.storage_path is not null and new.storage_path <> '' then
    perform public.validate_upload_request(
      'assignment_submission',
      coalesce(new.file_name, ''),
      coalesce(new.file_size_bytes, 0),
      1,
      new.student_id,
      null
    );
  end if;
  return new;
end;
$$;

drop trigger if exists validate_submission_upload_metadata_before_save on public.submissions;
create trigger validate_submission_upload_metadata_before_save
before insert or update of file_name, file_size_bytes, storage_path
on public.submissions
for each row execute function public.validate_submission_upload_metadata();

create or replace function public.get_admin_upload_storage_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  materials_bytes bigint;
  submissions_bytes bigint;
  profile_bytes bigint;
  total_bytes bigint;
begin
  perform public.require_admin();

  select coalesce(sum(file_size_bytes), 0) into materials_bytes
  from public.materials;

  select coalesce(sum(file_size_bytes), 0) into submissions_bytes
  from public.submissions
  where file_size_bytes is not null;

  select coalesce(sum(size_bytes), 0) into profile_bytes
  from public.upload_file_metadata
  where source = 'profile_image';

  total_bytes := materials_bytes + submissions_bytes + profile_bytes;

  return jsonb_build_object(
    'materials_storage_bytes', materials_bytes,
    'assignment_submissions_storage_bytes', submissions_bytes,
    'profile_images_storage_bytes', profile_bytes,
    'total_storage_bytes', total_bytes
  );
end;
$$;
