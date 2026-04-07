const express = require('express');
const { getNowIST, toIST } = require('../utils/dateUtils');
const supabase = require('../db/supabase');
const authMiddleware = require('../middleware/auth');
const { sendGlobalPush } = require('../utils/fcm');

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
  const normalizedDay = day.trim().toLowerCase();
  const { is_open, open_time, close_time } = req.body;
  const { data, error } = await supabase.from('weekly_schedule')
    .update({ is_open, open_time, close_time, updated_at: getNowIST().toISO() })
    .eq('day_of_week', normalizedDay)
    .select().single();
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
  

  
  // Trigger notification
  await supabase.from('notifications').insert([{
    title: 'SCHEDULE UPDATE',
    message: `${normalizedDay} schedule has been updated. The gym is now ${is_open ? 'OPEN' : 'CLOSED'} during the specified hours.`,
    type: 'schedule',
    user_id: null
  }]);

  // Push notification
  await sendGlobalPush('SCHEDULE UPDATE', `${normalizedDay} schedule updated. The gym is now ${is_open ? 'OPEN' : 'CLOSED'}.`);

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
  

  
  // Trigger notification
  await supabase.from('notifications').insert([{
    title: 'NEW HOLIDAY / CLOSURE',
    message: `The gym will be ${is_closed ? 'CLOSED' : 'OPEN'} on ${toIST(date).setLocale('en-IN').toLocaleString({ day: 'numeric', month: 'short' })}. Reason: ${reason}`,
    type: 'holiday',
    user_id: null
  }]);

  // Push notification
  await sendGlobalPush('HOLIDAY ALERT', `Gym will be ${is_closed ? 'CLOSED' : 'OPEN'} on ${toIST(date).setLocale('en-IN').toLocaleString({ day: 'numeric', month: 'short' })}. Reason: ${reason}`);

  res.json({ success: true, message: 'Holiday added', data, error_code: null });
});

// DELETE /schedule/holidays/:id — admin remove holiday
router.delete('/holidays/:id', authMiddleware(['admin']), async (req, res) => {
  const { error } = await supabase.from('holidays').delete().eq('id', req.params.id);
  if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'DELETE_ERROR' });

  res.json({ success: true, message: 'Holiday removed', error_code: null });
});

// GET /schedule/batches — fetch morning/evening slot timings
router.get('/batches', async (req, res) => {
  const { data, error } = await supabase.from('batches').select('id,name,start_time,end_time,is_active').order('name');
  if (error) return res.status(500).json({ success: false, message: error.message, error_code: 'DB_ERROR' });

  const slots = {
    morning: { slot: 'morning', ...SLOT_FALLBACKS.morning, id: null, is_active: true },
    evening: { slot: 'evening', ...SLOT_FALLBACKS.evening, id: null, is_active: true },
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
      is_active: batch.is_active ?? true,
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

  const { start_time, end_time, is_active = true } = req.body;
  if (!start_time || !end_time) {
    return res.status(400).json({ success: false, message: 'start_time and end_time required', error_code: 'MISSING_FIELDS' });
  }

  const defaultName = SLOT_FALLBACKS[slot].name;
  const { data: existing, error: fetchErr } = await supabase.from('batches').select('id,name').ilike('name', `%${slot}%`).limit(1).maybeSingle();
  if (fetchErr) return res.status(400).json({ success: false, message: fetchErr.message, error_code: 'FETCH_ERROR' });

  let updated;
  if (existing?.id) {
    const { data, error } = await supabase.from('batches').update({ start_time, end_time, is_active }).eq('id', existing.id).select('id,name,start_time,end_time,is_active').single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'UPDATE_ERROR' });
    updated = data;
  } else {
    const { data, error } = await supabase.from('batches').insert([{ name: defaultName, start_time, end_time, is_active }]).select('id,name,start_time,end_time,is_active').single();
    if (error) return res.status(400).json({ success: false, message: error.message, error_code: 'INSERT_ERROR' });
    updated = data;
  }



  // Push notification (Only if requested or for critical changes)
  if (req.query.notify !== 'false') {
    await sendGlobalPush('TIMING UPDATE', `The ${slot.toUpperCase()} batch timings updated. Status: ${is_active ? 'OPEN' : 'CLOSED'}.`);
  }

  res.json({ success: true, message: `${slot} batch timing updated`, data: { slot, ...updated }, error_code: null });
});

// POST /schedule/bulk-update — unified update for schedule and batches
router.post('/bulk-update', authMiddleware(['admin']), async (req, res) => {
  const { weekly, batches: batchUpdates } = req.body;
  
  try {
    // 1. Update Weekly Schedule
    if (weekly && Array.isArray(weekly)) {
      for (const day of weekly) {
        const normalizedDay = day.day_of_week.trim().toLowerCase();
        const { error: updateErr } = await supabase.from('weekly_schedule')
          .update({ is_open: day.is_open, open_time: day.open_time, close_time: day.close_time, updated_at: getNowIST().toISO() })
          .eq('day_of_week', normalizedDay);
        
        if (updateErr) console.error(`Failed to update ${normalizedDay}:`, updateErr.message);
      }
    }

    // 2. Update Batches
    if (batchUpdates && Array.isArray(batchUpdates)) {
      for (const b of batchUpdates) {
         const { data: existing } = await supabase.from('batches').select('id').ilike('name', `%${b.slot}%`).limit(1).maybeSingle();
         if (existing?.id) {
           await supabase.from('batches').update({ start_time: b.start_time, end_time: b.end_time, is_active: b.is_active }).eq('id', existing.id);
         }
      }
    }

    // 3. Audit Log (removed)

    // 4. ONE Notification & ONE Push
    const msg = "Gym operating hours and batch timings have been updated. Please check the dashboard for details.";
    await supabase.from('notifications').insert([{ title: 'OPERATIONS UPDATE', message: msg, type: 'timing', user_id: null }]);
    await sendGlobalPush('OPERATIONS UPDATE', msg);

    res.json({ success: true, message: 'Bulk update successful' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
