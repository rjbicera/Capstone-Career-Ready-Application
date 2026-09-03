const { auth, db } = require("../config/firebaseAdmin");
const { registerSchema } = require("../validators/authValidators");

/**
 * POST /api/v1/auth/register
 * Creates the Firebase Auth user AND the corresponding Firestore `users`
 * doc in one request — this is the endpoint documented in
 * docs/api/api-contract.md that the Flutter client was previously
 * bypassing (see docs/CHANGELOG-SDD.md [SDD v1.3] for the gap this closes).
 *
 * Note: this endpoint creates the account but does NOT sign the caller
 * in — Admin SDK user creation never establishes a client session. The
 * Flutter client still needs to call signInWithEmailAndPassword with the
 * same credentials right after a successful response, to get its
 * Firebase ID token for subsequent authenticated requests.
 */
async function register(req, res) {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: {
        code: "VALIDATION_ERROR",
        message: parsed.error.issues[0]?.message || "Invalid request body",
      },
    });
  }

  const { email, password, fullName, course, yearLevel } = parsed.data;

  let userRecord;
  try {
    userRecord = await auth.createUser({
      email,
      password,
      displayName: fullName,
    });
  } catch (err) {
    if (err.code === "auth/email-already-exists") {
      return res.status(400).json({
        error: { code: "EMAIL_IN_USE", message: "An account with this email already exists." },
      });
    }
    if (err.code === "auth/invalid-password") {
      return res.status(400).json({
        error: { code: "WEAK_PASSWORD", message: "Choose a stronger password." },
      });
    }
    // Anything else is unexpected — let the centralized error handler in
    // app.js log it server-side and return a generic 500.
    throw err;
  }

  const now = new Date();
  const userDoc = {
    uid: userRecord.uid,
    fullName,
    email,
    role: "student",
    course,
    yearLevel,
    createdAt: now,
    updatedAt: now,
  };

  try {
    await db.collection("users").doc(userRecord.uid).set(userDoc);
  } catch (err) {
    // Firestore write failed AFTER the Auth user was already created —
    // clean up so we don't leave an orphaned Auth account with no
    // matching profile doc (which would break /auth/me and anything
    // else that assumes every Auth user has a users/{uid} doc).
    await auth.deleteUser(userRecord.uid).catch(() => {
      // If cleanup itself fails, the orphaned account needs manual
      // removal via Firebase console — logged server-side, not exposed.
      console.error(`Orphaned Auth user after failed Firestore write: ${userRecord.uid}`);
    });
    throw err;
  }

  return res.status(201).json({
    uid: userRecord.uid,
    email,
    fullName,
    role: "student",
  });
}

/**
 * GET /api/v1/auth/me
 * Requires authMiddleware — req.uid comes from the verified ID token,
 * never from a client-sent field.
 */
async function me(req, res) {
  const doc = await db.collection("users").doc(req.uid).get();
  if (!doc.exists) {
    return res.status(404).json({
      error: { code: "USER_NOT_FOUND", message: "No profile found for this account." },
    });
  }

  const data = doc.data();
  return res.status(200).json({
    uid: data.uid,
    fullName: data.fullName,
    email: data.email,
    role: data.role,
    course: data.course,
    yearLevel: data.yearLevel,
    createdAt: data.createdAt?.toDate?.().toISOString() ?? null,
  });
}

module.exports = { register, me };
