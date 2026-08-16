# ADR-001: Profile document ID equals Firebase UID
**Status:** Accepted
**Date:** 2026-08-03

**Context:** The SDD's ER model gives `profiles` its own primary key plus a `uid` foreign key, for a relationship that is strictly 1:1 with `users`.

**Decision:** Use `uid` directly as the `profiles` document ID instead of a separate `profileId`.

**Consequences:** Direct `.doc(uid).get()` lookup — no query or index required. Structurally impossible to create duplicate profiles for one user. Deviates from the SDD's literal ER diagram; logged as SDD v1.1-track change in `docs/CHANGELOG-SDD.md` if/when the diagram itself is redrawn.
