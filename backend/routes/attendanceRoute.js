const express = require("express");
const supabase = require("../db/supabase");
const supabaseLogs = require("../db/supabaseLogs");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// GET /attendance/today (for current user)
router.get("/today", authMiddleware(["user","admin"]), async (req, res) => {
  const { getTodayISTStr, getNowIST } = require('../utils/dateUtils');
  const today = getTodayISTStr();
  const { data } = await supabaseLogs.from("attendance").select("*").eq("user_id", req.user.userId).eq("date", today).single();
  res.json({ success: true, message: "Today's record", data: data || null, error_code: null });
});

// GET /attendance/history (for current user)
router.get("/history", authMiddleware(["user","admin"]), async (req, res) => {
  const { data, error } = await supabaseLogs.from("attendance").select("*").eq("user_id", req.user.userId).order("date", { ascending: false }).limit(60);
  if (error) return res.status(500).json({ success: false, message: error.message, data: null, error_code: "DB_ERROR" });
  res.json({ success: true, message: "History fetched", data: data || [], error_code: null });
});

module.exports = router;
