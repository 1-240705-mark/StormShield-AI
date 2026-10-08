-- ═══════════════════════════════════════════════════════
-- Storage Buckets + RLS Policies
-- Run this once per fresh Supabase project.
-- ═══════════════════════════════════════════════════════

insert into storage.buckets (id, name, public)
values ('incident-photos', 'incident-photos', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('damage-reports', 'damage-reports', false)
on conflict (id) do nothing;

-- incident-photos: authenticated upload + read
drop policy if exists "auth upload incident photos" on storage.objects;
create policy "auth upload incident photos"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'incident-photos');

drop policy if exists "read incident photos" on storage.objects;
create policy "read incident photos"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'incident-photos');

-- avatars: public read, authenticated upload
drop policy if exists "public read avatars" on storage.objects;
create policy "public read avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "auth upload avatars" on storage.objects;
create policy "auth upload avatars"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'avatars');

-- damage-reports: authenticated upload + read
drop policy if exists "auth upload damage reports" on storage.objects;
create policy "auth upload damage reports"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'damage-reports');

drop policy if exists "read damage reports" on storage.objects;
create policy "read damage reports"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'damage-reports');