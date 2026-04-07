const supabase = require('../../db/supabase');
const supabaseLogs = require('../../db/supabaseLogs');
const { getNowIST, getTodayISTStr } = require('../../utils/dateUtils');

module.exports = async (req, res) => {
  try {
    const todayStr = getTodayISTStr();
    const cutoff30Iso = getNowIST().minus({ days: 30 }).toISO();

    let markedInactive = 0;
    let markedGrace = 0;
    let markedArchived = 0;

    // Step 1: active + expired membership -> inactive
    const { data: expiredUsers, error: expiredErr } = await supabase
      .from('users')
      .select('id')
      .eq('status', 'active')
      .eq('is_frozen', false)
      .lt('membership_expiry', todayStr);

    if (expiredErr) throw expiredErr;

    if (expiredUsers?.length) {
      const expiredIds = expiredUsers.map((u) => u.id);
      const { error: updateInactiveErr } = await supabase.from('users').update({ status: 'inactive' }).in('id', expiredIds);
      if (updateInactiveErr) throw updateInactiveErr;
      markedInactive = expiredIds.length;
    }

    // Step 2: inactive & expired > 30 days -> grace
    const cutoff30Date = getNowIST().minus({ days: 30 }).toISODate();
    const { data: graceUsers, error: graceErr } = await supabase
      .from('users')
      .select('id')
      .eq('status', 'inactive')
      .eq('is_frozen', false)
      .lt('membership_expiry', cutoff30Date);

    if (graceErr) throw graceErr;

    if (graceUsers?.length) {
      const graceIds = graceUsers.map((u) => u.id);
      const { error: graceUpdateErr } = await supabase.from('users').update({ status: 'grace' }).in('id', graceIds);
      if (graceUpdateErr) throw graceUpdateErr;
      markedGrace = graceIds.length;
    }

    // Step 3: grace & expired > 60 days -> archived
    const cutoff60Date = getNowIST().minus({ days: 60 }).toISODate();
    const { data: archiveUsers, error: archiveErr } = await supabase
      .from('users')
      .select('id')
      .in('status', ['inactive', 'grace'])
      .eq('is_frozen', false)
      .lt('membership_expiry', cutoff60Date);

    if (archiveErr) throw archiveErr;

    if (archiveUsers?.length) {
      const archiveIds = archiveUsers.map((u) => u.id);
      const { error: archiveUpdateErr } = await supabase.from('users').update({ status: 'archived' }).in('id', archiveIds);
      if (archiveUpdateErr) throw archiveUpdateErr;
      markedArchived = archiveIds.length;
    }

    // Step 4: Clear automated alerts older than 24 hours
    const cutoff24h = getNowIST().minus({ hours: 24 }).toISO();
    const { error: deleteNotifErr, count: deletedNotifs } = await supabaseLogs
      .from('notifications')
      .delete({ count: 'exact' })
      .lt('created_at', cutoff24h);

    if (deleteNotifErr) {
      console.error('❌ Notification cleanup failed:', deleteNotifErr);
    }

    return res.status(200).json({
      success: true,
      message: 'Daily cleanup successful',
      data: {
        marked_inactive: markedInactive,
        marked_grace: markedGrace,
        marked_archived: markedArchived,
        deleted_notifications: deletedNotifs || 0
      },
      error_code: null,
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: e.message, error_code: 'CRON_ERROR' });
  }
};
