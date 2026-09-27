const WebSocket = require("ws");
const { authMiddleware } = require("../middleware/authMiddleware");
const {
  createGeminiLiveSession,
  getPreviousAttemptSummaries,
} = require("../services/geminiLiveService");
const { db } = require("../config/firebaseAdmin");

/**
 * WebSocket handler for Gemini Live interview proxy.
 * 
 * Flow:
 * 1. Flutter gets sessionId from POST /interview/start
 * 2. Flutter connects to WS /interview/:sessionId/ws with Authorization header
 * 3. Backend validates token, loads session context, creates Gemini Live session
 * 4. Backend proxies messages bidirectionally between Flutter and Gemini Live
 */
function setupInterviewWebSocket(server) {
  const wss = new WebSocket.Server({ noServer: true });

  server.on("upgrade", async (request, socket, head) => {
    const url = new URL(request.url, `http://${request.headers.host}`);
    const pathname = url.pathname;

    // Match /api/v1/interview/:sessionId/ws
    const match = pathname.match(/^\/api\/v1\/interview\/([^/]+)\/ws$/);
    if (!match) return;

    const sessionId = match[1];

    // Extract token from query params or headers
    const token = url.searchParams.get("token") || 
      request.headers.authorization?.replace("Bearer ", "");

    if (!token) {
      socket.write("HTTP/1.1 401 Unauthorized\r\n\r\n");
      socket.destroy();
      return;
    }

    // Verify Firebase ID token
    const { auth } = require("../config/firebaseAdmin");
    let uid;
    try {
      const decodedToken = await auth.verifyIdToken(token);
      uid = decodedToken.uid;
    } catch (err) {
      socket.write("HTTP/1.1 401 Unauthorized\r\n\r\n");
      socket.destroy();
      return;
    }

    // Verify session exists and belongs to user
    const sessionRef = db.collection("users").doc(uid).collection("mockInterviews").doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      socket.write("HTTP/1.1 404 Not Found\r\n\r\n");
      socket.destroy();
      return;
    }

    const sessionData = sessionDoc.data();
    if (sessionData.status !== "in_progress") {
      socket.write("HTTP/1.1 409 Conflict\r\n\r\n");
      socket.destroy();
      return;
    }

    // Upgrade to WebSocket
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit("connection", ws, request, { uid, sessionId, sessionData });
    });
  });

  wss.on("connection", async (ws, request, { uid, sessionId, sessionData }) => {
    console.log(`[WS] Interview WebSocket connected: ${sessionId} for user ${uid}`);

    let geminiSession = null;
    let geminiConnected = false;

    try {
      // Get previous attempt summaries
      const previousAttemptSummaries = await getPreviousAttemptSummaries(uid, db, sessionData.attemptNumber);

      // Build interview context
      const interviewContext = {
        careerGoal: sessionData.careerGoal,
        course: sessionData.course,
        yearLevel: sessionData.yearLevel,
        attemptNumber: sessionData.attemptNumber,
        resume: {
          summary: sessionData.resumeSummary,
          skills: sessionData.resumeSkills,
          strengths: sessionData.resumeStrengths,
          weaknesses: sessionData.resumeWeaknesses,
          missingSkills: sessionData.resumeMissingSkills,
        },
        previousAttemptSummaries,
      };

      // Create Gemini Live session
      geminiSession = await createGeminiLiveSession(interviewContext);
      geminiConnected = true;

      console.log(`[WS] Gemini Live session created for ${sessionId}`);

      // Forward messages from Flutter -> Gemini Live
      ws.on("message", (data, isBinary) => {
        if (!geminiConnected || !geminiSession) return;

        try {
          const message = isBinary ? data : data.toString();
          // Forward to Gemini Live
          console.log('[WS] Flutter -> Gemini:', isBinary ? `[BINARY ${data.length} bytes]` : message.substring(0, 200));
          geminiSession.send(message);
        } catch (err) {
          console.error("[WS] Error sending to Gemini:", err.message);
        }
      });

      // Forward messages from Gemini Live -> Flutter
      geminiSession.onmessage = (message) => {
        if (ws.readyState === WebSocket.OPEN) {
          console.log('[WS] Gemini -> Flutter:', JSON.stringify(message).substring(0, 200));
          ws.send(message.data);
        }
      };

      geminiSession.onerror = (error) => {
        console.error("[WS] Gemini Live error:", error);
        ws.close(1011, "Gemini Live error");
      };

      geminiSession.onclose = (event) => {
        console.log(`[WS] Gemini Live closed for ${sessionId}:`, event?.code ?? "");
        geminiConnected = false;
        if (ws.readyState === WebSocket.OPEN) {
          ws.close(1000, "Gemini session ended");
        }
      };

      // Handle client disconnect
      ws.on("close", (code, reason) => {
        console.log(`[WS] Flutter disconnected from ${sessionId}:`, code, reason?.toString());
        if (geminiSession && geminiConnected) {
          geminiSession.close();
        }
      });

      ws.on("error", (error) => {
        console.error("[WS] WebSocket error:", error.message);
      });

    } catch (err) {
      console.error("[WS] Failed to setup interview:", err.message);
      ws.close(1011, "Server error");
    }
  });

  return wss;
}

module.exports = { setupInterviewWebSocket };