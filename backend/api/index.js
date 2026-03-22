const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { apiLimiter } = require('../middleware/rateLimit');

const authRoute     = require('../routes/authRoute');
const qrRoute       = require('../routes/qrRoute');
const attendanceRoute = require('../routes/attendanceRoute');
const adminRoute    = require('../routes/adminRoute');
const scheduleRoute = require('../routes/scheduleRoute');
const notificationRoute = require('../routes/notificationRoute');

const app = express();

app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*', methods: ['GET','POST','PUT','DELETE','PATCH'] }));
app.use(express.json({ limit: '10mb' }));
app.use(apiLimiter);

// Routes
app.use('/api/auth', authRoute);
app.use('/api/qr', qrRoute);
app.use('/api/attendance', attendanceRoute);
app.use('/api/admin', adminRoute);
app.use('/api/schedule', scheduleRoute);
app.use('/api/notifications', notificationRoute);

// GET /api/gym/status — check today holiday + weekly schedule
app.get('/api/gym/status', async (req, res) => {
  const supabase = require('../db/supabase');
  const today = new Date().toISOString().split('T')[0];
  const day = new Date().toLocaleDateString('en-US', { weekday: 'long' }).toLowerCase();

  const [{ data: holiday }, { data: schedule }] = await Promise.all([
    supabase.from('holidays').select('is_closed').eq('date', today).single(),
    supabase.from('weekly_schedule').select('*').eq('day_of_week', day).single(),
  ]);

  const is_holiday = holiday != null && holiday.is_closed;
  const day_schedule = schedule || { is_open: true, open_time: '05:00', close_time: '22:00' };
  const is_open = !is_holiday && day_schedule.is_open;

  res.json({ success: true, message: 'Gym status', data: { is_open, is_holiday, schedule: day_schedule, holiday_reason: holiday?.reason || null }, error_code: null });
});

// Health check & Root
app.get('/api/health', (req, res) => res.json({ success: true, message: 'Power House API running', timestamp: new Date().toISOString() }));
app.get('/', (req, res) => res.json({ success: true, message: 'Power House Gym API is running! 🏋️', documentation: '/api/health' }));

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal server error', error_code: 'INTERNAL_ERROR' });
});

if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`\n🚀 Power House API running on http://localhost:${PORT}\n`));
}

module.exports = app;
