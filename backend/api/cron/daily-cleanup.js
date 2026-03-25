const supabase = require('../../db/supabase');

module.exports = async (req, res) => {
  try {
    const todayStr = new Date().toISOString().split('T')[0];
    const cutoff30 = new Date();
    cutoff30.setDate(cutoff30.getDate() - 30);
    const cutoff30Iso = cutoff30.toISOString();

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

      const { error: inactiveLogErr } = await supabase.from('audit_logs').insert(
        expiredIds.map((id) => ({
          action: 'MARKED_INACTIVE',
          target_user: id,
          details: { reason: 'membership_expired', date: todayStr },
        }))
      );
      if (inactiveLogErr) throw inactiveLogErr;
      markedInactive = expiredIds.length;
    }

    // Step 2: inactive > 30 days since MARKED_INACTIVE -> grace
    const { data: inactiveLogs, error: inactiveLogsErr } = await supabase
      .from('audit_logs')
      .select('target_user, created_at')
      .eq('action', 'MARKED_INACTIVE')
      .lt('created_at', cutoff30Iso)
      .order('created_at', { ascending: false });

    if (inactiveLogsErr) throw inactiveLogsErr;

    const inactiveUserIds = [...new Set((inactiveLogs || []).map((l) => l.target_user).filter(Boolean))];
    if (inactiveUserIds.length) {
      const { data: inactiveUsers, error: inactiveUsersErr } = await supabase
        .from('users')
        .select('id')
        .in('id', inactiveUserIds)
        .eq('status', 'inactive');
      if (inactiveUsersErr) throw inactiveUsersErr;

      const toGraceIds = (inactiveUsers || []).map((u) => u.id);
      if (toGraceIds.length) {
        const { error: graceUpdateErr } = await supabase.from('users').update({ status: 'grace' }).in('id', toGraceIds);
        if (graceUpdateErr) throw graceUpdateErr;

        const { error: graceLogErr } = await supabase.from('audit_logs').insert(
          toGraceIds.map((id) => ({
            action: 'MARKED_GRACE',
            target_user: id,
            details: { reason: 'inactive_30_days', date: todayStr },
          }))
        );
        if (graceLogErr) throw graceLogErr;
        markedGrace = toGraceIds.length;
      }
    }

    // Step 3: grace > 30 days since MARKED_GRACE -> archived
    const { data: graceLogs, error: graceLogsErr } = await supabase
      .from('audit_logs')
      .select('target_user, created_at')
      .eq('action', 'MARKED_GRACE')
      .lt('created_at', cutoff30Iso)
      .order('created_at', { ascending: false });

    if (graceLogsErr) throw graceLogsErr;

    const graceUserIds = [...new Set((graceLogs || []).map((l) => l.target_user).filter(Boolean))];
    if (graceUserIds.length) {
      const { data: graceUsers, error: graceUsersErr } = await supabase
        .from('users')
        .select('id')
        .in('id', graceUserIds)
        .eq('status', 'grace');
      if (graceUsersErr) throw graceUsersErr;

      const toArchiveIds = (graceUsers || []).map((u) => u.id);
      if (toArchiveIds.length) {
        const { error: archiveUpdateErr } = await supabase.from('users').update({ status: 'archived' }).in('id', toArchiveIds);
        if (archiveUpdateErr) throw archiveUpdateErr;

        const { error: archiveLogErr } = await supabase.from('audit_logs').insert(
          toArchiveIds.map((id) => ({
            action: 'MARKED_ARCHIVED',
            target_user: id,
            details: { reason: 'grace_30_days', date: todayStr },
          }))
        );
        if (archiveLogErr) throw archiveLogErr;
        markedArchived = toArchiveIds.length;
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Daily cleanup successful',
      data: {
        marked_inactive: markedInactive,
        marked_grace: markedGrace,
        marked_archived: markedArchived,
      },
      error_code: null,
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: e.message, error_code: 'CRON_ERROR' });
  }
};
