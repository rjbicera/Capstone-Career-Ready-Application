const express = require("express");

const { authMiddleware } = require("../middleware/authMiddleware");

const {
  register,
  me,
  updateDemographics,
  updateProfile,
  exportData,
  deleteAccount,
} = require("../controllers/authController");

const router = express.Router();

// Email/password registration
router.post("/register", register);

// Get current Firebase user profile
router.get("/me", authMiddleware, me);

// Save demographic profile (one-time onboarding step)
router.patch("/me", authMiddleware, updateDemographics);

// General "Edit profile" updates (name, nickname, career goal, photo, etc.)
router.patch("/me/profile", authMiddleware, updateProfile);

// Download a copy of everything the backend holds on this user
router.get("/me/export", authMiddleware, exportData);

// Permanently delete the account (Firestore doc + Firebase Auth user)
router.delete("/me", authMiddleware, deleteAccount);

module.exports = router;
