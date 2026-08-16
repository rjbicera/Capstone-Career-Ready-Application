# Documentation, Versioning & Collaboration Plan

## 1. Two version tracks — don't conflate them

| Track | Bumps when | Lives in |
|---|---|---|
| **SDD document version** (1.0, 1.1, 1.2...) | A requirement, module design, DB schema, security policy, or API contract changes | `SDD_AI_Career_Prep_App.pdf/docx` revision history table (already exists — continue it) |
| **Code/build version** (v0.1.0 → v1.0.0) | A weekly implementation checkpoint completes (per Master Prompt §10) | Git tags + `docs/weekly-reports/` |

**Rule:** document the decision before or at the same time as the code that implements it — never after. If you catch yourselves coding something not yet in the SDD, stop, write the ADR/changelog entry, then continue.

## 2. SDD Changelog entry format

Add a `docs/CHANGELOG-SDD.md` (separate from the code `CHANGELOG.md` the Master Prompt already sets up). Every entry:

```markdown
## [SDD v1.1] - 2026-08-10
**Objective:** Why this change was needed
**Changed:** Which SDD section(s) — e.g. "§6.3.2 profiles schema, §10.3 Firestore rules"
**Reason:** What problem it solves or what triggered it
**Author:** name
**Related ADR:** ADR-003 (if applicable)
**Related code version:** v0.2.0 (if the code catches up in the same cycle)
```

## 3. Architecture Decision Records (ADRs)

`docs/architecture/decisions/ADR-XXX-short-title.md`, numbered sequentially, never edited after acceptance — supersede with a new ADR instead.

```markdown
# ADR-001: Profile document ID equals Firebase UID
**Status:** Accepted
**Date:** 2026-08-03
**Context:** SDD's ER model gives `profiles` its own PK plus a `uid` FK for a
strictly 1:1 relationship, requiring a query to fetch a profile.
**Decision:** Use `uid` directly as the `profiles` document ID.
**Consequences:** Direct `.doc(uid).get()` lookup, no index needed, structurally
impossible to create duplicate profiles for one user. Deviates from the SDD's
literal ER diagram — SDD updated to v1.1 to reflect this.
```

Seed these four now, from decisions already made this session:
- `ADR-001` — profile doc ID = uid
- `ADR-002` — readiness_scores as history collection, not single current value
- `ADR-003` — Firestore rules deny direct reads too, not just writes
- `ADR-004` — admin functionality lives inside the Flutter app (role-gated), not a separate web panel

## 4. Updated docs/ structure
```
docs/
├── architecture/
│   └── decisions/           # ADR-001, ADR-002, ...
├── api/                      # API contract, versioned alongside SDD changes
├── database/                 # firestore-schema-design.md lives here
├── weekly-reports/           # per Master Prompt §13, one per code version
├── CHANGELOG-SDD.md          # document-level changelog (new)
└── development-tools.md
```

---

## 5. Team collaboration plan (3 members)

### Module ownership — full-stack per module, not split by layer
Splitting "one person does all Flutter, one does all backend" creates constant handoff waiting (backend person blocks frontend person every single feature). Instead, each person owns a module **end-to-end** — Flutter screens + backend routes/services for it. This also matters for individual grading: each member needs demonstrable full-stack contribution, not just "I did the buttons."

| Member | Owns | Rationale |
|---|---|---|
| **A** | Authentication, User Profile, Career Readiness Dashboard | These are the "glue" modules — Dashboard consumes every other module's output, so whoever owns it needs visibility into all of them anyway. Natural fit with owning Auth (first thing built, foundation for everything). |
| **B** | Resume Analyzer, Skills Assessment | Both are upload/question-bank-heavy CRUD with one AI call each — similar shape, similar skills reused. |
| **C** | AI Mock Interview, AI Career Recommendations, `aiClient` abstraction | Groups the two most AI-interaction-heavy modules with the shared AI integration layer they'll be building on anyway. |

**Shared, not owned by one person:** Firestore schema/rules, CI config, `docs/`. Anyone touching these opens a PR; the other two review — no unilateral changes to shared foundations.

**Week 0 exception:** all three work on foundation together before splitting — repo scaffold, Firebase project, `aiClient` skeleton (needed by B and C before Week 2-3), Firestore rules deploy. Don't split module ownership until the foundation is shared and stable.

### Working agreement
- **Branch:** `feature/<module-name>` off `develop`, per module owner. Never commit directly to `main` or `develop`.
- **PR review:** required before merging into `develop` — reviewer must be a *different* module owner, not the author. Keep it to a 5-10 min skim: does it match the documented API contract/schema, any obvious security gap, does it follow the AI validation pattern.
- **Commit convention:** Conventional Commits (`feat(resume): ...`), already covered.
- **Sync point:** align your team meeting with the Master Prompt's STOP/CONTINUE checkpoints — you're already pausing there to review a completed version, so that's the natural moment for a live sync instead of a separate meeting.
- **Async standup:** short daily post (Discord/Slack/whatever) — what merged, what's blocked, what's next. Doesn't need to be a call.

### The Claude Code constraint (one month, shared)
Decide now, not later: is the Claude Code subscription **one seat used by whoever's "driving" that day**, or **one account all three share sequentially**? Either works, but affects workflow:
- **One consistent driver:** faster (no context-switching cost), but the other two are reviewing PRs/designing without hands-on execution — less individual "I built this" evidence for grading.
- **Rotating driver** (e.g., swap every few completed version checkpoints): every member gets real execution experience, at the cost of ramp-up time each swap since Claude Code needs to re-orient in the repo each session anyway (it's not literally continuous memory between sessions either — same constraint I have here, it re-reads git state each time you resume).

My recommendation for a capstone specifically: **rotate by module, not by day** — whoever owns Resume Analyzer drives Claude Code for their Week 2 stretch, then hands off. Keeps ownership and execution paired, which is cleaner for defense Q&A ("who built this, walk me through it").
