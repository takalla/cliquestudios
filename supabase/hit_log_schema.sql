-- supabase/hit_log_schema.sql
--
-- Schema for Clique Studios' Supabase project. Creates the table the
-- 404 page logs to, plus an insert-only Row Level Security policy so
-- the public anon key embedded in js/config.js can add rows but can
-- never read, update, or delete them. You'll read the data from the
-- Supabase dashboard (or your own authenticated tooling) with your own
-- credentials, not the public key.
--
-- Already applied to the live project. Kept here as documentation and
-- so the schema can be recreated (e.g. in a fresh project) by running
-- this in Supabase dashboard > SQL Editor > paste > Run, or via the
-- Supabase MCP's apply_migration tool.

create table if not exists public.error_404_site_pings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  event_type text not null check (event_type in ('pageview', 'button_click')),
  hostname text,                 -- which hostname the visitor was on, e.g. cliquestudios.io or admin.cliquestudios.io
  path text not null,           -- the URL path that was requested, e.g. /old-pricing-page
  referrer text,                 -- the URL that sent them here, if any
  user_agent text
);

comment on table public.error_404_site_pings is
  'Logs hits on the Clique Studios 404 (page-not-found) catch-all page at 404.html. Two event_type rows are recorded per visitor: "pageview" on page load, and "button_click" when they click the "Tell Us You Found This" button. Written client-side from js/404.js via the Supabase REST API, using the public anon/publishable key configured in js/config.js. RLS restricts the anon role to INSERT only, so the public key can log hits but never read, edit, or delete them -- view/query this data as the project owner via the Supabase dashboard or SQL editor. Purpose: surface dead links elsewhere on the site or the internet that are sending visitors to pages that no longer exist, so they can be found and fixed (see hostname/path/referrer columns).';

comment on column public.error_404_site_pings.event_type is 'Either "pageview" (404 page loaded) or "button_click" (visitor clicked "Tell Us You Found This").';
comment on column public.error_404_site_pings.hostname is 'The hostname the visitor was actually on (window.location.hostname), e.g. cliquestudios.io or admin.cliquestudios.io -- lets you tell apart hits on the main domain vs. a subdomain, since path alone only ever holds what comes after the domain.';
comment on column public.error_404_site_pings.path is 'The URL path (+ query string) that was requested and 404''d, e.g. /old-pricing-page.';
comment on column public.error_404_site_pings.referrer is 'document.referrer of the visitor -- the URL that linked/redirected them to this dead path, if any.';
comment on column public.error_404_site_pings.user_agent is 'navigator.userAgent of the visitor''s browser at the time of the hit.';
comment on column public.error_404_site_pings.created_at is 'Server-side timestamp (UTC) of when the row was inserted.';

-- Helpful for the query you'll actually run: "which dead links are still
-- getting traffic" and "how many hits per path/hostname."
create index if not exists error_404_site_pings_path_idx on public.error_404_site_pings (path);
create index if not exists error_404_site_pings_created_at_idx on public.error_404_site_pings (created_at);
create index if not exists error_404_site_pings_hostname_idx on public.error_404_site_pings (hostname);

alter table public.error_404_site_pings enable row level security;

-- Anyone (the anon/public key) can INSERT a row...
create policy "Allow public inserts on error_404_site_pings"
  on public.error_404_site_pings
  for insert
  to anon
  with check (true);

-- ...but nobody using the anon key can SELECT, UPDATE, or DELETE.
-- No policy for those actions = denied by default under RLS.
-- You'll view the data as the project owner in the Supabase dashboard,
-- which bypasses RLS, or via a service_role key you keep server-side —
-- never put the service_role key in this public repo.

-- Reporting view: pairs each dead hostname+path with the referrer that
-- sent visitors there, with pageview/click counts and first/last seen
-- times. Query this instead of the raw table for day-to-day "what's
-- broken, and on which hostname":
--   select * from dead_link_report;
create or replace view public.dead_link_report
with (security_invoker = on) as
select
  hostname,
  path,
  referrer,
  count(*) filter (where event_type = 'pageview') as pageviews,
  count(*) filter (where event_type = 'button_click') as button_clicks,
  min(created_at) as first_seen,
  max(created_at) as last_seen
from public.error_404_site_pings
group by hostname, path, referrer
order by pageviews desc;

comment on view public.dead_link_report is
  'Pairs each 404''d hostname+path with the referrer that sent visitors there, aggregated from error_404_site_pings. One row per (hostname, path, referrer) combo, with pageview/click counts and first/last seen timestamps -- read this top-to-bottom to see which dead links get the most traffic, on which hostname (main domain vs. a subdomain), and where they''re being linked from.';
