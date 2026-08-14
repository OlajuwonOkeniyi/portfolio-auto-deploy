# Portfolio Auto-Deploy

I got tired of manually deploying my portfolio site every time I made a small change. So I set up a proper CI/CD pipeline — validate, stage, deploy, version. Now I just push to main and it handles the rest.

No more FTP. No more "did I forget to push the latest build?" No more manually tagging releases. Just `git push origin main` and walk away.

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

That's it. Your site is live at `https://<username>.github.io/portfolio-auto-deploy/`.

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

Preview URL: `https://<username>.github.io/portfolio-auto-deploy/` (on staging branch — configure a separate GitHub Pages site or use the Actions deployment summary for the preview link).

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

## Lessons Learned

A few things I figured out along the way:

1. **Start with validation, not deployment.** I wasted time debugging deploy issues that were actually broken HTML. Adding the lint step first saved hours later.

2. **Staging doesn't need to be fancy.** A separate branch works fine for a static site. I don't need a whole Netlify setup — just a place to eyeball things before they go live.

3. **Date-based versions > sequential numbers.** When I'm looking at tags, `v2024.03.15.1` tells me immediately when something deployed. `v47` tells me nothing.

4. **Rollback needs to be one click.** If rolling back requires more than 30 seconds of thinking, you won't do it when you're panicking at 11pm. The `workflow_dispatch` trigger makes it trivial.

5. **Log everything.** The deploy log has saved me twice already — once when I couldn't remember which commit was in production, and once when I needed to prove to myself that yes, I did deploy on Tuesday.

## License

MIT — see [LICENSE](LICENSE).

---

*Built because I wanted to stop thinking about deploys and start thinking about content.*
