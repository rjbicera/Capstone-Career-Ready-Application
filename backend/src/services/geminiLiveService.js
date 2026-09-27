const { GoogleGenAI, Modality } = require("@google/genai");

const LIVE_MODEL = process.env.GEMINI_LIVE_MODEL || "gemini-3.8-live";
const MAX_QUESTIONS = 8;

/**
 * Build the system instruction for the Gemini Live interview session.
 * Incorporates user profile + resume analysis + attempt number for variation.
 */
function buildInterviewSystemInstruction(context) {
  const {
    careerGoal,
    course,
    yearLevel,
    attemptNumber,
    resume,
    previousAttemptSummaries = [],
  } = context;

  const resumeSummary = resume?.summary || "No resume summary available.";
  const skills = Array.isArray(resume?.skills) && resume.skills.length > 0
    ? resume.skills.join(", ")
    : "No skills listed.";
  const strengths = Array.isArray(resume?.strengths) && resume.strengths.length > 0
    ? resume.strengths.join(", ")
    : "No notable strengths identified.";
  const weaknesses = Array.isArray(resume?.weaknesses) && resume.weaknesses.length > 0
    ? resume.weaknesses.join(", ")
    : "No notable weaknesses identified.";
  const missingSkills = Array.isArray(resume?.missingSkills) && resume.missingSkills.length > 0
    ? resume.missingSkills.join(", ")
    : "No missing skills identified.";

  const previousAttemptsText = previousAttemptSummaries.length > 0
    ? `\n\nPREVIOUS INTERVIEW ATTEMPTS (for variation & progression):\n${previousAttemptSummaries.map((s, i) => 
        `Attempt ${s.attemptNumber}: Score ${s.overallScore}/100 (${s.questionCount} questions)\nSummary: ${s.summary}`
      ).join("\n\n")}\n\nIMPORTANT: This is attempt ${attemptNumber}. Generate DIFFERENT questions from previous attempts. Build on their progress - if they scored low on behavioral questions before, emphasize those. If they did well technically, go deeper.`
    : "";

  return `
You are a professional corporate interviewer conducting a realistic mock job interview for a student/early-career candidate.

═══════════════════════════════════
CANDIDATE PROFILE
═══════════════════════════════════
Intended career/job: ${careerGoal || "Not specified"}
Course: ${course || "Not specified"}
Year level: ${yearLevel || "Not specified"}
Interview attempt: ${attemptNumber} of max 2 per day

═══════════════════════════════════
RESUME ANALYSIS
═══════════════════════════════════
Summary: ${resumeSummary}
Skills: ${skills}
Strengths: ${strengths}
Areas for improvement: ${weaknesses}
Potential missing skills: ${missingSkills}
${previousAttemptsText}

═══════════════════════════════════
INTERVIEW RULES - FOLLOW STRICTLY
═══════════════════════════════════
1. Conduct this like a REAL corporate interview - conversational, professional, engaging.
2. Ask ONLY ONE question at a time. Wait for the answer before continuing.
3. Ask relevant follow-up questions when appropriate (dig deeper).
4. Do NOT repeat questions. Do NOT ask multiple questions in one turn.
5. Make questions DIFFERENT across attempts (${attemptNumber} of 2 today).
6. Personalize questions using the candidate's career goal, course, and resume.
7. Include a realistic mix of question types:
   - Behavioral ("Tell me about a time...")
   - Situational ("How would you handle...")
   - Technical/role-specific (appropriate for ${course || "their field"})
   - Teamwork/collaboration
   - Problem-solving
   - Communication
8. Questions must match the candidate's level (${yearLevel || "student"}).
9. Do NOT assume professional experience they don't have.
10. Allow academic projects, internships, coursework, personal projects as experience.
11. Do NOT reveal scoring criteria during the interview.
12. Do NOT give a score during the interview.
13. Keep it focused and professional - like a real interview.
14. Ask a maximum of ${MAX_QUESTIONS} substantive questions.
15. The interview should feel like a conversation, not a questionnaire.

═══════════════════════════════════
OPENING
═══════════════════════════════════
Start by briefly introducing yourself as the interviewer (name, role, company context).
Then ask the FIRST interview question only.
Do NOT ask multiple questions in your opening.

═══════════════════════════════════
END OF INTERVIEW TRIGGER
═══════════════════════════════════
When you have asked ${MAX_QUESTIONS} questions and received answers, say exactly:
"INTERVIEW_COMPLETE"
Then provide a final evaluation in this JSON format:
{
  "overallScore": 0-100,
  "summary": "2-3 paragraph evaluation covering strengths, areas for improvement, and specific actionable feedback",
  "questionScores": [
    {"question": "...", "score": 0-10, "feedback": "..."}
  ]
}
`.trim();
}

/**
 * Create a Gemini Live session for mock interview.
 * Returns a wrapper with `send` method compatible with WebSocket proxy.
 */
