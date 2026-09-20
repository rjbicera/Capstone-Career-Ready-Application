const express = require('express');
const multer = require('multer');
const path = require('path');
const os = require('os');
const fs = require('fs');
const crypto = require('crypto');
const { rateLimit, ipKeyGenerator } = require('express-rate-limit');
const { authMiddleware, requireStudent } = require('../middleware/authMiddleware');
const { analyzeResume, MAX_FILE_SIZE_BYTES } = require('../controllers/resumeController');

const router = express.Router();

const tempDirectory = path.join(os.tmpdir(), 'career-ready-resumes');
fs.mkdirSync(tempDirectory, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, tempDirectory),
  filename: (_req, file, cb) => {
    cb(null, `${crypto.randomUUID()}.pdf`);
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: MAX_FILE_SIZE_BYTES,
    files: 1,
  },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype !== 'application/pdf') {
      return cb(new multer.MulterError('LIMIT_UNEXPECTED_FILE', 'resume'));
    }
    return cb(null, true);
  },
});

const resumeAnalysisLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  keyGenerator: (req) => req.uid || ipKeyGenerator(req.ip),
  message: {
    error: {
      code: 'RESUME_ANALYSIS_RATE_LIMITED',
      message: 'Too many resume analyses. Please try again later.',
    },
  },
  handler: (_req, res) => {
    res.status(429).json({
      error: {
        code: 'RESUME_ANALYSIS_RATE_LIMITED',
        message: 'Too many resume analyses. Please try again later.',
      },
    });
  },
});

router.post(
  '/analyze',
  authMiddleware,
  requireStudent,
  resumeAnalysisLimiter,
  (req, res, next) => {
    upload.single('resume')(req, res, (err) => {
      if (!err) return next();

      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(413).json({
            error: {
              code: 'RESUME_TOO_LARGE',
              message: 'Resume PDF must be 10 MB or smaller.',
            },
          });
        }

        return res.status(415).json({
          error: {
            code: 'INVALID_RESUME_TYPE',
            message: 'Only PDF resumes are supported.',
          },
        });
      }

      return next(err);
    });
  },
  analyzeResume,
);

module.exports = router;
