const rateLimit = require("express-rate-limit");

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: { success: false, message: "Too many requests", error_code: "RATE_LIMIT_EXCEEDED" }
});

const scanLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 5, // 5 scans per minute per IP to prevent spamming
  message: { success: false, message: "Too many scan requests", error_code: "SCAN_SPAM" }
});

module.exports = { apiLimiter, scanLimiter };
