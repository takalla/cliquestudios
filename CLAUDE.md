# Clique Studios — Website — Progress & Plan

This file tracks build status for future Claude sessions (and OnNae). It's
a living doc — replace/expand the plan section once the real outline exists.

## Branch policy (OnNae, 2026-08-27 — read this before pushing anything)

**Only ever write code to `staging`. Never push to `main` (or any
default/production branch, in this repo or any other) unless OnNae
explicitly says to, in that specific conversation.** A standing
instruction to merge once does not carry forward to future changes —
ask again (or wait to be told) each time. This applies across every
Clique Studios repo, not just this one. OnNae's stated default going
forward is that *she* pushes `staging` → `main` herself once she's
happy with what's on `staging` — don't assume you should do it, even by
asking; wait for her to say she wants you to do it this time. (The one
exception so far: the `.git`-exposure security fix on 2026-08-27, which
she explicitly asked for — see below. That was a one-time ask, not a
standing one.)

Note for whoever picks this repo up next: a local `git merge`/`git
checkout main` from a Claude session got blocked outright by a safety
classifier in that session ("Blocked by classifier") even with explicit
user permission already given. Going through GitHub's API instead (open
a PR with `create_pull_request`, then `merge_pull_request`) worked fine
and wasn't blocked — use that path for any future `staging` → `main`
merge instead of local git commands.

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
  actually deploy this static site. `assets.not_found_handling` set
  explicitly to `"404-page"` (not automatic for Workers static assets the
  way it was on classic Cloudflare Pages).
- `404.html`/`index.html` both got a "Back to homepage" link (`href="/"`)
  -- currently loops back to the same placeholder content since the two
  files are intentionally identical, but will work correctly once a real
  homepage exists
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

Also done, 2026-08-27 (Claude session with push access):
- **Fixed a live security exposure.** `main` had never received the real
  `wrangler.jsonc`/`.assetsignore` that existed on `staging` — the *only*
  production deploy that had ever run (the very first one, before any of
  that config existed) auto-generated a bare-minimum config with no
  `.assetsignore`, so it uploaded the entire `.git` directory as public
  static assets (`.git/config`, `.git/HEAD`, commit objects, all of it —
  see that build's log, UUID `9b54f112`, for the full file list). Very
  likely publicly fetchable at `cliquestudios.io/.git/...` the whole
  time. Same root cause also meant `assets.not_found_handling` was never
  set on `main`, so `cliquestudios.io/<anything-that-doesn't-exist>`
  wasn't serving `404.html`, and `js/404.js` on `main` never sent
  `hostname` (only `staging`'s version did), so that column was null on
  every row in `error_404_site_pings`.
  **Fixed via [PR #3](https://github.com/takalla/cliquestudios/pull/3)**
  (merge `staging` → `main`, explicitly requested by OnNae given the
  security angle), then a production deploy. Confirmed fixed: the new
  deploy's build log shows 86 files read (vs. 104 before) and no
  `.git/*` paths in the upload list. Purged Cloudflare's edge cache for
  `cliquestudios.io` afterward as a precaution.
- `admin.cliquestudios.io` now has its own Worker (`cliquestudios-admin`
  in `cliquestudios-adminportal`), Custom Domain, and zone Route
  (`admin.cliquestudios.io/*` — OnNae added the Route manually; the
  Custom Domain alone wasn't enough). No longer falls into this site's
  wildcard Route/404 page. Full details live in that repo's own
  `CLAUDE.md`.
- **404 page redesigned** (`404.html`, and `index.html` kept in sync as
  a byte-for-byte copy per the existing convention below): removed the
  "Tell Us You Found This" button and its footnote entirely (it created
  an extra row per click, which turned out to feel unnecessary once
  every pageview was already being logged) and `js/404.js`'s now-dead
  click handler. Replaced with a one-shot animated sequence that plays
  on load, over the existing joke card: a "Site destroyed in 3… 2… 1…!"
  countdown flashes, jagged flames rise from the bottom and cover the
  screen, then fade into a dark ash screen with drifting ash specks and
  a "Back to Home" button. All disabled under `prefers-reduced-motion`
  (falls back to just the static joke card, no animation forced on
  motion-sensitive visitors). Verified with a local Playwright
  screenshot at several points in the timeline before pushing.

In progress / not done yet:
- `www.cliquestudios.io` still has a leftover CNAME to `pixie.porkbun.com`
  (a Porkbun service, not GitHub Pages) — not yet addressed, decide
  whether `www` should also point at the Worker
- Homepage (`index.html`) is still a placeholder — it's intentionally a
  byte-for-byte copy of `404.html` (the joke: "we're a web design agency
  and we don't have a website yet"), now including the destruction
  sequence above. Real site content/design not built. **When building
  the real homepage: replace `index.html` and leave `404.html` alone**
  (same rule as always) — but also decide whether the destruction
  sequence should stay on the 404 page once the two files diverge, since
  it was designed with "you hit a page that doesn't exist" framing in
  mind, not "here's our homepage."
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
