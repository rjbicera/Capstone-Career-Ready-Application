const express = require("express");
const { authMiddleware } = require("../middleware/authMiddleware");
const { register, me } = require("../controllers/authController");

const router = express.Router();

// POST /api/v1/auth/register — no auth required, creates the account.
router.post("/register", register);

// GET /api/v1/auth/me — requires a valid Firebase ID token.
router.get("/me", authMiddleware, me);

// NOTE: /auth/login, /auth/google, /auth/reset-password are listed in
// api-contract.md but not implemented here yet — their request/response
// shapes aren't fully specified in the contract (unlike /register and
// /me above), and the Flutter app currently handles sign-in, Google
// auth, and password reset directly via firebase_auth client-side,
// which works today. Left as a deliberate scope boundary for this pass
// rather than guessing at an unspecified contract — see
// docs/CHANGELOG-SDD.md [SDD v1.3] for context.

module.exports = router;
