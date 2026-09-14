const express = require("express");

const { authMiddleware } = require("../middleware/authMiddleware");

const {
  register,
  me,
  updateDemographics,
  updateProfile,
} = require("../controllers/authController");

const router = express.Router();

// Email/password registration
router.post("/register", register);

// Get current Firebase user profile
router.get("/me", authMiddleware, me);

// Save demographic profile (one-time onboarding step)
router.patch("/me", authMiddleware, updateDemographics);

// General "Edit profile" updates (name, nickname, career goal, etc.)
router.patch("/me/profile", authMiddleware, updateProfile);

module.exports = router;
