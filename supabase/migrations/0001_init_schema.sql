-- ═══════════════════════════════════════════════════════════════
-- StormShield AI — Initial Schema (Stage 1B)
-- ═══════════════════════════════════════════════════════════════
-- Creates:
--   • 6 enum types
--   • 11 tables with PostGIS geography columns
--   • Indexes for performance
--   • Triggers (auto-create profile, updated_at)
--   • Row Level Security (RLS) policies by role
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- 0. Extensions (safety net — enabled in UI too)
-- ─────────────────────────────────────────────
create extension if not exists postgis;

-- ─────────────────────────────────────────────
-- 1. Enums
-- ─────────────────────────────────────────────
do $$ begin
  create type user_role as enum ('citizen', 'responder', 'admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type incident_type as enum (
    'flood', 'fire', 'earthquake', 'typhoon', 'landslide',
    'medical', 'structural', 'power_outage', 'other'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type severity_level as enum ('low', 'medium', 'high', 'critical');
exception when duplicate_object then null; end $$;

do $$ begin
  create type incident_status as enum (
    'pending', 'verified', 'assigned', 'in_progress',
    'resolved', 'rejected', 'archived'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type alert_type as enum (
    'flood_warning', 'typhoon_warning', 'earthquake',
    'evacuation_order', 'all_clear', 'general'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type center_status as enum ('open', 'full', 'closed', 'standby');
exception when duplicate_object then null; end $$;

-- ─────────────────────────────────────────────
-- 2. profiles (extends auth.users)
-- ─────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'citizen',
  full_name text,
  phone text,
  barangay text,
  city text default 'Santa Rosa',
  province text default 'Laguna',
  avatar_url text,
  family_code text,                -- for family location sharing (later)
  last_seen_at timestamptz default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_barangay on public.profiles(barangay);

-- ─────────────────────────────────────────────
-- 3. incidents (citizen reports)
-- ─────────────────────────────────────────────
create table if not exists public.incidents (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles(id) on delete set null,
  type incident_type not null,
  severity severity_level not null default 'medium',
  status incident_status not null default 'pending',
  title text not null,
  description text,
  photo_url text,
  ai_analysis jsonb,                -- Gemini Vision response (Stage 8)
  location geography(Point, 4326) not null,
  address_text text,
  barangay text,
  people_affected int default 0,
  is_sos boolean default false,
  assigned_to uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_incidents_location on public.incidents using gist(location);
create index if not exists idx_incidents_status on public.incidents(status);
create index if not exists idx_incidents_type on public.incidents(type);
create index if not exists idx_incidents_severity on public.incidents(severity);
create index if not exists idx_incidents_created on public.incidents(created_at desc);

-- ─────────────────────────────────────────────
-- 4. sos_alerts (one-tap emergency)
-- ─────────────────────────────────────────────
create table if not exists public.sos_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  location geography(Point, 4326) not null,
  message text,
  resolved boolean default false,
  responder_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists idx_sos_location on public.sos_alerts using gist(location);
create index if not exists idx_sos_resolved on public.sos_alerts(resolved);
create index if not exists idx_sos_created on public.sos_alerts(created_at desc);

-- ─────────────────────────────────────────────
-- 5. evacuation_centers
-- ─────────────────────────────────────────────
create table if not exists public.evacuation_centers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  location geography(Point, 4326) not null,
  address_text text,
  barangay text,
  capacity int not null default 0,
  current_occupancy int default 0,
  status center_status not null default 'standby',
  contact_phone text,
  amenities text[] default '{}',
  is_active boolean default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_centers_location on public.evacuation_centers using gist(location);
create index if not exists idx_centers_status on public.evacuation_centers(status);
create index if not exists idx_centers_active on public.evacuation_centers(is_active);

-- ─────────────────────────────────────────────
-- 6. alerts (admin/responder broadcast)
-- ─────────────────────────────────────────────
create table if not exists public.alerts (
  id uuid primary key default gen_random_uuid(),
  type alert_type not null,
  severity severity_level not null default 'medium',
  title text not null,
  body text not null,
  affected_barangays text[] default '{}',
  affected_area geography(Polygon, 4326),
  expires_at timestamptz,
  is_active boolean default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_alerts_type on public.alerts(type);
create index if not exists idx_alerts_active on public.alerts(is_active);
create index if not exists idx_alerts_expires on public.alerts(expires_at);

-- ─────────────────────────────────────────────
-- 7. weather_cache (Open-Meteo responses)
-- ─────────────────────────────────────────────
create table if not exists public.weather_cache (
  id uuid primary key default gen_random_uuid(),
  location geography(Point, 4326) not null,
  payload jsonb not null,
  fetched_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 minutes')
);

create index if not exists idx_weather_location on public.weather_cache using gist(location);

-- ─────────────────────────────────────────────
-- 8. chat_sessions + chat_messages (Gemini)
-- ─────────────────────────────────────────────
create table if not exists public.chat_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text default 'New conversation',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_chat_sessions_user on public.chat_sessions(user_id);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.chat_sessions(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_session on public.chat_messages(session_id);
create index if not exists idx_chat_messages_created on public.chat_messages(created_at);

-- ─────────────────────────────────────────────
-- 9. responder_assignments (audit of incident handling)
-- ─────────────────────────────────────────────
create table if not exists public.responder_assignments (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid references public.incidents(id) on delete cascade,
  responder_id uuid references public.profiles(id) on delete cascade,
  assigned_by uuid references public.profiles(id) on delete set null,
  notes text,
  status incident_status not null default 'assigned',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_assignments_incident on public.responder_assignments(incident_id);
create index if not exists idx_assignments_responder on public.responder_assignments(responder_id);

-- ─────────────────────────────────────────────
-- 10. donations (relief tracking — nice-to-have)
-- ─────────────────────────────────────────────
create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  donor_id uuid references public.profiles(id) on delete set null,
  center_id uuid references public.evacuation_centers(id) on delete set null,
  item text not null,
  quantity int default 1,
  unit text default 'pcs',
  status text default 'pledged' check (status in ('pledged', 'delivered', 'received', 'cancelled')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ─────────────────────────────────────────────
-- 11. audit_log
-- ─────────────────────────────────────────────
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  target_table text,
  target_id uuid,
  payload jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_actor on public.audit_log(actor_id);
create index if not exists idx_audit_created on public.audit_log(created_at desc);

-- ─────────────────────────────────────────────
-- 12. Triggers
-- ─────────────────────────────────────────────

-- 12a. Auto-create profile on new auth.users signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'citizen')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 12b. Auto-update updated_at
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_incidents_updated on public.incidents;
create trigger trg_incidents_updated
  before update on public.incidents
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_centers_updated on public.evacuation_centers;
create trigger trg_centers_updated
  before update on public.evacuation_centers
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_chat_sessions_updated on public.chat_sessions;
create trigger trg_chat_sessions_updated
  before update on public.chat_sessions
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_assignments_updated on public.responder_assignments;
create trigger trg_assignments_updated
  before update on public.responder_assignments
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_donations_updated on public.donations;
create trigger trg_donations_updated
  before update on public.donations
  for each row execute function public.touch_updated_at();

-- ─────────────────────────────────────────────
-- 13. Row Level Security
-- ─────────────────────────────────────────────
alter table public.profiles               enable row level security;
alter table public.incidents              enable row level security;
alter table public.sos_alerts             enable row level security;
alter table public.evacuation_centers     enable row level security;
alter table public.alerts                 enable row level security;
alter table public.weather_cache          enable row level security;
alter table public.chat_sessions          enable row level security;
alter table public.chat_messages          enable row level security;
alter table public.responder_assignments  enable row level security;
alter table public.donations              enable row level security;
alter table public.audit_log              enable row level security;

-- Helper: current user's role
create or replace function public.current_role()
returns user_role
language sql stable security definer set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

-- ─── profiles ───
drop policy if exists "profiles: self read" on public.profiles;
create policy "profiles: self read" on public.profiles
  for select using (auth.uid() = id or public.current_role() in ('responder','admin'));

drop policy if exists "profiles: self update" on public.profiles;
create policy "profiles: self update" on public.profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id and role = (select role from public.profiles where id = auth.uid()));
  -- ^ prevents role escalation

drop policy if exists "profiles: admin all" on public.profiles;
create policy "profiles: admin all" on public.profiles
  for all using (public.current_role() = 'admin');

-- ─── incidents ───
drop policy if exists "incidents: public read verified" on public.incidents;
create policy "incidents: public read verified" on public.incidents
  for select using (
    status in ('verified','assigned','in_progress','resolved')
    or auth.uid() = reporter_id
    or public.current_role() in ('responder','admin')
  );

drop policy if exists "incidents: citizen insert" on public.incidents;
create policy "incidents: citizen insert" on public.incidents
  for insert with check (auth.uid() = reporter_id);

drop policy if exists "incidents: responder/admin update" on public.incidents;
create policy "incidents: responder/admin update" on public.incidents
  for update using (public.current_role() in ('responder','admin'));

drop policy if exists "incidents: admin delete" on public.incidents;
create policy "incidents: admin delete" on public.incidents
  for delete using (public.current_role() = 'admin');

-- ─── sos_alerts ───
drop policy if exists "sos: own + responder/admin read" on public.sos_alerts;
create policy "sos: own + responder/admin read" on public.sos_alerts
  for select using (
    auth.uid() = user_id
    or public.current_role() in ('responder','admin')
  );

drop policy if exists "sos: own insert" on public.sos_alerts;
create policy "sos: own insert" on public.sos_alerts
  for insert with check (auth.uid() = user_id);

drop policy if exists "sos: responder/admin update" on public.sos_alerts;
create policy "sos: responder/admin update" on public.sos_alerts
  for update using (public.current_role() in ('responder','admin'));

-- ─── evacuation_centers ───
drop policy if exists "centers: public read" on public.evacuation_centers;
create policy "centers: public read" on public.evacuation_centers
  for select using (is_active = true);

drop policy if exists "centers: admin write" on public.evacuation_centers;
create policy "centers: admin write" on public.evacuation_centers
  for all using (public.current_role() = 'admin');

-- ─── alerts ───
drop policy if exists "alerts: public read active" on public.alerts;
create policy "alerts: public read active" on public.alerts
  for select using (is_active = true);

drop policy if exists "alerts: responder/admin write" on public.alerts;
create policy "alerts: responder/admin write" on public.alerts
  for all using (public.current_role() in ('responder','admin'));

-- ─── weather_cache ───
drop policy if exists "weather: public read" on public.weather_cache;
create policy "weather: public read" on public.weather_cache
  for select using (true);

drop policy if exists "weather: auth write" on public.weather_cache;
create policy "weather: auth write" on public.weather_cache
  for insert with check (auth.role() = 'authenticated');

-- ─── chat ───
drop policy if exists "chat_sessions: own" on public.chat_sessions;
create policy "chat_sessions: own" on public.chat_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "chat_messages: own session" on public.chat_messages;
create policy "chat_messages: own session" on public.chat_messages
  for all using (
    exists (select 1 from public.chat_sessions s
            where s.id = session_id and s.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.chat_sessions s
            where s.id = session_id and s.user_id = auth.uid())
  );

-- ─── responder_assignments ───
drop policy if exists "assignments: involved read" on public.responder_assignments;
create policy "assignments: involved read" on public.responder_assignments
  for select using (
    responder_id = auth.uid()
    or public.current_role() in ('responder','admin')
  );

drop policy if exists "assignments: responder/admin write" on public.responder_assignments;
create policy "assignments: responder/admin write" on public.responder_assignments
  for all using (public.current_role() in ('responder','admin'));

-- ─── donations ───
drop policy if exists "donations: involved read" on public.donations;
create policy "donations: involved read" on public.donations
  for select using (
    donor_id = auth.uid() or public.current_role() in ('responder','admin')
  );

drop policy if exists "donations: donor insert" on public.donations;
create policy "donations: donor insert" on public.donations
  for insert with check (auth.uid() = donor_id);

drop policy if exists "donations: admin all" on public.donations;
create policy "donations: admin all" on public.donations
  for all using (public.current_role() = 'admin');

-- ─── audit_log ───
drop policy if exists "audit: admin read" on public.audit_log;
create policy "audit: admin read" on public.audit_log
  for select using (public.current_role() = 'admin');

-- ═══════════════════════════════════════════════════════════════
-- END OF SCHEMA
-- ═══════════════════════════════════════════════════════════════