# Career Ready

Career Ready is a student-focused career preparation application built around resume improvement, mock interview practice, skills assessment, profile management, and a career-readiness dashboard.

The repository currently contains a **Flutter mobile application** backed by a **Node.js/Express REST API** and **Firebase Authentication, Firestore, and Cloud Storage**. AI-powered resume analysis is implemented through the **Google Gemini API**.

> **Repository status:** The mobile UI and core authentication/profile flows are substantially implemented. The backend currently implements authentication/profile APIs, admin authorization testing, and AI resume analysis. Several features described in the project API contract—such as persistent mock-interview sessions, server-side skills assessments, and career recommendations—remain planned/incomplete.

---

## Features

### Implemented

- Splash screen and onboarding flow
- Email/password registration and login
- Google Sign-In
- Forgot-password flow
- Firebase Authentication
- Firebase ID-token authentication for protected backend endpoints
- Firebase App Check integration
- Student demographic/profile onboarding
- Profile editing
  - Full name
  - Nickname
  - Course
  - Year level
  - Gender
  - Career goal
  - Profile photo
- Change email flow with Firebase verification
- Change password flow
- Biometric-login setting support
- Light/dark theme support
- Notifications/preferences UI
- Settings and legal-document screens
- Account deletion
- User data export
- Course-aware skills assessment UI
  - BSIT skill categories
  - BSBA skill categories
  - Quiz flow
  - Progress updates
- Mock interview question flow
  - Course-aware question bank
  - Progress through interview questions
  - Local completion tracking
- Home dashboard with an in-memory readiness calculation
- Resume PDF selection and upload
- AI resume analysis using Gemini
- Resume analysis results including:
  - Overall score
  - Content score
  - Layout score
  - ATS score
  - Summary
  - Strengths
  - Weaknesses
  - Skills
  - Missing skills
  - Actionable feedback
- Saved-resume UI
- Admin role authorization test endpoint

### Partially implemented / local-only

The following currently work primarily as client-side experiences rather than complete backend-backed modules:

- Mock interview results/history are not persisted by the backend.
- Skills assessment results are held in the Flutter `AppState` during the session.
- The Home readiness score is calculated locally from resume, skills, and interview activity.
- Saved resume UI exists, but the backend does not currently expose a complete resume listing/deletion API.
- Notifications are currently a settings/UI feature rather than a complete server notification system.

### Planned / not yet implemented

The API contract and project documentation describe additional modules that are not currently mounted or implemented in the backend:

- Persistent mock-interview sessions and answer evaluation
- Server-side skills assessment/question retrieval/submission
- Career-readiness history/trends API
- AI career recommendations
- Complete dashboard API
- Full resume management API (list/detail/delete)
- Full profile API under `/profile` as described by the older API contract

For the authoritative planned API design, see [`docs/api/api-contract.md`](docs/api/api-contract.md).

---

## Technology Stack

### Mobile

- **Flutter / Dart**
- Firebase Core
- Firebase Authentication
- Firebase Storage
- Firebase App Check
- Google Sign-In
- `file_picker`
- `image_picker`
- `local_auth`
- `shared_preferences`
- `share_plus`
- `http`
- `flutter_svg`

### Backend

- **Node.js**
- **Express.js**
- Firebase Admin SDK
- Firestore
- Firebase Authentication
- Firebase Storage
- Google Generative AI SDK
- OpenAI SDK dependency for future/alternative AI integration
- Multer
- Zod
- Express Validator
- Helmet
- CORS
- Morgan
- Express Rate Limit
- Jest / Supertest
- Nodemon

### Infrastructure / Security

- Firebase project: `capstone-career-ready-app`
- Firestore region: `asia-southeast1`
- Firebase Authentication
- Firebase App Check
- Firestore deny-by-default client rules
- Per-user Cloud Storage rules for profile photos
- HTTP security headers through Helmet
- CORS allow-list support
- Global and authentication-specific rate limiting
- Request body size limits
- Server-side Firebase ID-token verification
- Server-side role checks
- Zod validation for authentication/profile payloads

---

## Architecture

