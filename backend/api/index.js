const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { apiLimiter } = require('../middleware/rateLimit');
const { getNowIST, getNowISTDate } = require('../utils/dateUtils');

const authRoute = require('../routes/authRoute');
const qrRoute = require('../routes/qrRoute');
const attendanceRoute = require('../routes/attendanceRoute');
const adminRoute = require('../routes/adminRoute');
const scheduleRoute = require('../routes/scheduleRoute');
const notificationRoute = require('../routes/notificationRoute');
const userRoute = require('../routes/userRoute');

const IST_TZ = 'Asia/Kolkata';

const getIstNow = () => {
  const now = getNowISTDate();
  const day = now
    .toLocaleDateString('en-US', { weekday: 'long', timeZone: IST_TZ })
    .toLowerCase();
  const date = new Intl.DateTimeFormat('en-CA', { timeZone: IST_TZ }).format(now);
  const time = new Intl.DateTimeFormat('en-GB', {
    timeZone: IST_TZ,
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).format(now);

  return { day, date, time };
};

const app = express();

app.use(helmet({ contentSecurityPolicy: false }));
const ALLOWED_ORIGINS = [
  'https://powerhouse-patna-gym.vercel.app',
  'https://powerhouse-admin.vercel.app',
];
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Vercel cron, server-to-server)
    if (!origin || ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
    callback(new Error('CORS: origin not allowed'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
}));
app.use(express.json({ limit: '10mb' }));
app.use(apiLimiter);

// Routes
app.use('/api/auth', authRoute);
app.use('/api/qr', qrRoute);
app.use('/api/attendance', attendanceRoute);
app.use('/api/admin', adminRoute);
app.use('/api/schedule', scheduleRoute);
app.use('/api/notifications', notificationRoute);
app.use('/api/user', userRoute);

// GET /api/gym/status — check today holiday + weekly schedule
app.get('/api/gym/status', async (req, res) => {
  const supabase = require('../db/supabase');
  const { date: today, day, time: nowTime } = getIstNow();

  const [{ data: holiday }, { data: schedule }, { data: batches }] = await Promise.all([
    supabase.from('holidays').select('is_closed, reason').eq('date', today).maybeSingle(),
    supabase.from('weekly_schedule').select('*').eq('day_of_week', day).maybeSingle(),
    supabase.from('batches').select('id,name,start_time,end_time,is_active'),
  ]);

  const is_holiday = holiday != null && holiday.is_closed;
  const day_schedule = schedule || { is_open: true, open_time: '05:00', close_time: '22:00' };

  const batchTimings = { morning: null, evening: null };
  (batches || []).forEach((batch) => {
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

  const mergedDaySchedule = {
    ...day_schedule,
    open_time: morningSlot.start_time,
    close_time: eveningSlot.end_time,
  };

  const isOpenByDay = !is_holiday && day_schedule.is_open;
  const isInWindow = (start, end) => Boolean(start && end && nowTime >= start && nowTime <= end);
  const inMorningSlot = isInWindow(morningSlot.start_time.slice(0, 8), morningSlot.end_time.slice(0, 8));
  const inEveningSlot = isInWindow(eveningSlot.start_time.slice(0, 8), eveningSlot.end_time.slice(0, 8));
  
  // Gym is open ONLY if it's an open day AND we are in a batch window AND that batch is currently ACTIVE
  const isMorningOpen = inMorningSlot && morningSlot.is_active;
  const isEveningOpen = inEveningSlot && eveningSlot.is_active;
  const is_open = isOpenByDay && (isMorningOpen || isEveningOpen);

  res.json({
    success: true,
    message: 'Gym status',
    data: {
      is_open,
      is_holiday,
      is_open_today: isOpenByDay,
      schedule: mergedDaySchedule,
      batches: {
        morning: morningSlot,
        evening: eveningSlot,
      },
      holiday_reason: holiday?.reason || null,
      timezone: IST_TZ,
      current_time: nowTime,
    },
    error_code: null,
  });
});

// Health check & Root
app.get('/api/health', (req, res) =>
  res.json({
    success: true,
    message: 'Power House API running',
    timestamp: getNowIST().toISO(),
  })
);

app.get('/', (req, res) =>
  res.json({
    success: true,
    message: 'Power House Gym API is running! 🏋️',
    documentation: '/api/health',
  })
);

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error_code: 'INTERNAL_ERROR',
  });
});

if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`\n🚀 Power House API running on http://localhost:${PORT}\n`));
}

module.exports = app;