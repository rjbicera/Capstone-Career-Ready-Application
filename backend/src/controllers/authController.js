const { auth, db } = require("../config/firebaseAdmin");

const {
  registerSchema,
  demographicsSchema,
} = require("../validators/authValidators");

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
    email,

    role: "student",

    course: null,
    yearLevel: null,
    gender: null,

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

      email: firebaseUser.email || null,

      role: "student",

      course: null,
      yearLevel: null,
      gender: null,

      profileComplete: false,

      createdAt: now,
      updatedAt: now,
    };

    await userRef.set(newProfile);

    doc = await userRef.get();
  }

  const data = doc.data();

  return res.status(200).json({
    uid: data.uid,

    fullName: data.fullName,
    email: data.email,
    role: data.role,

    course: data.course ?? null,

    yearLevel: data.yearLevel ?? null,

    gender: data.gender ?? null,

    profileComplete: data.profileComplete === true,

    createdAt: data.createdAt?.toDate?.().toISOString() ?? null,

    updatedAt: data.updatedAt?.toDate?.().toISOString() ?? null,
  });
}

// ------------------------------------------------------------
// PATCH /api/v1/auth/me
//
// Saves demographic profile.
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

  const { course, yearLevel, gender } = parsed.data;

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

    profileComplete: true,

    updatedAt: new Date(),
  });

  const updatedDoc = await userRef.get();

  const data = updatedDoc.data();

  return res.status(200).json({
    uid: data.uid,

    fullName: data.fullName,
    email: data.email,
    role: data.role,

    course: data.course ?? null,

    yearLevel: data.yearLevel ?? null,

    gender: data.gender ?? null,

    profileComplete: data.profileComplete === true,

    createdAt: data.createdAt?.toDate?.().toISOString() ?? null,

    updatedAt: data.updatedAt?.toDate?.().toISOString() ?? null,
  });
}

module.exports = {
  register,
  me,
  updateDemographics,
};
