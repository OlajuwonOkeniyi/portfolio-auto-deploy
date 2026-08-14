# Changelog

All notable changes to this project are documented here. This file is updated manually for meaningful changes — for raw deploy timestamps and SHAs, see [deploy_log.md](deploy_log.md).

Format follows [Keep a Changelog](https://keepachangelog.com/).

This project was built in August 2026. Every entry below corresponds to a real commit and, where a version is given, a real tag in this repository.

---

## [Unreleased]

### Fixed

- **Link checker reported every unreachable host as a broken link.** `check_links.sh` captured curl's status with `HTTP_CODE=$(curl ... || echo "000")`. On a failed transfer curl writes its `%{http_code}` template to stdout (`000`) *and* exits non-zero, so the `|| echo` fired too and the substitution captured `000000`. That matched neither the 2xx/3xx pattern nor the `000` timeout branch, so unreachable hosts fell through to the "definitively broken" case and failed the build — the exact opposite of the documented "timeouts are warnings" design. curl's output and exit status are now captured separately and the result normalised.
- **Bot-protection responses now warn instead of failing.** 403, 429 and 999 mean "we don't serve automated clients", not "this link is broken". LinkedIn answers CI traffic with 999 and Cloudflare-fronted hosts answer with 403; treating those as errors made deploys depend on a third party's bot policy.
- **HTML validation passed when the validator was missing.** In `validate_html.sh`, `TIDY_OUTPUT=$(tidy ...)` exits 127 when tidy is not installed. 127 is neither 1 (warnings) nor 2 (errors), so every file fell through to the "clean pass" branch and the gate reported success while validating nothing. The script now checks for `tidy` up front and exits 1 if it is absent, and treats any exit code above 2 as a blocking failure.
- **Stale exit code leaked between files in HTML validation.** `TIDY_EXIT=${TIDY_EXIT:-0}` only substitutes when the variable is *unset*. Once one file failed, `TIDY_EXIT` stayed at 2 and `|| TIDY_EXIT=$?` never fires on success — so every later clean file inherited the 2 and was reported broken. `TIDY_EXIT` is now reset at the top of each iteration.
- **Staging environment URL rendered blank.** The `deploy-staging` job set `environment.url` to `steps.deploy.outputs.staging_url`, but `deploy` is the peaceiris action, which emits no such output; the value was written by a different, unnamed step. The URL step now has an `id` and runs before the deploy, and the environment references it.
- **Appended deploy-log rows landed outside the markdown table.** `deploy_log.md` kept explanatory prose below the table, so the `>>` append in the `deploy-prod` job wrote each new row after the footer and broke the rendered table. The prose now sits above the table.

### Changed

- Replaced template placeholder attribution and example identifiers throughout the docs with the real author and repository.
- `LICENSE` copyright now names the actual author and year.
- Every worked example now uses this repository's real tag (`v2026.08.14.1`) instead of a placeholder dated March 2024 — 26 occurrences across the README, the docs and both workflows.
- README Quick Start rewritten as "How It's Set Up": a record of the GitHub Pages source, environments and secrets actually configured here, rather than fork-this-repo instructions addressed to a stranger.
- README staging section now states the real constraint — a Pages project site serves one branch at a time, so `gh-pages-staging` has no public URL and the value of the stage is the gate, not the preview.
- `docs/PIPELINE.md` design rationale rewritten to argue from how the pipeline is actually built (`needs:` ordering) rather than from invented project history.
- README "What Building This Surfaced" trimmed from seven items to the four with a silent-failure mode; the rest stay documented here.
- Corrected "date-based semver" (it is date-based versioning, not semver) and the claim that `deploy_log.md` records a deployer (it records the trigger event).

### Removed

- `BUILD.md` — a 250-line "get this running on your own GitHub account" tutorial. This repository is the deployment pipeline for one live site, not a distributable starter kit; the configuration it described is now recorded in the README and `environments/README.md`.
- `site/assets/` and its placeholder README — the directory was empty and unreferenced by `index.html`.

---

## [v2026.08.14.1] — 2026-08-14

First successful end-to-end run of the pipeline: validate → staging → production → tag. Live at
https://olajuwonokeniyi.github.io/portfolio-auto-deploy/

### Added

- CI/CD pipeline (`deploy.yml`): validate → stage → deploy → tag, with each stage gating the next
- Rollback workflow (`rollback.yml`) — manual `workflow_dispatch` revert to any previous tag
- HTML validation via W3C Tidy and a dependency-free broken-link checker
- Staging deploys to `gh-pages-staging`, production to `gh-pages`
- Automatic date-based versioning (`vYYYY.MM.DD.N`) and GitHub Releases
- Deploy logging with an audit trail in `deploy_log.md`
- Portfolio site (`site/index.html`, `site/styles.css`) with a dark theme

### Fixed

- Removed `preconnect` link tags that the link checker could not resolve, which had failed the two
  preceding pipeline runs at the "Run link checker" step

---

### How This File Works

Each meaningful change gets an entry here. The pipeline doesn't auto-edit this file (automated edits create merge conflicts and noisy diffs), but `deploy_log.md` is updated automatically on every deploy with timestamps, SHAs, and status.
