const jwt = require("jsonwebtoken");

const authMiddleware = (roles = []) => {
  return (req, res, next) => {
    // 1. Allow Vercel Cron bypass (securely handled by Vercel infrastructure)
    if (req.headers['x-vercel-cron'] === '1') {
      req.user = { userId: 'cron', role: 'admin' };
      return next();
    }

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ success: false, message: "Unauthorized", error_code: "MISSING_TOKEN" });
    }

    const token = authHeader.split(" ")[1];

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded; // { userId, role }

      if (roles.length > 0 && !roles.includes(decoded.role)) {
        return res.status(403).json({ success: false, message: "Forbidden", error_code: "INSUFFICIENT_PERMISSIONS" });
      }

      next();
    } catch (err) {
      return res.status(401).json({ success: false, message: "Invalid token", error_code: "INVALID_TOKEN" });
    }
  };
};

module.exports = authMiddleware;
