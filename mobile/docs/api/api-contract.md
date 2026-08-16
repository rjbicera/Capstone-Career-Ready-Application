# API Contract — v1.1
Base path: `/api/v1`. All responses JSON. All protected routes require `Authorization: Bearer <firebase_id_token>`.
Error shape (all endpoints): `{ "error": { "code": "STRING_CODE", "message": "human readable" } }`

**SDD gap fix (logged as SDD v1.1, see docs/CHANGELOG-SDD.md):** added the Profile endpoint group, missing from SDD §9 despite being required by §5.2.

---

## Auth
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/auth/register` | No | Creates Firebase Auth user + `users` doc |
| POST | `/auth/login` | No | Verifies credential, confirms session |
| POST | `/auth/google` | No | Google Sign-In credential exchange |
| POST | `/auth/reset-password` | No | Sends reset email |
| GET | `/auth/me` | Yes | Returns current `users` doc |

**POST /auth/register**
```json
// Request
{ "email": "string", "password": "string", "fullName": "string", "course": "string", "yearLevel": "string" }
// Response 201
{ "uid": "string", "email": "string", "fullName": "string", "role": "student" }
// Errors: 400 EMAIL_IN_USE, 400 WEAK_PASSWORD, 400 VALIDATION_ERROR
```

**GET /auth/me**
```json
// Response 200
{ "uid": "string", "fullName": "string", "email": "string", "role": "student|admin", "course": "string", "yearLevel": "string", "createdAt": "ISO8601" }
```

---

## Profile  *(new group — see gap note above)*
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/profile` | Yes | Own profile only |
| PUT | `/profile` | Yes | Full or partial update |
| POST | `/profile/photo` | Yes | multipart/form-data, replaces `photoUrl` |

**GET /profile**
```json
// Response 200 (matches profiles/{uid} schema)
{ "uid": "string", "bio": "string", "skills": ["string"], "certifications": ["string"], "careerGoal": "string", "photoUrl": "string|null", "updatedAt": "ISO8601" }
// 404 PROFILE_NOT_FOUND if onboarding not completed yet
```

**PUT /profile**
```json
// Request (any subset of fields)
{ "bio": "string", "skills": ["string"], "certifications": ["string"], "careerGoal": "string" }
// Response 200: updated profile object
// Errors: 400 VALIDATION_ERROR
```

**POST /profile/photo**
```
// Request: multipart/form-data, field name "photo", max 2MB, image/jpeg|png only
// Response 200: { "photoUrl": "string" }
// Errors: 400 FILE_TOO_LARGE, 400 INVALID_FILE_TYPE
```

---

## Resume Analyzer
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/resumes/upload` | Yes | multipart, creates `resumes` doc, status=`uploaded` |
| POST | `/resumes/:resumeId/analyze` | Yes | Triggers AI pipeline (see ai-prompt-architecture.md §1) |
| GET | `/resumes` | Yes | List own resumes, newest first |
| GET | `/resumes/:resumeId/feedback` | Yes | Returns `resume_feedback` doc |
| DELETE | `/resumes/:resumeId` | Yes | Deletes resume + associated feedback |

**POST /resumes/upload**
```
// Request: multipart/form-data, field "file" (PDF/DOCX, max 5MB), field "targetRole" (optional string)
// Response 201
{ "resumeId": "string", "fileName": "string", "status": "uploaded", "uploadedAt": "ISO8601" }
// Errors: 400 FILE_TOO_LARGE, 400 INVALID_FILE_TYPE, 400 MISSING_FILE
```

**POST /resumes/:resumeId/analyze**
```json
// Request: {} (targetRole already stored from upload; optionally override)
// Response 200 (matches resume_feedback schema + resumes.atsScore)
{
  "atsScore": 82,
  "subScores": { "contentQuality": 30, "structureFormatting": 20, "atsKeywordMatch": 20, "completeness": 12 },
  "strengths": ["string"], "weaknesses": ["string"], "suggestions": ["string"]
}
// Errors: 404 RESUME_NOT_FOUND, 409 ALREADY_ANALYZING, 502 AI_PROVIDER_ERROR (after retry exhausted)
```

**GET /resumes**
```json
// Response 200
{ "resumes": [ { "resumeId": "string", "fileName": "string", "status": "string", "atsScore": "number|null", "uploadedAt": "ISO8601" } ] }
```

---

## AI Mock Interview
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/interview/start` | Yes | Creates `interview_sessions` doc, returns first question |
| POST | `/interview/:sessionId/answer` | Yes | Scores answer, returns next question or "complete" signal |
| POST | `/interview/:sessionId/complete` | Yes | Finalizes session, computes overallScore in backend code |
| GET | `/interview/sessions` | Yes | List own sessions, newest first |
| GET | `/interview/:sessionId` | Yes | Full session detail incl. all questions/answers |

