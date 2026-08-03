# ADR-004: Admin functionality lives inside the Flutter app, role-gated — no separate web panel
**Status:** Accepted
**Date:** 2026-08-03

**Context:** SDD §1.4 names career services staff/adviser as the admin persona. SDD §11.3 explicitly marks a web admin panel as optional, and §14 defers a full institutional analytics portal to post-capstone. SDD §9.4 requires `POST /api/v1/admin/assessments` as a real, gradable deliverable.

**Decision:** Admin capability (assessment/question-bank management) is built as an extra, role-gated section of the same Flutter app — not a separate frontend, and not managed by hand via the Firebase console.

**Reason:** A second frontend (separate stack, deploy, auth wiring) is unbudgeted scope not accounted for in the 15-week plan. Managing data via the Firebase console bypasses both the backend's validation logic and the security-rules-enforced-at-one-point design (ADR-003), and isn't demonstrable as a graded feature.

**Consequences:** Reuses existing Firebase Auth flow, API client, and widget library — minimal added architecture. Client-side role check (`role == "admin"`) controls what's shown; server-side role verification on every `/api/v1/admin/*` route (re-checked against the ID token, never trusting a client-sent role) is the actual enforcement point.
