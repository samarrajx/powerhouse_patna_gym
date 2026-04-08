const { getNowISTDate, IST_TZ } = require('./dateUtils');

/**
 * Centrally determines if the gym is currently open based on:
 * 1. Holidays
 * 2. Weekly Schedule
 * 3. Active Batch Windows (Morning/Evening)
 */
async function getGymStatus(supabase) {
  const now = getNowISTDate();
  
  // Format current date/time in IST
  const day = now.toLocaleDateString('en-US', { weekday: 'long', timeZone: IST_TZ }).toLowerCase();
  const todayDateStr = new Intl.DateTimeFormat('en-CA', { timeZone: IST_TZ }).format(now);
  const currentTimeStr = new Intl.DateTimeFormat('en-GB', {
    timeZone: IST_TZ,
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).format(now);

  const [{ data: holiday }, { data: schedule }, { data: batches }] = await Promise.all([
    supabase.from('holidays').select('is_closed, reason').eq('date', todayDateStr).maybeSingle(),
    supabase.from('weekly_schedule').select('*').eq('day_of_week', day).maybeSingle(),
    supabase.from('batches').select('id,name,start_time,end_time,is_active'),
  ]);

  const isHoliday = holiday != null && holiday.is_closed;
  const daySchedule = schedule || { is_open: true, open_time: '05:00', close_time: '22:00' };

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
    name: batchTimings.morning?.name || defaultMorning.name,
    start_time: batchTimings.morning?.start_time || defaultMorning.start_time,
    end_time: batchTimings.morning?.end_time || defaultMorning.end_time,
    is_active: batchTimings.morning?.is_active ?? true,
  };

  const eveningSlot = {
    name: batchTimings.evening?.name || defaultEvening.name,
    start_time: batchTimings.evening?.start_time || defaultEvening.start_time,
    end_time: batchTimings.evening?.end_time || defaultEvening.end_time,
    is_active: batchTimings.evening?.is_active ?? true,
  };

  const isOpenByDay = !isHoliday && daySchedule.is_open;
  
  const isInWindow = (start, end) => {
    const s = start.slice(0, 8);
    const e = end.slice(0, 8);
    return Boolean(s && e && currentTimeStr >= s && currentTimeStr <= e);
  };

  const isMorningOpen = isInWindow(morningSlot.start_time, morningSlot.end_time) && morningSlot.is_active;
  const isEveningOpen = isInWindow(eveningSlot.start_time, eveningSlot.end_time) && eveningSlot.is_active;
  
  // Final decision
  const is_open = isOpenByDay && (isMorningOpen || isEveningOpen);

  return {
    is_open,
    is_holiday: isHoliday,
    holiday_reason: holiday?.reason || null,
    is_open_today: isOpenByDay,
    current_time: currentTimeStr,
    current_day: day,
    current_date: todayDateStr,
    batches: {
      morning: morningSlot,
      evening: eveningSlot
    },
    schedule: {
      ...daySchedule,
      open_time: morningSlot.start_time,
      close_time: eveningSlot.end_time
    }
  };
}

module.exports = { getGymStatus };
