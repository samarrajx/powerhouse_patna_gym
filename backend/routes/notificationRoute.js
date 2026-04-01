const express = require('express');
const router = express.Router();
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');
const { sendGlobalPush } = require('../utils/fcm');

// GET /api/notifications -> Get user notifications + global announcements
router.get('/', authMiddleware(['user', 'admin']), async (req, res) => {
  try {
    const [notifRes, announceRes] = await Promise.all([
      supabase
        .from('notifications')
        .select('*')
        .or(`user_id.eq.${req.user.userId},user_id.is.null`)
        .order('created_at', { ascending: false })
        .limit(50),
      supabase
        .from('announcements')
        .select('*')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(20)
    ]);

    if (notifRes.error) throw notifRes.error;
    if (announceRes.error) throw announceRes.error;

    // Merge and format
    const notifications = (notifRes.data || []);
    const announcements = (announceRes.data || []).map(a => ({
      id: `ann_${a.id}`,
      user_id: null,
      type: 'announcement',
      title: a.title,
      message: a.content,
      is_read: false, // Announcements are global and persistent
      created_at: a.created_at
    }));

    const merged = [...notifications, ...announcements].sort((a, b) => 
      new Date(b.created_at) - new Date(a.created_at)
    );

    res.json({ success: true, data: merged });
  } catch (err) {
    console.error('Notification fetch error:', err);
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
    
    // Broadcast via FCM
    await sendGlobalPush(title, message, { type });
    
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
      .eq('user_id', req.user.userId);

    if (error) throw error;
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to update notification' });
  }
});

module.exports = router;
