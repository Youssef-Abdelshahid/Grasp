-- Replace this placeholder with the email address of the account that should
-- become the first active admin after the admin backend migration is applied.
--
-- Run this in Supabase SQL Editor, or with:
-- supabase db query < supabase/admin_setup_example.sql

update public.profiles
set
  role = 'admin',
  account_status = 'active',
  deleted_at = null,
  updated_at = timezone('utc', now())
where email = 'youssefmoshahid@gmail.com';
