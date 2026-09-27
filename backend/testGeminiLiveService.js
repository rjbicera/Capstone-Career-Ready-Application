require("dotenv").config();

const { createGeminiLiveSession } = require("./src/services/geminiLiveService");

async function test() {
  let session;

  try {
    console.log("Creating Gemini Live interview session...");

    session = await createGeminiLiveSession({
      careerGoal: "Software Developer",
      course: "BSIT",
      yearLevel: "3rd Year",
      attemptNumber: 1,

      resume: {
        summary:
          "A BSIT student interested in software development and backend systems.",

        skills: ["JavaScript", "Node.js", "Flutter", "Firebase"],

        strengths: ["Problem solving", "Willingness to learn"],

        weaknesses: ["Limited professional experience"],

        missingSkills: ["Professional software development experience"],
      },
    });

    console.log("Gemini Live interview session created successfully.");

    session.sendClientContent({
      turns: [
        {
          role: "user",
          parts: [
            {
              text: "Start the interview.",
            },
          ],
        },
      ],
      turnComplete: true,
    });

    console.log("Interview start message sent.");
    console.log("Waiting for Gemini...");

    setTimeout(() => {
      console.log("Closing test session...");

      if (session) {
        session.close();
      }
    }, 15000);
  } catch (error) {
    console.error("Gemini Live service test failed:");
    console.error(error);
  }
}

test();
