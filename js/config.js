// ═══════════════════════════════════════════════════════
// StormShield AI — Configuration
// ═══════════════════════════════════════════════════════
// NOTE: The Supabase "anon" key is SAFE to expose in
// frontend code. Row Level Security (RLS) protects data.
// We'll fill these in during Stage 1B after creating the
// Supabase project.
// ═══════════════════════════════════════════════════════

export const CONFIG = {
  SUPABASE_URL: "https://hatqwgmtzgrbxfswiibi.supabase.co/rest/v1/",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhdHF3Z210emdyYnhmc3dpaWJpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE0NzY1NjMsImV4cCI6MjEwNzA1MjU2M30.LTFspc2zaideoRd_a92RI7GMYWcwHLGhPzfQKe4fBgg",

  APP_NAME: "StormShield AI",
  APP_VERSION: "0.1.0",

  // Demo area: City of Santa Rosa, Laguna
  DEFAULT_CENTER: { lat: 14.3123, lng: 121.1118 },
  DEFAULT_ZOOM: 13,

  // Free services (no key needed)
  OSRM_URL: "https://router.project-osrm.org",
  NOMINATIM_URL: "https://nominatim.openstreetmap.org",
  OPEN_METEO_URL: "https://api.open-meteo.com/v1/forecast",

  // Feature flags (flip on as we build each stage)
  FEATURES: {
    auth: false,
    reporting: false,
    sos: false,
    evacuation: false,
    chat: false,
    weather: false,
    damageAI: false,
    responder: false,
  },
};