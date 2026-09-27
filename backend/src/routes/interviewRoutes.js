const express = require("express");

const { authMiddleware, requireStudent } = require("../middleware/authMiddleware");
const {
  getStatus,
  startInterview,
  completeInterview,
  getSessions,
} = require("../controllers/interviewController");

const router = express.Router();

// All interview routes require auth + student role
router.use(authMiddleware, requireStudent);

// GET /api/v1/interview/status - Check readiness + daily attempts
router.get("/status", getStatus);

// POST /api/v1/interview/start - Create new interview session
router.post("/start", startInterview);

// POST /api/v1/interview/:sessionId/complete - Finalize interview with score
router.post("/:sessionId/complete", completeInterview);

// GET /api/v1/interview/sessions - List past sessions
router.get("/sessions", getSessions);

module.exports = router;