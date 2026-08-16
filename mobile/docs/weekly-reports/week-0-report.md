# Weekly Development Report

**Version:** v0.1.0
**Week:** 0 — Project Inception & Environment
**Objective:** Establish a working repository foundation, documented architecture, and a bootable Flutter + Express scaffold that all team members can pull and build on.

## Completed

- GitHub repository created (`rjbicera/Capstone-Career-Ready-Application`), collaborator access configured
- Full documentation set committed: Project Baseline Assessment, Firestore schema design, AI prompt architecture, API contract, collaboration/documentation policy, SDD changelog
- 4 Architecture Decision Records written (profile doc ID, readiness history, Firestore deny-all rules, admin-in-app)
- `firebase/firestore.rules` and `firestore.indexes.json` drafted (not yet deployed to a live Firebase project — pending Firebase project creation)
- Flutter SDK installed and verified (`flutter doctor` clean) on 2 of 3 team machines; Android toolchain configured (SDK, Build-Tools 28.0.3, licenses accepted)
- Node.js LTS confirmed installed on all attempted machines
- `mobile/` scaffolded via `flutter create`, org `com.captone.careerprep` — boots and runs default app
- `backend/` scaffolded via `npm init` + dependency install (Express 5, Firebase Admin, Gemini/OpenAI SDKs, zod, and dev tooling)
- Backend folder structure created matching the layered architecture (config/middleware/routes/controllers/services/repositories/integrations/models)
- Backend starter files added: `server.js`, `src/app.js` (with centralized error handler), `src/config/firebaseAdmin.js`, `src/middleware/authMiddleware.js` (token verification + admin role check), `.env.example`
- Backend verified booting locally: `GET /api/v1/health` → `200 {"status":"ok"}`
- `.gitattributes` added to normalize line endings across team machines

## Files Changed

137 files added in the scaffold commit (`f3d8d35`) — Flutter project structure, backend structure + starter files + dependencies (`package.json`, `package-lock.json`).

## APIs Added/Changed

- `GET /api/v1/health` — implemented and verified. All other endpoints from the API contract remain unimplemented, to be built per module owner starting Week 1.

## Database Changes

- No live Firestore project yet — rules/indexes/schema are designed and committed but not deployed. **Blocking item for Week 1**, since Auth needs a real Firebase project.

## AI Changes

None yet — `aiClient` and prompt files are designed (`docs/architecture/ai-prompt-architecture.md`) but not implemented. Scheduled for Week 2 (Resume Analyzer) per module ownership.

## Tests Executed

- Manual: `flutter run` (default counter app launches)
- Manual: `npm run dev` + browser request to `/api/v1/health`
- No automated tests yet — expected, no application logic exists yet to test

## Test Results

- Passed: 2 (manual boot checks, both frontend and backend)
- Failed: 0
- Skipped: automated test suite (Jest/Flutter test) — nothing to test yet

## Security Review

- Firestore rules drafted deny-all (ADR-003) — not yet deployed/verified against a live project
- `.env.example` committed with placeholder values only; no real secrets in repo
- `authMiddleware.js` written correctly re-verifying role server-side rather than trusting client input, per SDD §10.1 — not yet exercised against a real Firebase Auth token (no live project)

## Known Issues

- Third team member's machine not yet verified (Flutter/Node/Android Studio status unknown as of this report)
- No live Firebase project created yet — blocks any real Auth/Firestore work in Week 1
- Line-ending normalization (`.gitattributes`) added after the initial scaffold commit — existing files not retroactively renormalized (low risk, no conflicts yet)

## Technical Debt

- CI/CD pipeline (`.github/workflows/`) not yet built — flagged in original baseline assessment, deferred until there's actual code to lint/test in CI
- No automated test suite yet — acceptable for Week 0, must not carry into Week 1 untested

## Git Commit
