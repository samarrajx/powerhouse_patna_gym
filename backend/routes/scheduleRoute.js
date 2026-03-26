const express = require('express');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');

const router = express.Router();
const SLOT_FALLBACKS = {
  morning: { name: 'Morning Batch', start_time: '05:30:00', end_time: '09:30:00' },
  evening: { name: 'Evening Batch', start_time: '16:00:00', end_time: '20:00:00' },
};

const normalizeSlot = (name = '') => {
  const lower = name.toLowerCase();
  if (lower.includes('morning')) return 'morning';
  if (lower.includes('evening')) return 'evening';
  return null;
};

// GET /schedule/weekly — all 7 days
router.get('/weekly', async (req, res) => {
  const { data, error } = await supabase.from('weekly_schedule').select('*').order('id');
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });
  res.json({ success: true, message: 'Weekly schedule', data: data || [], error_code: null });
});

// PUT /schedule/weekly/:day — admin update a day
router.put('/weekly/:day', authMiddleware(['admin']), async (req, res) => {
  const { day } = req.params;
  const normalizedDay = `${day.slice(0, 1).toUpperCase()}${day.slice(1).toLowerCase()}`;
  const { is_open, open_time, close_time } = req.body;
  const { data, error } = await supabase.from('weekly_schedule').update({ is_open, open_time, close_time, updated_at: new Date().toISOString() }).ilike('day_of_week', normalizedDay).select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
  
  await supabase.from('audit_logs').insert([{ action: 'UPDATE_SCHEDULE', performed_by: req.user.userId, details: { day: normalizedDay, is_open, open_time, close_time } }]);
  
  // Trigger notification
  await supabase.from('notifications').insert([{
    title: 'SCHEDULE UPDATE',
    message: `${normalizedDay} schedule has been updated. The gym is now ${is_open ? 'OPEN' : 'CLOSED'} during the specified hours.`,
    type: 'schedule',
    user_id: null
  }]);

  res.json({ success: true, message: `${normalizedDay} schedule updated`, data, error_code: null });
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
  
  // Trigger notification
  await supabase.from('notifications').insert([{
    title: 'NEW HOLIDAY / CLOSURE',
    message: `The gym will be ${is_closed ? 'CLOSED' : 'OPEN'} on ${new Date(date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}. Reason: ${reason}`,
    type: 'holiday',
    user_id: null
  }]);

  res.json({ success: true, message: 'Holiday added', data, error_code: null });
});

// DELETE /schedule/holidays/:id — admin remove holiday
router.delete('/holidays/:id', authMiddleware(['admin']), async (req, res) => {
  const { error } = await supabase.from('holidays').delete().eq('id', req.params.id);
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'DELETE_ERROR' });
  await supabase.from('audit_logs').insert([{ action: 'DELETE_HOLIDAY', performed_by: req.user.userId, details: { id: req.params.id } }]);
  res.json({ success: true, message: 'Holiday removed', error_code: null });
});

// GET /schedule/batches — fetch morning/evening slot timings
router.get('/batches', async (req, res) => {
  const { data, error } = await supabase.from('batches').select('id,name,start_time,end_time').order('name');
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  const slots = {
    morning: { slot: 'morning', ...SLOT_FALLBACKS.morning, id: null },
    evening: { slot: 'evening', ...SLOT_FALLBACKS.evening, id: null },
  };

  (data || []).forEach((batch) => {
    const slot = normalizeSlot(batch.name);
    if (!slot) return;
    slots[slot] = {
      slot,
      id: batch.id,
      name: batch.name,
      start_time: batch.start_time || SLOT_FALLBACKS[slot].start_time,
      end_time: batch.end_time || SLOT_FALLBACKS[slot].end_time,
    };
  });

  res.json({ success: true, message: 'Batch timings', data: [slots.morning, slots.evening], error_code: null });
});

// PUT /schedule/batches/:slot — update morning/evening slot timings
router.put('/batches/:slot', authMiddleware(['admin']), async (req, res) => {
  const slot = (req.params.slot || '').toLowerCase();
  if (!['morning', 'evening'].includes(slot)) {
    return res.status(400).json({ success: false, message: 'Slot must be morning or evening', error_code: 'INVALID_SLOT' });
  }

  const { start_time, end_time } = req.body;
  if (!start_time || !end_time) {
    return res.status(400).json({ success: false, message: 'start_time and end_time required', error_code: 'MISSING_FIELDS' });
  }

  const defaultName = SLOT_FALLBACKS[slot].name;
  const { data: existing, error: fetchErr } = await supabase.from('batches').select('id,name').ilike('name', `%${slot}%`).limit(1).maybeSingle();
  if (fetchErr) return res.status(400).json({ success: false, message: fetchErr.message, error_code: 'FETCH_ERROR' });

  let updated;
  if (existing?.id) {
    const { data, error } = await supabase.from('batches').update({ start_time, end_time }).eq('id', existing.id).select('id,name,start_time,end_time').single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
    updated = data;
  } else {
    const { data, error } = await supabase.from('batches').insert([{ name: defaultName, start_time, end_time }]).select('id,name,start_time,end_time').single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'INSERT_ERROR' });
    updated = data;
  }

  await supabase.from('audit_logs').insert([{
    action: 'UPDATE_BATCH_TIMING',
    performed_by: req.user.userId,
    details: { slot, start_time, end_time, batch_id: updated.id },
  }]);

  // Trigger notification
  await supabase.from('notifications').insert([{
    title: 'TIMING UPDATE',
    message: `The ${slot.toUpperCase()} batch timings have been updated to ${start_time.slice(0, 5)} - ${end_time.slice(0, 5)}.`,
    type: 'timing',
    user_id: null
  }]);

  res.json({
    success: true,
    message: `${slot} batch timing updated`,
    data: { slot, ...updated },
    error_code: null,
  });
});

module.exports = router;
