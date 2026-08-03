# ADR-002: readiness_scores is a history collection, not a single current-value document
**Status:** Accepted
**Date:** 2026-08-03

**Context:** SDD §6.3.10 describes `readiness_scores` as one entity per student, but SDD §9.5 requires `GET /dashboard/trends`, which needs historical data over time. These two requirements can't both be satisfied by a single document per user.

**Decision:** Write a new `readiness_scores` document every time the composite score is recalculated. "Current" score = most recent by `updatedAt`. Trends = query the last N documents ordered by `updatedAt`.

**Consequences:** Requires a composite index (`uid` ASC, `updatedAt` DESC) — included in `firebase/firestore.indexes.json`. Slightly more storage than a single doc, negligible at capstone scale. Enables the trends endpoint to function at all.
