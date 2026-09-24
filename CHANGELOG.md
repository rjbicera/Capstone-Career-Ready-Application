# Changelog (code / build track)

Tracks completed implementation checkpoints. See `docs/CHANGELOG-SDD.md` for document/architecture-level decisions and rationale — this file tracks what shipped, that one tracks why.

## [v0.1.0] - 2026-08-05
**Scope:** Repository foundation and bootable full-stack scaffold.
- Repo structure, docs, ADRs 001–005, Firestore rules/indexes deployed
- Flutter + Express scaffolds, both verified booting

## [v0.2.0] - 2026-09-03 (retroactive — reconstructed from docs/CHANGELOG-SDD.md v1.1–v1.6)
**Scope:** Authentication & Profile module complete.
- Real Firebase Auth wired end-to-end: email/password login, signup, Google Sign-In, password reset, logout
- `POST /auth/register`, `GET /auth/me`, `PATCH /auth/me` implemented on the backend
- Demographic profiling screen (course/year level/gender/nickname) covering both signup paths
- Dark mode implemented app-wide (`ThemeController`, palette-aware `AppColors`)
- Known fixed bugs: dropdown-transparency (theme surface color), Google Sign-In Firestore gap, post-auth routing "fail open" bug, 157-error AppColors alias regression, repo contamination incident (see `docs/incident-log.md`)

## [Unreleased]
- Resume Analyzer, Mock Interview, Skills Assessment, Career Dashboard modules — not yet implemented (backend routes don't exist beyond Auth)
- SVG background PNG conversion still pending
