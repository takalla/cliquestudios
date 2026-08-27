# Clique Studios — Website — Progress & Plan

This file tracks build status for future Claude sessions (and OnNae). It's
a living doc — replace/expand the plan section once the real outline exists.

## What this is

Clique Studios' public marketing website (currently just a placeholder
homepage + a fully-built 404/catch-all page), at `cliquestudios.io`. Plain
HTML/CSS/JS, no build step, no framework.

A separate, sibling repo — [cliquestudios-admin](https://github.com/takalla/cliquestudios-admin) —
holds the internal admin portal at `admin.cliquestudios.io`. Kept separate
on purpose: different application (authenticated, dynamic) from this public
static site, with its own Cloudflare Worker and its own deploy pipeline, so
neither can break the other. Both share the same Supabase project.

## Stack

- Plain HTML/CSS/JS, no build step, no framework
- Supabase (project ref `qkwqllrgvrpdkbtequdb`) for 404 hit logging —
  see `supabase/hit_log_schema.sql` for the full schema
- Cloudflare Workers (static assets) for hosting, deployed via Workers
  Builds on push — see `wrangler.jsonc`
- Domain registered at Porkbun, DNS delegated to Cloudflare

## Status as of 2026-08-27

Done:
- 404 page (`404.html`) fully built and logging to Supabase
  (`error_404_site_pings` table: one `pageview` row per visit, a second
  `button_click` row if the visitor clicks "Tell Us You Found This")
- `dead_link_report` Supabase view pairs path + referrer with hit counts,
  for spotting which dead links are getting traffic and from where
- `wrangler.jsonc` / `.assetsignore` added so Cloudflare Workers Builds can
  actually deploy this static site (Worker name: `cliquestudios`)
- Nameservers switched from Porkbun to Cloudflare; stale GitHub Pages
  A/AAAA records (leftover from before this migration) deleted from the
  Cloudflare DNS zone
- GitHub Pages disabled in repo settings (Cloudflare Workers is now the
  only host)

In progress / not done yet:
- Cloudflare zone was still showing `pending` as of this writing — waiting
  on nameserver propagation after removing the old Porkbun nameservers
- Custom domain (`cliquestudios.io`) not yet attached to the Worker in
  Cloudflare (Workers & Pages > cliquestudios > Settings > Domains &
  Routes) — needed before the live domain will actually serve this site
  instead of showing "visitors cannot reach this hostname"
- `www.cliquestudios.io` still has a leftover CNAME to `pixie.porkbun.com`
  (a Porkbun service, not GitHub Pages) — not yet addressed, decide
  whether `www` should also point at the Worker
- Homepage (`index.html`) is still a placeholder — real site content/design
  not built yet
- The real content/design of the actual marketing site (beyond the 404
  page) hasn't been scoped out

## Branching

Development happens on `staging`, merged to `main` via PR. Cloudflare
Workers Builds only does a full production deploy (`wrangler deploy`) on
pushes to `main` — pushes to `staging` (or any other branch) only produce
a preview version, not a live deploy.

## Open questions / decisions for OnNae

- What does the actual homepage/marketing site look like? (Currently just
  a placeholder — the 404 page is the only fully-designed page so far.)
- Should `www.cliquestudios.io` redirect/point to the same Worker as the
  bare domain?
