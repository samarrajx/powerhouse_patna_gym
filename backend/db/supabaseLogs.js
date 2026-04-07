require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");

const supabaseUrl = process.env.SUPABASE_URL_LOGS;
const supabaseKey = process.env.SUPABASE_KEY_LOGS;

// This client connects entirely to the second Supabase project for high-volume logs
let supabaseLogs;

if (supabaseUrl && supabaseKey) {
  try {
    supabaseLogs = createClient(supabaseUrl, supabaseKey);
  } catch (err) {
    console.error("❌ Failed to initialize supabaseLogs:", err.message);
  }
} else {
  console.warn("⚠️ SUPABASE_URL_LOGS or SUPABASE_KEY_LOGS is missing. Logging features will be disabled.");
  // Create a placeholder to prevent crashes
  supabaseLogs = {
    from: () => ({
      select: () => ({ eq: () => ({ single: async () => ({ data: null, error: 'LOGS_DISABLED' }), maybeSingle: async () => ({ data: null, error: 'LOGS_DISABLED' }), order: () => ({ limit: async () => ({ data: [], error: 'LOGS_DISABLED' }) }) }) }),
      insert: async () => ({ error: 'LOGS_DISABLED' }),
      update: async () => ({ error: 'LOGS_DISABLED' }),
      delete: async () => ({ error: 'LOGS_DISABLED' }),
      rpc: async () => ({ data: null, error: 'LOGS_DISABLED' })
    })
  };
}

module.exports = supabaseLogs;
