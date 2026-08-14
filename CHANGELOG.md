# Changelog

All notable changes to this project are documented here. This file is updated manually for meaningful changes — for raw deploy timestamps and SHAs, see [deploy_log.md](deploy_log.md).

Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [v2024.03.20.1] — 2024-03-20

### Changed
- Improved link checker to gracefully handle external timeouts instead of failing the build
- Increased external URL timeout from 5s to 10s (LinkedIn was intermittently timing out)

### Fixed
- Fixed rollback workflow not logging the actor who triggered it
- Fixed deploy log table alignment in rendered markdown

---

## [v2024.03.18.1] — 2024-03-18

### Added
- Rollback workflow (`rollback.yml`) — one-click revert to any previous tag
- Deploy logging with audit trail (deploy_log.md)
- Tag format validation in rollback workflow (prevents typos from causing cryptic errors)

### Changed
- Deploy pipeline now requires both validation AND staging to pass before production
- Concurrency control: new pushes cancel in-progress deploys instead of queuing

---

## [v2024.03.16.1] — 2024-03-16

### Added
- Staging environment — deploys to `gh-pages-staging` branch before production
- GitHub Environment integration with clickable preview URLs in the Actions UI
- Custom domain support via `CUSTOM_DOMAIN` repo secret

### Changed
- Switched from `JamesIves/github-pages-deploy-action` to `peaceiris/actions-gh-pages` for better orphan branch handling

---

## [v2024.03.15.1] — 2024-03-15

### Initial Release
- Portfolio site with dark theme (GitHub-dark inspired palette)
- CI/CD pipeline: validate → stage → deploy → tag
- HTML validation via W3C Tidy
- Broken link checker (local + external URLs)
- Automatic date-based semantic versioning (vYYYY.MM.DD.N)
- Deploy logging with markdown table format

---

## [Unreleased]

_Next deploy will appear here._

---

### How This File Works

Each meaningful change gets an entry here. The pipeline doesn't auto-edit this file (automated edits create merge conflicts and noisy diffs), but the deploy_log.md is updated automatically on every deploy with timestamps, SHAs, and status.
