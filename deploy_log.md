# Deploy Log

Timestamped record of every production deployment and rollback.

Written automatically: the `deploy-prod` job in `.github/workflows/deploy.yml`
appends a row on each production deploy, and `rollback.yml` appends one on each
rollback. Rows are appended with `>>`, so the table has to stay the last thing in
this file and the newest entry is at the bottom. The explanatory prose sits above
it for that reason - when it sat below, every appended row landed after the
closing paragraph and the rendered table silently broke.

The 14 August entry carries no version because of a defect in the pipeline, since
fixed. The log row was written in `deploy-prod` while the version was computed
afterwards in `tag-release`, and nothing went back to substitute it, so the column
could only ever receive the literal placeholder `pending-tag`. The version is now
computed before the row is written and passed to `tag-release` as a job output,
so both use one value. An earlier row containing example data has been removed.

| Timestamp (UTC) | Version | Commit | Trigger | Status |
|---|---|---|---|---|
| 2026-08-14 01:45:15 | - | `b3b6450` | push | ✅ success |
| 2026-08-17 05:09:52 | v2026.08.17.1 | `f811f07` | push | ✅ success |
