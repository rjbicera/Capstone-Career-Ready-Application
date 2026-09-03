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

## [SDD v1.4] - 2026-09-03 (AI-assisted, needs team review before final sign-off)

**Objective:** Correct v1.3's description of the auth flow against what the code actually did, and close the gaps found.
**Changed:**

- **v1.3 overstated completion.** It said `login_screen.dart` and `forgot_password_screen.dart` "call `firebase_auth` directly" and that `Firebase.initializeApp()` was added to `main.dart`. None of that was true at the time: `main.dart` never called `Firebase.initializeApp()` at all (so any `FirebaseAuth` call anywhere in the app, including signup's sign-in step, would have thrown `No Firebase App '[DEFAULT]' has been created` the first time it ran); `login_screen.dart` checked email/password against a hardcoded list of three temp accounts; `forgot_password_screen.dart` just awaited a fake delay; `profile_screen.dart`'s logout popped the nav stack without calling `signOut()`, so the ID token stayed valid.
- `signup_screen.dart`, by contrast, was already correctly wired to `AuthApiService.register()` (the backend endpoint from `authController.js`) followed by a client-side sign-in — this was the one part of v1.3 that matched the code.
- Fixed all four gaps: `main.dart` now calls `Firebase.initializeApp()` before `runApp`; `login_screen.dart` calls `FirebaseAuth.instance.signInWithEmailAndPassword`; `forgot_password_screen.dart` calls `sendPasswordResetEmail`; `profile_screen.dart` calls `signOut()` before navigating to `LoginScreen`.
  **Reason:** Documentation and code had drifted apart — the changelog's own stated purpose is to be the source of truth code implementation follows, so letting it describe an unfinished flow as done was worth correcting rather than leaving for someone to discover at demo time.
  **Author:** AI-assisted (Claude), at RJ's request — flagging for a team member to review and re-attribute per your usual process before this is treated as final.
  **Related ADR:** —
  **Related code version:** `mobile/lib/main.dart`, `mobile/lib/screens/{login,forgot_password,profile}_screen.dart`

## [SDD v1.5] - 2026-09-03 (AI-assisted, needs team review before final sign-off)

**Objective:** Fix a reported UI bug (sign-up screen's year-level dropdown rendering transparent/overlapping the fields below it) and wire up Google Sign-In.
**Changed:**

- **Root cause of the dropdown bug:** `AppTheme.light`'s `ColorScheme.fromSeed(...)` sets `surface: AppColors.background`, and `AppColors.background` is `Colors.transparent` — done deliberately so the `AppBackground` gradient shows through the Scaffold body. But `DropdownButtonFormField`'s menu popup paints itself from `Theme.of(context).canvasColor` (which tracks `colorScheme.surface` when unset), so that same transparency was leaking into the dropdown's popup, and would equally affect `AlertDialog` (e.g. the logout confirmation on profile), `PopupMenuButton`, and bottom sheets anywhere else in the app. Fixed at the theme level (`canvasColor`, `dialogTheme`, `popupMenuTheme`, `bottomSheetTheme`, `dropdownMenuTheme` all pinned to opaque `AppColors.card`) rather than patching just the one dropdown, since the same bug was latent everywhere a Material popup gets used. Also set `dropdownColor` explicitly on the sign-up screen's dropdown as a second layer of defense.
- **Google Sign-In:** added `google_sign_in` to `pubspec.yaml` and implemented the handler in `login_screen.dart` (`GoogleSignIn` → `GoogleAuthProvider.credential` → `FirebaseAuth.signInWithCredential`), replacing the empty `onPressed`.
- **Known gap, not yet resolved:** a brand-new Google account signing in this way gets a valid Firebase Auth session but no Firestore `users` doc — Google doesn't supply `course`/`yearLevel`, and `/auth/register` requires both. `GET /auth/me` will 404 for these users until there's a "finish setting up your profile" screen plus a backend endpoint that creates the `users/{uid}` doc for an already-authenticated user (rather than one that also creates the Auth user, like `/auth/register` does now). Flagged with a code comment on `_handleGoogleSignIn`.
- **Also not done, and can't be from here:** the Google Cloud / Firebase console side of this — registering the app's SHA-1 fingerprint (Android) and configuring the URL scheme (iOS) for the OAuth client, and confirming the Google provider is enabled in Firebase Auth. The code will not actually complete a sign-in until that console configuration exists; whoever owns the Firebase project needs to do that part.
  **Reason:** RJ asked for the year-level dropdown bug from a screenshot, dark mode, and Google Sign-In, in one request; this entry covers the two closeable-in-code items. Dark mode is scoped separately (see conversation) since every screen currently reads colors from `AppColors` directly rather than `Theme.of(context)`, making it a much larger, app-wide change rather than a contained fix.
  **Author:** AI-assisted (Claude), at RJ's request — flagging for a team member to review and re-attribute per your usual process before this is treated as final.
  **Related ADR:** —
  **Related code version:** `mobile/lib/theme/app_theme.dart`, `mobile/lib/screens/{signup,login}_screen.dart`, `mobile/pubspec.yaml`

## [SDD v1.6] - 2026-09-03 (AI-assisted, needs team review before final sign-off)

**Objective:** Close the Google Sign-In Firestore gap flagged in v1.5, and move demographic profiling (course/yearLevel/gender) out of the signup form into its own step per docs/architecture's recommendation, so it covers Google accounts too.
**Changed:**

- **`users/{uid}` schema:** `course` and `yearLevel` are now nullable (set at registration only if provided, otherwise filled in later); added `gender: string | null` and `authProvider: "password" | "google"`; added `profileComplete: boolean`.
- **`POST /auth/register`:** `course`/`yearLevel` are now optional in the request — `authValidators.js`'s `registerSchema`. `authController.js`'s `register()` sets `profileComplete` based on whether they were actually sent.
- **New: `PATCH /auth/me`** (`demographicsSchema` in `authValidators.js`, `updateDemographics()` in `authController.js`, routed in `authRoutes.js`) — the demographic-profiling step. `course` is now a real `BSIT`/`BSBA` enum instead of the old free-text field, since it's the variable the rest of the app is meant to branch career categories/question banks/AI prompts on. Works even when no `users/{uid}` doc exists yet: it backfills `fullName`/`email` from the verified Firebase Auth record via `auth.getUser(req.uid)` — this is what makes it work for Google accounts, which never go through `/auth/register` at all.
- **New screen: `demographic_profile_screen.dart`** — Program, Year level, Gender (optional) dropdowns. Shown after signup (both paths) and calls `PATCH /auth/me`.
- **`signup_screen.dart`:** removed the Course text field and Year level dropdown entirely (this also removes one of the two places the v1.5 dropdown-transparency bug could have recurred). `_handleSignUp` now routes to `DemographicProfileScreen` instead of `MainNavigation` directly.
- **`login_screen.dart`:** added `_routeAfterSignIn()`, called after both email/password and Google sign-in — calls `GET /auth/me` and routes to `DemographicProfileScreen` if `profileComplete` is false or the doc doesn't exist (`USER_NOT_FOUND`), otherwise `MainNavigation`. If the backend can't be reached, it lets the user into the app anyway rather than blocking sign-in on this check — they'll be asked again next time it succeeds.
- **`auth_api_service.dart`:** `register()`'s `course`/`yearLevel` params are now optional; added `me()` and `updateDemographics()`.
- Updated `docs/api/api-contract.md` (Auth section) and `docs/database/firestore-schema-design.md` (`users/{uid}`) to match.
  **Reason:** RJ asked for two things together: make Google Sign-In actually usable end-to-end, and add demographic profiling (name/gender/course) after signup, referencing the earlier BSIT/BSBA planning discussion. Those turned out to be the same fix — Google's missing-Firestore-doc problem and "where does course/yearLevel get collected" are both solved by one shared post-signup step rather than two separate patches.
  **Author:** AI-assisted (Claude), at RJ's request — flagging for a team member to review and re-attribute per your usual process before this is treated as final.
  **Related ADR:** —
  **Related code version:** `backend/src/{validators/authValidators,controllers/authController,routes/authRoutes}.js`, `mobile/lib/screens/{signup,login,demographic_profile}_screen.dart`, `mobile/lib/services/auth_api_service.dart`, `docs/api/api-contract.md`, `docs/database/firestore-schema-design.md`
