# AI PDF Scanner-Document Scan — website

Marketing page + Privacy Policy for the app, by Sharkstack Developments. Next.js (App Router) + Tailwind CSS.

- `app/page.tsx` — home page
- `app/privacy-policy/page.tsx` — Privacy Policy (covers all Sharkstack Developments apps)

## Local development

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Deploy to Vercel

This folder lives inside the main app's git repo, at `website/` — not the repo root. When
importing on Vercel, set the **Root Directory** to `website` (Project Settings → General →
Root Directory) so it builds this Next.js app instead of the Flutter project.

**Option A — GitHub import (recommended, auto-deploys on every push):**

1. Go to [vercel.com/new](https://vercel.com/new) and import the
   `abdelhaqouballouk0-droid/AI-PDF-Scanner-Document-Scan` repository.
2. Set **Root Directory** to `website`.
3. Framework preset: Next.js (auto-detected). No environment variables needed.
4. Deploy.

**Option B — CLI (one-off deploy without a git push):**

```bash
cd website
vercel login      # opens a browser / sends a magic link to confirm your account
vercel --prod      # first run also asks to link/create the Vercel project
```
