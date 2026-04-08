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

// Trust proxy for Vercel/proxies (required for express-rate-limit)
app.set('trust proxy', 1);

app.use(helmet({ contentSecurityPolicy: false }));
const ALLOWED_ORIGINS = [
  'https://powerhouse-patna-gym.vercel.app',
  'https://powerhouse-admin.vercel.app',
  'http://localhost:5173',
  'http://localhost:5174',
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

// GET /api/gym/status — unified status check
app.get('/api/gym/status', async (req, res) => {
  const supabase = require('../db/supabase');
  const { getGymStatus } = require('../utils/gymStatus');

  try {
    const status = await getGymStatus(supabase);
    res.json({
      success: true,
      message: 'Gym status',
      data: status,
      error_code: null,
    });
  } catch (err) {
    console.error('[STATUS] Error fetching gym status:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch gym status' });
  }
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