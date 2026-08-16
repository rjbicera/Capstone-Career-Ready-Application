# Project Baseline Assessment
**AI-Powered Career Preparation Application — Capstone**
Derived from: SDD v1.0 (July 2026), Developer Setup Guide, Master Development Prompt

---

## 1. Architecture Summary
Client-server, 4 layers:
- **Presentation** — Flutter mobile app (Android + iOS), talks to backend only via HTTPS REST
- **Application** — Node.js/Express.js REST API (`/api/v1`), holds all business logic
- **Data & Platform** — Firebase Auth, Cloud Firestore, Cloud Storage (managed BaaS)
- **AI Services** — OpenAI or Gemini, accessed **only** server-side via `aiClient.js` abstraction

Both frontend and backend are internally layered (UI/State/Service-Repository/Local-storage on Flutter side; Route-Controller/Middleware/Service/Integration/Data-access on backend side).

## 2. Technology Stack
| Layer | Tech |
|---|---|
| Mobile | Flutter (Dart), Provider or Riverpod, Hive + SharedPreferences |
| Backend | Node.js LTS, Express.js |
| Database | Cloud Firestore (NoSQL) |
| Auth | Firebase Authentication (email/password + Google Sign-In) |
| Storage | Firebase Cloud Storage |
| AI | OpenAI API **or** Gemini API, abstracted behind `aiClient.js` |
| Version control | Git + GitHub |
| API testing | Postman/Insomnia |
| Design | Figma |
| Deployment | Docker → Render/Railway/Cloud Run |

**Decision (Week 0):** start with **Gemini** as primary provider (free tier, no billing friction for a student team); keep OpenAI path stubbed behind the same interface.

## 3. Required Modules
1. Authentication
2. User Profile
3. Resume Analyzer
4. AI Mock Interview
5. Skills Assessment
6. Career Readiness Dashboard
7. AI Career Recommendations

Each is logically independent, communicating only via shared Firestore data or the Dashboard aggregator — no direct module-to-module coupling.

## 4. Database Model (Firestore collections)
`users`, `profiles`, `resumes`, `resume_feedback`, `interview_sessions`, `interview_questions` (sub-collection), `assessments`, `assessment_questions`, `assessment_results`, `career_recommendations`, `readiness_scores`

Relationships are via `uid`/`resumeId`/`sessionId` reference fields, not joins. **Rule:** no new collection without checking whether an existing one already models the data, and documenting why if one is added.

## 5. API Model
Versioned under `/api/v1`, JSON in/out, Firebase ID token via `Authorization: Bearer <token>` on all protected routes, standard HTTP codes, consistent `{ "error": { "code", "message" } }` shape.

Full endpoint list already defined in SDD §9 across Auth, Resumes, Interview, Assessments, Dashboard — use as-is, don't invent new naming conventions.

## 6. Security Requirements
- Firebase Auth only; no custom password handling
- ID token verified server-side on every protected request
- RBAC (student/admin) with explicit role checks on admin routes
- Firestore rules deny direct client read/write on sensitive collections — all writes go through the authenticated API
- AI keys server-side only, never in Flutter or Git
- HTTPS/TLS everywhere, CORS locked to known origins
- Input validation (express-validator), rate limiting on AI-invoking endpoints
- `npm audit`/Dependabot for dependency scanning

## 7. Testing Requirements
Unit (Jest/Flutter test) → Integration (Postman/Supertest) → System → UAT → Performance (JMeter/k6) → Security (OWASP ZAP) → Usability. Acceptance threshold: non-AI responses <3s, AI responses <10s.

## 8. Deployment Requirements
Docker image for backend → Render/Railway/Cloud Run. Three isolated Firebase projects: `-dev`, `-staging`, `-prod`. Flutter release builds point at environment-specific `API_BASE_URL` via `--dart-define`.

## 9. Development Tools Required
Flutter SDK, Dart, Android Studio + SDK + emulator, VS Code, Node LTS, npm, Firebase CLI + Emulator Suite, Git, Postman/Insomnia, Figma, Docker.

**Environment audit note:** these must be verified on your actual machine (`flutter doctor`, `node -v`, `firebase --version`, `docker --version`) — this cannot be done from a web chat session. Do this step in Claude Code or manually, and report results back.

## 10. Recommended Claude Tooling
- **Claude Code** (desktop/terminal/VS Code) — for the actual Week 0–14 build: real repo access, running `flutter`/`npm`/`firebase` commands, git commits/tags per week.
- GitHub integration (if available in your Claude Code environment) — PRs, issue tracking.
- No third-party MCP plugins are required for this stack; avoid adding any that duplicate Claude Code's built-in file/git/bash capabilities.

## 11. Required Accounts
Google (Firebase), GitHub, Google AI Studio (Gemini key) — all free to start. Deferred until later: Apple Developer ($99/yr, iOS distribution only), Google Play Console ($25 one-time, publishing only), Render/Railway (free tier fine for capstone).

## 12. Required Environment Variables
```
AI_PROVIDER=
AI_API_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
FIREBASE_STORAGE_BUCKET=
PORT=
NODE_ENV=
ALLOWED_ORIGIN=
```
Committed only as `.env.example` with blank values. Real values shared privately (password manager), never in Git or chat.

## 13. Repository Structure
```
career-prep-app/
├── mobile/        (Flutter: lib/core, models, services, repositories, providers, features, widgets)
├── backend/       (src/config, middleware, routes, controllers, services, repositories, integrations, models)
├── docs/          (architecture, api, database, weekly-reports, development-tools.md)
├── firebase/      (firestore.rules, firestore.indexes.json, storage.rules)
├── .github/workflows/
├── README.md
├── CHANGELOG.md
└── .gitignore
```
Monorepo — right call for a 3-person team with no separate release cadence between mobile/backend.

## 14. Weekly Roadmap (v0.1.0 → v1.0.0)
| Ver | Week | Scope |
|---|---|---|
| 0.1.0 | 0 | Environment + repo foundation |
| 0.2.0 | 1 | Auth + User Profile |
| 0.3.0 | 2 | Resume Analyzer |
| 0.4.0 | 3 | AI Mock Interview |
| 0.5.0 | 4 | Skills Assessment |
| 0.6.0 | 5 | Career Readiness Dashboard |
| 0.7.0 | 6 | AI Career Recommendations |
| 0.8.0 | 7 | UI/UX refinement + integration |
| 0.8.1 | 8 | Security hardening |
| 0.8.2 | 9 | Performance + full testing |
| 0.9.0 | 10 | UAT |
| 0.9.1 | 11 | Bug fixing/stabilization |
| 0.9.5 | 12 | Deployment prep |
| 1.0.0-rc1 | 13 | Release candidate |
| 1.0.0 | 14 | Final capstone release |

---

## Open Decisions Flagged for the Team (not yet in SDD)
1. **AI output determinism** — how will you defend a resume score that changes on re-analysis? Recommend: low temperature + strict JSON schema + rubric-based prompt, documented in `docs/architecture/ai-scoring-rationale.md`.
2. **Readiness weight justification (30/35/35)** — needs one paragraph of rationale for your defense panel.
3. **CI/CD** — SDD doesn't specify one; `.github/workflows/` is in the proposed structure but needs an actual pipeline (lint + test on PR, minimum) before Week 12.
