const { auth, db } = require("../config/firebaseAdmin");

const {
  registerSchema,
  demographicsSchema,
  profileUpdateSchema,
} = require("../validators/authValidators");

// Shape returned to the client for /auth/me, PATCH /auth/me, and
// PATCH /auth/me/profile — kept in one place so those endpoints
// never drift out of sync with each other.
function serializeUser(data) {
  return {
    uid: data.uid,

    fullName: data.fullName,
    nickname: data.nickname ?? null,
    email: data.email,
    photoUrl: data.photoUrl ?? null,
    role: data.role,

    course: data.course ?? null,
    yearLevel: data.yearLevel ?? null,
    gender: data.gender ?? null,
    careerGoal: data.careerGoal ?? null,

    profileComplete: data.profileComplete === true,

    createdAt: data.createdAt?.toDate?.().toISOString() ?? null,
    updatedAt: data.updatedAt?.toDate?.().toISOString() ?? null,
  };
}

// ------------------------------------------------------------
// POST /api/v1/auth/register
// Email/password registration
// ------------------------------------------------------------

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

  const { email, password, fullName } = parsed.data;

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
        error: {
          code: "EMAIL_IN_USE",
          message: "An account with this email already exists.",
        },
      });
    }

    if (
      err.code === "auth/invalid-password" ||
      err.code === "auth/password-does-not-meet-requirements"
    ) {
      return res.status(400).json({
        error: {
          code: "WEAK_PASSWORD",
          message: "Choose a stronger password.",
        },
      });
    }

    throw err;
  }

  const now = new Date();

  const userDoc = {
    uid: userRecord.uid,
    fullName,
    nickname: null,
    email,
    photoUrl: null,

    role: "student",

    course: null,
    yearLevel: null,
    gender: null,
    careerGoal: null,

    profileComplete: false,

    createdAt: now,
    updatedAt: now,
  };

  try {
    await db.collection("users").doc(userRecord.uid).set(userDoc);
  } catch (err) {
    await auth.deleteUser(userRecord.uid).catch(() => {
      console.error(`Could not clean up Firebase Auth user: ${userRecord.uid}`);
    });

    throw err;
  }

  return res.status(201).json({
    uid: userRecord.uid,
    email,
    fullName,
    role: "student",
    profileComplete: false,
  });
}

// ------------------------------------------------------------
// GET /api/v1/auth/me
//
// This also handles NEW Google users.
//
// Firebase creates the Google Auth account first.
// If users/{uid} doesn't exist, create it here.
// ------------------------------------------------------------

async function me(req, res) {
  const userRef = db.collection("users").doc(req.uid);

  let doc = await userRef.get();

  if (!doc.exists) {
    const firebaseUser = await auth.getUser(req.uid);

    const now = new Date();

    const newProfile = {
      uid: firebaseUser.uid,

      fullName:
        firebaseUser.displayName ||
        firebaseUser.email?.split("@")[0] ||
        "Student",
      nickname: null,

      email: firebaseUser.email || null,
      photoUrl: firebaseUser.photoURL || null,

      role: "student",

      course: null,
      yearLevel: null,
      gender: null,
      careerGoal: null,

      profileComplete: false,

      createdAt: now,
      updatedAt: now,
    };

    await userRef.set(newProfile);

    doc = await userRef.get();
  } else {
    // Safety net for email changes made directly through Firebase Auth
    // (e.g. the mobile app's "Edit profile" email flow, which uses
    // verifyBeforeUpdateEmail — the address only becomes the user's
    // real Auth email once they click the verification link, at some
    // point AFTER the client-side call returns). Rather than trust a
    // client-supplied email on a generic partial-update endpoint, we
    // just compare against the Auth record here on every /me fetch and
    // quietly re-sync Firestore's cached copy when they've drifted.
    const data = doc.data();
    const firebaseUser = await auth.getUser(req.uid);

    if (firebaseUser.email && firebaseUser.email !== data.email) {
      await userRef.update({
        email: firebaseUser.email,
        updatedAt: new Date(),
      });
      doc = await userRef.get();
    }
  }

  return res.status(200).json(serializeUser(doc.data()));
}

// ------------------------------------------------------------
// PATCH /api/v1/auth/me
//
// Saves demographic profile (one-time onboarding step).
// ------------------------------------------------------------

