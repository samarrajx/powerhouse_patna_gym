const express = require('express');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// GET /schedule/weekly — all 7 days
router.get('/weekly', async (req, res) => {
  const { data, error } = await supabase.from('weekly_schedule').select('*').order('id');
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Weekly schedule', data: data || [], error_code: null });
});

// PUT /schedule/weekly/:day — admin update a day
router.put('/weekly/:day', authMiddleware(['admin']), async (req, res) => {
  const { day } = req.params;
  const { is_open, open_time, close_time } = req.body;
  const { data, error } = await supabase.from('weekly_schedule').update({ is_open, open_time, close_time, updated_at: new Date().toISOString() }).eq('day_of_week', day).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'UPDATE_SCHEDULE', performed_by: req.user.userId, details: { day, is_open, open_time, close_time } }]);
  res.json({ success: true, message: `${day} schedule updated`, data, error_code: null });
});

// GET /schedule/holidays
router.get('/holidays', async (req, res) => {
  const { data, error } = await supabase.from('holidays').select('*').order('date', { ascending: false });
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Holidays', data: data || [], error_code: null });
});

// POST /schedule/holidays — admin add holiday
router.post('/holidays', authMiddleware(['admin']), async (req, res) => {
  const { date, reason, is_closed = true } = req.body;
  if (!date || !reason) return res.status(400).json({ success: false, message: 'date and reason required', error_code: 'MISSING_FIELDS' });
  const { data, error } = await supabase.from('holidays').insert([{ date, reason, is_closed }]).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'INSERT_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'ADD_HOLIDAY', performed_by: req.user.userId, details: { date, reason } }]);
  res.json({ success: true, message: 'Holiday added', data, error_code: null });
});

// DELETE /schedule/holidays/:id — admin remove holiday
router.delete('/holidays/:id', authMiddleware(['admin']), async (req, res) => {
  const { error } = await supabase.from('holidays').delete().eq('id', req.params.id);
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'DELETE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'DELETE_HOLIDAY', performed_by: req.user.userId, details: { id: req.params.id } }]);
  res.json({ success: true, message: 'Holiday removed', error_code: null });
});

module.exports = router;
