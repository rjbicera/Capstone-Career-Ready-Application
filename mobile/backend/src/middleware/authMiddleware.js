const { auth } = require("../config/firebaseAdmin");

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    return res.status(401).json({ error: { code: "MISSING_TOKEN", message: "Authorization header required" } });
  }

  const idToken = header.split("Bearer ")[1];
  try {
    const decoded = await auth.verifyIdToken(idToken);
    req.uid = decoded.uid; // always use req.uid downstream — never a client-sent uid field
    next();
  } catch (err) {
    return res.status(401).json({ error: { code: "INVALID_TOKEN", message: "Token verification failed" } });
  }
}

// Use AFTER authMiddleware on admin-only routes. Re-checks role from Firestore,
// never trusts a role claim the client might send in the request body.
async function requireAdmin(req, res, next) {
  const { db } = require("../config/firebaseAdmin");
  const userDoc = await db.collection("users").doc(req.uid).get();
  if (!userDoc.exists || userDoc.data().role !== "admin") {
    return res.status(403).json({ error: { code: "FORBIDDEN", message: "Admin access required" } });
  }
  next();
}

module.exports = { authMiddleware, requireAdmin };
