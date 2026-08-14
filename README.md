# Portfolio Auto-Deploy

[![Deploy Pipeline](https://github.com/OlajuwonOkeniyi/portfolio-auto-deploy/actions/workflows/deploy.yml/badge.svg)](https://github.com/OlajuwonOkeniyi/portfolio-auto-deploy/actions/workflows/deploy.yml)
[![Live site](https://img.shields.io/badge/live-olajuwonokeniyi.github.io-8575ff)](https://olajuwonokeniyi.github.io/portfolio-auto-deploy/)

My portfolio was a single HTML file I copied into place by hand. This repo replaces that with a
proper CI/CD pipeline — validate, stage, deploy, version — so a change reaches production the same
way every time: `git push origin main`, and the pipeline does the rest.

Built in August 2026. The site it deploys is live at
https://olajuwonokeniyi.github.io/portfolio-auto-deploy/

## Overview

This is a personal CI/CD pipeline for my portfolio site. It's intentionally simple — a static HTML/CSS site deployed to GitHub Pages — but the pipeline itself demonstrates real-world practices:

- **Quality gates** that block deploys if HTML is broken or links are dead
- **Staging environment** for preview before production goes live
- **Automatic semantic versioning** tied to each production deploy
- **One-click rollback** if something goes wrong
- **Deploy history** tracked in version control

## How It Works

```
Push to main
     │
     ▼
┌─────────────┐
│  Validate   │  ← HTML lint + broken link check
└─────┬───────┘
      │ pass
      ▼
┌─────────────┐
│  Deploy     │  ← Push to staging branch (preview URL)
│  Staging    │
└─────┬───────┘
      │ success
      ▼
┌─────────────┐
│  Deploy     │  ← Push to gh-pages branch (live site)
│  Production │
└─────┬───────┘
      │ success
      ▼
┌─────────────┐
│  Tag &      │  ← Creates vYYYY.MM.DD.N tag + GitHub Release
│  Release    │
└─────────────┘
```

If validation fails, nothing deploys. If staging fails, production isn't touched. Each stage gates the next.

## Tech Stack

| Component | Tool | Why |
|-----------|------|-----|
| CI/CD | GitHub Actions | Free for public repos, lives next to the code |
| Hosting (prod) | GitHub Pages | Free, fast, custom domain support |
| Hosting (staging) | `gh-pages-staging` branch | Same infra, separate URL via branch deploy |
| Validation | HTML Tidy + custom link checker | Catches broken markup before deploy |
| Versioning | Git tags (date-based semver) | Automatic, traceable, rollback-friendly |
| Scripts | Bash | No dependencies, runs anywhere |

## Quick Start

1. **Fork this repo**
2. **Enable GitHub Pages**: Settings → Pages → Source: "Deploy from a branch" → `gh-pages` / `/ (root)`
3. **Push a change to `main`** — the pipeline runs automatically
4. **Check the Actions tab** to watch it validate → stage → deploy → tag

That's it. Your site is live at `https://<your-username>.github.io/portfolio-auto-deploy/`.
This one runs at https://olajuwonokeniyi.github.io/portfolio-auto-deploy/

### Optional: Custom Domain

Add a `CNAME` file in `site/` with your domain, then configure DNS. The pipeline will deploy it along with everything else.

## Pipeline Stages

### 1. Validate (`validate` job)

Runs two checks:
- **HTML validation** via `tidy` — catches unclosed tags, invalid attributes, malformed markup
- **Link checking** — scans all `href` and `src` attributes, verifies local files exist and remote URLs respond

If either fails, the workflow stops. No broken HTML reaches production.

### 2. Deploy Staging (`deploy-staging` job)

Pushes the `site/` directory to the `gh-pages-staging` branch. This gives you a preview URL to check before promoting to production.

Preview URL: `https://<your-username>.github.io/portfolio-auto-deploy/` (on staging branch — configure a separate GitHub Pages site or use the Actions deployment summary for the preview link).

### 3. Deploy Production (`deploy-prod` job)

After staging succeeds, deploys to the `gh-pages` branch. This is the live site. Uses the `peaceiris/actions-gh-pages` action for atomic deploys.

Also appends an entry to `deploy_log.md` with timestamp, commit SHA, and deployer.

### 4. Tag Release (`tag-release` job)

Creates a date-based semantic version tag: `v2024.03.15.1` (year.month.day.build-number).

If you deploy multiple times in one day, the build number increments. Also creates a GitHub Release with auto-generated release notes.

## Rollback

Things break. Here's how to fix them fast:

### Manual Rollback (recommended)

1. Go to **Actions** → **Rollback Deploy** workflow
2. Click **"Run workflow"**
3. Enter the tag to roll back to (e.g., `v2024.03.15.1`)
4. The workflow checks out that tag and deploys it to `gh-pages`

### CLI Rollback

```bash
# Find the tag you want
git tag --list 'v*' --sort=-version:refname | head -10

# Trigger the rollback workflow
gh workflow run rollback.yml -f tag_version=v2024.03.15.1
```

See [docs/ROLLBACK.md](docs/ROLLBACK.md) for the full procedure and decision tree.

## Versioning

Tags follow the format: `vYYYY.MM.DD.N`

- `YYYY.MM.DD` — date of the deploy
- `N` — build number for that day (starts at 1, increments if you deploy multiple times)

Examples:
- `v2024.03.15.1` — first deploy on March 15, 2024
- `v2024.03.15.2` — second deploy that same day
- `v2024.03.16.1` — first deploy the next day

This gives you chronological ordering, easy identification ("that was last Tuesday's deploy"), and unlimited deploys per day.

## Project Structure

```
portfolio-auto-deploy/
├── README.md                  ← you are here
├── LICENSE
├── CHANGELOG.md               ← deploy history (human-readable)
├── deploy_log.md              ← machine-friendly deploy log
├── .gitignore
├── .github/workflows/
│   ├── deploy.yml             ← main pipeline: validate → stage → prod → tag
│   └── rollback.yml           ← manual rollback to any previous tag
├── site/
│   ├── index.html             ← the portfolio page
│   ├── styles.css             ← styling
│   └── assets/                ← images, fonts, etc.
├── scripts/
│   ├── validate_html.sh       ← HTML linting via tidy
│   └── check_links.sh        ← broken link detection
├── docs/
│   ├── PIPELINE.md            ← pipeline design decisions
│   └── ROLLBACK.md            ← rollback procedures
└── environments/
    └── README.md              ← staging vs prod explanation
```

## Deployment History

See [deploy_log.md](deploy_log.md) for a timestamped log of every production deploy, including commit SHAs and version tags.

## What Building This Surfaced

This pipeline was built in August 2026 as a working demonstration of a gated deploy
process. Standing it up and then auditing it turned up several defects worth recording —
the bugs are more instructive than the code that worked first time.

1. **A quality gate that can't run must fail, not pass.** `validate_html.sh` shelled out to
   `tidy` and branched on its exit code. When `tidy` wasn't installed, the command
   substitution exited 127 — neither 1 (warnings) nor 2 (errors) — so every file fell
   through to the "clean pass" branch. The gate reported success while validating nothing.
   Any script that dispatches on a tool's exit codes needs to assert the tool exists first,
   and needs a default branch that fails closed.

2. **`||` on a command that writes to stdout before failing gives you two values.**
   `check_links.sh` used `HTTP_CODE=$(curl -w "%{http_code}" ... || echo "000")`. On a failed
   transfer curl prints `000` *and* exits non-zero, so the fallback appended a second `000`
   and the variable held `000000`. That matched no branch, so every unreachable host was
   reported as definitively broken and blocked the deploy — the opposite of the documented
   intent. Capture output and exit status separately.

3. **`${VAR:-default}` doesn't reset a loop variable.** `:-` substitutes only when a variable
   is *unset*. Reusing `TIDY_EXIT` across files meant one failure poisoned every subsequent
   iteration. Loop-scoped state has to be assigned at the top of the loop.

4. **Third-party bot policy is not your build's business.** LinkedIn answers automated
   requests with HTTP 999 and Cloudflare-fronted hosts answer with 403. Failing the build on
   those makes your deploy depend on someone else's rate limiter. They're warnings now;
   genuine 4xx/5xx still block.

5. **Check what a workflow expression actually resolves to.** The staging job's
   `environment.url` referenced `steps.deploy.outputs.staging_url`, but `deploy` was the
   third-party deploy action, which emits no such output — the value came from a different,
   unnamed step. GitHub doesn't error on an unresolvable expression; it renders empty. The
   link looked configured and was blank.

6. **Append-only logs constrain file layout.** The `deploy-prod` job appends a row to
   `deploy_log.md` with `>>`. The file kept its explanatory prose *below* the table, so every
   appended row landed after the footer and broke the rendered markdown table. The prose moved
   above the table.

7. **Rollback needs to be one click.** If rolling back takes more than 30 seconds of thinking,
   you won't do it under pressure. The `workflow_dispatch` trigger with a tag input makes it a
   form submission.

## License

MIT — see [LICENSE](LICENSE).

---

*Built by Olajuwon Okeniyi, August 2026.*
