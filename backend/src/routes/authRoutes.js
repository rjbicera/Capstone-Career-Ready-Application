const express = require("express");

const { authMiddleware } = require("../middleware/authMiddleware");

const {
  register,
  me,
  updateDemographics,
} = require("../controllers/authController");

const router = express.Router();

// Email/password registration
router.post("/register", register);

// Get current Firebase user profile
router.get("/me", authMiddleware, me);

// Save demographic profile
router.patch("/me", authMiddleware, updateDemographics);

module.exports = router;
