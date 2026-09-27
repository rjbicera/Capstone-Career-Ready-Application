const { db } = require("../config/firebaseAdmin");
const {
  createGeminiLiveSession,
  getPreviousAttemptSummaries,
} = require("../services/geminiLiveService");

const MAX_DAILY_ATTEMPTS = parseInt(process.env.MAX_DAILY_INTERVIEWS || "50", 10);
const TIME_ZONE = process.env.INTERVIEW_TIME_ZONE || "Asia/Manila";
const MAX_QUESTIONS = 8;

// Helper: get current date in configured timezone
function getTodayString() {
  const now = new Date();
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  return formatter.format(now); // YYYY-MM-DD
}

// Helper: get user's latest completed resume analysis
async function getLatestResumeAnalysis(uid) {
  const resumesRef = db.collection("users").doc(uid).collection("resumes");
  const snapshot = await resumesRef
    .where("analysisStatus", "==", "completed")
    .orderBy("analysisAt", "desc")
    .limit(1)
    .get();

  if (snapshot.empty) return null;

  const doc = snapshot.docs[0];
  return { resumeId: doc.id, ...doc.data() };
}

// GET /api/v1/interview/status
async function getStatus(req, res) {
  try {
    const uid = req.uid;
    const today = getTodayString();

    // Get daily counter
    const dailyRef = db
      .collection("users")
      .doc(uid)
      .collection("mockInterviewDaily")
      .doc(today);
    const dailyDoc = await dailyRef.get();

    const attemptsUsed = dailyDoc.exists ? (dailyDoc.data().count || 0) : 0;
    const attemptsRemaining = Math.max(0, MAX_DAILY_ATTEMPTS - attemptsUsed);

    // Check readiness: resume analysis + career goal
    const [resumeAnalysis, userDoc] = await Promise.all([
      getLatestResumeAnalysis(uid),
      db.collection("users").doc(uid).get(),
    ]);

    const userData = userDoc.data() || {};
    const hasCareerGoal = !!userData.careerGoal;
    const hasResume = !!resumeAnalysis;
    const ready = hasCareerGoal && hasResume && attemptsRemaining > 0;

    return res.status(200).json({
      attemptsUsed,
      attemptsRemaining,
      maxAttempts: MAX_DAILY_ATTEMPTS,
      ready,
      missingRequirements: {
        careerGoal: !hasCareerGoal,
        resumeAnalysis: !hasResume,
        dailyLimitReached: attemptsRemaining === 0,
      },
    });
  } catch (err) {
    console.error("Interview status error:", err.message);
    return res.status(500).json({
      error: { code: "STATUS_FAILED", message: "Unable to get interview status." },
    });
  }
}

