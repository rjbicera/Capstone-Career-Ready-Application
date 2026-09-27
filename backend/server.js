require("dotenv").config();

const http = require("http");
const app = require("./src/app");
const { setupInterviewWebSocket } = require("./src/websocket/interviewWebSocket");

const PORT = Number(process.env.PORT) || 4000;

const server = http.createServer(app);

// Setup WebSocket handlers
setupInterviewWebSocket(server);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`WebSocket server ready for interview connections`);
});