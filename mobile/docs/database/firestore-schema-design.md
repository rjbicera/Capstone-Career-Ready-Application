# Firestore Schema Design
Refines SDD §6 into field-level, implementable collections. Deviations from the SDD are called out with rationale, per Master Prompt §20 (document ambiguity resolutions, don't silently change scope).

---

## Design decisions that differ from the SDD's raw ER model

**1. `profiles` document ID = `uid`, not a separate `profileId`.**
The SDD gives `profiles` its own PK plus a `uid` FK. Since the relationship is strictly 1:1, using `uid` as the document ID itself means you fetch a profile with `profiles.doc(uid).get()` — no query, no index, no possibility of a user ending up with two profile docs. Same reasoning applies to nothing else in the schema (everything else is genuinely 1-to-many).

**2. `readiness_scores` is a history collection, not a single current-value doc.**
The SDD lists a `GET /dashboard/trends` endpoint requiring historical data, but the entity table implies one row. Resolved by writing a **new document every time the score is recalculated**, and reading "current" as the most recent by `updatedAt`. This is the only way trends can exist.

**3. `assessment_questions` correct answers are never sent to the client directly.**
More on this in the security rules below — it's a common capstone bug (exam answers leak because Firestore rules allow read on the whole assessment doc).

---

## Collections

### `users/{uid}`
```
uid: string          // == Firebase Auth UID, == doc ID
fullName: string
email: string
role: "student" | "admin"
course: string
yearLevel: string
createdAt: timestamp
updatedAt: timestamp
```

### `profiles/{uid}`  (doc ID = uid)
```
uid: string
bio: string
skills: array<string>
certifications: array<string>
careerGoal: string
photoUrl: string | null
updatedAt: timestamp
```

### `resumes/{resumeId}`
```
resumeId: string
uid: string                    // indexed — owner
fileUrl: string                // Cloud Storage path
fileName: string
fileSizeBytes: number
mimeType: "application/pdf" | "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
targetRole: string | null
status: "uploaded" | "analyzing" | "analyzed" | "failed"
atsScore: number | null
uploadedAt: timestamp
analyzedAt: timestamp | null
```
`status` matters: your Activity Diagram (SDD §7.5) shows analysis as an async step after upload. Without a status field, the client has no way to show "analyzing..." vs "failed" vs done.

### `resume_feedback/{feedbackId}`
```
feedbackId: string
resumeId: string      // indexed
uid: string            // indexed, denormalized on purpose — lets you query "all feedback for user X" without a join through resumes
strengths: array<string>
weaknesses: array<string>
suggestions: array<string>
aiProvider: "gemini" | "openai"
aiModel: string         // e.g. "gemini-1.5-flash" — always log which model produced a score, you'll need this if scores look inconsistent later
analyzedAt: timestamp
```

### `interview_sessions/{sessionId}`
```
sessionId: string
uid: string             // indexed
jobRole: string
status: "in_progress" | "completed" | "abandoned"
startedAt: timestamp
completedAt: timestamp | null
overallScore: number | null
questionCount: number
```

### `interview_sessions/{sessionId}/interview_questions/{questionId}`  (subcollection)
```
questionId: string
order: number
questionText: string
answerText: string
score: number
aiFeedback: string
answeredAt: timestamp
```
Subcollection is correct here (per SDD) — questions are always accessed in the context of one session, never queried across sessions.

### `assessments/{assessmentId}`  (admin-managed reference data, shared across all users)
```
assessmentId: string
title: string
category: "technical" | "soft-skill"
totalItems: number
isActive: boolean
createdBy: string        // admin uid
createdAt: timestamp
updatedAt: timestamp
```

### `assessments/{assessmentId}/assessment_questions/{questionId}`  (subcollection)
```
questionId: string
questionText: string
options: array<string>
correctAnswerIndex: number   // NEVER returned to client directly — see security rules
explanation: string
```

### `assessment_results/{resultId}`
```
resultId: string
uid: string             // indexed
assessmentId: string    // indexed
score: number
totalItems: number
categoryBreakdown: map<string, number>
answers: array<{ questionId: string, selectedIndex: number, correct: boolean }>
takenAt: timestamp
```

### `career_recommendations/{recommendationId}`
```
recommendationId: string
uid: string              // indexed
suggestedRoles: array<{ role: string, matchPercentage: number, rationale: string }>
suggestedSkillsToLearn: array<string>
generatedAt: timestamp
```

### `readiness_scores/{scoreId}`  (history, see decision #2 above)
```
scoreId: string
uid: string              // indexed
resumeScore: number
interviewScore: number
skillsScore: number
overallReadiness: number
updatedAt: timestamp
```

---

## Required composite indexes
Single-field indexes are automatic. These queries need explicit composite indexes (define in `firestore.indexes.json`, deploy with `firebase deploy --only firestore:indexes`):

| Collection | Fields |
|---|---|
| `resumes` | `uid` ASC, `uploadedAt` DESC |
| `interview_sessions` | `uid` ASC, `startedAt` DESC |
| `assessment_results` | `uid` ASC, `takenAt` DESC |
| `readiness_scores` | `uid` ASC, `updatedAt` DESC |
| `career_recommendations` | `uid` ASC, `generatedAt` DESC |

Without these, your "history" and "trends" endpoints will throw a `FAILED_PRECONDITION` error the first time you deploy to a real project (the emulator is more lenient and will silently let non-indexed queries through in dev, which is why this bites people specifically at deployment).