async function updateDemographics(req, res) {
  const parsed = demographicsSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: {
        code: "VALIDATION_ERROR",
        message:
          parsed.error.issues[0]?.message || "Invalid demographic information.",
      },
    });
  }

  const { course, yearLevel, gender, nickname } = parsed.data;

  const userRef = db.collection("users").doc(req.uid);

  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return res.status(404).json({
      error: {
        code: "USER_NOT_FOUND",
        message: "No profile found for this account.",
      },
    });
  }

  await userRef.update({
    course,
    yearLevel,

    gender: gender !== undefined ? gender : null,
    nickname: nickname !== undefined ? nickname : null,

    profileComplete: true,

    updatedAt: new Date(),
  });

  const updatedDoc = await userRef.get();

  return res.status(200).json(serializeUser(updatedDoc.data()));
}

// ------------------------------------------------------------
// PATCH /api/v1/auth/me/profile
//
// General "Edit profile" updates, made any time after onboarding.
// Unlike updateDemographics, every field is optional — only the
// fields the caller actually sends get written. (Email is
// deliberately NOT accepted here — see the sync note in `me()`.)
// ------------------------------------------------------------

async function updateProfile(req, res) {
  const parsed = profileUpdateSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: {
        code: "VALIDATION_ERROR",
        message: parsed.error.issues[0]?.message || "Invalid profile update.",
      },
    });
  }

  const updates = parsed.data;

  // "" is the client's way of saying "remove my photo" — store it as
  // null so serializeUser reports no photo rather than an empty string.
  if (updates.photoUrl === "") {
    updates.photoUrl = null;
  }

  if (Object.keys(updates).length === 0) {
    return res.status(400).json({
      error: {
        code: "VALIDATION_ERROR",
        message: "Provide at least one field to update.",
      },
    });
  }

  const userRef = db.collection("users").doc(req.uid);

  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return res.status(404).json({
      error: {
        code: "USER_NOT_FOUND",
        message: "No profile found for this account.",
      },
    });
  }

  await userRef.update({
    ...updates,
    updatedAt: new Date(),
  });

  const updatedDoc = await userRef.get();

  return res.status(200).json(serializeUser(updatedDoc.data()));
}

// ------------------------------------------------------------
// GET /api/v1/auth/me/export
//
// "Export my data" (Settings). Returns everything the backend holds
// on this user as a single JSON payload the client can share/save.
// Resume/interview/skills activity isn't included because it isn't
// backend-persisted yet (see the functionality checklist) — flagged
// explicitly in the payload rather than silently omitted.
// ------------------------------------------------------------

async function exportData(req, res) {
  const userRef = db.collection("users").doc(req.uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    return res.status(404).json({
      error: {
        code: "USER_NOT_FOUND",
        message: "No profile found for this account.",
      },
    });
  }

  return res.status(200).json({
    exportedAt: new Date().toISOString(),
    profile: serializeUser(userDoc.data()),
    note:
      "Resume analysis, mock interview, and skills assessment activity are " +
      "not yet stored on the server, so they are not included in this export.",
  });
}

// ------------------------------------------------------------
// DELETE /api/v1/auth/me
//
// Permanently deletes the user's Firestore profile AND their
// Firebase Auth account. The client should already have made the
// user reauthenticate (see reauth_helper.dart) before calling this —
// Firebase Auth itself also enforces a recent-login requirement for
// sensitive account changes, but the reauth step gives a clearer
// in-app error message than a raw Firebase exception would.
// ------------------------------------------------------------

async function deleteAccount(req, res) {
  const userRef = db.collection("users").doc(req.uid);

  await userRef.delete().catch((err) => {
    // If the Firestore doc is already gone, that's fine — keep going
    // and still remove the Auth account. Anything else, surface it.
    if (err.code !== 5 /* NOT_FOUND */) {
      throw err;
    }
  });

  try {
    await auth.deleteUser(req.uid);
  } catch (err) {
    if (err.code !== "auth/user-not-found") {
      throw err;
    }
  }

  return res.status(200).json({ deleted: true });
}

module.exports = {
  register,
  me,
  updateDemographics,
  updateProfile,
  exportData,
  deleteAccount,
};
