// js/config.js
// -----------------------------------------------------------------------
// Supabase connection for the traffic/click logging on this 404 page.
//
// Left EMPTY on purpose. Clique Studios' own Supabase project (separate
// from any personal Supabase account) hasn't been handed over yet. Until
// both values below are filled in, 404.js safely no-ops on every event —
// it just console.logs what *would* have been sent, so the page still
// works perfectly with zero risk of a broken build.
//
// To wire this up once the Clique Supabase project exists:
//   1. In that Supabase project: Project Settings > API, copy the
//      "Project URL" and the "anon" / "publishable" key.
//   2. Paste them into supabaseUrl / supabaseAnonKey below.
//   3. Run the SQL in /supabase/hit_log_schema.sql against that project
//      (creates the table + an insert-only Row Level Security policy —
//      the anon key can add rows but can never read, edit, or delete
//      them, so it's safe to ship in this public file).
// No other code changes needed — 404.js picks this up automatically.
// -----------------------------------------------------------------------
window.CLIQUE_404_CONFIG = {
  supabaseUrl: "", // e.g. "https://xxxxxxxxxxxx.supabase.co"
  supabaseAnonKey: "", // the PUBLIC anon/publishable key — never the service_role key
  table: "site_pings"
};
