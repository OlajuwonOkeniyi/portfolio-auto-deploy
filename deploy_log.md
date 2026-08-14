# Deploy Log

Timestamped record of every production deployment.

_Updated automatically by the deploy pipeline (`deploy-prod` job) and by the rollback workflow.
Each row is one production deployment or rollback event. New rows are appended to the bottom,
which is why this note sits above the table rather than below it — an appended row has to land
inside the table to render._

_Known limitation: the `Version` column reads `pending-tag` for pipeline deploys. The version tag
is minted by the `tag-release` job, which runs after `deploy-prod` writes this row, so the row is
written before the tag exists. Cross-reference the commit SHA against the Releases page for the
version. Rollback rows do record the tag, because a rollback names its target up front._

| Timestamp (UTC) | Version | Commit SHA | Triggered By | Status |
|-----------------|---------|------------|--------------|--------|
| 2026-08-14 01:45:15 | pending-tag (`v2026.08.14.1`) | `b3b6450` | push | ✅ success |
| 2026-08-14 04:42:33 | pending-tag | `9c5aa9f` | push | ✅ success |
| 2026-08-14 04:58:18 | pending-tag | `caa6882` | push | ✅ success |
| 2026-08-14 05:19:56 | pending-tag | `666bc0b` | push | ✅ success |
