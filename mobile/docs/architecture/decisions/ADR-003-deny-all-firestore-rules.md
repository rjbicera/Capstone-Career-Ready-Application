# ADR-003: Firestore rules deny direct client reads, not just writes
**Status:** Accepted
**Date:** 2026-08-03

**Context:** SDD §10.3 requires denying direct client writes so all mutations pass through the authenticated Express API. It does not explicitly require denying reads.

**Decision:** Deny direct client reads as well as writes, on every collection, with no exceptions.

**Reason:** `assessment_questions` contains `correctAnswerIndex`. If clients could read Firestore directly, any authenticated user could retrieve exam answers via a raw REST/JS client call, bypassing the app's own question-serving logic entirely. Additionally, every read in this app already requires uid-scoping business logic (e.g. "only return my own resume feedback") that the backend already implements — duplicating that logic in security rules is unnecessary attack surface.

**Consequences:** Every read goes through the Express API — one extra network hop compared to reading Firestore directly from Flutter, in exchange for a single, auditable enforcement point. Given the app already calls the backend for AI-mediated responses on most screens, this costs effectively nothing in practice.
