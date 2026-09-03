# SDD Changelog (document / architecture track)

Tracks changes to requirements, module design, schema, security policy, or API contract. Code implementation follows these entries, not the other way around.

## [SDD v1.0] - 2026-07

**Objective:** Baseline capstone SDD.
**Changed:** Initial document — full system design.
**Reason:** Original submission per capstone documentation requirements.
**Author:** Project Team

## [SDD v1.1] - 2026-08-03

**Objective:** Fill a gap between documented modules and documented API surface.
**Changed:** §9 API Design — added Profile endpoint group (`GET/PUT /profile`, `POST /profile/photo`).
**Reason:** SDD §5.2 requires a User Profile module with editable fields and photo upload, but §9 never listed corresponding endpoints. Discovered while drafting the full API contract.
**Author:** Project Team
**Related ADR:** —
**Related code version:** —

## [SDD v1.2] - 2026-08-11

**Objective:** Reconcile §8.1 Screen Descriptions and §8.2 Navigation Flow with the Flutter screens actually implemented (splash → onboarding → login → dashboard).
**Changed:**

- §8.1 — added Splash and Onboarding as documented screens (previously only referenced in §8.2 narrative, not the screen table).
- §8.1 — updated Career Readiness Dashboard row: readiness indicator is a single composite ring (not per-category cards) plus a swipeable "Continue prep" carousel, to reduce first-load cognitive load per §8 minimalist design principle.
- §8.2 — corrected navigation topology: Skills Assessment is reached via a push from AI Mock Interview (not a fifth bottom-nav tab); bottom nav has four items (Home, Resume Analyzer, AI Mock Interview, Profile).
- §8.1 — AI Career Recommendations row deferred; not yet implemented in the current build (see Related code version).
  **Reason:** Frontend implementation (mobile/lib/screens/) proceeded from approved wireframes before this section was reconciled against the build. This entry brings the document back in sync per the changelog's own tracking principle; no undocumented behavior is being introduced, only recorded.
  **Author:** Project Team (Jenard Reyes — frontend)
  **Related ADR:** —
  **Related code version:** `mobile/lib/screens/{splash,onboarding,login,home,resume_analysis,mock_interview,skills_assessment,profile}_screen.dart`

## [SDD v1.3] - 2026-09-03

**Objective:** Reconcile §9 Auth endpoints and the frontend's actual auth implementation; document a real architecture gap rather than let code and contract silently disagree.
**Changed:**

- Flutter now calls `firebase_auth` directly from the client (`login_screen.dart`, `signup_screen.dart`, `forgot_password_screen.dart`, and the logout action in `profile_screen.dart`) for sign-in, registration, password reset, and sign-out — Firebase project `capstone-career-ready-app` connected via FlutterFire CLI, `firebase_options.dart` generated, `Firebase.initializeApp()` added to `main.dart`.
- **Known gap, not yet resolved:** `docs/api/api-contract.md` documents `POST /auth/register` as creating **both** the Firebase Auth user **and** a Firestore `users` doc server-side. The current client-side `createUserWithEmailAndPassword` call only creates the Auth user — no `users` doc is created. Profile data (course, year level, role) has nowhere to persist server-side until this is resolved.
- Added `mobile/lib/state/app_state.dart` — an in-memory `ChangeNotifier` singleton holding resume score, interview completion count, and skills progress, feeding a computed `overallReadiness` shown on the Home dashboard. This is a local stand-in for real backend-fed state; `backend/src/` still only contains `firebaseAdmin.js` config and `authMiddleware.js` — none of the feature routes in `api-contract.md` (`/resume`, `/interview`, `/assessments`, `/auth/*`) are implemented yet, so nothing in AppState currently persists across app restarts or syncs across devices.
  **Reason:** Auth needed to work end-to-end for testing/demo purposes before backend feature routes existed. Client-side Firebase Auth is a legitimate pattern on its own (ADR-004 already establishes the Flutter app reuses "existing Firebase Auth flow" directly), but bypassing `/auth/register` specifically means the Firestore `users` doc contract in api-contract.md is currently unfulfilled. Flagging this now so it isn't discovered later as a silent data-model gap — decide explicitly whether to (a) migrate registration to call the backend endpoint once it exists, keeping Firebase Auth + Firestore doc creation atomic server-side, or (b) revise the contract to accept client-created Firestore docs.
  **Author:** Project Team (Jenard Reyes — frontend)
  **Related ADR:** ADR-004-admin-in-app.md (established client-side Firebase Auth reuse), ADR-005-credential-loading.md (backend Firebase Admin setup, unrelated but adjacent)
  **Related code version:** `mobile/lib/main.dart`, `mobile/lib/screens/{login,signup,forgot_password,profile}_screen.dart`, `mobile/lib/state/app_state.dart`, `mobile/lib/firebase_options.dart`
