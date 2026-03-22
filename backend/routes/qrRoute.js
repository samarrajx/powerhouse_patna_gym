const express = require('express');
const jwt = require('jsonwebtoken');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// ─── Helper: Check if Gym is Open ────────────────────────────────────────────
async function checkGymOpen() {
  const now = new Date();
  const todayDateStr = now.toISOString().split('T')[0];
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayName = days[now.getDay()];

  // 1. Check if today is a holiday
  const { data: holiday } = await supabase.from('holidays').select('*').eq('date', todayDateStr).single();
  if (holiday && holiday.is_closed) {
    return { isOpen: false, reason: `Holiday: ${holiday.reason}` };
  }

  // 2. Check weekly schedule
  const { data: schedule } = await supabase.from('weekly_schedule').select('*').eq('day_of_week', dayName).single();
  if (!schedule) return { isOpen: true }; // Default open if no schedule defined
  if (!schedule.is_open) return { isOpen: false, reason: 'Closed today based on weekly schedule' };

  // 3. Check time logic (Warning: time zones can be tricky, keeping it simple using server time)
  // Assuming open_time and close_time are 'HH:MM:SS' strings
  const currentTime = now.toTimeString().split(' ')[0]; // 'HH:MM:SS'
  if (schedule.open_time && currentTime < schedule.open_time) {
    return { isOpen: false, reason: `Gym opens at ${schedule.open_time}` };
  }
  if (schedule.close_time && currentTime > schedule.close_time) {
    return { isOpen: false, reason: `Gym closed at ${schedule.close_time}` };
  }

  return { isOpen: true };
}

// ─── Generate Dynamic QR Token (Admin displays this) ─────────────────────────
router.get('/generate', authMiddleware(['admin']), async (req, res) => {
  try {
    const gymStatus = await checkGymOpen();
    if (!gymStatus.isOpen) {
      return res.status(403).json({ success: false, message: gymStatus.reason, error_code: 'GYM_CLOSED' });
    }

    // Generate a 30-second token
    const token = jwt.sign(
      { type: 'attendance_qr' },
      process.env.JWT_SECRET,
      { expiresIn: '120s' }
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

  const gymStatus = await checkGymOpen();
  if (!gymStatus.isOpen) {
    return res.status(403).json({ success: false, message: gymStatus.reason, error_code: 'GYM_CLOSED' });
  }

  try {
    const decoded = jwt.verify(code_hash, process.env.JWT_SECRET);
    if (decoded.type !== 'attendance_qr') throw new Error('Invalid token type');
  } catch (err) {
    console.error('[QR VERIFY ERROR]:', err.message);
    return res.status(400).json({ success: false, message: `Invalid or expired QR: ${err.message}`, error_code: 'INVALID_QR' });
  }

  const user_id = req.user.userId;
  const user_role = req.user.role;
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toISOString();

  console.log(`[QR SCAN] User: ${user_id} (${user_role}) | Code length: ${code_hash?.length}`);

  // Check if user has attendance today
  const { data: existing } = await supabase.from('attendance')
    .select('*').eq('user_id', user_id).eq('date', today).single();

  let action = '';
  if (!existing) {
    const { error } = await supabase.from('attendance').insert([{ user_id, date: today, time_in: now }]);
    if (error) {
      console.error('Attendance Check-In Error:', error);
      return res.status(400).json({ success: false, message: `DB Error: ${error.message} (${error.code})`, error_code: 'ATTENDANCE_ERROR' });
    }
    action = 'IN';
  } else if (!existing.time_out) {
    const { error } = await supabase.from('attendance').update({ time_out: now }).eq('id', existing.id);
    if (error) {
      console.error('Attendance Check-Out Error:', error);
      return res.status(400).json({ success: false, message: `DB Error: ${error.message} (${error.code})`, error_code: 'ATTENDANCE_ERROR' });
    }
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
