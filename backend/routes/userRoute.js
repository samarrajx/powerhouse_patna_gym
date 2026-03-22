const express = require('express');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /api/user/leaderboard - Top 10 by streak
router.get('/leaderboard', authMiddleware(), async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, name, current_streak, best_streak, role')
      .neq('role', 'admin')
      .order('current_streak', { ascending: false })
      .limit(10);

    if (error) throw error;
    res.json({ success: true, message: 'Leaderboard fetched', data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/user/stats - User's ranking and overall stats
router.get('/stats', authMiddleware(), async (req, res) => {
  try {
    const { userId } = req.user;
    const { data: user, error: userErr } = await supabase.from('users').select('current_streak, best_streak').eq('id', userId).single();
    if (userErr) throw userErr;

    // Get rank
    const { count: rankCount } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true })
      .neq('role', 'admin')
      .gt('current_streak', user.current_streak || 0);

    res.json({ 
      success: true, 
      data: { 
        ...user, 
        rank: (rankCount || 0) + 1 
      } 
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
