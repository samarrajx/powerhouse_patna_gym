require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");

const supabaseUrl = process.env.SUPABASE_URL_LOGS;
const supabaseKey = process.env.SUPABASE_KEY_LOGS;

// This client connects entirely to the second Supabase project for high-volume logs
const supabaseLogs = createClient(supabaseUrl, supabaseKey);

module.exports = supabaseLogs;
