# Environments

This project uses two deployment environments to separate "testing it" from "it's live."

## Staging

- **Branch:** `gh-pages-staging`
- **Purpose:** Preview deploys before they go to production
- **URL:** Same repo, different branch (or configure a second GitHub Pages site)
- **Protection:** None — deploys automatically after validation passes
- **Lifetime:** Overwritten on every push to main

### How to view staging

Option 1: Check the workflow run summary — it includes the staging URL.
Option 2: Switch the GitHub Pages source to `gh-pages-staging` temporarily.
Option 3: Clone the branch locally and open `index.html`.

## Production

- **Branch:** `gh-pages`
- **Purpose:** The live site visitors see
- **URL:** `https://<username>.github.io/portfolio-auto-deploy/`
- **Protection:** Optional — can add required reviewers in GitHub environment settings
- **Lifetime:** Persists until next deploy or rollback

### Adding manual approval for production

If you want a human checkpoint before going live:

1. Go to **Settings → Environments**
2. Click **production** (create it if it doesn't exist)
3. Check **"Required reviewers"**
4. Add yourself (or a teammate)
5. Save

Now the pipeline will pause at the `deploy-prod` job and wait for approval. You'll get a notification to review and approve.

## Secrets Configuration

Secrets are set at the repository level (Settings → Secrets and variables → Actions):

| Secret | Environment | Purpose |
|--------|-------------|---------|
| `GITHUB_TOKEN` | Both | Automatically provided by GitHub Actions |
| `CUSTOM_DOMAIN` | Production | Optional — your custom domain (e.g., `alexchen.dev`) |

### Why not environment-specific secrets?

For this project, there's nothing environment-specific to configure. Both staging and production use the same `GITHUB_TOKEN`. If I added a CDN or external service, I'd put staging credentials in the staging environment and production credentials in the production environment.

## Environment Variables

Set in the workflow file (`deploy.yml`), not as secrets:

| Variable | Value | Purpose |
|----------|-------|---------|
| `SITE_DIR` | `site` | Directory containing the static site files |

## Local Development

There's no "local environment" config because the site is static HTML. Just open `site/index.html` in a browser:

```bash
# Option 1: Direct open
open site/index.html

# Option 2: Local server (better for relative paths)
cd site && python3 -m http.server 8000

# Option 3: Live reload
npx live-server site/
```
