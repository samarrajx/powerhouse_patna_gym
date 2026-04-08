const express = require('express');
const { getNowIST, getTodayISTStr, getNowISTDate, toIST } = require('../utils/dateUtils');
const multer = require('multer');
const { parse } = require('csv-parse/sync');
const bcrypt = require('bcrypt');
const supabase = require('../db/supabase');
const supabaseLogs = require('../db/supabaseLogs');
const authMiddleware = require('../middleware/auth');
const { sendToAll, sendToUser } = require('../utils/fcm');
const { getGymStatus } = require('../utils/gymStatus');

const { isInitialized, getError } = require('../db/firebase');
const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
const hasMissingColumn = (err, column) => (err?.message || '').toLowerCase().includes(column.toLowerCase());

// ─── Dashboard stats ────────────────────────────────────────────────────────
router.get('/dashboard', authMiddleware(['admin']), async (req, res) => {
  const today = getTodayISTStr();
  
  // PROACTIVE SYNC: Update all active members whose membership has expired
  try {
    await supabase.from('users')
      .update({ status: 'inactive' })
      .eq('status', 'active')
      .lt('membership_expiry', today);
  } catch (err) {
    console.error('Proactive expiry sync failed:', err);
  }

  // Last 7 days helper
  const last7Days = [];
  for (let i = 6; i >= 0; i--) {
    const d = getNowISTDate();
    d.setDate(d.getDate() - i);
    last7Days.push(d.toISOString().split('T')[0]);
  }

  // Robust Fetching: Execute queries and catch errors individually
  const fetchStat = async (query, fallback = 0) => {
    try {
      const { count, error } = await query;
      if (error) throw error;
      return count || 0;
    } catch (err) {
      console.error('Dashboard stat fetch failed:', err.message);
      return fallback;
    }
  };

  const [
    total_users,
    today_attendance,
    inactive_users,
    expiring_soon,
    footfallRaw
  ] = await Promise.all([
    fetchStat(supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'admin').eq('status', 'active')),
    fetchStat(supabaseLogs.from('attendance').select('*', { count: 'exact', head: true }).eq('date', today)),
    fetchStat(supabase.from('users').select('*', { count: 'exact', head: true }).in('status', ['inactive', 'grace'])),
    fetchStat(supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'admin').lte('membership_expiry', new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0]).gte('membership_expiry', today)),
    supabaseLogs.from('attendance').select('date').gte('date', last7Days[0]).lte('date', last7Days[6]).then(res => res.data || [])
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
    message: 'Dashboard data fetched', 
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


// ─── Get next suggested roll number ──────────────────────────────────────────
router.get('/users/next-roll-no', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase
    .from('users')
    .select('roll_no')
    .not('roll_no', 'is', null);

  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  // Find the highest numeric roll_no and add 1
  let maxRollNo = 0;
  (data || []).forEach(u => {
    const num = parseInt(u.roll_no, 10);
    if (!isNaN(num) && num > maxRollNo) maxRollNo = num;
  });

  res.json({ success: true, data: { next_roll_no: String(maxRollNo + 1) }, error_code: null });
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
    .select('id,name,phone,phone_alt,roll_no,address,father_name,date_of_joining,body_type,batch_id,membership_plan,membership_expiry,fees_status,status,role,is_frozen,freeze_start_date,must_change_password,created_at', { count: 'exact' })
    .order('created_at', { ascending: false });

  if (!all) q = q.range(from, to);
  if (status) q = q.eq('status', status);
  if (search) q = q.or(`name.ilike.%${search}%,phone.ilike.%${search}%,roll_no.ilike.%${search}%`);

  let { data, error, count } = await q;
  if (error && (hasMissingColumn(error, 'is_frozen') || hasMissingColumn(error, 'freeze_start_date'))) {
    let fallbackQ = supabase
      .from('users')
      .select('id,name,phone,phone_alt,roll_no,address,father_name,date_of_joining,body_type,batch_id,membership_plan,membership_expiry,fees_status,status,role,must_change_password,created_at', { count: 'exact' })
      .order('created_at', { ascending: false });

    if (!all) fallbackQ = fallbackQ.range(from, to);
    if (status) fallbackQ = fallbackQ.eq('status', status);
    if (search) fallbackQ = fallbackQ.or(`name.ilike.%${search}%,phone.ilike.%${search}%,roll_no.ilike.%${search}%`);

    ({ data, error, count } = await fallbackQ);
    data = (data || []).map((u) => ({ ...u, is_frozen: false, freeze_start_date: null }));
  }
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Users fetched', data: data || [], total_count: count || 0, page, limit, error_code: null });
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

  if (role && id === req.user.userId) {
    return res.status(400).json({ success: false, message: 'You cannot change your own role.', error_code: 'SELF_ROLE_CHANGE' });
  }

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

  // Fetch all batches for batch_name -> batch_id resolution
  const { data: batchList } = await supabase.from('batches').select('id, name');
  const batchMap = {};
  (batchList || []).forEach(b => { batchMap[b.name.toLowerCase()] = b.id; });

  const results = { created: 0, failed: [], total: records.length };
  const validRecords = records.filter((r) => {
    if (!r.name || !r.phone) {
      results.failed.push({ phone: r.phone || '?', reason: 'Missing name or phone' });
      return false;
    }
    return true;
  });

  const passwordHashes = await Promise.all(validRecords.map((r) => bcrypt.hash(r.password || 'samgym', 10)));

  // Normalize DD-MM-YYYY or DD/MM/YYYY -> YYYY-MM-DD
  const normalizeDate = (val) => {
    if (!val) return null;
    // already YYYY-MM-DD
    if (/^\d{4}-\d{2}-\d{2}$/.test(val)) return val;
    // DD-MM-YYYY or DD/MM/YYYY
    const m = val.match(/^(\d{2})[-\/](\d{2})[-\/](\d{4})$/);
    if (m) return `${m[3]}-${m[2]}-${m[1]}`;
    return val; // pass through, let DB error naturally
  };

  const allRows = validRecords.map((r, i) => ({
    name: r.name, phone: r.phone, phone_alt: r.phone_alt || null,
    password_hash: passwordHashes[i], roll_no: r.roll_no || null, address: r.address || null,
    father_name: r.father_name || null, date_of_joining: normalizeDate(r.date_of_joining),
    body_type: r.body_type || null, membership_plan: r.membership_plan || 'Standard',
    membership_expiry: normalizeDate(r.membership_expiry),
    fees_status: r.fees_status || 'paid',
    notes: r.notes || null,
    batch_id: r.batch_name ? (batchMap[r.batch_name.toLowerCase()] || null) : null,
    must_change_password: true,
  }));

  // Insert row by row for precise per-row error reporting
  for (const row of allRows) {
    const { error } = await supabase.from('users').insert([row]);
    if (error) {
      const isDuplicate = error.message?.toLowerCase().includes('duplicate') || error.code === '23505';
      results.failed.push({
        phone: row.phone,
        reason: isDuplicate ? 'Duplicate phone number already exists' : error.message,
      });
    } else {
      results.created += 1;
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
  const today = getTodayISTStr();
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
  const today = getTodayISTStr();
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
  const end = getNowISTDate();
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
  const today = getTodayISTStr();
  const { data: attData, error } = await supabaseLogs.from('attendance')
    .select('id,user_id,date,time_in,time_out')
    .eq('date', today)
    .order('time_in', { ascending: false });

  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  // Application-level Join
  let mappedData = [];
  if (attData && attData.length > 0) {
    const userIds = [...new Set(attData.map(a => a.user_id).filter(Boolean))];
    const { data: userData } = await supabase.from('users').select('id,name,phone,roll_no').in('id', userIds);
    const userMap = {};
    (userData || []).forEach(u => { userMap[u.id] = u; });

    mappedData = attData.map(a => ({
      ...a,
      users: userMap[a.user_id] || null
    }));
  }

  res.json({ success: true, message: "Today's attendance", data: mappedData, error_code: null });
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

  const { data: attData, error } = await supabaseLogs
    .from('attendance')
    .select('id,user_id,date,time_in,time_out')
    .gte('date', from)
    .lte('date', to)
    .order('date', { ascending: false })
    .order('time_in', { ascending: false });

  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  // Application-level Join
  let mappedData = [];
  if (attData && attData.length > 0) {
    const userIds = [...new Set(attData.map(a => a.user_id).filter(Boolean))];
    const { data: userData } = await supabase.from('users').select('id,name,phone,roll_no').in('id', userIds);
    const userMap = {};
    (userData || []).forEach(u => { userMap[u.id] = u; });

    mappedData = attData.map(a => ({
      ...a,
      users: userMap[a.user_id] || null
    }));
  }

  res.json({ success: true, message: 'Attendance report', data: mappedData, error_code: null });
});

// ─── Revenue summary (admin) ────────────────────────────────────────────────
router.get('/reports/revenue', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabase
    .from('users')
    .select('fees_status,role')
    .neq('role', 'admin');

  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  const summary = (data || []).reduce((acc, user) => {
    const amount = 0; // fees_amount missing in DB
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

  const { data: existing } = await supabaseLogs.from('attendance').select('id').eq('user_id', user_id).eq('date', date).maybeSingle();

  let result;
  if (existing) {
    const { data, error } = await supabaseLogs.from('attendance').update({ time_in: time_in || existing.time_in, time_out }).eq('id', existing.id).select().single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
    result = data;
  } else {
    const { data, error } = await supabaseLogs.from('attendance').insert([{ user_id, date, time_in, time_out }]).select().single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'INSERT_ERROR' });
    result = data;
  }

  res.json({ success: true, message: 'Attendance record saved', data: result, error_code: null });
});

// ─── User-specific attendance history (admin) ─────────────────────────────
router.get('/attendance/user/:userId', authMiddleware(['admin']), async (req, res) => {
  const { data, error } = await supabaseLogs.from('attendance').select('*').eq('user_id', req.params.userId).order('date', { ascending: false }).limit(90);
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
  const { data, error } = await supabase.from('templates').update({ message, updated_at: getNowISTDate() }).eq('id', req.params.id).select().single();
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

  // Trigger Push Notification if active
  if (is_active) {
    await sendToAll(title || 'New Announcement', content || 'Check the app for details', { type: 'announcement', id: data.id.toString() })
      .catch(() => {});
  }

  res.json({ success: true, message: 'Announcement created', data, error_code: null });
});

router.put('/announcements/:id', authMiddleware(['admin']), async (req, res) => {
  const { title, content, is_active } = req.body;

  const { data, error } = await supabase.from('announcements').update({ title, content, is_active }).eq('id', req.params.id).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });

  // Trigger Push Notification if active
  if (is_active) {
    await sendToAll(title || 'Updated Announcement', content || 'Check the app for details', { type: 'announcement', id: data.id.toString() })
      .catch(err => console.error('Push failed:', err));
  }

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



/**
 * Auto-checkout users who are past their batch time or if the gym closed.
 * Also sends a 10-minute warning.
 */
router.get('/attendance/auto-checkout', authMiddleware(['admin']), async (req, res) => {
  try {
    const gymStatus = await getGymStatus(supabase);
    const now = getNowIST();
    const currentTimeStr = now.toFormat('HH:mm:ss');
    const results = [];

    // 1. Get all active sessions
    const { data: activeSessions, error: sessionError } = await supabaseLogs
      .from('attendance')
      .select('id, user_id, date, time_in')
      .is('time_out', null);

    if (sessionError) throw sessionError;
    if (!activeSessions || activeSessions.length === 0) {
      return res.json({ success: true, message: 'No active sessions found', count: 0 });
    }

    // 2. Hydrate sessions with user data (batch_id, name)
    const userIds = [...new Set(activeSessions.map(s => s.user_id).filter(Boolean))];
    const { data: usersData } = await supabase.from('users').select('id, name, batch_id').in('id', userIds);
    const userMap = {};
    (usersData || []).forEach(u => { userMap[u.id] = u; });

    // 3. Evaluate each session
    const morning = gymStatus.batches.morning;
    const evening = gymStatus.batches.evening;

    const getTargetBatch = (batchId) => {
      if (batchId === morning.id) return morning;
      if (batchId === evening.id) return evening;
      return null;
    };

    /**
     * Helper to check if it's exactly 10 minutes before a time string (HH:mm:ss)
     */
    const isWarningTime = (endTimeStr) => {
      if (!endTimeStr) return false;
      const end = DateTime.fromFormat(endTimeStr, 'HH:mm:ss', { zone: IST_TZ });
      const warningStart = end.minus({ minutes: 10 });
      const warningEnd = end.minus({ minutes: 9 });
      // If now is between (end - 10m) and (end - 9m), it's warning window for this 1-min cron run
      return now >= warningStart && now < warningEnd;
    };

    for (const session of activeSessions) {
      const user = userMap[session.user_id] || {};
      const batch = getTargetBatch(user.batch_id);
      
      // -- A. 15-MINUTE WARNING (with duplicate prevention) --
      // We check if a warning was already sent today for this user
      if (batch) {
        const end = DateTime.fromFormat(batch.end_time, 'HH:mm:ss', { zone: IST_TZ });
        const warningWindowStart = end.minus({ minutes: 15 });
        const warningWindowEnd = end.minus({ minutes: 5 });

        if (now >= warningWindowStart && now < warningWindowEnd) {
          // Check if already notified today
          const { data: alreadyNotified } = await supabaseLogs
            .from('notifications')
            .select('id')
            .eq('user_id', session.user_id)
            .eq('type', 'session_warning')
            .gte('created_at', now.startOf('day').toISO())
            .maybeSingle();

          if (!alreadyNotified) {
            const title = 'Gym Session Ending';
            const message = `Your session in the ${batch.name} is ending in 10-15 minutes. Please prepare to check out.`;
            
            await sendToUser(session.user_id, title, message, { type: 'session_warning', batch_name: batch.name }).catch(() => {});
            
            await supabaseLogs.from('notifications').insert([{
              user_id: session.user_id,
              title,
              message,
              type: 'session_warning',
              created_at: now.toISO()
            }]);

            results.push({ user: user.name, action: 'notified_warning' });
          }
          continue; 
        }
      }

      // -- B. AUTO-CHECKOUT (BATCH END OR GYM CLOSED) --
      let shouldCheckout = false;
      let checkoutTime = null;
      let reason = '';
      let type = 'auto_checkout';

      if (batch && currentTimeStr >= batch.end_time) {
        shouldCheckout = true;
        checkoutTime = batch.end_time;
        reason = `End of ${batch.name}`;
      } else if (!gymStatus.is_open) {
        shouldCheckout = true;
        checkoutTime = currentTimeStr;
        reason = gymStatus.is_holiday ? `Holiday: ${gymStatus.holiday_reason}` : 'Gym Closed';
      }

      if (shouldCheckout) {
        const { error: updateError } = await supabaseLogs
          .from('attendance')
          .update({ 
            time_out: now.set({ 
              hour: parseInt(checkoutTime.split(':')[0]), 
              minute: parseInt(checkoutTime.split(':')[1]), 
              second: 0 
            }).toISO(),
            updated_at: now.toISO()
          })
          .eq('id', session.id);

        if (!updateError) {
          const title = 'Auto-Checkout Complete';
          const message = `You have been checked out automatically. Reason: ${reason}.`;
          
          await sendToUser(session.user_id, title, message, { type, reason }).catch(() => {});
          
          await supabaseLogs.from('notifications').insert([{
            user_id: session.user_id,
            title,
            message,
            type,
            created_at: now.toISO()
          }]);

          results.push({ user: user.name, action: 'auto_checkout', reason });
        }
      }
    }

    res.json({ success: true, results, count: results.length });
  } catch (error) {
    console.error('❌ Auto-checkout error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * Periodic Membership Renewal Reminders
 */
router.get('/notifications/membership-reminders', authMiddleware(['admin']), async (req, res) => {
  try {
    // Get "today" in IST
    const nowIST = getNowIST();
    const today = nowIST.startOf('day');

    const getTargetDate = (offset) => {
      return today.plus({ days: offset }).toISODate();
    };

    const target5 = getTargetDate(5);
    const target2 = getTargetDate(2);
    const target1 = getTargetDate(1);

    // 1. Fetch users for reminders
    const { data: reminderUsers, error: reminderError } = await supabase
      .from('users')
      .select('id, name, membership_expiry')
      .in('membership_expiry', [target5, target2, target1]);

    if (reminderError) throw reminderError;

    for (const user of reminderUsers) {
      const daysLeft = Math.round(toIST(user.membership_expiry).diff(today, 'days').days);
      let message = "";
      const title = 'Membership Renewal';
      
      if (daysLeft === 5) message = "Your membership expires in 5 days! Plan ahead to keep your streak going. 💪";
      else if (daysLeft === 2) message = "Your membership expires in 2 days. Renew today to avoid any interruption! ⏳";
      else if (daysLeft === 1) message = "Last call! Your membership expires tomorrow. Don't miss your next workout! 🏃‍♂️";

      if (message) {
        // Send Push
        await sendToUser(user.id, title, message, { type: 'membership_reminder' }).catch(() => {});
        
        // Save to DB
        await supabaseLogs.from('notifications').insert([{
          user_id: user.id,
          title,
          message,
          type: 'membership_reminder',
          created_at: nowIST.toISO()
        }]).catch(() => {});
      }
    }

    // 2. Fetch users who are overdue (expired before today)
    const { data: overdueUsers, error: overdueError } = await supabase
      .from('users')
      .select('id, name, membership_expiry')
      .lt('membership_expiry', today.toISODate())
      .eq('status', 'active'); // Only notify active users who forgot to renew

    if (overdueError) throw overdueError;

    for (const user of overdueUsers) {
      const title = 'Plan Overdue';
      const message = "Your membership has expired. Please renew your plan to keep your account up to date! 🚨";
      
      // Send Push
      await sendToUser(user.id, title, message, { type: 'membership_overdue' }).catch(() => {});

      // Save to DB
      await supabaseLogs.from('notifications').insert([{
        user_id: user.id,
        title,
        message,
        type: 'membership_overdue',
        created_at: nowIST.toISO()
      }]).catch(() => {});
    }

    res.json({ 
      success: true, 
      reminders_sent: reminderUsers.length, 
      overdue_notified: overdueUsers.length 
    });
  } catch (error) {
    console.error('❌ Membership reminders error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── Storage & Data Management ───────────────────────────────────────────────

/**
 * GET /admin/storage/overview
 * Combined storage usage from both Supabase projects.
 */
router.get('/storage/overview', authMiddleware(['admin']), async (req, res) => {
  try {
    const getDbSizeSafe = async (client, projectLabel) => {
      try {
        if (!client || typeof client.rpc !== 'function') {
          console.warn(`⚠️ Project ${projectLabel} client not fully initialized or missing RPC method.`);
          return 0;
        }
        const { data, error } = await client.rpc('get_db_size');
        if (error) {
          console.error(`❌ Project ${projectLabel} RPC error (get_db_size):`, error.message, error.hint || '');
          return 0;
        }
        return data || 0;
      } catch (err) {
        console.error(`❌ Unexpected error in getDbSizeSafe for ${projectLabel}:`, err.message);
        return 0;
      }
    };

    const [coreSize, logsSize] = await Promise.all([
      getDbSizeSafe(supabase, 'Core'),
      getDbSizeSafe(supabaseLogs, 'Logs')
    ]);

    const totalSize = coreSize + logsSize;
    const totalSizeMB = parseFloat((totalSize / (1024 * 1024)).toFixed(2));
    
    // Each project has a 500MB limit, so 1000MB combined
    const limitMB = 1000;
    const remainingMB = Math.max(0, parseFloat((limitMB - totalSizeMB).toFixed(2)));
    const usedPercent = Math.min(Math.round((totalSizeMB / limitMB) * 100), 100);

    res.json({
      success: true,
      size_mb: totalSizeMB,
      storage_limit_mb: limitMB,
      used_percent: usedPercent,
      remaining_mb: remainingMB,
      core_size_mb: parseFloat((coreSize / (1024 * 1024)).toFixed(2)),
      logs_size_mb: parseFloat((logsSize / (1024 * 1024)).toFixed(2))
    });
  } catch (error) {
    console.error('❌ Storage overview error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * GET /admin/storage/tables
 * Lists tables and sizes from both projects.
 */
router.get('/storage/tables', authMiddleware(['admin']), async (req, res) => {
  try {
    const fetchTables = async (client, projectLabel) => {
      try {
        if (!client || typeof client.rpc !== 'function') {
          console.warn(`⚠️ Project ${projectLabel} client not fully initialized or missing RPC method.`);
          return [];
        }
        const { data, error } = await client.rpc('get_table_sizes');
        if (error) {
          console.error(`❌ Project ${projectLabel} RPC error (get_table_sizes):`, error.message, error.hint || '');
          return [];
        }

        const deletableTables = ['attendance', 'notifications', 'announcements', 'qr_logs', 'visit_logs'];

        return (data || []).map(t => ({
          ...t,
          project: projectLabel,
          size_mb: ((t.size_bytes || 0) / (1024 * 1024)).toFixed(2),
          is_deletable: deletableTables.includes(t.table_name)
        }));
      } catch (err) {
        console.error(`❌ Unexpected error in fetchTables for ${projectLabel}:`, err.message);
        return [];
      }
    };

    const [coreTables, logsTables] = await Promise.all([
      fetchTables(supabase, 'Core'),
      fetchTables(supabaseLogs, 'Logs')
    ]);

    // Combine and sort by size
    const allTables = [...coreTables, ...logsTables].sort((a, b) => (b.size_bytes || 0) - (a.size_bytes || 0));
    
    // Calculate percentages relative to the 1000MB combined limit
    const totalLimitBytes = 1000 * 1024 * 1024;
    const finalTables = allTables.map(t => ({
      ...t,
      percent_of_total: parseFloat(((t.size_bytes / totalLimitBytes) * 100).toFixed(2))
    }));

    res.json(finalTables);
  } catch (error) {
    console.error('❌ Storage tables error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * GET /admin/storage/count
 * Preview number of rows to be deleted.
 */
router.get('/storage/count', authMiddleware(['admin']), async (req, res) => {
  const { table, from_date, to_date, project } = req.query;
  if (!table || !from_date || !to_date) return res.status(400).json({ success: false, message: 'Missing parameters' });

  try {
    const client = project === 'Logs' ? supabaseLogs : supabase;
    
    // Determine the date column to use
    // Attendance uses 'date', others usually use 'created_at'
    const dateCol = table === 'attendance' ? 'date' : 'created_at';
    
    const { count, error } = await client
      .from(table)
      .select('*', { count: 'exact', head: true })
      .gte(dateCol, table === 'attendance' ? from_date : `${from_date}T00:00:00`)
      .lte(dateCol, table === 'attendance' ? to_date : `${to_date}T23:59:59`);

    if (error) throw error;
    res.json({ success: true, row_count: count });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

/**
 * DELETE /admin/storage/clean
 * Bulk delete data from specified table and range.
 */
router.delete('/storage/clean', authMiddleware(['admin']), async (req, res) => {
  const { table, from_date, to_date, project } = req.body;
  if (!table || !from_date || !to_date) return res.status(400).json({ success: false, message: 'Missing parameters' });

  try {
    const client = project === 'Logs' ? supabaseLogs : supabase;
    const dateCol = table === 'attendance' ? 'date' : 'created_at';

    const { error } = await client
      .from(table)
      .delete()
      .gte(dateCol, table === 'attendance' ? from_date : `${from_date}T00:00:00`)
      .lte(dateCol, table === 'attendance' ? to_date : `${to_date}T23:59:59`);

    if (error) throw error;
    res.json({ success: true, message: `Successfully cleared data from ${table} (${project})` });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;

