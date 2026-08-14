# BUILD.md — Setup & Deployment Guide

Complete instructions for getting this portfolio auto-deploy pipeline running on your own GitHub account. No prior CI/CD experience required.

---

## Prerequisites

Before you start, make sure you have:

- [ ] A **GitHub account** (free tier works fine)
- [ ] **Git** installed locally (`git --version` to check)
- [ ] A **text editor** (VS Code, vim, whatever you prefer)
- [ ] Basic comfort with the terminal (you'll run ~5 commands total)

Optional (for staging via Netlify):
- [ ] A Netlify account (free tier) if you want a separate staging URL

---

## Step 1: Fork or Clone → Push to Your Own Repo

**Option A: Fork (easiest)**
1. Click the **Fork** button on the original repo's GitHub page
2. This creates a copy under your account
3. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/portfolio-auto-deploy.git
   cd portfolio-auto-deploy
   ```

**Option B: Fresh repo (if you want a clean history)**
1. Create a new repo on GitHub (don't initialize with README)
2. Clone and push:
   ```bash
   git clone https://github.com/OlajuwonOkeniyi/portfolio-auto-deploy.git
   cd portfolio-auto-deploy
   git remote set-url origin https://github.com/YOUR-USERNAME/portfolio-auto-deploy.git
   git push -u origin main
   ```

---

## Step 2: Enable GitHub Pages

1. Go to your repo on GitHub
2. Navigate to **Settings → Pages** (left sidebar, under "Code and automation")
3. Under "Source", select **Deploy from a branch**
4. Set the branch to **`gh-pages`** and folder to **`/ (root)`**
5. Click **Save**

> **Note:** The `gh-pages` branch won't exist until your first successful deploy. That's fine — GitHub will start serving as soon as the branch appears.

Your site will be live at: `https://YOUR-USERNAME.github.io/portfolio-auto-deploy/`

---

## Step 3: Configure Environments

Environments give you protection rules (optional manual approval) and environment-specific secrets.

1. Go to **Settings → Environments**
2. Create two environments:

   **`staging`**
   - No protection rules needed (auto-deploys are fine for staging)
   
   **`production`**
   - (Optional) Add a **required reviewer** — this means someone must click "Approve" in the Actions UI before the prod deploy runs
   - (Optional) Add a **wait timer** (e.g., 5 minutes) to give yourself time to check staging

---

## Step 4: Set Up Secrets

Go to **Settings → Secrets and variables → Actions**.

**Required secrets:** None! The pipeline uses `GITHUB_TOKEN` which is provided automatically.

**Optional secrets:**

| Secret | Purpose |
|--------|---------|
| `CUSTOM_DOMAIN` | If you own a domain (e.g., `yourdomain.dev`), set it here. The deploy action will create a CNAME file. |
| `NETLIFY_AUTH_TOKEN` | If using Netlify for staging previews instead of a GitHub Pages staging branch. |

---

## Step 5: Make a Change, Commit, and Push

The pipeline triggers on pushes to `main` that touch `site/**`, `scripts/**`, or the workflow file itself. Let's trigger it:

```bash
# Edit something in the site
echo "<!-- triggered first deploy -->" >> site/index.html

# Commit and push
git add site/index.html
git commit -m "feat: trigger first pipeline run"
git push origin main
```

---

## Step 6: Watch the Pipeline Run

1. Go to your repo → **Actions** tab
2. You should see a "Deploy Pipeline" workflow running
3. Click into it to see the four jobs:
   - ✅ Validate HTML & Links
   - ✅ Deploy to Staging
   - ✅ Deploy to Production
   - ✅ Tag & Release

Each job has a clickable log. If anything fails, the log tells you exactly what went wrong.

> **Direct link:** `https://github.com/YOUR-USERNAME/portfolio-auto-deploy/actions`

---

## Step 7: Verify Staging Deploy

After the "Deploy to Staging" job completes:

1. In the Actions run, look for the **Deployments** section in the right sidebar
2. Click the **staging** environment link
3. Or navigate directly to your GitHub Pages URL

The staging branch (`gh-pages-staging`) contains a preview of what's about to go to production.

---

## Step 8: Verify Production Deploy

After the full pipeline completes:

1. Visit your live site: `https://YOUR-USERNAME.github.io/portfolio-auto-deploy/`
2. Check the **Releases** page on your repo — you should see a new release like `v2024.03.15.1`
3. Check `deploy_log.md` in your repo — it should have a new entry with timestamp and SHA

---

## Step 9: Test Rollback

Let's verify the rollback workflow works:

1. Go to **Actions → Rollback Deploy** (left sidebar)
2. Click **Run workflow**
3. Enter the tag to roll back to (e.g., `v2024.03.15.1`)
4. Optionally add a reason
5. Click **Run workflow**
6. Watch it complete, then verify your site is serving the old version

> **Note:** The rollback doesn't revert your `main` branch — it just re-deploys the old version's `site/` folder to `gh-pages`. Fix the issue on `main` and push to resume normal deploys.

---

## Customizing the Site Content

### Change the portfolio content:

1. Edit `site/index.html` — update name, title, tagline, project list
2. Edit `site/styles.css` — change colors in the `:root` variables
3. Add images to `site/assets/` and reference them in HTML
4. Commit and push — the pipeline handles the rest

### The CSS design tokens (in `:root`):

```css
--bg: #0d1117;           /* Page background */
--surface: #161b22;      /* Card backgrounds */
--accent: #58a6ff;       /* Links and highlights — change this for brand color */
--max-width: 640px;      /* Content column width */
```

---

## Adding More Validation Checks

The pipeline runs scripts from `scripts/` during the validate job. To add a new check:

1. Create a new script in `scripts/` (e.g., `scripts/check_accessibility.sh`)
2. Make it executable: `chmod +x scripts/check_accessibility.sh`
3. Follow the same pattern as existing scripts:
   - Exit 0 = pass
   - Exit 1 = fail (blocks deploy)
   - Print clear error messages
4. Add a step to `.github/workflows/deploy.yml` in the `validate` job:
   ```yaml
   - name: Run accessibility check
     run: ./scripts/check_accessibility.sh
   ```

### Ideas for additional checks:

| Check | Tool | What it catches |
|-------|------|----------------|
| Accessibility | `pa11y` | Missing alt text, color contrast, ARIA issues |
| Performance | `lighthouse-ci` | Large images, render-blocking resources |
| Spelling | `cspell` | Typos in content |
| Security headers | custom script | Missing CSP, X-Frame-Options |
| Image optimization | `imageoptim-cli` | Oversized images inflating page weight |

---

## Troubleshooting

### Pipeline never triggers

- **Check the paths filter.** The workflow only triggers on changes to `site/**`, `scripts/**`, or `.github/workflows/deploy.yml`. Editing README.md won't trigger it (by design).
- **Check the branch.** Only pushes to `main` trigger the pipeline. Feature branches don't deploy.
- **Manual trigger:** Go to Actions → Deploy Pipeline → Run workflow.

### "Permission denied" on scripts

The workflow runs `chmod +x scripts/*.sh` to handle this. If you're running locally:
```bash
chmod +x scripts/*.sh
```

### HTML validation fails

Read the tidy output in the Actions log. Common fixes:
- Close all tags (`<br>` → `<br>` is fine, but `<div>` needs `</div>`)
- Add `alt` attributes to `<img>` tags
- Don't nest `<p>` inside `<p>`

### Link checker fails on external URLs

- If a URL returns 4xx/5xx: the link is genuinely broken — update or remove it
- If a URL times out: it's probably rate-limiting CI (LinkedIn does this). The script treats timeouts as warnings, not failures, so this shouldn't block your deploy

### Deploy succeeds but site shows old content

GitHub Pages caches aggressively. Try:
1. Hard refresh: `Ctrl+Shift+R` (or `Cmd+Shift+R` on Mac)
2. Wait 2-3 minutes — Pages CDN propagation takes time
3. Check the `gh-pages` branch directly to confirm new content is there

### Rollback fails with "tag not found"

- Check the exact tag name: `git tag --list 'v*'`
- Tags are case-sensitive and format-sensitive (`v2024.03.15.1`, not `V2024.3.15.1`)
- The tag must exist in the remote repo (push tags with `git push --tags`)

### Concurrent deploy conflicts

The workflow uses `concurrency: cancel-in-progress: true`. If you push twice quickly, the first run gets cancelled. This is intentional — the second push has the latest code anyway.

---

## Architecture Overview

```
push to main
     │
     ▼
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌──────────────┐
│  Validate   │────▶│ Deploy Staging  │────▶│ Deploy Prod     │────▶│ Tag Release  │
│  HTML/Links │     │ (gh-pages-stg)  │     │ (gh-pages)      │     │ (vYYYY.MM.DD)│
└─────────────┘     └─────────────────┘     └─────────────────┘     └──────────────┘
     │                                              │
     │ fails → pipeline stops                       │ succeeds → updates deploy_log.md
     ▼                                              ▼
  (nothing deploys)                         (site is live)
```

Each arrow is a `needs:` dependency — downstream jobs only run if upstream succeeds.

---

## File Map

```
portfolio-auto-deploy/
├── .github/workflows/
│   ├── deploy.yml          ← Main pipeline (validate → stage → prod → tag)
│   └── rollback.yml        ← Emergency rollback (manual trigger)
├── scripts/
│   ├── validate_html.sh    ← HTML quality gate (uses tidy)
│   └── check_links.sh     ← Link checker (local + external)
├── site/
│   ├── index.html          ← Portfolio page (edit this for content)
│   ├── styles.css          ← Styles (edit :root vars for theming)
│   └── assets/             ← Images, fonts, etc.
├── environments/           ← Environment-specific configs (if needed)
├── docs/                   ← Additional documentation
├── BUILD.md                ← This file
├── CHANGELOG.md            ← Version history (manually updated)
├── deploy_log.md           ← Auto-updated deploy audit trail
├── README.md               ← Project overview
└── LICENSE                 ← MIT License
```
