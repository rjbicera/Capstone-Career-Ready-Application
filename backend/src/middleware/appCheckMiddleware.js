const { getAppCheck } = require("firebase-admin/app-check");

/**
 * Firebase App Check middleware.
 *
 * During development:
 * - Missing App Check token is allowed.
 * - Invalid App Check token is rejected.
 *
 * When REQUIRE_APP_CHECK=true:
 * - Missing token is rejected.
 * - Invalid token is rejected.
 */
async function appCheckMiddleware(req, res, next) {
  const appCheckToken = req.get("X-Firebase-AppCheck");

  // Development / rollout mode.
  if (!appCheckToken) {
    if (process.env.REQUIRE_APP_CHECK === "true") {
      return res.status(401).json({
        error: {
          code: "MISSING_APP_CHECK",
          message: "App Check token required.",
        },
      });
    }

    return next();
  }

  try {
    const appCheckClaims = await getAppCheck().verifyToken(appCheckToken);

    req.appCheck = appCheckClaims;

    return next();
  } catch (err) {
    console.error("App Check verification failed:", err.message);

    return res.status(401).json({
      error: {
        code: "INVALID_APP_CHECK",
        message: "App Check verification failed.",
      },
    });
  }
}

module.exports = appCheckMiddleware;
