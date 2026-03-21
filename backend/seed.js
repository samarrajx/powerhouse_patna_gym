require("dotenv").config();
const { createClient } = require("@supabase/supabase-js");
const bcrypt = require("bcrypt");

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function seed() {
  console.log("🌱 Seeding database...");

  // 1. Batches
  const { error: bErr } = await supabase.from("batches").upsert([
    { name: "Morning Batch", start_time: "05:30:00", end_time: "09:30:00" },
    { name: "Evening Batch", start_time: "16:00:00", end_time: "20:00:00" },
  ], { onConflict: "name" });
  if (bErr) console.error("Batches:", bErr.message); else console.log("✅ Batches seeded");

  // 2. Admin user  (password: admin123)
  const adminHash = await bcrypt.hash("admin123", 10);
  const { error: aErr } = await supabase.from("users").upsert([
    { name: "Super Admin", phone: "9999999999", password_hash: adminHash, role: "admin", status: "active" },
  ], { onConflict: "phone" });
  if (aErr) console.error("Admin:", aErr.message); else console.log("✅ Admin user seeded (phone: 9999999999, pass: admin123)");

  // 3. Member user (password: samgym)
  const memberHash = await bcrypt.hash("samgym", 10);
  const { data: batchData } = await supabase.from("batches").select("id").eq("name","Morning Batch").single();
  const { error: mErr } = await supabase.from("users").upsert([
    {
      name: "Rahul Sharma", phone: "9876543210", password_hash: memberHash,
      role: "user", status: "active", membership_plan: "Gold",
      membership_expiry: "2026-12-31", fees_status: "paid",
      batch_id: batchData?.id ?? null,
    },
  ], { onConflict: "phone" });
  if (mErr) console.error("Member:", mErr.message); else console.log("✅ Member user seeded (phone: 9876543210, pass: samgym)");

  console.log("\n🎉 Seeding complete!");
  console.log("─────────────────────────────────────");
  console.log("  ADMIN  → phone: 9999999999 | pass: admin123");
  console.log("  MEMBER → phone: 9876543210 | pass: samgym");
  console.log("─────────────────────────────────────");
}

seed().catch(console.error);