**POST /interview/start**
```json
// Request: { "jobRole": "string" }
// Response 201
{ "sessionId": "string", "firstQuestion": { "questionId": "string", "questionText": "string", "questionType": "behavioral|technical|situational" } }
```

**POST /interview/:sessionId/answer**
```json
// Request: { "questionId": "string", "answerText": "string" }
// Response 200
{
  "evaluation": { "score": 7, "subScores": { "relevance": 3, "clarity": 2, "completeness": 2 }, "feedback": "string" },
  "nextQuestion": { "questionId": "string", "questionText": "string" } ,
  // OR, if session reached question limit (e.g. 8 questions):
  "sessionComplete": true
}
// Errors: 400 EMPTY_ANSWER, 404 SESSION_NOT_FOUND, 409 SESSION_ALREADY_COMPLETED
```

**POST /interview/:sessionId/complete**
```json
// Response 200
{ "sessionId": "string", "overallScore": 78, "questionCount": 8, "completedAt": "ISO8601" }
```

---

## Skills Assessment
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/assessments` | Yes | List active assessments (title, category only — no questions) |
| GET | `/assessments/:assessmentId/questions` | Yes | Returns questions **without** `correctAnswerIndex` |
| POST | `/assessments/:assessmentId/submit` | Yes | Scores server-side, stores `assessment_results`, triggers AI explanations for wrong answers |
| GET | `/assessments/results` | Yes | List own results, newest first |

**GET /assessments/:assessmentId/questions**
```json
// Response 200 — correctAnswerIndex deliberately omitted (security: see firestore.rules rationale)
{ "questions": [ { "questionId": "string", "questionText": "string", "options": ["string"] } ] }
```

**POST /assessments/:assessmentId/submit**
```json
// Request
{ "answers": [ { "questionId": "string", "selectedIndex": 0 } ] }
// Response 200
{
  "score": 16, "totalItems": 20,
  "categoryBreakdown": { "networking": 8, "programming": 8 },
  "results": [ { "questionId": "string", "correct": true, "correctAnswerIndex": 1, "explanation": "string|null (only present if wrong)" } ]
}
// Errors: 400 INCOMPLETE_SUBMISSION (answer count != question count)
```

---

## Career Readiness Dashboard
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/dashboard/readiness` | Yes | Latest `readiness_scores` doc (by updatedAt desc) |
| GET | `/dashboard/recommendations` | Yes | Latest `career_recommendations` doc |
| POST | `/dashboard/recommendations/refresh` | Yes | Regenerates via AI, rate-limited (see below) |
| GET | `/dashboard/trends` | Yes | Time series of `readiness_scores`, last N entries |

**GET /dashboard/readiness**
```json
// Response 200
{ "resumeScore": 82, "interviewScore": 78, "skillsScore": 74, "overallReadiness": 78, "updatedAt": "ISO8601" }
// overallReadiness = round(resumeScore*0.30 + interviewScore*0.35 + skillsScore*0.35)
```

**POST /dashboard/recommendations/refresh**
```
// Response 200: same shape as GET /dashboard/recommendations
// Errors: 429 RATE_LIMITED — cap at e.g. 1 refresh per 10 minutes per user (AI cost control)
```

**GET /dashboard/trends**
```json
// Query param: ?limit=10 (default)
// Response 200
{ "history": [ { "overallReadiness": 78, "updatedAt": "ISO8601" } ] }
```

---

## Cross-cutting rules for every module owner
1. Every handler validates the request body against a schema (express-validator or zod) **before** touching Firestore or calling AI — reject bad input at the edge.
2. Every handler that reads/writes a user-scoped doc filters by the token's `uid`, never a client-supplied `uid` field — this is the #1 way capstone APIs leak other users' data.
3. AI-invoking endpoints (`resumes/:id/analyze`, `interview/:id/answer`, `assessments/:id/submit`, `dashboard/recommendations/refresh`) go through `aiClient.callAI()` with schema validation — no raw AI output touches Firestore.
4. 401 for missing/invalid token, 403 for valid token but wrong role/ownership, 404 for valid access but resource doesn't exist — don't blur these three.
