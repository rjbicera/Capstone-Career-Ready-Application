# Capstone Career-Ready Application

AI-Powered Career Preparation Application for Graduating College Students — a capstone project by [team member names].

Flutter mobile app · Node.js/Express.js REST API · Firebase (Auth, Firestore, Storage) · Gemini/OpenAI API

## Repository structure

```
mobile/     — Flutter application
backend/    — Node.js/Express.js REST API
docs/       — SDD, architecture decisions, API contract, weekly reports
firebase/   — Firestore rules, indexes, Storage rules
```

## Current status

**Frontend (`mobile/`):** All core screens are implemented and navigable end-to-end —
Splash → Onboarding (3 slides) → Login/Sign Up/Forgot Password → bottom-nav shell
(Home, Resume Analyzer, AI Mock Interview, Profile) → Edit Profile, Saved Resumes,
Notifications, Settings. Skills Assessment includes a working quiz flow (per-category
question bank → score → updates that skill's progress bar). Resume upload uses a real
device file picker (`file_picker`). A shared `AppState` (in-memory `ChangeNotifier`)
feeds the Home dashboard's composite readiness score from resume/interview/skills
activity, so it's no longer a hardcoded number.

Firebase Authentication is wired for real (project: `capstone-career-ready-app`,
connected via FlutterFire CLI) — sign in, sign up, password reset, and sign out all
call `firebase_auth` directly from the client.

**⚠️ Known gap:** `docs/api/api-contract.md` specifies `POST /auth/register` as creating
both the Firebase Auth user _and_ a Firestore `users` doc server-side. The current
client-side registration only creates the Auth user — see
`docs/CHANGELOG-SDD.md` [SDD v1.3] for the full note and options going forward.

**Backend (`backend/`):** Scaffolded with Firebase Admin config (`firebaseAdmin.js`)
and auth middleware (`authMiddleware.js`) only. None of the feature routes documented
in `docs/api/api-contract.md` (`/auth/*`, `/resume`, `/interview`, `/assessments`,
`/profile`) are implemented yet — this is the next major chunk of work.

AI Career Recommendations (SDD §8.1) is documented but not yet built on either side.

## Documentation index

- Software Design Document: `docs/SDD_AI_Career_Prep_App.pdf`
- SDD changelog (decisions over time): `docs/CHANGELOG-SDD.md`
- Architecture decisions: `docs/architecture/decisions/`
- API contract: `docs/api/api-contract.md`
- Firestore schema: `docs/database/firestore-schema-design.md`
- Weekly development reports: `docs/weekly-reports/`

## Local development setup

See `docs/Developer-Setup-Guide.pdf` for full environment setup instructions (accounts, SDKs, Firebase project, running the emulator suite).

For the Flutter app specifically: after `flutter pub get`, you'll need your own
`google-services.json` (Android) from the `capstone-career-ready-app` Firebase project
— ask a teammate with console access to add you as a project member if you don't have
one yet.
