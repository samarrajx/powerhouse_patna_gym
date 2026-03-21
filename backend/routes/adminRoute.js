const express = require('express');
const multer = require('multer');
const { parse } = require('csv-parse/sync');
const bcrypt = require('bcrypt');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

// ─── Dashboard stats ────────────────────────────────────────────────────────
router.get('/dashboard', authMiddleware(['admin']), async (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const [
    { count: total_users },
    { count: today_attendance },
    { count: inactive_users },
    { count: expiring_soon },
  ] = await Promise.all([
    supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'admin').eq('status', 'active'),
    supabase.from('attendance').select('*', { count: 'exact', head: true }).eq('date', today),
    supabase.from('users').select('*', { count: 'exact', head: true }).in('status', ['inactive', 'grace']),
    supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'admin').lte('membership_expiry', new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0]).gte('membership_expiry', today),
  ]);
  res.json({ success: true, message: 'Dashboard data', data: { total_users, today_attendance, inactive_users, expiring_soon }, error_code: null });
});

// ─── List all members ────────────────────────────────────────────────────────
router.get('/users', authMiddleware(['admin']), async (req, res) => {
  const { status, search } = req.query;
  let q = supabase.from('users').select('id,name,phone,phone_alt,roll_no,address,father_name,date_of_joining,body_type,batch_id,membership_plan,membership_expiry,fees_status,status,role,must_change_password,created_at').order('created_at', { ascending: false });

  if (status) q = q.eq('status', status);
  const { data, error } = await q;
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  let result = data || [];
  if (search) {
    const s = search.toLowerCase();
    result = result.filter(u => u.name?.toLowerCase().includes(s) || u.phone?.includes(s) || u.roll_no?.toLowerCase().includes(s));
  }
  res.json({ success: true, message: 'Users fetched', data: result, error_code: null });
});

// ─── Onboard single member ───────────────────────────────────────────────────
router.post('/users/onboard', authMiddleware(['admin']), async (req, res) => {
  const {
    name, phone, phone_alt, password = 'samgym',
    roll_no, address, father_name, date_of_joining, body_type,
    batch_id, membership_plan, membership_expiry, fees_status, notes,
  } = req.body;

  if (!name || !phone) return res.status(400).json({ success: false, message: 'Name and phone required', error_code: 'MISSING_FIELDS' });

  const password_hash = await bcrypt.hash(password, 10);
  const { data, error } = await supabase.from('users').insert([{
    name, phone, phone_alt, password_hash, roll_no, address, father_name,
    date_of_joining, body_type, batch_id, membership_plan, membership_expiry,
    fees_status: fees_status || 'paid', notes, must_change_password: true,
  }]).select().single();

  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'CREATE_ERROR' });

  await supabase.from('audit_logs').insert([{ action: 'CREATE_USER', performed_by: req.user.userId, target_user: data.id, details: { phone, name } }]);
  res.json({ success: true, message: 'Member created', data, error_code: null });
});

// ─── Edit Member ─────────────────────────────────────────────────────────────
router.put('/users/:id', authMiddleware(['admin']), async (req, res) => {
  const { id } = req.params;
  const {
    name, phone, phone_alt, roll_no, address, father_name, date_of_joining, body_type,
    batch_id, membership_plan, membership_expiry, fees_status, notes, role
  } = req.body;

  const updateFields = {
    name, phone, phone_alt, roll_no, address, father_name,
    date_of_joining, body_type, batch_id, membership_plan, membership_expiry,
    fees_status, notes
  };
  if (role) updateFields.role = role;

  const { data, error } = await supabase.from('users').update(updateFields).eq('id', id).select().single();


  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'EDIT_USER', performed_by: req.user.userId, target_user: id, details: { name, phone } }]);
  res.json({ success: true, message: 'Member updated', data, error_code: null });
});

// ─── Reset Password ──────────────────────────────────────────────────────────
router.post('/users/:id/reset-password', authMiddleware(['admin']), async (req, res) => {
  const { id } = req.params;
  const password_hash = await bcrypt.hash('samgym', 10);
  
  const { error } = await supabase.from('users').update({
    password_hash,
    must_change_password: true
  }).eq('id', id);

  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'RESET_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'RESET_PASSWORD', performed_by: req.user.userId, target_user: id, details: {} }]);
  res.json({ success: true, message: 'Password reset to samgym', data: null, error_code: null });
});

