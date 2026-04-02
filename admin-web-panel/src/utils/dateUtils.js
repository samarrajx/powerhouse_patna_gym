/**
/**
 * Get current time in Asia/Kolkata timezone
 * @returns {Date}
 */
export const getNowIST = () => {
  const now = new Date();
  // We use Intl.DateTimeFormat to get the string representation in IST, then parse it back to a Date object.
  // Note: This is for display/frontend logic purposes.
  const istString = now.toLocaleString("en-US", { timeZone: "Asia/Kolkata" });
  return new Date(istString);
};

/**
 * Get today's date in YYYY-MM-DD format (IST)
 * @returns {string}
 */
export const getTodayISTStr = () => {
  const now = new Date();
  const year = new Intl.DateTimeFormat('en-US', { year: 'numeric', timeZone: 'Asia/Kolkata' }).format(now);
  const month = new Intl.DateTimeFormat('en-US', { month: '2-digit', timeZone: 'Asia/Kolkata' }).format(now);
  const day = new Intl.DateTimeFormat('en-US', { day: '2-digit', timeZone: 'Asia/Kolkata' }).format(now);
  return `${year}-${month}-${day}`;
};

/**
 * Format a date to local IST display string
 * @param {Date|string} date 
 * @returns {string}
 */
export const formatIST = (date, options = { weekday: 'long', day: 'numeric', month: 'long' }) => {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('en-IN', { ...options, timeZone: 'Asia/Kolkata' });
};

/**
 * Get days difference between an expiry date and today (IST)
 * @param {string|Date} expiryDate 
 * @returns {number}
 */
export const getDaysLeftIST = (expiryDate) => {
  if (!expiryDate) return 0;
  const expiry = new Date(expiryDate);
  const today = getNowIST();
  
  // Set times to midnight for accurate day comparison
  expiry.setHours(0, 0, 0, 0);
  today.setHours(0, 0, 0, 0);
  
  const diffTime = expiry.getTime() - today.getTime();
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};
