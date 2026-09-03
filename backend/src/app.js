const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.ALLOWED_ORIGIN?.split(",") || "*" }));
app.use(express.json());
app.use(morgan("dev"));

app.get("/api/v1/health", (req, res) => res.json({ status: "ok" }));

app.use("/api/v1/auth", require("./routes/authRoutes"));

// Mount remaining route files as each module owner builds them, e.g.:
// app.use("/api/v1/profile", require("./routes/profileRoutes"));
// app.use("/api/v1/resumes", require("./routes/resumeRoutes"));
// app.use("/api/v1/interview", require("./routes/interviewRoutes"));
// app.use("/api/v1/assessments", require("./routes/assessmentRoutes"));
// app.use("/api/v1/dashboard", require("./routes/dashboardRoutes"));

// Centralized error handler — must be LAST middleware registered
app.use((err, req, res, next) => {
  console.error(err); // server-side only, per security policy: never leak stack traces to client
  res.status(err.status || 500).json({
    error: {
      code: err.code || "INTERNAL_ERROR",
      message: err.expose ? err.message : "Something went wrong",
    },
  });
});

module.exports = app;
