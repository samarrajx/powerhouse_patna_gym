require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Using Service Role key on the backend to bypass RLS securely for admin tasks, OR we can pass JWT dynamically.

const supabase = createClient(supabaseUrl, supabaseKey);

module.exports = supabase;
