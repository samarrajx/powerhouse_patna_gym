const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// POST /auth/login
router.post('/login', async (req, res) => {
  const { phone, password } = req.body;
  console.log(`[AUTH] Login attempt for: ${phone}`);
  if (!phone || !password) return res.status(400).json({ success: false, message: 'Phone and password required', error_code: 'MISSING_CREDS' });

  const { data: user, error } = await supabase.from('users').select('*').eq('phone', phone.trim()).single();
  if (error || !user) {
    console.warn(`[AUTH] User not found or DB error: ${phone}`, error?.message);
    return res.status(401).json({ success: false, message: 'Invalid credentials', error_code: 'INVALID_CREDS' });
  }
  if (user.status === 'inactive') return res.status(403).json({ success: false, message: 'Account is inactive', error_code: 'ACCOUNT_INACTIVE' });

  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials', error_code: 'INVALID_CREDS' });

  const token = jwt.sign({ userId: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });

  res.json({
    success: true, message: 'Login successful', error_code: null,
    data: {
      token,
      user: {
        id: user.id, name: user.name, role: user.role, phone: user.phone,
        phone_alt: user.phone_alt, roll_no: user.roll_no, address: user.address,
        father_name: user.father_name, date_of_joining: user.date_of_joining,
        body_type: user.body_type, membership_plan: user.membership_plan,
        membership_expiry: user.membership_expiry, fees_status: user.fees_status,
        batch_id: user.batch_id, status: user.status,
        must_change_password: user.must_change_password === true,
        current_streak: user.current_streak,
        best_streak: user.best_streak,
        is_frozen: user.is_frozen,
      },
      comeback_eligible: _checkComeback(user)
    }
  });
});

router.get('/me', authMiddleware(), async (req, res) => {
  const { data: user, error } = await supabase.from('users').select('*').eq('id', req.user.userId).single();
  if (error || !user) return res.status(404).json({ success: false, message: 'User not found', error_code: 'NOT_FOUND' });
  
  res.json({ 
    success: true, 
    message: 'User data', 
    data: {
      ...user,
      must_change_password: user.must_change_password === true,
    },
    comeback_eligible: _checkComeback(user),
    error_code: null 
  });
});

// Helper
function _checkComeback(user) {
  const { getNowIST } = require('../utils/dateUtils');
  if (!user.streak_last_updated) return false;
  const last = new Date(user.streak_last_updated);
  const now = getNowIST().toJSDate();
  const diff = (now - last) / (1000 * 60 * 60 * 24);
  
  // 15 days inactivity AND either never claimed or claimed > 30 days ago
  if (diff > 15) {
     if (!user.last_comeback_date) return true;
     const lastClaim = new Date(user.last_comeback_date);
     const diffClaim = (now - lastClaim) / (1000 * 60 * 60 * 24);
     return diffClaim > 30;
  }
  return false;
}

// ─── Claim Comeback ──────────────────────────────────────────────────────────
router.post('/claim-comeback', authMiddleware(), async (req, res) => {
  const { data: user, error: getErr } = await supabase.from('users').select('*').eq('id', req.user.userId).single();
  if (getErr || !user) return res.status(404).json({ success: false, message: 'User not found' });

  if (!_checkComeback(user)) {
    return res.status(400).json({ success: false, message: 'Not eligible for comeback bonus' });
  }

  let newExpiry = user.membership_expiry;
  if (newExpiry) {
    const expDate = new Date(newExpiry);
    expDate.setDate(expDate.getDate() + 2); // 2 days bonus
    newExpiry = expDate.toISOString().split('T')[0];
  }

  const { getTodayISTStr } = require('../utils/dateUtils');
  const today = getTodayISTStr();
  const { error } = await supabase.from('users').update({ 
    membership_expiry: newExpiry, 
    last_comeback_date: today 
  }).eq('id', req.user.userId);

  if (error) return res.status(400).json({ success: false, message: error.message });


  res.json({ success: true, message: 'Welcome back! 2 days added to your membership.' });
});

// POST /auth/change-password
router.post('/change-password', authMiddleware(), async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  if (!oldPassword || !newPassword) return res.status(400).json({ success: false, message: 'Both passwords required', error_code: 'MISSING_FIELDS' });
  if (newPassword.length < 6) return res.status(400).json({ success: false, message: 'Min 6 characters', error_code: 'PWD_TOO_SHORT' });

  const { data: user } = await supabase.from('users').select('password_hash').eq('id', req.user.userId).single();
  if (!user) return res.status(404).json({ success: false, message: 'User not found', error_code: 'NOT_FOUND' });

  const isMatch = await bcrypt.compare(oldPassword, user.password_hash);
  if (!isMatch) return res.status(400).json({ success: false, message: 'Current password is incorrect', error_code: 'PWD_MISMATCH' });

  const newHash = await bcrypt.hash(newPassword, 10);
  await supabase.from('users').update({ password_hash: newHash, must_change_password: false }).eq('id', req.user.userId);


  res.json({ success: true, message: 'Password updated successfully', data: {}, error_code: null });
});

// POST /auth/device-token
router.post('/device-token', authMiddleware(), async (req, res) => {
  const { token, platform } = req.body;
  if (!token) return res.status(400).json({ success: false, message: 'Token required' });

  try {
    const { error } = await supabase
      .from('device_tokens')
      .upsert({ 
        user_id: req.user.userId, 
        token, 
        platform, 
        updated_at: require('../utils/dateUtils').getNowISTDate() 
      }, { onConflict: 'user_id, token' });

    if (error) throw error;
    
    res.json({ success: true, message: 'Token registered' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to register token' });
  }
});

module.exports = router;
