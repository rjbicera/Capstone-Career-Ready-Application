# Changelog (code / build track)

Tracks completed weekly implementation checkpoints. See `docs/CHANGELOG-SDD.md` for document/architecture-level changes.

## [v0.1.0] - 2026-08-05
**Week:** 0 — Project Inception & Environment
**Scope:** Repository foundation and bootable full-stack scaffold.

**Added**
- Repository structure, `.gitignore`, `.gitattributes`, `README.md`
- Full documentation set: baseline assessment, Firestore schema design, AI prompt architecture, API contract, collaboration/documentation policy
- 4 ADRs (profile doc ID, readiness history, Firestore deny-all rules, admin-in-app)
- `firebase/firestore.rules`, `firestore.indexes.json` (designed, not yet deployed — no live Firebase project)
- `mobile/` — Flutter project scaffolded (`com.captone.careerprep`), verified boots
- `backend/` — Express project scaffolded, layered folder structure, starter files (`server.js`, `app.js`, `firebaseAdmin.js`, `authMiddleware.js`, `.env.example`), verified `GET /api/v1/health` returns `200`

**Known gaps carried into v0.2.0**
- No live Firebase project yet
- Third team member's local environment unverified
- No automated tests yet (expected — no application logic exists yet)
