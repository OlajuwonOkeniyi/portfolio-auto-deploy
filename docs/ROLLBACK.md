# Rollback Procedure

How to roll back a bad deploy to any previously tagged version.

## Decision Tree

```
Something's wrong with the live site
          │
          ├── Is it a content issue (typo, wrong text)?
          │     └── Fix it on main and push → pipeline redeploys automatically
          │
          ├── Is the site completely broken?
          │     └── ROLLBACK immediately, then investigate
          │
          └── Is it a minor visual issue?
                └── Fix on main and push (no rollback needed)
```

## Rollback via GitHub UI (Recommended)

1. Navigate to the repository on GitHub
2. Click the **Actions** tab
3. In the left sidebar, click **Rollback Deploy**
4. Click the **"Run workflow"** button (top right)
5. Enter the tag to roll back to:
   - Find recent tags: look at the releases page or `deploy_log.md`
   - Format: `v2026.08.14.1`
6. Optionally enter a reason (for the audit log)
7. Click **"Run workflow"**

The workflow redeploys that tag's `site/` directory to `gh-pages`; GitHub Pages picks up the change on its next build.

## Rollback via CLI

```bash
# List recent tags to find the one you want
git tag --list 'v*' --sort=-version:refname | head -10

# Trigger the rollback
gh workflow run rollback.yml \
  -f tag_version=v2026.08.14.1 \
  -f reason="Broken CSS on mobile"

# Watch it run
gh run watch
```

## Finding the Right Tag

### Option 1: Check deploy_log.md

```bash
# See recent deploys
tail -10 deploy_log.md
```

### Option 2: List git tags

```bash
# Most recent tags first
git tag --list 'v*' --sort=-version:refname | head -10
```

### Option 3: GitHub Releases page

Go to the repository's Releases page — each deploy creates a release with the commit message.

## What Happens During Rollback

1. The workflow checks out the specified tag (full source at that point in time)
2. The `site/` directory from that tag is deployed to `gh-pages`
3. A rollback entry is added to `deploy_log.md` on main
4. The live site now serves the old version

**Important:** The `main` branch is NOT modified. It still has the newer (broken) code. You need to fix the issue on main and push again to move forward.

## After Rollback

1. **Verify the site is working** — check the live URL
2. **Investigate the issue** — look at what changed between the rolled-back tag and the broken deploy
3. **Fix on main** — commit the fix
4. **Push to main** — the pipeline will validate, stage, and deploy the fix
5. **Confirm** — check that the new deploy works correctly

## Emergency: Manual Rollback (No GitHub Actions)

If Actions is down or the workflow won't trigger:

```bash
# Check out the tag locally
git checkout v2026.08.14.1

# Force-push site/ contents to gh-pages
git subtree push --prefix site origin gh-pages

# Or use the nuclear option:
cd site
git init
git add .
git commit -m "emergency rollback to v2026.08.14.1"
git push -f origin HEAD:gh-pages
cd ..
rm -rf site/.git
```

This bypasses the pipeline entirely. Use only in emergencies.

## Preventing Bad Deploys

The best rollback is one you never need:

- The validation step catches most HTML issues
- Staging gives you a preview before prod
- Keep changes small — easier to identify what broke
- Check the Actions tab after pushing to confirm success