// POST /api/v1/interview/start
async function startInterview(req, res) {
  try {
    const uid = req.uid;
    const today = getTodayString();

    // Check readiness
    const [resumeAnalysis, userDoc] = await Promise.all([
      getLatestResumeAnalysis(uid),
      db.collection("users").doc(uid).get(),
    ]);

    if (!resumeAnalysis) {
      return res.status(400).json({
        error: { code: "RESUME_REQUIRED", message: "Complete a resume analysis first." },
      });
    }

    const userData = userDoc.data() || {};
    if (!userData.careerGoal) {
      return res.status(400).json({
        error: { code: "CAREER_GOAL_REQUIRED", message: "Set a career goal in your profile first." },
      });
    }

    // Transactional daily limit check + increment
    const dailyRef = db
      .collection("users")
      .doc(uid)
      .collection("mockInterviewDaily")
      .doc(today);

    let attemptNumber = 0;
    await db.runTransaction(async (transaction) => {
      const dailyDoc = await transaction.get(dailyRef);
      const currentCount = dailyDoc.exists ? (dailyDoc.data().count || 0) : 0;

      if (currentCount >= MAX_DAILY_ATTEMPTS) {
        throw new Error("DAILY_LIMIT_REACHED");
      }

      attemptNumber = currentCount + 1;
      transaction.set(dailyRef, { count: attemptNumber, updatedAt: new Date() }, { merge: true });
    });

    // Create interview session
    const sessionRef = db
      .collection("users")
      .doc(uid)
      .collection("mockInterviews")
      .doc();

    const sessionId = sessionRef.id;

    const sessionData = {
      sessionId,
      uid,
      status: "in_progress",
      attemptNumber,
      careerGoal: userData.careerGoal,
      course: userData.course,
      yearLevel: userData.yearLevel,
      resumeId: resumeAnalysis.resumeId,
      resumeScore: resumeAnalysis.analysis?.overallScore,
      resumeSummary: resumeAnalysis.analysis?.summary,
      resumeSkills: resumeAnalysis.analysis?.skills || [],
      resumeStrengths: resumeAnalysis.analysis?.strengths || [],
      resumeWeaknesses: resumeAnalysis.analysis?.weaknesses || [],
      resumeMissingSkills: resumeAnalysis.analysis?.missingSkills || [],
      startedAt: new Date(),
      completedAt: null,
      overallScore: null,
      summary: null,
      questionCount: 0,
    };

    await sessionRef.set(sessionData);

    // Get previous attempt summaries for question variation
    const previousAttemptSummaries = await getPreviousAttemptSummaries(uid, db, attemptNumber);

    // Create Gemini Live session
    const interviewContext = {
      careerGoal: userData.careerGoal,
      course: userData.course,
      yearLevel: userData.yearLevel,
      attemptNumber,
      resume: {
        summary: resumeAnalysis.analysis?.summary,
        skills: resumeAnalysis.analysis?.skills,
        strengths: resumeAnalysis.analysis?.strengths,
        weaknesses: resumeAnalysis.analysis?.weaknesses,
        missingSkills: resumeAnalysis.analysis?.missingSkills,
      },
      previousAttemptSummaries,
    };

    const geminiSession = await createGeminiLiveSession(interviewContext);

    // Store session reference for later use (in production, you'd use a session manager)
    // For now, we return session info and the client will connect via WebSocket
    return res.status(201).json({
      sessionId,
      attemptNumber,
      maxQuestions: MAX_QUESTIONS,
      message: "Interview session created. Connect to Gemini Live via WebSocket.",
    });
  } catch (err) {
    console.error("Start interview error:", err.message);
    if (err.message === "DAILY_LIMIT_REACHED") {
      return res.status(429).json({
        error: { code: "DAILY_LIMIT_REACHED", message: "Daily interview limit reached. Try again tomorrow." },
      });
    }
    return res.status(500).json({
      error: { code: "START_FAILED", message: "Unable to start interview." },
    });
  }
}

// POST /api/v1/interview/:sessionId/complete
async function completeInterview(req, res) {
  try {
    const uid = req.uid;
    const { sessionId } = req.params;
    const { overallScore, summary } = req.body;

    if (typeof overallScore !== "number" || overallScore < 0 || overallScore > 100) {
      return res.status(400).json({
        error: { code: "INVALID_SCORE", message: "overallScore must be a number 0-100." },
      });
    }

    const sessionRef = db
      .collection("users")
      .doc(uid)
      .collection("mockInterviews")
      .doc(sessionId);

    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      return res.status(404).json({
        error: { code: "SESSION_NOT_FOUND", message: "Interview session not found." },
      });
    }

    const sessionData = sessionDoc.data();
    if (sessionData.status === "completed") {
      return res.status(409).json({
        error: { code: "ALREADY_COMPLETED", message: "Session already completed." },
      });
    }

    await sessionRef.update({
      status: "completed",
      overallScore,
      summary: summary || "",
      completedAt: new Date(),
      questionCount: MAX_QUESTIONS,
    });

    return res.status(200).json({
      sessionId,
      overallScore,
      summary,
      completedAt: new Date().toISOString(),
    });
  } catch (err) {
    console.error("Complete interview error:", err.message);
    return res.status(500).json({
      error: { code: "COMPLETE_FAILED", message: "Unable to complete interview." },
    });
  }
}

// GET /api/v1/interview/sessions (history)
async function getSessions(req, res) {
  try {
    const uid = req.uid;
    const snapshot = await db
      .collection("users")
      .doc(uid)
      .collection("mockInterviews")
      .orderBy("startedAt", "desc")
      .limit(20)
      .get();

    const sessions = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        sessionId: data.sessionId,
        attemptNumber: data.attemptNumber,
        status: data.status,
        overallScore: data.overallScore,
        startedAt: data.startedAt?.toDate?.()?.toISOString?.() || data.startedAt,
        completedAt: data.completedAt?.toDate?.()?.toISOString?.() || data.completedAt,
        questionCount: data.questionCount,
      };
    });

    return res.status(200).json({ sessions });
  } catch (err) {
    console.error("Get sessions error:", err.message);
    return res.status(500).json({
      error: { code: "SESSIONS_FAILED", message: "Unable to fetch interview sessions." },
    });
  }
}

module.exports = {
  getStatus,
  startInterview,
  completeInterview,
  getSessions,
  MAX_DAILY_ATTEMPTS,
  TIME_ZONE,
};