```text
┌───────────────────────────────┐
│       Flutter Mobile App      │
│                               │
│  Screens / Widgets / AppState │
│              │                │
│       Firebase Auth           │
│       Google Sign-In          │
│       Firebase Storage        │
│              │                │
│       HTTP REST requests      │
└──────────────┬────────────────┘
               │
               │ Firebase ID Token
               │ X-Firebase-AppCheck
               ▼
┌───────────────────────────────┐
│       Node.js / Express API   │
│                               │
│  Helmet / CORS / Rate Limits  │
│  App Check Middleware         │
│  Auth Middleware              │
│  Role Authorization           │
│  Zod Validation               │
│              │                │
│       Controllers / Routes    │
└──────────────┬────────────────┘
               │
       ┌───────┴─────────┐
       ▼                 ▼
┌──────────────┐  ┌───────────────┐
│   Firebase   │  │ Gemini AI API │
│ Auth/Firestore│  │ Resume        │
│ /Storage     │  │ Analysis      │
└──────────────┘  └───────────────┘
```

### Important data-flow detail

Firestore is intentionally **not directly readable or writable from the client**. The production Firestore rules deny all client access:

```text
allow read, write: if false;
```

User-scoped Firestore operations are therefore performed by the backend after verifying the Firebase ID token and deriving the UID from the verified token.

Profile photos are the exception: the mobile app uploads them directly to Firebase Storage, where rules restrict each user to their own `<uid>.jpg` file.

---

## Repository Structure

```text
.
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   └── firebaseAdmin.js
│   │   ├── controllers/
│   │   │   ├── authController.js
│   │   │   └── resumeController.js
│   │   ├── middleware/
│   │   │   ├── appCheckMiddleware.js
│   │   │   └── authMiddleware.js
│   │   ├── routes/
│   │   │   ├── adminRoutes.js
│   │   │   ├── authRoutes.js
│   │   │   └── resumeRoutes.js
│   │   └── validators/
│   │       └── authValidators.js
│   ├── tests/
│   ├── .env.example
│   ├── package.json
│   └── server.js
│
├── mobile/
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── state/
│   │   ├── theme/
│   │   ├── widgets/
│   │   ├── firebase_options.dart
│   │   └── main.dart
│   ├── assets/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── windows/
│   ├── macos/
│   ├── linux/
│   ├── pubspec.yaml
│   └── test/
│
├── firebase/
│   ├── firestore.rules
│   ├── firestore.indexes.json
│   └── storage.rules
│
├── docs/
│   ├── api/
│   ├── architecture/
│   ├── database/
│   ├── weekly-reports/
│   ├── SDD_AI_Career_Prep_App.pdf
│   └── Developer-Setup-Guide.pdf
│
├── firebase.json
└── README.md
```

---

# Getting Started

## Prerequisites

Install the following before running the project:

- Flutter SDK compatible with the Dart SDK declared in `mobile/pubspec.yaml`
- Dart SDK
- Node.js
- npm
- A Firebase project with access to the project's Firebase resources
- Android Studio and/or an Android emulator for Android development
- Xcode for iOS/macOS development
- Git

For the complete environment setup, also review:

- [`docs/Developer-Setup-Guide.pdf`](docs/Developer-Setup-Guide.pdf)
- [`docs/ADR-005-credential-loading.md`](docs/ADR-005-credential-loading.md)

---

## 1. Clone the repository

```bash
git clone <repository-url>
cd Capstone-Career-Ready-Application-main
```

---

## 2. Set up the Flutter mobile application

```bash
cd mobile
flutter pub get
```

Check the Flutter installation:

```bash
flutter doctor
```

Run the application:

```bash
flutter run
```

### Firebase configuration

The Flutter project is configured for the Firebase project:

```text
capstone-career-ready-app
```

The repository contains FlutterFire-generated configuration in:

```text
mobile/lib/firebase_options.dart
```

Android also expects the Firebase Android configuration at:

```text
mobile/android/app/google-services.json
```

If the file is not present in your local checkout, obtain the correct file from the Firebase project rather than creating a different Firebase project configuration.

---

## 3. Start the backend

From the repository root:

```bash
cd backend
npm install
```

Create a local environment file:

```bash
cp .env.example .env
```