// ─── Bulk CSV upload ─────────────────────────────────────────────────────────
router.post('/users/bulk', authMiddleware(['admin']), upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'CSV file required', error_code: 'NO_FILE' });

  let records;
  try {
    records = parse(req.file.buffer.toString(), { columns: true, skip_empty_lines: true, trim: true });
  } catch (e) {
    return res.status(400).json({ success: false, message: 'Invalid CSV: ' + e.message, error_code: 'CSV_PARSE_ERROR' });
  }

  const results = { created: 0, failed: [], total: records.length };

  for (const r of records) {
    if (!r.name || !r.phone) { results.failed.push({ phone: r.phone || '?', reason: 'Missing name or phone' }); continue; }
    const password_hash = await bcrypt.hash(r.password || 'samgym', 10);
    const { error } = await supabase.from('users').insert([{
      name: r.name, phone: r.phone, phone_alt: r.phone_alt || null,
      password_hash, roll_no: r.roll_no || null, address: r.address || null,
      father_name: r.father_name || null, date_of_joining: r.date_of_joining || null,
      body_type: r.body_type || null, membership_plan: r.membership_plan || 'Standard',
      membership_expiry: r.membership_expiry || null,
      fees_status: r.fees_status || 'paid', must_change_password: true,
    }]);
    if (error) results.failed.push({ phone: r.phone, reason: error.message });
    else results.created++;
  }

  await supabase.from('audit_logs').insert([{ action: 'BULK_UPLOAD', performed_by: req.user.userId, details: results }]);
  res.json({ success: true, message: `${results.created}/${results.total} created`, data: results, error_code: null });
});

// ─── Get inactive / grace users ──────────────────────────────────────────────
router.get('/users/inactive', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase.from('users').select('*').in('status', ['inactive', 'grace']).order('updated_at', { ascending: false });
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Inactive users', data: data || [], error_code: null });
});

// ─── Restore user ───────────────────────────────────────────────────────────
router.post('/users/:id/restore', authMiddleware(['admin']), async (req, res) => {
  const { id } = req.params;
  const { data, error } = await supabase.from('users').update({ status: 'active' }).eq('id', id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'RESTORE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'RESTORE_USER', performed_by: req.user.userId, target_user: id, details: {} }]);
  res.json({ success: true, message: 'User restored to active', data, error_code: null });
});

// ─── Today's attendance (admin) ──────────────────────────────────────────────
router.get('/attendance/today', authMiddleware(['admin']), async (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const { data, error } = await supabase.from('attendance').select('*, users(name,phone,roll_no)').eq('date', today).order('time_in', { ascending: false });
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: "Today's attendance", data: data || [], error_code: null });
});

// ─── Manual attendance (admin) ───────────────────────────────────────────────
router.post('/attendance/manual', authMiddleware(['admin']), async (req, res) => {
  const { user_id, date, time_in, time_out } = req.body;
  if (!user_id || !date) return res.status(400).json({ success: false, message: 'user_id and date required', error_code: 'MISSING_FIELDS' });

  const { data: existing } = await supabase.from('attendance').select('id').eq('user_id', user_id).eq('date', date).single();

  let result;
  if (existing) {
    const { data, error } = await supabase.from('attendance').update({ time_in: time_in || existing.time_in, time_out }).eq('id', existing.id).select().single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
    result = data;
  } else {
    const { data, error } = await supabase.from('attendance').insert([{ user_id, date, time_in, time_out }]).select().single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'INSERT_ERROR' });
    result = data;
  }

  await supabase.from('audit_logs').insert([{ action: 'MANUAL_ATTENDANCE', performed_by: req.user.userId, target_user: user_id, details: { date, time_in, time_out } }]);
  res.json({ success: true, message: 'Attendance record saved', data: result, error_code: null });
});

// ─── User-specific attendance history (admin) ─────────────────────────────
router.get('/attendance/user/:userId', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase.from('attendance').select('*').eq('user_id', req.params.userId).order('date', { ascending: false }).limit(90);
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'History', data: data || [], error_code: null });
});

module.exports = router;
