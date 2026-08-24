# Incident Log

Operational failures and their resolutions — distinct from ADRs (which record deliberate design decisions). Kept so recurring mistakes are recognizable and so the team (and adviser/panel) has an honest record of real problems encountered and how they were actually resolved.

---

## INC-001: Repository contamination from misdirected zip extraction
**Date:** 2026-08-19
**Severity:** High (already merged into `main` via PR before detection)

**What happened:**
A full repository zip export (`Capstone-Career-Ready-Application-main.zip`) was extracted directly into the `mobile/` folder instead of a separate location. This nested an entire duplicate copy of the repository — `mobile/backend/`, `mobile/docs/`, `mobile/firebase/`, agent-skill reference folders (`mobile/.agents/`, `mobile/.claude/`), IDE config (`mobile/.idea/`), and a second complete nested Flutter project at `mobile/mobile/` — inside the real `mobile/` folder. `git add .` was then run from that location and merged into `main` via Pull Request #1, growing the tracked file count under `mobile/` from ~150 to 509 without the anomaly being caught in review.

**Impact:**
- `mobile/README.md` was silently overwritten with the repo root's README content, with UTF-8 encoding corruption introduced in the process (`â€"`, `Â·` artifacts in place of em-dashes and middot characters).
- `mobile/test/widget_test.dart` was shadowed by a stale duplicate at `mobile/mobile/test/widget_test.dart`, causing confusion during debugging (edits appeared not to take effect because the wrong file was being edited).
- No functional/runtime impact — the real Flutter app at `mobile/lib` and `mobile/pubspec.yaml` was never touched, only duplicated alongside.

**Root cause:** Zip extracted to the wrong destination folder; no PR-level red flag caught before merge despite an unusually large file-count change for the stated scope of the PR.

**Fix applied:**
1. Restored `mobile/README.md` from the clean copy found in the nested duplicate before deleting it.
2. `git rm -r --cached` on all contaminated paths, followed by physical deletion from disk.
3. Verified via `git ls-files mobile/ | Measure-Object -Line`: 509 → 150 tracked files.
4. Re-ran `flutter analyze` to confirm the real project was unaffected and the earlier confusing duplicate/contradictory analyzer output (caused by two overlapping Flutter project contexts) resolved.
5. Committed and pushed the cleanup; team instructed to `git pull` before touching `mobile/` again, to avoid any local stale copy resurrecting the contamination.

**Prevention going forward:**
- Reinforces the existing collaboration policy (`docs/collaboration-and-documentation-plan.md`): PR review by a second team member before merging into `main` is not optional — a "509 files changed" diff on a PR meant to add a handful of screens is an immediate, visible red flag a reviewer should catch before merge.
- When extracting a downloaded zip of the repo (e.g., to inspect a teammate's changes outside git), extract to a **new, clearly separate folder**, never into an existing project folder.
