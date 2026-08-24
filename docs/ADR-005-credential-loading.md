# ADR-005: Local Firebase Admin credential loading strategy
**Status:** Accepted
**Date:** 2026-08-19

**Context:** `firebaseAdmin.js` originally used `admin.credential.cert({...})` with individual `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` / `FIREBASE_PRIVATE_KEY` env vars, per the Developer Setup Guide's original pattern. Two real problems surfaced implementing this:

1. **`admin.credential` was `undefined`** at runtime — the installed `firebase-admin@14.2.0` has moved to a modular API (`firebase-admin/app`, `firebase-admin/auth`, etc.); the older namespace-style compat API (`admin.credential.cert`) is no longer reliable.
2. **`FIREBASE_PRIVATE_KEY` failed to parse** (`OpenSSL DECODER routines::unsupported`) after being manually copy-pasted from the downloaded service account JSON into `.env` on Windows. The multi-line PEM content, once embedded as a `\n`-escaped single-line `.env` value, was corrupted somewhere in the Notepad/clipboard chain — never resolved to a root cause, since a more robust approach existed.

**Decision:**
1. Rewrote `firebaseAdmin.js` to use the current modular API: `initializeApp`/`cert` from `firebase-admin/app`, `getAuth`/`getFirestore`/`getStorage` from their respective modules.
2. Added a `FIREBASE_SERVICE_ACCOUNT_PATH` env var. When set, credentials load directly from the downloaded service account JSON file on disk — no manual key copy-pasting. When unset, falls back to the original three individual env vars (needed for production hosts like Render/Railway, which have no persistent filesystem to hold a JSON key file).

**Consequences:**
- Each teammate's local `.env` needs `FIREBASE_SERVICE_ACCOUNT_PATH` pointing at **their own** downloaded service account key file, kept outside the repo, never committed or shared between teammates.
- Slightly more per-teammate setup than a single shared string template, but eliminates the fragile private-key-escaping failure mode entirely for local development.
- Production credential handling (individual env vars set in the hosting dashboard) is unchanged from the original design — this ADR only affects local dev.
