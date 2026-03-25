const express = require('express');
const multer = require('multer');
const { parse } = require('csv-parse/sync');
const bcrypt = require('bcrypt');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
const hasMissingColumn = (err, column) => (err?.message || '').toLowerCase().includes(column.toLowerCase());

// ─── Dashboard stats ────────────────────────────────────────────────────────
router.get('/dashboard', authMiddleware(['admin']), async (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  
  // PROACTIVE SYNC: Update all active members whose membership has expired
  try {
    await supabase.from('users')
      .update({ status: 'inactive' })
      .eq('status', 'active')
      .lt('membership_expiry', today);
  } catch (err) {
    console.error('Proactive expiry sync failed:', err);
  }
  // Calculate last 7 days
  const last7Days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    last7Days.push(d.toISOString().split('T')[0]);
  }

  const [
    { count: total_users },
    { count: today_attendance },
    { count: inactive_users },
    { count: expiring_soon },
    { data: footfallRaw }
  ] = await Promise.all([
    supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'admin').eq('status', 'active'),
    supabase.from('attendance').select('*', { count: 'exact', head: true }).eq('date', today),
    supabase.from('users').select('*', { count: 'exact', head: true }).in('status', ['inactive', 'grace']),
    supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'admin').lte('membership_expiry', new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0]).gte('membership_expiry', today),
    supabase.from('attendance').select('date').gte('date', last7Days[0]).lte('date', last7Days[6])
  ]);

  const footfallMap = (footfallRaw || []).reduce((acc, curr) => {
    acc[curr.date] = (acc[curr.date] || 0) + 1;
    return acc;
  }, {});

  const weekly_footfall = last7Days.map(date => ({
    day: new Date(date).toLocaleDateString('en-US', { weekday: 'short' }),
    full_date: date,
    scans: footfallMap[date] || 0
  }));

  res.json({ 
    success: true, 
    message: 'Dashboard data', 
    data: { 
      total_users, 
      today_attendance, 
      inactive_users, 
      expiring_soon,
      weekly_footfall
    }, 
    error_code: null 
  });
});


// ─── List all members ────────────────────────────────────────────────────────
router.get('/users', authMiddleware(['admin']), async (req, res) => {
  const { status, search } = req.query;
  const page = Math.max(parseInt(req.query.page || '1', 10), 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit || '50', 10), 1), 200);
  const all = req.query.all === 'true';
  const from = (page - 1) * limit;
  const to = from + limit - 1;

  let q = supabase
    .from('users')
    .select('id,name,phone,phone_alt,roll_no,address,father_name,date_of_joining,body_type,batch_id,membership_plan,membership_expiry,fees_status,fees_amount,status,role,is_frozen,freeze_start_date,must_change_password,created_at', { count: 'exact' })
    .order('created_at', { ascending: false });

  if (!all) q = q.range(from, to);
  if (status) q = q.eq('status', status);
  if (search) q = q.or(`name.ilike.%${search}%,phone.ilike.%${search}%,roll_no.ilike.%${search}%`);

  let { data, error, count } = await q;
  if (error && (hasMissingColumn(error, 'fees_amount') || hasMissingColumn(error, 'is_frozen') || hasMissingColumn(error, 'freeze_start_date'))) {
    let fallbackQ = supabase
      .from('users')
      .select('id,name,phone,phone_alt,roll_no,address,father_name,date_of_joining,body_type,batch_id,membership_plan,membership_expiry,fees_status,status,role,must_change_password,created_at', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (!all) fallbackQ = fallbackQ.range(from, to);
    if (status) fallbackQ = fallbackQ.eq('status', status);
    if (search) fallbackQ = fallbackQ.or(`name.ilike.%${search}%,phone.ilike.%${search}%,roll_no.ilike.%${search}%`);

    ({ data, error, count } = await fallbackQ);
    data = (data || []).map((u) => ({ ...u, is_frozen: false, freeze_start_date: null, fees_amount: 0 }));
  }
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Users fetched', data: data || [], total_count: count || 0, page, limit, error_code: null });
});

