const { getNowIST, IST_TZ } = require('./dateUtils');

/**
 * Centrally determines if the gym is currently open based on:
 * 1. Holidays
 * 2. Weekly Schedule
 * 3. Active Batch Windows (Morning/Evening)
 */
async function getGymStatus(supabase) {
  const now = getNowIST();
  
  // Format current date/time in IST
  const dayName = now.setLocale('en-US').toFormat('cccc').toLowerCase(); // e.g., 'monday'
  const todayDateStr = now.toISODate(); // YYYY-MM-DD
  const currentTimeStr = now.toFormat('HH:mm:ss');

  const [{ data: holiday }, { data: schedule }, { data: batches }] = await Promise.all([
    supabase.from('holidays').select('is_closed, reason').eq('date', todayDateStr).maybeSingle(),
    supabase.from('weekly_schedule').select('*').eq('day_of_week', dayName).maybeSingle(),
    supabase.from('batches').select('id,name,start_time,end_time,is_active'),
  ]);

  const isHoliday = holiday != null && holiday.is_closed;
  
  // Weekly schedule fallback (if DB entry missing)
  const daySchedule = schedule || { is_open: true, open_time: '05:00:00', close_time: '23:59:59' };

  // Setup Batch slots
  const batchTimings = { morning: null, evening: null };
  const fetchedBatches = batches || [];
  
  fetchedBatches.forEach((batch) => {
    const name = (batch.name || '').toLowerCase();
    if (name.includes('morning')) batchTimings.morning = batch;
    if (name.includes('evening')) batchTimings.evening = batch;
  });

  const defaultMorning = { name: 'Morning Batch', start_time: '05:30:00', end_time: '09:30:00', is_active: true };
  const defaultEvening = { name: 'Evening Batch', start_time: '16:00:00', end_time: '20:00:00', is_active: true };

  const morningSlot = {
    id: batchTimings.morning?.id || null,
    name: batchTimings.morning?.name || defaultMorning.name,
    start_time: batchTimings.morning?.start_time || defaultMorning.start_time,
    end_time: batchTimings.morning?.end_time || defaultMorning.end_time,
    is_active: batchTimings.morning?.is_active ?? true,
  };

  const eveningSlot = {
    id: batchTimings.evening?.id || null,
    name: batchTimings.evening?.name || defaultEvening.name,
    start_time: batchTimings.evening?.start_time || defaultEvening.start_time,
    end_time: batchTimings.evening?.end_time || defaultEvening.end_time,
    is_active: batchTimings.evening?.is_active ?? true,
  };

  const isOpenByDay = !isHoliday && daySchedule.is_open;
  
  /**
   * Helper to check if now is inside a HH:mm:ss window
   */
  const isInWindow = (start, end) => {
    if (!start || !end) return false;
    // Normalize to 8 characters (HH:mm:ss)
    const s = start.length === 5 ? `${start}:00` : start.slice(0, 8);
    const e = end.length === 5 ? `${end}:00` : end.slice(0, 8);
    return currentTimeStr >= s && currentTimeStr <= e;
  };

  const isMorningOpen = isInWindow(morningSlot.start_time, morningSlot.end_time) && morningSlot.is_active;
  const isEveningOpen = isInWindow(eveningSlot.start_time, eveningSlot.end_time) && eveningSlot.is_active;
  
  // Final decision: Must be an open day AND within one of the active batch windows
  const is_open = isOpenByDay && (isMorningOpen || isEveningOpen);

  return {
    is_open,
    is_holiday: isHoliday,
    holiday_reason: holiday?.reason || null,
    is_open_today: isOpenByDay,
    current_time: currentTimeStr,
    current_day: dayName,
    current_date: todayDateStr,
    batches: {
      morning: morningSlot,
      evening: eveningSlot
    },
    schedule: {
      ...daySchedule,
      // Overwrite display timings with the actual batch windows for dashboard clarity
      open_time: morningSlot.start_time,
      close_time: eveningSlot.end_time
    }
  };
}

module.exports = { getGymStatus };
