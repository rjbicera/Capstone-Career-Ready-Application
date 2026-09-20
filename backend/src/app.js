const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");

const appCheckMiddleware = require("./middleware/appCheckMiddleware");

const app = express();

/*
|--------------------------------------------------------------------------
| Server / Proxy Configuration
|--------------------------------------------------------------------------
|
| Needed when the app is deployed behind a reverse proxy/load balancer.
| This also allows express-rate-limit to correctly determine the client IP.
|
*/
app.set("trust proxy", 1);

/*
|--------------------------------------------------------------------------
| Security Headers
|--------------------------------------------------------------------------
*/
app.use(helmet());

/*
|--------------------------------------------------------------------------
| CORS
|--------------------------------------------------------------------------
|
| ALLOWED_ORIGIN example:
|
| ALLOWED_ORIGIN=http://localhost:3000,http://localhost:5173
|
| For native Flutter requests, the Origin header is generally absent,
| so these requests are not blocked by CORS.
|
*/
const allowedOrigins = (process.env.ALLOWED_ORIGIN || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

const isProduction = process.env.NODE_ENV === "production";

app.use(
  cors({
    origin: (origin, callback) => {
      // Native/mobile clients and non-browser requests may not send Origin.
      if (!origin) {
        return callback(null, true);
      }

      // Development fallback when no explicit origins are configured.
      if (!isProduction && allowedOrigins.length === 0) {
        return callback(null, true);
      }

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error("Origin is not allowed by the server."));
    },

    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],

    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Accept",
      "X-Firebase-AppCheck",
    ],

    optionsSuccessStatus: 204,
  }),
);

/*
|--------------------------------------------------------------------------
| Request Body Limits
|--------------------------------------------------------------------------
|
| Prevents unexpectedly large JSON requests from consuming excessive memory.
|
*/
app.use(
  express.json({
    limit: "100kb",
  }),
);

/*
|--------------------------------------------------------------------------
| Request Logging
|--------------------------------------------------------------------------
*/
app.use(morgan(isProduction ? "combined" : "dev"));

/*
|--------------------------------------------------------------------------
| Global Rate Limiter
|--------------------------------------------------------------------------
|
| Protects the entire API from excessive requests.
|
*/
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes

  limit: 120,

  standardHeaders: "draft-7",

  legacyHeaders: false,

  message: {
    error: {
      code: "RATE_LIMITED",
      message: "Too many requests. Please try again later.",
    },
  },

  handler: (req, res) => {
    res.status(429).json({
      error: {
        code: "RATE_LIMITED",
        message: "Too many requests. Please try again later.",
      },
    });
  },
});

app.use("/api/v1", globalLimiter);
app.use("/api/v1", appCheckMiddleware);

/*
|--------------------------------------------------------------------------
| Authentication Rate Limiter
|--------------------------------------------------------------------------
|
| Authentication endpoints are more sensitive than normal API endpoints.
| This limits repeated registration/login/authentication attempts.
|
*/
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes

  limit: 20,

  standardHeaders: "draft-7",

  legacyHeaders: false,

  message: {
    error: {
      code: "AUTH_RATE_LIMITED",
      message: "Too many authentication attempts. Please try again later.",
    },
  },

  handler: (req, res) => {
    res.status(429).json({
      error: {
        code: "AUTH_RATE_LIMITED",
        message: "Too many authentication attempts. Please try again later.",
      },
    });
  },
});

app.use("/api/v1/auth", authLimiter);

/*
|--------------------------------------------------------------------------
| Health Check
|--------------------------------------------------------------------------
*/
app.get("/api/v1/health", (req, res) => {
  res.status(200).json({
    status: "ok",
  });
});

/*
|--------------------------------------------------------------------------
| Authentication Routes
|--------------------------------------------------------------------------
*/
app.use("/api/v1/auth", require("./routes/authRoutes"));

/*
|--------------------------------------------------------------------------
| Remaining Routes
|--------------------------------------------------------------------------
|
| Mount these when their modules are implemented.
|
*/
app.use("/api/v1/admin", require("./routes/adminRoutes"));
// app.use("/api/v1/profile", require("./routes/profileRoutes"));
app.use("/api/v1/resumes", require("./routes/resumeRoutes"));
// app.use("/api/v1/interview", require("./routes/interviewRoutes"));
// app.use("/api/v1/assessments", require("./routes/assessmentRoutes"));
// app.use("/api/v1/dashboard", require("./routes/dashboardRoutes"));

/*
|--------------------------------------------------------------------------
| 404 Handler
|--------------------------------------------------------------------------
*/
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: "NOT_FOUND",
      message: "The requested resource was not found.",
    },
  });
});

/*
|--------------------------------------------------------------------------
| Centralized Error Handler
|--------------------------------------------------------------------------
|
| IMPORTANT:
| Never expose stack traces, Firebase errors, database details,
| environment variables, or other internal information to clients.
|
*/
app.use((err, req, res, next) => {
  console.error(err);

  const statusCode =
    Number.isInteger(err.status) && err.status >= 400 && err.status < 600
      ? err.status
      : 500;

  const expose = err.expose === true && statusCode >= 400 && statusCode < 500;

  res.status(statusCode).json({
    error: {
      code: expose && err.code ? err.code : "INTERNAL_ERROR",
      message: expose ? err.message : "Something went wrong.",
    },
  });
});

module.exports = app;
