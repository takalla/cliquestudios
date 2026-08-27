// js/config.js
// -----------------------------------------------------------------------
// Supabase connection for the traffic/click logging on this 404 page.
//
// Wired up to Clique Studios' Supabase project. Rows land in the
// error_404_site_pings table (see /supabase/hit_log_schema.sql for the
// full schema + an insert-only Row Level Security policy — the anon key
// below can add rows but can never read, edit, or delete them, so it's
// safe to ship in this public file).
// -----------------------------------------------------------------------
window.CLIQUE_404_CONFIG = {
  supabaseUrl: "https://qkwqllrgvrpdkbtequdb.supabase.co",
  supabaseAnonKey: "sb_publishable_1skvWTfq5oYplZmVSDvx_A_AcuHTD0W", // PUBLIC publishable key — never the service_role key
  table: "error_404_site_pings"
};
