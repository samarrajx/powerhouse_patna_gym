const express = require('express');
const router = express.Router();
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/authMiddleware');

// GET /api/notifications -> Get user notifications + global announcements
router.get('/', authMiddleware(['user', 'admin']), async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .or(`user_id.eq.${req.user.id},user_id.is.null`)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
});

// POST /api/notifications/broadcast -> Admin broadcast to all
router.post('/broadcast', authMiddleware(['admin']), async (req, res) => {
  const { title, message, type = 'announcement' } = req.body;
  if (!title || !message) {
    return res.status(400).json({ success: false, message: 'Title and message required' });
  }

  try {
    const { data, error } = await supabase
      .from('notifications')
      .insert({ title, message, type, user_id: null })
      .select();

    if (error) throw error;
    res.json({ success: true, message: 'Broadcast sent successfully', data });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to send broadcast' });
  }
});

// PUT /api/notifications/:id/read -> Mark as read
router.put('/:id/read', authMiddleware(['user', 'admin']), async (req, res) => {
  try {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', req.params.id)
      .eq('user_id', req.user.id);

    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to update notification' });
  }
});

module.exports = router;
