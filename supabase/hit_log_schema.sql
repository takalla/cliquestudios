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
  path text not null,           -- the URL path that was requested, e.g. /old-pricing-page
  referrer text,                 -- the URL that sent them here, if any
  user_agent text
);

comment on table public.error_404_site_pings is
  'Logs hits on the Clique Studios 404 (page-not-found) catch-all page at 404.html. Two event_type rows are recorded per visitor: "pageview" on page load, and "button_click" when they click the "Tell Us You Found This" button. Written client-side from js/404.js via the Supabase REST API, using the public anon/publishable key configured in js/config.js. RLS restricts the anon role to INSERT only, so the public key can log hits but never read, edit, or delete them -- view/query this data as the project owner via the Supabase dashboard or SQL editor. Purpose: surface dead links elsewhere on the site or the internet that are sending visitors to pages that no longer exist, so they can be found and fixed (see path/referrer columns).';

comment on column public.error_404_site_pings.event_type is 'Either "pageview" (404 page loaded) or "button_click" (visitor clicked "Tell Us You Found This").';
comment on column public.error_404_site_pings.path is 'The URL path (+ query string) that was requested and 404''d, e.g. /old-pricing-page.';
comment on column public.error_404_site_pings.referrer is 'document.referrer of the visitor -- the URL that linked/redirected them to this dead path, if any.';
comment on column public.error_404_site_pings.user_agent is 'navigator.userAgent of the visitor''s browser at the time of the hit.';
comment on column public.error_404_site_pings.created_at is 'Server-side timestamp (UTC) of when the row was inserted.';

-- Helpful for the query you'll actually run: "which dead links are still
-- getting traffic" and "how many hits per path."
create index if not exists error_404_site_pings_path_idx on public.error_404_site_pings (path);
create index if not exists error_404_site_pings_created_at_idx on public.error_404_site_pings (created_at);

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

-- Sample query for the dashboard once data starts coming in:
--   select path, referrer, count(*) as hits
--   from error_404_site_pings
--   where event_type = 'pageview'
--   group by path, referrer
--   order by hits desc;
