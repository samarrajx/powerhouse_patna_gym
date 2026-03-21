const express = require('express');
const jwt = require('jsonwebtoken');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// ─── Generate Dynamic QR Token (Admin displays this) ─────────────────────────
router.get('/generate', authMiddleware(['admin']), async (req, res) => {
  try {
    // Generate a 30-second token
    const token = jwt.sign(
      { type: 'attendance_qr' },
      process.env.JWT_SECRET,
      { expiresIn: '30s' }
    );
    res.json({ success: true, message: 'QR generated', data: { qr_code: token, expires_in: 30 }, error_code: null });
  } catch(e) {
    res.status(500).json({ success: false, message: e.message, error_code: 'GENERATE_ERROR' });
  }
});

// ─── Scan QR Token (User scans this with their phone) ────────────────────────
router.post('/scan', authMiddleware(['user']), async (req, res) => {
  const { code_hash } = req.body;
  if (!code_hash) return res.status(400).json({ success: false, message: 'QR token required', error_code: 'MISSING_QR' });

  try {
    const decoded = jwt.verify(code_hash, process.env.JWT_SECRET);
    if (decoded.type !== 'attendance_qr') throw new Error('Invalid token type');
  } catch (err) {
    return res.status(400).json({ success: false, message: 'Invalid or expired QR code', error_code: 'INVALID_QR' });
  }

  const user_id = req.user.userId;
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toTimeString().split(' ')[0]; // HH:MM:SS

  // Check if user has attendance today
  const { data: existing } = await supabase.from('attendance')
    .select('*').eq('user_id', user_id).eq('date', today).single();

  let action = '';
  if (!existing) {
    const { error } = await supabase.from('attendance').insert([{ user_id, date: today, time_in: now }]);
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'ATTENDANCE_ERROR' });
    action = 'IN';
  } else if (!existing.time_out) {
    const { error } = await supabase.from('attendance').update({ time_out: now }).eq('id', existing.id);
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'ATTENDANCE_ERROR' });
    action = 'OUT';
  } else {
    return res.status(400).json({ success: false, message: 'You have already checked out today', error_code: 'ALREADY_COMPLETED' });
  }

  const { data: userDetails } = await supabase.from('users').select('name, roll_no').eq('id', user_id).single();

  await supabase.from('audit_logs').insert([{
    action: 'QR_SCAN', performed_by: user_id, target_user: user_id, details: { action, time: now }
  }]);

  res.json({ success: true, message: `Checked ${action} successfully`, data: { action, user: userDetails }, error_code: null });
});

module.exports = router;