On Windows PowerShell, you can instead copy the file manually:

```powershell
Copy-Item .env.example .env
```

Then fill in the required values.

Start the development server:

```bash
npm run dev
```

Or run it normally:

```bash
npm start
```

The default server port is:

```text
4000
```

Health check:

```text
GET /api/v1/health
```

Expected response:

```json
{
  "status": "ok"
}
```

---

# Backend Environment Variables

The backend provides the following `.env.example`:

```env
PORT=4000
NODE_ENV=development
ALLOWED_ORIGIN=http://localhost:3000

AI_PROVIDER=gemini
OPENAI_API_KEY=
GEMINI_API_KEY=

FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
FIREBASE_STORAGE_BUCKET=
```

The backend may also use:

```env
REQUIRE_APP_CHECK=false
GEMINI_MODEL=gemini-3.8-flash
```

### Required for the current AI resume analyzer

At minimum, the backend needs:

```env
GEMINI_API_KEY=your_gemini_api_key
```

The resume analyzer currently uses Gemini through `@google/generative-ai`.

### Firebase Admin credentials

The backend uses Firebase Admin credentials to access Firebase services securely from the server.

Do **not** commit service-account private keys or other server credentials to Git.

If `FIREBASE_PRIVATE_KEY` is stored in an environment variable, ensure newline escaping is handled according to the credential-loading implementation in the repository.

---

# Running the Flutter App With the Backend

The current mobile API service uses:

```text
http://10.0.2.2:4000/api/v1
```

`10.0.2.2` is the Android Emulator's special address for reaching the host computer's `localhost`.

### Android Emulator

Run the backend on the host computer:

```bash
cd backend
npm run dev
```

Then run the Flutter app on an Android emulator:

```bash
cd mobile
flutter run
```

### Physical Android device

`10.0.2.2` normally will not point to the development computer from a physical device.

Use the development computer's LAN IP instead, for example:

```text
http://192.168.1.100:4000/api/v1
```

Make sure:

- The phone and computer are on the same network.
- The backend is listening on an accessible interface.
- The firewall allows the backend port.
- The backend's `ALLOWED_ORIGIN` is configured appropriately for browser-based clients if needed.

### iOS Simulator

The API base URL may need to use the host machine's loopback address rather than Android's `10.0.2.2`.

---

# Authentication

Firebase Authentication is used for:

- Email/password authentication
- Google Sign-In
- Password reset
- Password changes
- Email verification/update flow
- Account deletion

The Flutter app obtains a Firebase ID token after authentication and sends it to protected backend endpoints as:

```http
Authorization: Bearer <firebase_id_token>
```

The backend verifies that token with Firebase Admin SDK.

The backend never trusts a client-supplied UID for authorization. The UID is taken from the verified Firebase token:

```text
req.uid = decodedToken.uid
```

---

# Firebase App Check

The application includes Firebase App Check.

The Flutter application currently activates:

```text
AndroidProvider.debug
```

This is appropriate for local development but should not be treated as the production App Check configuration.

The backend supports an optional strict mode:

```env
REQUIRE_APP_CHECK=true
```

When strict mode is enabled, requests without a valid `X-Firebase-AppCheck` token are rejected.

Before production deployment, configure an appropriate production App Check provider and verify the release application registration.

---

# API

Base path:

```text
/api/v1
```

All protected routes require a Firebase ID token.

## Currently implemented endpoints

### Health

```http
GET /api/v1/health
```

### Authentication and profile

```http
POST   /api/v1/auth/register
GET    /api/v1/auth/me
PATCH  /api/v1/auth/me
PATCH  /api/v1/auth/me/profile
GET    /api/v1/auth/me/export
DELETE /api/v1/auth/me
```

The registration endpoint creates:

1. A Firebase Authentication user
2. A corresponding Firestore `users/{uid}` document

Google users can have their Firestore profile created automatically when `/auth/me` is first requested.

### Admin authorization test

```http
GET /api/v1/admin/access-test
```

Requires an authenticated Firebase user whose Firestore profile has:

```json
{
  "role": "admin"
}
```

### Resume analysis

```http
POST /api/v1/resumes/analyze
```

