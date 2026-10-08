// ═══════════════════════════════════════════════════════
// StormShield AI — Supabase Client
// ═══════════════════════════════════════════════════════
// Loads the Supabase JS SDK from CDN and initializes
// a singleton client. Same pattern as LibraryIQ Pro.
// ═══════════════════════════════════════════════════════

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { CONFIG } from "./config.js";

if (CONFIG.SUPABASE_URL.includes("YOUR_")) {
  console.warn(
    "⚠️ StormShield AI: Supabase credentials not set yet. " +
      "Fill them in js/config.js (Stage 1B)."
  );
}

export const supabase = createClient(
  CONFIG.SUPABASE_URL,
  CONFIG.SUPABASE_ANON_KEY,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  }
);

export const isConfigured = () =>
  !CONFIG.SUPABASE_URL.includes("YOUR_") &&
  !CONFIG.SUPABASE_ANON_KEY.includes("YOUR_");