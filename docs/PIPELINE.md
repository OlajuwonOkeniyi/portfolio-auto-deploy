# Pipeline Design

How the deploy pipeline works and why I made these choices.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                           │
│                                                             │
│  ┌───────────┐    ┌──────────┐    ┌──────────┐    ┌─────┐ │
│  │ validate  │───▶│ staging  │───▶│   prod   │───▶│ tag │ │
│  └───────────┘    └──────────┘    └──────────┘    └─────┘ │
│       │                                                     │
│       ▼ (fail)                                              │
│   [stop — nothing deploys]                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Design Decisions

### Why validate before deploy (not after)?

Seems obvious, but I initially had it reversed — deploy first, then run checks. The problem: broken HTML was already live by the time I noticed. Moving validation to the front means nothing broken ever reaches production.

### Why a staging step for a personal site?

Two reasons:
1. **Catches deploy-specific issues.** Sometimes HTML works locally but breaks when deployed (relative paths, missing assets, CORS issues).
2. **Habit building.** I use staging→prod promotion at work. Keeping the same mental model for personal projects means I don't make lazy mistakes.

### Why date-based versioning instead of semver?

Traditional semver (1.2.3) implies intentional version bumps. For a portfolio site, I deploy whenever I make a change — there's no "major vs minor" distinction. Date-based versions (`v2024.03.15.1`) give me:
- Instant context about when something was deployed
- No manual version bumping
- Natural chronological ordering
- Unlimited deploys per day

### Why `peaceiris/actions-gh-pages` instead of built-in Pages deploy?

GitHub's newer Pages deployment (via artifacts + deploy action) is more "correct" but also more complex. For a static site, pushing to a `gh-pages` branch is simpler, more portable, and easier to debug. The `peaceiris` action handles the force-push cleanly and supports CNAME files.

### Why not use a build step?

There's no build because there's nothing to build. It's static HTML/CSS. If I add a static site generator later (Hugo, 11ty), I'll insert a build job between validate and deploy-staging. The pipeline structure already supports it — just add a job and update the `needs:` dependencies.

### Concurrency control

The workflow uses `concurrency: deploy-pipeline` with `cancel-in-progress: true`. This means:
- If I push twice quickly, the first deploy is cancelled
- Only one deploy runs at a time (no race conditions on gh-pages)
- The latest push always wins

### The `[skip ci]` commit message

The deploy-prod job commits to `deploy_log.md` with `[skip ci]` in the message. Without this, the log commit would trigger another deploy, creating an infinite loop. GitHub Actions recognizes `[skip ci]` and won't trigger workflows for that commit.

## Secrets and Environment Configuration

### Required Secrets

| Secret | Required | Purpose |
|--------|----------|---------|
| `GITHUB_TOKEN` | Auto-provided | Deploy to gh-pages, create releases |
| `CUSTOM_DOMAIN` | Optional | CNAME for custom domain |

### Environments

Two environments are configured in GitHub:

- **staging** — no protection rules, deploys immediately
- **production** — optionally add required reviewers for manual approval before prod deploy

To add manual approval:
1. Go to Settings → Environments → production
2. Add "Required reviewers"
3. The pipeline will pause at deploy-prod and wait for approval

## Failure Modes

| Failure | Result | Recovery |
|---------|--------|----------|
| HTML validation fails | Pipeline stops at validate | Fix HTML, push again |
| Staging deploy fails | Prod not touched | Check Actions logs, fix, push |
| Prod deploy fails | Old version still live | Check permissions, retry |
| Tag creation fails | Site is deployed but untagged | Manual tag or re-run job |
| External link timeout | Non-blocking warning | Links still checked, deploy continues |

## Future Improvements

Things I might add:
- [ ] Lighthouse CI score check (performance gate)
- [ ] Screenshot comparison between staging and prod
- [ ] Slack/Discord notification on deploy
- [ ] Branch preview deploys for PRs
- [ ] HTML minification in a build step
