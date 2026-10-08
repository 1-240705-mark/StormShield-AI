-- ═══════════════════════════════════════════════════════════════
-- StormShield AI — Seed Data for Santa Rosa, Laguna
-- ═══════════════════════════════════════════════════════════════
-- Realistic evacuation centers + sample alerts for demo.
-- Uses ST_GeogFromText for PostGIS geography(Point, 4326).
-- WKT format: 'POINT(longitude latitude)'  ← note lon first!
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- 1. Evacuation Centers (10 real Santa Rosa locations)
-- ─────────────────────────────────────────────
insert into public.evacuation_centers
  (name, description, location, address_text, barangay, capacity, current_occupancy, status, contact_phone, amenities)
values

  -- 1. Santa Rosa Sports Complex (Balibago) — main evac center
  (
    'Santa Rosa Sports Complex',
    'Primary city evacuation center with full facilities and medical station.',
    ST_GeogFromText('POINT(121.10687 14.27972)'),
    'Brgy. Balibago, Santa Rosa, Laguna',
    'Balibago',
    5000, 0, 'standby', '(049) 123-4001',
    ARRAY['water', 'food', 'medical', 'restrooms', 'power', 'wifi']
  ),

  -- 2. Balibago Elementary School
  (
    'Balibago Elementary School',
    'Barangay-level evacuation site for the Balibago cluster.',
    ST_GeogFromText('POINT(121.10820 14.28140)'),
    'Brgy. Balibago, Santa Rosa, Laguna',
    'Balibago',
    800, 0, 'standby', '(049) 123-4002',
    ARRAY['water', 'restrooms', 'power']
  ),

  -- 3. Tagapo Covered Court
  (
    'Tagapo Covered Court',
    'Community evacuation site in Brgy. Tagapo.',
    ST_GeogFromText('POINT(121.09680 14.30170)'),
    'Brgy. Tagapo, Santa Rosa, Laguna',
    'Tagapo',
    600, 0, 'standby', '(049) 123-4003',
    ARRAY['water', 'restrooms']
  ),

  -- 4. Sinalhan Barangay Hall
  (
    'Sinalhan Barangay Hall',
    'Coastal barangay evacuation center near Laguna de Bay.',
    ST_GeogFromText('POINT(121.08460 14.31420)'),
    'Brgy. Sinalhan, Santa Rosa, Laguna',
    'Sinalhan',
    400, 0, 'standby', '(049) 123-4004',
    ARRAY['water', 'food', 'medical']
  ),

  -- 5. Pulong Sta. Cruz Evacuation Center
  (
    'Pulong Sta. Cruz Evacuation Center',
    'Main evacuation site for the southern cluster.',
    ST_GeogFromText('POINT(121.07620 14.26610)'),
    'Brgy. Pulong Sta. Cruz, Santa Rosa, Laguna',
    'Pulong Sta. Cruz',
    1200, 0, 'standby', '(049) 123-4005',
    ARRAY['water', 'food', 'restrooms', 'power']
  ),

  -- 6. Malitlit Multi-Purpose Hall
  (
    'Malitlit Multi-Purpose Hall',
    'Upland evacuation center for the Malitlit area.',
    ST_GeogFromText('POINT(121.07180 14.25290)'),
    'Brgy. Malitlit, Santa Rosa, Laguna',
    'Malitlit',
    500, 0, 'standby', '(049) 123-4006',
    ARRAY['water', 'restrooms']
  ),

  -- 7. Santa Rosa Central Elementary School (Poblacion)
  (
    'Santa Rosa Central Elementary School',
    'Central Poblacion evacuation site.',
    ST_GeogFromText('POINT(121.11220 14.31260)'),
    'Brgy. Kanluran, Santa Rosa, Laguna',
    'Kanluran',
    1000, 0, 'standby', '(049) 123-4007',
    ARRAY['water', 'food', 'medical', 'restrooms']
  ),

  -- 8. Nuvali Evacuation Site
  (
    'Nuvali Evacuation Site',
    'Large open-ground evacuation area along the Nuvali corridor.',
    ST_GeogFromText('POINT(121.08420 14.22960)'),
    'Nuvali, Brgy. Sto. Domingo, Santa Rosa, Laguna',
    'Sto. Domingo',
    3000, 0, 'standby', '(049) 123-4008',
    ARRAY['water', 'food', 'medical', 'restrooms', 'power', 'wifi', 'pet-friendly']
  ),

  -- 9. Aplaya Barangay Hall
  (
    'Aplaya Barangay Hall',
    'High-risk flood-zone coastal barangay evacuation site.',
    ST_GeogFromText('POINT(121.09920 14.33240)'),
    'Brgy. Aplaya, Santa Rosa, Laguna',
    'Aplaya',
    350, 0, 'standby', '(049) 123-4009',
    ARRAY['water', 'food']
  ),

  -- 10. Dila Barangay Covered Court
  (
    'Dila Barangay Covered Court',
    'Community evacuation site for the Dila cluster.',
    ST_GeogFromText('POINT(121.12230 14.30750)'),
    'Brgy. Dila, Santa Rosa, Laguna',
    'Dila',
    700, 0, 'standby', '(049) 123-4010',
    ARRAY['water', 'restrooms', 'power']
  );

-- ─────────────────────────────────────────────
-- 2. Sample Alerts (3 active)
-- ─────────────────────────────────────────────
insert into public.alerts
  (type, severity, title, body, affected_barangays, expires_at, is_active)
values

  -- Alert 1 — Active flood warning for coastal barangays
  (
    'flood_warning',
    'high',
    'Flood Warning: Coastal Barangays',
    'Due to continuous rainfall and rising water levels in Laguna de Bay, residents of Aplaya, Sinalhan, and Malusak are advised to prepare for possible evacuation. Move to higher ground and monitor official announcements.',
    ARRAY['Aplaya', 'Sinalhan', 'Malusak'],
    now() + interval '12 hours',
    true
  ),

  -- Alert 2 — Typhoon advisory
  (
    'typhoon_warning',
    'medium',
    'Typhoon Signal No. 1 — Santa Rosa',
    'A tropical depression has entered PAR. Signal No. 1 is raised over Laguna. Expect moderate to heavy rains and gusty winds within 36 hours. Secure loose objects and prepare emergency kits.',
    ARRAY['Balibago', 'Tagapo', 'Kanluran', 'Dila', 'Sto. Domingo'],
    now() + interval '36 hours',
    true
  ),

  -- Alert 3 — General advisory
  (
    'general',
    'low',
    'Emergency Hotlines Active',
    'The Santa Rosa Emergency Operations Center is active 24/7. For emergencies, use the SOS feature in StormShield AI or call 911 / (049) 123-4567. Stay safe and stay informed.',
    ARRAY[]::text[],
    now() + interval '7 days',
    true
  );

-- ─────────────────────────────────────────────
-- 3. Verify
-- ─────────────────────────────────────────────
select 'evacuation_centers' as table_name, count(*) as rows from public.evacuation_centers
union all
select 'alerts', count(*) from public.alerts;