require("dotenv").config();
const supabaseCore = require("../db/supabase");
const supabaseLogs = require("../db/supabaseLogs");

async function migrate() {
  console.log("Starting migration of attendance and notifications...");

  // Migrate Notifications
  console.log("Fetching notifications from core...");
  const { data: notifications, error: notifErr } = await supabaseCore.from("notifications").select("*");
  if (notifErr) {
    console.error("Error fetching notifications:", notifErr);
    process.exit(1);
  }

  console.log(`Found ${notifications.length} notifications. Inserting into logs database...`);
  if (notifications.length > 0) {
    const { error: insertNotifErr } = await supabaseLogs.from("notifications").insert(notifications);
    if (insertNotifErr) {
      console.error("Error inserting notifications into logs DB:", insertNotifErr);
      process.exit(1);
    }
  }

  // Migrate Attendance
  console.log("Fetching attendance from core...");
  const { data: attendance, error: attErr } = await supabaseCore.from("attendance").select("*");
  if (attErr) {
    console.error("Error fetching attendance:", attErr);
    process.exit(1);
  }

  console.log(`Found ${attendance.length} attendance records. Inserting into logs database...`);
  if (attendance.length > 0) {
    const mappedAttendance = attendance.map(a => ({
      id: a.id,
      user_id: a.user_id,
      date: a.date,
      time_in: a.time_in,
      time_out: a.time_out,
      created_at: a.created_at
    }));
    const { error: insertAttErr } = await supabaseLogs.from("attendance").insert(mappedAttendance);
    if (insertAttErr) {
      console.error("Error inserting attendance into logs DB:", insertAttErr);
      process.exit(1);
    }
  }

  console.log("Migration complete! You can safely delete attendance and notifications from the old core database now.");
  process.exit(0);
}

migrate();