// ─── Onboard single member ───────────────────────────────────────────────────
router.post('/users/onboard', authMiddleware(['admin']), async (req, res) => {
  const {
    name, phone, phone_alt, password = 'samgym',
    roll_no, address, father_name, date_of_joining, body_type,
    batch_id, membership_plan, membership_expiry, fees_status, fees_amount, notes,
  } = req.body;

  if (!name || !phone) return res.status(400).json({ success: false, message: 'Name and phone required', error_code: 'MISSING_FIELDS' });

  const password_hash = await bcrypt.hash(password, 10);
  const { data, error } = await supabase.from('users').insert([{
    name, phone, phone_alt, password_hash, roll_no, address, father_name,
    date_of_joining, body_type, batch_id, membership_plan, membership_expiry,
    fees_status: fees_status || 'paid', fees_amount: fees_amount ? Number(fees_amount) : 0, notes, must_change_password: true,
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
    batch_id, membership_plan, membership_expiry, fees_status, fees_amount, notes, role
  } = req.body;

  if (role && id === req.user.userId) {
    return res.status(400).json({ success: false, message: 'You cannot change your own role.', error_code: 'SELF_ROLE_CHANGE' });
  }

  const updateFields = {
    name, phone, phone_alt, roll_no, address, father_name,
    date_of_joining, body_type, batch_id, membership_plan, membership_expiry,
    fees_status, fees_amount, notes
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
  const validRecords = records.filter((r) => {
    if (!r.name || !r.phone) {
      results.failed.push({ phone: r.phone || '?', reason: 'Missing name or phone' });
      return false;
    }
    return true;
  });

  const passwordHashes = await Promise.all(validRecords.map((r) => bcrypt.hash(r.password || 'samgym', 10)));
  const allRows = validRecords.map((r, i) => ({
    name: r.name, phone: r.phone, phone_alt: r.phone_alt || null,
    password_hash: passwordHashes[i], roll_no: r.roll_no || null, address: r.address || null,
    father_name: r.father_name || null, date_of_joining: r.date_of_joining || null,
    body_type: r.body_type || null, membership_plan: r.membership_plan || 'Standard',
    membership_expiry: r.membership_expiry || null,
    fees_status: r.fees_status || 'paid', fees_amount: r.fees_amount ? Number(r.fees_amount) : 0, must_change_password: true,
  }));

  if (allRows.length) {
    const { error } = await supabase.from('users').insert(allRows);
    if (error) {
      const duplicate = error.message?.toLowerCase().includes('duplicate') || error.code === '23505';
      if (duplicate) {
        results.failed.push({ phone: 'multiple', reason: 'One or more records have duplicate unique fields' });
      } else {
        results.failed.push({ phone: 'multiple', reason: error.message });
      }
    } else {
      results.created += allRows.length;
    }
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
  const { data: existing, error: fetchErr } = await supabase.from('users').select('id,membership_expiry').eq('id', id).single();
  if (fetchErr || !existing) return res.status(404).json({ success: false, message: 'User not found', error_code: 'NOT_FOUND' });
  const today = new Date().toISOString().split('T')[0];
  if (existing.membership_expiry && existing.membership_expiry < today) {
    return res.status(400).json({ success: false, message: 'Cannot restore: membership has expired. Update expiry first.', error_code: 'EXPIRED_MEMBERSHIP' });
  }
  const { data, error } = await supabase.from('users').update({ status: 'active' }).eq('id', id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'RESTORE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'RESTORE_USER', performed_by: req.user.userId, target_user: id, details: {} }]);
  res.json({ success: true, message: 'User restored to active', data, error_code: null });
});

// ─── Freeze User ─────────────────────────────────────────────────────────────
router.post('/users/:id/freeze', authMiddleware(['admin']), async (req, res) => {
  const { id } = req.params;
  const today = new Date().toISOString().split('T')[0];
  const { data, error } = await supabase.from('users').update({ is_frozen: true, freeze_start_date: today }).eq('id', id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'FREEZE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'FREEZE_USER', performed_by: req.user.userId, target_user: id, details: { date: today } }]);
  res.json({ success: true, message: 'Membership frozen', data });
});

// ─── Unfreeze User ───────────────────────────────────────────────────────────
router.post('/users/:id/unfreeze', authMiddleware(['admin']), async (req, res) => {
  const { id } = req.params;
  const { data: user, error: getErr } = await supabase.from('users').select('*').eq('id', id).single();
  if (getErr || !user) return res.status(404).json({ success: false, message: 'User not found' });
  if (!user.is_frozen || !user.freeze_start_date) return res.status(400).json({ success: false, message: 'User is not frozen' });

  const start = new Date(user.freeze_start_date);
  const end = new Date();
  const diffTime = Math.abs(end - start);
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  let newExpiry = user.membership_expiry;
  if (newExpiry) {
    const expDate = new Date(newExpiry);
    expDate.setDate(expDate.getDate() + diffDays);
    newExpiry = expDate.toISOString().split('T')[0];
  }

  const { data, error } = await supabase.from('users').update({ is_frozen: false, freeze_start_date: null, membership_expiry: newExpiry }).eq('id', id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UNFREEZE_ERROR' });
  
  await supabase.from('audit_logs').insert([{ action: 'UNFREEZE_USER', performed_by: req.user.userId, target_user: id, details: { days_added: diffDays } }]);
  res.json({ success: true, message: `Membership unfrozen. Added ${diffDays} days to expiry.`, data });
});

// ─── Today's attendance (admin) ──────────────────────────────────────────────
router.get('/attendance/today', authMiddleware(['admin']), async (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const { data, error } = await supabase.from('attendance').select('*, users(name,phone,roll_no)').eq('date', today).order('time_in', { ascending: false });
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: "Today's attendance", data: data || [], error_code: null });
});

// ─── Attendance report by date range (admin) ────────────────────────────────
router.get('/reports/attendance', authMiddleware(['admin']), async (req, res) => {
  const { from, to } = req.query;
  if (!from || !to) {
    return res.status(400).json({ success: false, message: 'from and to query params are required', error_code: 'MISSING_FIELDS' });
  }
  if (from > to) {
    return res.status(400).json({ success: false, message: 'from must be <= to', error_code: 'INVALID_RANGE' });
  }

  const { data, error } = await supabase
    .from('attendance')
    .select('id,user_id,date,time_in,time_out,users(name,phone,roll_no)')
    .gte('date', from)
    .lte('date', to)
    .order('date', { ascending: false })
    .order('time_in', { ascending: false });

  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Attendance report', data: data || [], error_code: null });
});

// ─── Revenue summary (admin) ────────────────────────────────────────────────
router.get('/reports/revenue', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase
    .from('users')
    .select('fees_status,fees_amount,role')
    .neq('role', 'admin');

  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  const summary = (data || []).reduce((acc, user) => {
    const amount = Number(user.fees_amount || 0);
    if (user.fees_status === 'paid') acc.collected += amount;
    if (['pending', 'overdue'].includes(user.fees_status)) acc.outstanding += amount;
    return acc;
  }, { collected: 0, outstanding: 0 });

  res.json({ success: true, message: 'Revenue summary', data: summary, error_code: null });
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

// ─── Templates (Body Type Messages) ──────────────────────────────────────────
router.get('/templates', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase.from('templates').select('*').order('category');
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Templates list', data: data || [], error_code: null });
});

router.put('/templates/:id', authMiddleware(['admin']), async (req, res) => {
  const { message } = req.body;
  const { data, error } = await supabase.from('templates').update({ message, updated_at: new Date() }).eq('id', req.params.id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
  res.json({ success: true, message: 'Template updated', data, error_code: null });
});

// ─── Announcements ───────────────────────────────────────────────────────────
router.get('/announcements', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase.from('announcements').select('*').order('created_at', { ascending: false });
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Announcements list', data: data || [], error_code: null });
});

router.post('/announcements', authMiddleware(['admin']), async (req, res) => {
  const { title, content, is_active } = req.body;
  const { data, error } = await supabase.from('announcements').insert([{ title, content, is_active }]).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'INSERT_ERROR' });
  res.json({ success: true, message: 'Announcement created', data, error_code: null });
});

router.put('/announcements/:id', authMiddleware(['admin']), async (req, res) => {
  const { title, content, is_active } = req.body;
  const { data, error } = await supabase.from('announcements').update({ title, content, is_active }).eq('id', req.params.id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
  res.json({ success: true, message: 'Announcement updated', data, error_code: null });
});

router.delete('/announcements/:id', authMiddleware(['admin']), async (req, res) => {
  const { error } = await supabase.from('announcements').delete().eq('id', req.params.id);
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'DELETE_ERROR' });
  res.json({ success: true, message: 'Announcement deleted', error_code: null });
});


// ─── Batches ────────────────────────────────────────────────────────────────
router.get('/batches', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase.from('batches').select('id, name').order('name');
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Batches list', data: data || [], error_code: null });
});


module.exports = router;