async function createGeminiLiveSession(interviewContext) {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not configured.");
  }

  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

  const systemInstruction = buildInterviewSystemInstruction(interviewContext);

  const liveSession = await ai.live.connect({
    model: LIVE_MODEL,
    config: {
      responseModalities: [Modality.AUDIO],
      systemInstruction,
    },
    callbacks: {
      onopen() {
        console.log("[Gemini Live] Interview connection opened");
      },
      onmessage(message) {
        // Messages contain audio/text chunks - handled by caller
      },
      onerror(error) {
        console.error("[Gemini Live] Interview error:", error);
      },
      onclose(event) {
        console.log("[Gemini Live] Interview connection closed:", event?.code ?? "");
      },
    },
  });

  // Wrap the session to provide a compatible `send` method
  // The @google/genai Live API uses sendClientContent for sending audio/data
  return {
    send: (data) => {
      // data can be String (JSON) or Buffer/Uint8Array (audio)
      if (typeof data === 'string') {
        // Send text/JSON message
        liveSession.sendClientContent({
          turns: [{ role: 'user', parts: [{ text: data }] }],
          turnComplete: true,
        });
      } else {
        // Send audio data (Buffer/Uint8Array)
        const audioData = data instanceof Buffer ? data : Buffer.from(data);
        liveSession.sendClientContent({
          turns: [{ 
            role: 'user', 
            parts: [{ 
              inlineData: { 
                mimeType: 'audio/pcm', 
                data: audioData.toString('base64') 
              } 
            }] 
          }],
          turnComplete: true,
        });
      }
    },
    close: () => liveSession.close(),
    // Expose the original callbacks
    onmessage: liveSession.onmessage,
    onerror: liveSession.onerror,
    onclose: liveSession.onclose,
    // Allow setting custom callbacks
    set onmessage(handler) { liveSession.onmessage = handler; },
    set onerror(handler) { liveSession.onerror = handler; },
    set onclose(handler) { liveSession.onclose = handler; },
  };
}

/**
 * Get previous attempt summaries with scores for variation.
 */
async function getPreviousAttemptSummaries(uid, db, currentAttempt) {
  if (currentAttempt <= 1) return [];

  try {
    const sessionsRef = db.collection("users").doc(uid).collection("mockInterviews");
    const snapshot = await sessionsRef
      .where("attemptNumber", "<", currentAttempt)
      .where("status", "==", "completed")
      .orderBy("attemptNumber", "desc")
      .limit(2)
      .get();

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        attemptNumber: data.attemptNumber,
        overallScore: data.overallScore,
        summary: data.summary,
        questionCount: data.questionCount,
      };
    }).filter((d) => d.summary);
  } catch (err) {
    console.warn("Could not fetch previous attempt summaries:", err.message);
    return [];
  }
}

/**
 * Generate final evaluation using regular Gemini (not Live) for scoring.
 * Called after the Live session ends.
 */
async function generateFinalEvaluation(interviewContext, conversationHistory) {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not configured.");
  }

  const { GoogleGenerativeAI } = require("@google/generative-ai");
  const client = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = client.getGenerativeModel({
    model: process.env.GEMINI_MODEL || "gemini-3.1-flash-lite",
    generationConfig: { responseMimeType: "application/json" },
  });

  const prompt = `
You are an expert interview evaluator. Analyze this mock interview and provide a score and summary.

CANDIDATE:
- Career Goal: ${interviewContext.careerGoal}
- Course: ${interviewContext.course}
- Year Level: ${interviewContext.yearLevel}
- Attempt: ${interviewContext.attemptNumber}

RESUME CONTEXT:
- Summary: ${interviewContext.resume?.summary || "N/A"}
- Skills: ${Array.isArray(interviewContext.resume?.skills) ? interviewContext.resume.skills.join(", ") : "N/A"}
- Strengths: ${Array.isArray(interviewContext.resume?.strengths) ? interviewContext.resume.strengths.join(", ") : "N/A"}
- Weaknesses: ${Array.isArray(interviewContext.resume?.weaknesses) ? interviewContext.resume.weaknesses.join(", ") : "N/A"}

CONVERSATION HISTORY (interviewer + candidate):
${conversationHistory.map((m) => `${m.role}: ${m.content}`).join("\n\n")}

Return ONLY valid JSON:
{
  "overallScore": 0-100,
  "summary": "2-3 paragraph evaluation: strengths shown, areas for improvement, specific actionable feedback for next interview",
  "questionScores": [
    {"question": "question text", "score": 0-10, "feedback": "specific feedback on this answer"}
  ]
}
`.trim();

  const result = await model.generateContent(prompt);
  const text = result.response.text();

  try {
    return JSON.parse(text);
  } catch (err) {
    console.error("Failed to parse evaluation JSON:", text);
    // Fallback
    return {
      overallScore: 70,
      summary: "Evaluation parsing failed. Please review the interview manually.",
      questionScores: [],
    };
  }
}

module.exports = {
  createGeminiLiveSession,
  buildInterviewSystemInstruction,
  getPreviousAttemptSummaries,
  generateFinalEvaluation,
  MAX_QUESTIONS,
  LIVE_MODEL,
};