const { auth, db } = require("../config/firebaseAdmin");

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({
      error: {
        code: "MISSING_TOKEN",
        message: "Authorization header required.",
      },
    });
  }

  const idToken = header.substring("Bearer ".length).trim();

  if (!idToken) {
    return res.status(401).json({
      error: {
        code: "MISSING_TOKEN",
        message: "Authorization token is required.",
      },
    });
  }

  try {
    const decodedToken = await auth.verifyIdToken(idToken);

    // Never trust a UID supplied by the client.
    req.uid = decodedToken.uid;
    req.firebaseUser = decodedToken;

    return next();
  } catch (err) {
    console.error("Authentication verification failed:", err.message);

    return res.status(401).json({
      error: {
        code: "INVALID_TOKEN",
        message: "Token verification failed.",
      },
    });
  }
}

/**
 * Restrict an endpoint to one or more roles.
 *
 * Usage:
 * router.get("/admin-only", authMiddleware, requireRole("admin"), handler);
 */
function requireRole(...allowedRoles) {
  return async (req, res, next) => {
    if (!req.uid) {
      return res.status(401).json({
        error: {
          code: "UNAUTHENTICATED",
          message: "Authentication required.",
        },
      });
    }

    try {
      const userDoc = await db.collection("users").doc(req.uid).get();

      if (!userDoc.exists) {
        return res.status(403).json({
          error: {
            code: "FORBIDDEN",
            message: "User profile not found.",
          },
        });
      }

      const userData = userDoc.data();
      const role = userData?.role;

      if (!allowedRoles.includes(role)) {
        return res.status(403).json({
          error: {
            code: "FORBIDDEN",
            message: "You do not have permission to perform this action.",
          },
        });
      }

      // Make the server-side role available to downstream handlers.
      req.userRole = role;
      req.userProfile = userData;

      return next();
    } catch (err) {
      console.error("Authorization lookup failed:", err.message);

      return res.status(500).json({
        error: {
          code: "AUTHORIZATION_ERROR",
          message: "Unable to verify permissions.",
        },
      });
    }
  };
}

const requireAdmin = requireRole("admin");
const requireStudent = requireRole("student");

module.exports = {
  authMiddleware,
  requireRole,
  requireAdmin,
  requireStudent,
};