Requirements:

- Firebase authentication
- Student role
- Firebase App Check when strict mode is enabled
- One PDF file
- Maximum PDF size: **10 MB**

The file is temporarily written to the server's temporary directory, analyzed by Gemini, and then removed.

The backend stores the analysis metadata/result under the authenticated user's Firestore area.

---

# Resume Analysis

The current resume pipeline is:

```text
Flutter
   │
   │ PDF upload
   ▼
Express API
   │
   ├── Firebase ID token verification
   ├── Student role verification
   ├── Rate limiting
   ├── MIME/type validation
   ├── 10 MB size limit
   ├── PDF signature validation
   │
   ▼
Temporary server file
   │
   ▼
Gemini multimodal analysis
   │
   ▼
Normalized JSON result
   │
   ▼
Firestore
   │
   ▼
Flutter result screen
```

The AI prompt explicitly treats the uploaded resume as **untrusted user content** and instructs the model not to follow instructions embedded in the PDF.

The analyzer normalizes and bounds AI output before it is returned/stored.

### Resume analysis rate limit

The current endpoint allows up to:

```text
5 analyses per hour per authenticated user
```

A global API limiter also applies.

---

# Security

The repository includes several security controls.

## Backend

- Helmet security headers
- CORS allow-list
- Global API rate limiting
- Authentication-specific rate limiting
- Resume-analysis rate limiting
- JSON body size limit
- Firebase ID-token verification
- Server-side role authorization
- Zod request validation
- Firebase App Check support
- Centralized error handling
- No internal stack traces returned to clients
- UID derived from the verified token
- Temporary resume cleanup after processing
- PDF MIME and file-signature validation

## Firestore

Client access is intentionally denied:

```text
allow read, write: if false;
```

This forces application data access through the backend.

This also prevents clients from directly reading sensitive assessment data such as correct answer indexes.

## Cloud Storage

Profile photos are restricted by:

- Authenticated user requirement
- UID-based filename
- Image content type
- 5 MB maximum size
- Per-user delete permission

---

# Important Security / Deployment Notes

Before production deployment, review these items carefully:

1. Replace Firebase App Check's Android debug provider with the appropriate production provider.
2. Enable strict backend App Check enforcement with:
   ```env
   REQUIRE_APP_CHECK=true
   ```
3. Set a production `ALLOWED_ORIGIN` instead of relying on development behavior.
4. Keep Firebase Admin credentials and AI API keys outside the repository.
5. Use HTTPS for production API traffic.
6. Review Firebase Authentication provider settings and authorized domains.
7. Review Firebase Storage rules before exposing profile images publicly.
8. Keep Firestore rules deny-by-default unless a deliberate client-access requirement is introduced.
9. Configure appropriate server logging/monitoring without logging tokens, passwords, API keys, or sensitive user content.
10. Review the AI provider's data-handling and retention policies before using the application with real user resumes.

---

# Data Model

The currently implemented backend uses the `users` collection:

```text
users/{uid}
```

A user profile contains fields such as:

```text
uid
fullName
nickname
email
photoUrl
role
course
yearLevel
gender
careerGoal
profileComplete
createdAt
updatedAt
```

Resume analysis metadata/results are stored beneath the authenticated user:

```text
users/{uid}/resumes/{resumeId}
```

The repository also contains Firestore indexes for planned collections including:

```text
resumes
interview_sessions
assessment_results
readiness_scores
career_recommendations
```

Those indexes reflect the broader application design; the corresponding feature APIs are not all implemented yet.

See:

- [`firebase/firestore.indexes.json`](firebase/firestore.indexes.json)
- [`docs/database/firestore-schema-design.md`](docs/database/firestore-schema-design.md)

---

# Development Commands

## Flutter

```bash
cd mobile

flutter pub get
flutter doctor
flutter run
```

Run Flutter tests:

```bash
flutter test
```

Analyze the project:

```bash
flutter analyze
```

Build Android:

```bash
flutter build apk
```

---

## Backend

```bash
cd backend

npm install
npm run dev
npm start
```

Run tests:

```bash
npm test
```

Run linting:

```bash
npm run lint
```

