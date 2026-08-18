-- supabase/hit_log_schema.sql
--
-- Run this against Clique Studios' Supabase project (NOT any personal
-- account) once it's handed over. Creates the table the 404 page logs
-- to, plus an insert-only Row Level Security policy so the public anon
-- key embedded in js/config.js can add rows but can never read, update,
-- or delete them. You'll read the data from the Supabase dashboard (or
-- your own authenticated tooling) with your own credentials, not the
-- public key.
--
-- How to run it: Supabase dashboard > SQL Editor > paste this > Run.
-- (Or via the Supabase MCP's apply_migration tool once that project is
-- connected to a Claude session.)

create table if not exists public.site_pings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  event_type text not null check (event_type in ('pageview', 'button_click')),
  path text not null,           -- the URL path that was requested, e.g. /old-pricing-page
  referrer text,                 -- the URL that sent them here, if any
  user_agent text
);

-- Helpful for the query you'll actually run: "which dead links are still
-- getting traffic" and "how many hits per path."
create index if not exists site_pings_path_idx on public.site_pings (path);
create index if not exists site_pings_created_at_idx on public.site_pings (created_at);

alter table public.site_pings enable row level security;

-- Anyone (the anon/public key) can INSERT a row...
create policy "Allow public inserts on site_pings"
  on public.site_pings
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
--   from site_pings
--   where event_type = 'pageview'
--   group by path, referrer
--   order by hits desc;
