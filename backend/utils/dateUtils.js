const { DateTime } = require('luxon');

/**
 * Get current time in Asia/Kolkata
 */
function getNowIST() {
  return DateTime.now().setZone('Asia/Kolkata');
}

/**
 * Get today's date string in YYYY-MM-DD (IST)
 */
function getTodayISTStr() {
  return getNowIST().toISODate();
}

/**
 * Convert any date to IST DateTime
 */
function toIST(date) {
  if (!date) return getNowIST();
  return DateTime.fromJSDate(new Date(date)).setZone('Asia/Kolkata');
}

/**
 * Get a JS Date object set to IST
 */
function getNowISTDate() {
  return getNowIST().toJSDate();
}

module.exports = {
  getNowIST,
  getTodayISTStr,
  toIST,
  getNowISTDate
};