---

# Testing Status

The repository currently contains:

- A Flutter widget smoke test verifying that the application boots.
- Backend test infrastructure using Jest and Supertest.

Testing coverage is still limited relative to the size of the application.

Recommended future tests include:

- Authentication controller tests
- Profile validation tests
- Authorization/RBAC tests
- Resume upload validation tests
- Resume analysis error-path tests
- Rate-limit tests
- App Check tests
- Firestore integration tests
- Widget tests for onboarding/login/profile flows
- Skills quiz tests
- End-to-end authentication and resume-analysis tests

---

# Documentation

Additional project documentation is available in `docs/`.

### Core documents

- [`docs/SDD_AI_Career_Prep_App.pdf`](docs/SDD_AI_Career_Prep_App.pdf) — Software Design Document
- [`docs/Developer-Setup-Guide.pdf`](docs/Developer-Setup-Guide.pdf) — development environment/setup guide
- [`docs/CHANGELOG-SDD.md`](docs/CHANGELOG-SDD.md) — SDD decisions and changes
- [`docs/api/api-contract.md`](docs/api/api-contract.md) — intended REST API contract
- [`docs/database/firestore-schema-design.md`](docs/database/firestore-schema-design.md) — Firestore design
- [`docs/architecture/ai-prompt-architecture.md`](docs/architecture/ai-prompt-architecture.md) — AI prompt architecture
- [`docs/architecture/project-baseline-assessment.md`](docs/architecture/project-baseline-assessment.md) — project baseline assessment
- [`docs/incident-log.md`](docs/incident-log.md) — recorded incidents and fixes
- [`docs/weekly-reports/`](docs/weekly-reports/) — development reports

---

# Current Implementation vs. API Contract

It is important to distinguish the **implemented repository** from the broader API contract.

| Module | Current repository | API contract |
|---|---|---|
| Firebase Authentication | Implemented | Planned/implemented design |
| User profile | Implemented through `/auth/me*` | Also describes `/profile` endpoints |
| Google Sign-In | Implemented in Flutter | Described in contract |
| Resume AI analysis | Implemented | Broader resume CRUD contract is planned |
| Mock interview UI | Implemented locally | Persistent backend module planned |
| Skills quiz UI | Implemented locally | Server-side assessment module planned |
| Readiness score | Local Flutter calculation | Backend dashboard API planned |
| Career recommendations | Not implemented | Planned |
| Admin authorization | Access-test implemented | Broader admin module planned |
| Firestore security | Implemented | Designed around backend-only access |

This distinction helps prevent documentation from claiming backend functionality that is only present in the design documents.

---

# Known Limitations

- Resume analysis currently accepts PDF files only.
- Resume analysis requires a configured Gemini API key.
- Mock interview recording is currently represented by a local UI state; there is no complete audio recording/transcription/evaluation backend.
- Interview completion counts are currently held in memory.
- Skills progress is currently held in memory and is reset when the application state is cleared.
- The readiness score is currently calculated locally using placeholder weights:
  - Resume: 40%
  - Skills: 40%
  - Interview activity: 20%
- The readiness formula is explicitly marked in code as a placeholder pending final alignment with the SDD.
- Resume PDF files are not retained permanently by the current analyzer; only analysis metadata/results are persisted.
- The current mobile API base URL is development-oriented (`10.0.2.2:4000`).
- Production App Check configuration is still required.
- Automated test coverage is limited.
- Several documented API modules are still unimplemented.

---

# Recommended Development Order

A practical sequence for completing the remaining backend functionality is:

1. Persist mock-interview sessions and results.
2. Implement the skills-assessment API with server-side scoring.
3. Implement resume listing/history and deletion.
4. Move readiness scoring from local Flutter state to the backend.
5. Implement readiness history/trends.
6. Implement AI career recommendations.
7. Connect the mobile dashboard to the backend readiness APIs.
8. Expand automated tests around authentication, authorization, AI input validation, and data ownership.
9. Complete production App Check configuration and deployment hardening.

---

# License

No project-specific open-source license is currently declared in the repository.

If this project is intended to be distributed publicly, add an appropriate `LICENSE` file and update this section.
