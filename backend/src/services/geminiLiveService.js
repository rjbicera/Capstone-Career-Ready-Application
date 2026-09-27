const { GoogleGenAI, Modality } = require("@google/genai");

const LIVE_MODEL = process.env.GEMINI_LIVE_MODEL || "gemini-3.8-live";

async function createGeminiLiveSession(interviewContext) {
  if (!process.env.GEMINI_API_KEY) {
    throw new Error("GEMINI_API_KEY is not configured.");
  }

  const ai = new GoogleGenAI({
    apiKey: process.env.GEMINI_API_KEY,
  });

  const { careerGoal, course, yearLevel, attemptNumber, resume } =
    interviewContext;

  const resumeSummary = resume?.summary || "No resume summary available.";

  const skills = Array.isArray(resume?.skills)
    ? resume.skills.join(", ")
    : "No skills available.";

  const strengths = Array.isArray(resume?.strengths)
    ? resume.strengths.join(", ")
    : "No strengths available.";

  const weaknesses = Array.isArray(resume?.weaknesses)
    ? resume.weaknesses.join(", ")
    : "No weaknesses available.";

  const missingSkills = Array.isArray(resume?.missingSkills)
    ? resume.missingSkills.join(", ")
    : "No missing skills information available.";

  const systemInstruction = `
You are a professional corporate interviewer conducting a realistic
mock job interview.

CANDIDATE INFORMATION
---------------------
Intended career/job:
${careerGoal || "Not specified"}

Course:
${course || "Not specified"}

Year level:
${yearLevel || "Not specified"}

Interview attempt:
${attemptNumber || 1}

RESUME INFORMATION
------------------
Resume summary:
${resumeSummary}

Skills:
${skills}

Strengths:
${strengths}

Areas that may need improvement:
${weaknesses}

Potential missing skills:
${missingSkills}

INTERVIEW RULES
---------------
1. Conduct the interview like a real corporate interview.
2. Ask only ONE question at a time.
3. Wait for the candidate's answer before continuing.
4. Ask relevant follow-up questions when appropriate.
5. Do not repeatedly ask the same question.
6. Make questions different across interview attempts.
7. Use the candidate's career goal and resume to personalize questions.
8. Include a realistic mixture of:
   - behavioral questions
   - situational questions
   - technical/work-related questions
   - teamwork questions
   - problem-solving questions
   - workplace communication questions
9. Questions should be appropriate for the candidate's course and year level.
10. Do not assume the candidate has professional experience they do not have.
11. If the candidate is a student, allow academic projects, internships,
    coursework, and personal projects to be used as experience.
12. Do not reveal the scoring criteria during the interview.
13. Do not give a final score during the interview.
14. Keep the interview focused and professional.
15. Ask a maximum of 8 substantive interview questions.
16. The interview should feel like an actual interview, not a questionnaire.
17. Attempt ${attemptNumber || 1} should use a different set of questions
    from previous attempts whenever possible.

OPENING
-------
Start by briefly introducing yourself as the interviewer and then ask
the candidate the first interview question.

Do not ask multiple questions in your opening.
`;

  const session = await ai.live.connect({
    model: LIVE_MODEL,

    config: {
      responseModalities: [Modality.AUDIO],
      systemInstruction,
    },

    callbacks: {
      onopen() {
        console.log("Gemini Live interview connection opened.");
      },

      onmessage(message) {
        // Audio/text streaming will be handled by the caller.
      },

      onerror(error) {
        console.error("Gemini Live interview error:", error);
      },

      onclose(event) {
        console.log(
          "Gemini Live interview connection closed.",
          event?.code ?? "",
        );
      },
    },
  });

  return session;
}

module.exports = {
  createGeminiLiveSession,
};
