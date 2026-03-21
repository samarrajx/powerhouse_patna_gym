require('dotenv').config();
const { Client } = require('pg');

const client = new Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  connectionTimeoutMillis: 15000,
});

const migrations = [
  // 1. Extend users table
  `ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS roll_no TEXT,
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS father_name TEXT,
    ADD COLUMN IF NOT EXISTS date_of_joining DATE,
    ADD COLUMN IF NOT EXISTS body_type TEXT,
    ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS phone_alt TEXT,
    ADD COLUMN IF NOT EXISTS notes TEXT`,

  // 2. Admin doesn't need password change
  `UPDATE public.users SET must_change_password = FALSE WHERE role = 'admin'`,

  // 3. Add days_active to batches
  `ALTER TABLE public.batches 
   ADD COLUMN IF NOT EXISTS days_active TEXT[] DEFAULT ARRAY['monday','tuesday','wednesday','thursday','friday','saturday']`,

  // 4. Create weekly_schedule table
  `CREATE TABLE IF NOT EXISTS public.weekly_schedule (
    id SERIAL PRIMARY KEY,
    day_of_week TEXT NOT NULL UNIQUE
      CHECK (day_of_week IN ('monday','tuesday','wednesday','thursday','friday','saturday','sunday')),
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    open_time TIME DEFAULT '05:00:00',
    close_time TIME DEFAULT '22:00:00',
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // 5. Seed weekly schedule
  `INSERT INTO public.weekly_schedule (day_of_week, is_open, open_time, close_time) VALUES
    ('monday',    TRUE,  '05:00', '22:00'),
    ('tuesday',   TRUE,  '05:00', '22:00'),
    ('wednesday', TRUE,  '05:00', '22:00'),
    ('thursday',  TRUE,  '05:00', '22:00'),
    ('friday',    TRUE,  '05:00', '22:00'),
    ('saturday',  TRUE,  '06:00', '21:00'),
    ('sunday',    FALSE, '06:00', '12:00')
  ON CONFLICT (day_of_week) DO NOTHING`,

  // 6. Create holidays table
  `CREATE TABLE IF NOT EXISTS public.holidays (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    reason TEXT NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // 7. RLS policies
  `ALTER TABLE public.weekly_schedule ENABLE ROW LEVEL SECURITY`,
  `ALTER TABLE public.holidays ENABLE ROW LEVEL SECURITY`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='weekly_schedule' AND policyname='public_read') THEN
      CREATE POLICY public_read ON public.weekly_schedule FOR SELECT USING (TRUE);
    END IF;
  END $$`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='weekly_schedule' AND policyname='service_write') THEN
      CREATE POLICY service_write ON public.weekly_schedule FOR ALL USING (TRUE);
    END IF;
  END $$`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='holidays' AND policyname='public_read') THEN
      CREATE POLICY public_read ON public.holidays FOR SELECT USING (TRUE);
    END IF;
  END $$`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='holidays' AND policyname='service_write') THEN
      CREATE POLICY service_write ON public.holidays FOR ALL USING (TRUE);
    END IF;
  END $$`,

  // 8. Create templates table
  `CREATE TABLE IF NOT EXISTS public.templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category TEXT NOT NULL UNIQUE,
    message TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // 9. Seed base templates
  `INSERT INTO public.templates (category, message) VALUES
    ('skinny', 'Hey {name}, looking to bulk up? Check out our high-protein diet charts at the reception!'),
    ('normal', 'Hi {name}, staying consistent is key! Ready for today''s workout?'),
    ('fatty', 'Hey {name}, focus on cardio and high reps today for maximum fat burn!')
  ON CONFLICT (category) DO NOTHING`,

  // 10. Data migration for body types
  `UPDATE public.users SET body_type = 'skinny' WHERE body_type IN ('slim', 'Skinny')`,
  `UPDATE public.users SET body_type = 'normal' WHERE body_type IN ('average', 'athletic', 'Normal')`,
  `UPDATE public.users SET body_type = 'fatty' WHERE body_type IN ('heavy', 'Fatty')`,
  `UPDATE public.users SET body_type = 'normal' WHERE body_type IS NULL`,

  // Clean up old templates if needed
  `DELETE FROM public.templates WHERE category NOT IN ('skinny', 'normal', 'fatty')`,

  // 11. Create announcements table

  `CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
  )`,

  // 11. RLS for new tables
  `ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY`,
  `ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='templates' AND policyname='public_read') THEN
      CREATE POLICY public_read ON public.templates FOR SELECT USING (TRUE);
    END IF;
  END $$`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcements' AND policyname='public_read') THEN
      CREATE POLICY public_read ON public.announcements FOR SELECT USING (TRUE);
    END IF;
  END $$`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='templates' AND policyname='service_all') THEN
      CREATE POLICY service_all ON public.templates FOR ALL USING (TRUE);
    END IF;
  END $$`,
  `DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='announcements' AND policyname='service_all') THEN
      CREATE POLICY service_all ON public.announcements FOR ALL USING (TRUE);
    END IF;
  END $$`,

];

async function run() {
  console.log(`\n🔌 Connecting to Supabase directly...\n`);
  try {
    await client.connect();
    console.log('✅ Connected via direct connection!\n');
  } catch(e) {
    console.error(`❌ Connection failed: ${e.message}`);
    process.exit(1);
  }

  let success = 0, skipped = 0, failed = 0;

  for (const sql of migrations) {
    const label = sql.slice(0, 65).replace(/\s+/g,' ').trim();
    try {
      await client.query(sql);
      console.log(`  ✅  ${label}`);
      success++;
    } catch (e) {
      if (e.message.includes('already exists') || e.message.includes('duplicate') || e.message.includes('IF NOT EXISTS')) {
        console.log(`  ⚠️   Skip: ${label}`);
        skipped++;
      } else {
        console.error(`  ❌  ${label}`);
        console.error(`       → ${e.message}`);
        failed++;
      }
    }
  }

  await client.end();
  console.log(`\n🎉 Done! ${success} run, ${skipped} skipped, ${failed} failed.\n`);
}

run();
