# Clique Studios — Website — Progress & Plan

This file tracks build status for future Claude sessions (and OnNae). It's
a living doc — replace/expand the plan section once the real outline exists.

## What this is

Clique Studios' public marketing website (currently just a placeholder
homepage + a fully-built 404/catch-all page), at `cliquestudios.io`. Plain
HTML/CSS/JS, no build step, no framework.

A separate, sibling repo — [cliquestudios-adminportal](https://github.com/takalla/cliquestudios-adminportal) —
holds the internal admin portal, meant to live at `admin.cliquestudios.io`.
Kept separate on purpose: different application (authenticated, dynamic)
from this public static site, with its own Cloudflare Worker and its own
deploy pipeline, so neither can break the other. Both share the same
Supabase project.

## Stack

- Plain HTML/CSS/JS, no build step, no framework
- Supabase (project ref `qkwqllrgvrpdkbtequdb`) for 404 hit logging —
  see `supabase/hit_log_schema.sql` for the full schema
- Cloudflare Workers (static assets) for hosting, deployed via Workers
  Builds on push — see `wrangler.jsonc`. Worker name in the Cloudflare
  account is `cliquestudios` — must match `wrangler.jsonc`'s `name` field
  exactly or Workers Builds fails.
- Domain registered at Porkbun, DNS delegated to Cloudflare (zone is
  `cc36b447e39ad76ab282a489210cdebf`, Cloudflare account "Onnae@cliquestudios.io's
  Account", account id `97c20f377935fdc7566d14ebb1806ea5`)

## Status as of 2026-08-27

Done:
- 404 page (`404.html`) fully built and logging to Supabase
  (`error_404_site_pings` table: one `pageview` row per visit, a second
  `button_click` row if the visitor clicks "Tell Us You Found This").
  Logs `hostname` (window.location.hostname) alongside `path`, so hits on
  the main domain vs. a subdomain (e.g. `admin.cliquestudios.io`) are
  distinguishable in the data -- `path` alone only ever holds what comes
  after the domain.
- `dead_link_report` Supabase view groups by (hostname, path, referrer)
  with hit counts, for spotting which dead links/hostnames are getting
  traffic and from where. View uses `security_invoker = on` so it
  actually enforces the table's RLS instead of bypassing it as the
  view's owner.
- `wrangler.jsonc` / `.assetsignore` added so Cloudflare Workers Builds can
  actually deploy this static site
- Nameservers switched from Porkbun to Cloudflare and fully activated;
  stale GitHub Pages A/AAAA records (leftover from before this migration)
  deleted from the Cloudflare DNS zone
- GitHub Pages disabled in repo settings (Cloudflare Workers is now the
  only host)
- Custom domain `cliquestudios.io` is live on the `cliquestudios` Worker
  -- confirmed working (visiting the domain serves this site's 404/
  placeholder content, not GitHub's or Cloudflare's generic error page)
- `.claude/settings.json` PostToolUse hook added: fires a reminder to
  check `fes-coding-standards` any time a `.html`/`.css`/`.js` file is
  written or edited in this repo (the skill's own "auto-trigger" wording
  isn't actually enforced by anything -- this hook is what makes it
  reliable). Same hook copied into `cliquestudios-adminportal`. Note:
  this only applies per-repo -- there's no single switch that makes it
  fire in brand-new repos automatically; add the same
  `.claude/settings.json` to any new repo going forward.

In progress / not done yet:
- **`admin.cliquestudios.io` is not yet its own Worker/custom domain.**
  Right now there's a wildcard Route (`*.cliquestudios.io/*`) on the
  `cliquestudios` Worker from the original setup, which catches *any*
  subdomain (including `admin.cliquestudios.io`) and serves this site's
  static assets -- since there's no matching file, it falls through to
  404.html. That's why visiting `admin.cliquestudios.io` currently shows
  this site's 404 page instead of the actual admin portal. Fix: create a
  Worker for `cliquestudios-adminportal` (connect that repo via Workers
  Builds), then add `admin.cliquestudios.io` as a Custom Domain on that
  new Worker -- an exact-hostname Custom Domain takes precedence over the
  wildcard Route, so this should resolve correctly once done.
- `www.cliquestudios.io` still has a leftover CNAME to `pixie.porkbun.com`
  (a Porkbun service, not GitHub Pages) — not yet addressed, decide
  whether `www` should also point at the Worker
- Homepage (`index.html`) is still a placeholder — it's intentionally a
  byte-for-byte copy of `404.html` (the joke: "we're a web design agency
  and we don't have a website yet"). Real site content/design not built.
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
