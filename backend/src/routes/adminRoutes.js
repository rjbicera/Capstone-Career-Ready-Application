const express = require("express");

const {
  authMiddleware,
  requireAdmin,
} = require("../middleware/authMiddleware");

const router = express.Router();

/**
 * Protected admin access test.
 *
 * This endpoint intentionally returns only a simple confirmation.
 * It exists so we can verify that server-side RBAC is working before
 * the rest of the admin API is implemented.
 */
router.get("/access-test", authMiddleware, requireAdmin, (req, res) => {
  return res.status(200).json({
    status: "ok",
    role: "admin",
    message: "Admin authorization verified.",
  });
});

module.exports = router;
