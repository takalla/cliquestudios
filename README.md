# Clique Studios — 404 / Catch-All Page

A one-screen, self-aware 404 page for cliquestudios.io: "we're a web
agency without a website yet" humor, one button, and hooks to log which
broken/old URLs are still sending people here. Built to your FES coding
standards — external CSS only, BEM classes, hex/rgba colors, `box-sizing:
border-box`, flexbox layout, responsive at 480/768/1200px, semantic HTML.

## What's in here

```
404.html                the page itself
index.html               identical copy — see "About index.html" below
css/404.css               all styling (BEM, hex/rgba only, responsive)
js/config.js              Supabase URL/key — currently EMPTY, see below
js/404.js                 pageview + button-click tracking logic
supabase/hit_log_schema.sql   table + RLS policy to run once you're ready
README.md                 this file
```

## About index.html

Since cliquestudios.io doesn't have a real homepage yet, `index.html` is
just a copy of `404.html`. That way visitors hitting the bare domain see
this page too, not a blank Cloudflare default screen. **When you build
the real homepage, replace `index.html` — leave `404.html` alone,** it
needs to keep existing as the catch-all target.

## Why this doubles as a true catch-all

You asked for this to catch *any* URL on the domain that isn't a real
page — not just literal 404s. Cloudflare Pages does this natively: if a
`404.html` file exists at the root of your deployed site, Cloudflare
automatically serves it (with a real 404 status) for **any** request
that doesn't match an actual file or route. No redirect happens, so the
visitor's browser still shows the exact URL they tried — which is
exactly what `js/404.js` reads (`window.location.pathname`) to log which
dead link they hit. This is why Cloudflare Pages was the right call here
rather than a generic static host.

## Deploying: GitHub → Cloudflare Pages → Porkbun DNS

**1. Push this folder to a GitHub repo.**

```bash
git init
git add .
git commit -m "Add 404 catch-all page"
git branch -M main
git remote add origin https://github.com/<your-username>/cliquestudios-site.git
git push -u origin main
```

(If you don't have a repo yet, create an empty one on GitHub first —
no README/license, since you already have files here.)

**2. Connect it to Cloudflare Pages.**

- Cloudflare dashboard → **Workers & Pages** → **Create** → **Pages** →
  **Connect to Git** → pick this repo.
- Build settings: **Framework preset: None**, **Build command: (leave
  blank)**, **Build output directory: `/`** (root — there's no build
  step, it's plain HTML/CSS/JS).
- Deploy. Every push to `main` auto-updates the live site from here on —
  that's the "push updates through Cloudflare" part.

**3. Point cliquestudios.io at it.**

You bought the domain through Porkbun, so DNS is one of two paths:

- **Recommended — move nameservers to Cloudflare.** In the Pages
  project → **Custom domains** → add `cliquestudios.io`, Cloudflare
  gives you two nameservers. Set those as the domain's nameservers in
  Porkbun (Porkbun dashboard → domain → NS records). This also puts DNS
  fully inside Cloudflare, which you'll want anyway once Workers/D1/KV
  come into play for other Clique projects (Website Edit Admin Portal,
  etc.) — one control panel instead of split between Porkbun and
  Cloudflare.
- **Faster, narrower option — keep DNS at Porkbun.** Add the CNAME
  record Cloudflare shows you (pointing at `<your-project>.pages.dev`)
  directly in Porkbun's DNS settings instead of switching nameservers.
  Works fine for just this site, but you lose the "everything in one
  Cloudflare dashboard" benefit for future domain-level Cloudflare
  features.

Either way, propagation is usually minutes, occasionally up to ~24
hours.

## Wiring up traffic tracking (once Clique's Supabase project exists)

Right now `js/config.js` has empty `supabaseUrl` / `supabaseAnonKey`
values on purpose — you mentioned Clique's Supabase project is coming
from a separate account and isn't ready yet. Until then, every pageview
and button click just gets logged to the browser console instead of
sent anywhere, so nothing is broken or waiting on that decision.

When that project is ready:

1. Run `supabase/hit_log_schema.sql` against it (SQL Editor, or ask me
   to run it via the Supabase MCP tool once that project is connected
   to a session — I'll show you the exact cost/plan info before
   creating anything, same as I did this time).
2. Grab the Project URL and the **anon/publishable** key (Project
   Settings → API) — not the `service_role` key, that one must never
   end up in a public file like this.
3. Paste both into `js/config.js`.
4. Push. That's the entire hookup — `js/404.js` already knows what to
   do with them.

**What you'll be able to see once it's live:** every row in
`site_pings` has the exact path someone hit (so a dead link to, say,
`/old-portfolio` shows up by name if it's still getting clicked), the
referring URL when there is one, a timestamp, and whether it was just a
pageview or someone actually clicked the button. The sample query at
the bottom of the SQL file gives you "hits per path" sorted
highest-first.

## Coding-standards checklist (for your own review)

- No inline styles, no `<style>` blocks — everything's in `css/404.css`.
- All colors are hex/rgba — see the "PLACEHOLDER" comments in the CSS;
  swap these for real Clique brand hex codes once you run the branding
  package on your own site (yes, noted — the irony of not having your
  own brand colors defined yet is not lost on me either).
- BEM throughout: `.error-page`, `.error-page__card`,
  `.error-page__button`, `.error-page__button--clicked`, etc.
- `box-sizing: border-box` reset at the top of the stylesheet.
- Flexbox for all layout; no `position: absolute` used at all here since
  nothing layered was needed.
- Responsive breakpoints at 480 / 768 / 1200px.
- Semantic structure: `<header>`, `<main>`, `<footer>` — no div soup.
- Accessible: decorative emoji marked `aria-hidden`, focus-visible state
  on the button, no images so no alt-text gaps to worry about.
