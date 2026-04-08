
require("dotenv").config({ path: 'c:/Users/Samar Raj/OneDrive/Desktop/POWER HOUSE/backend/.env' });
const { createClient } = require("@supabase/supabase-js");

async function test() {
  console.log("Testing Core Project...");
  const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
  const { data: d1, error: e1 } = await supabase.rpc('get_db_size');
  console.log("Core get_db_size:", { data: d1, error: e1 });
  const { data: d2, error: e2 } = await supabase.rpc('get_table_sizes');
  console.log("Core get_table_sizes record count:", d2 ? d2.length : 0);
  if (e2) console.error("Core get_table_sizes error:", e2);

  console.log("\nTesting Logs Project...");
  const supabaseLogs = createClient(process.env.SUPABASE_URL_LOGS, process.env.SUPABASE_KEY_LOGS);
  const { data: d3, error: e3 } = await supabaseLogs.rpc('get_db_size');
  console.log("Logs get_db_size:", { data: d3, error: e3 });
  const { data: d4, error: e4 } = await supabaseLogs.rpc('get_table_sizes');
  console.log("Logs get_table_sizes record count:", d4 ? d4.length : 0);
  if (e4) console.error("Logs get_table_sizes error:", e4);
}

test();
