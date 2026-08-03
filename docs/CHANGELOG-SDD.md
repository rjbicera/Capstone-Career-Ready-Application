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
