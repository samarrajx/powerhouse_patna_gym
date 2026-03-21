const supabase = require("../../db/supabase");

// Helper function to calculate date differences
const diffDays = (date1, date2) => Math.floor((date1 - date2) / (1000 * 60 * 60 * 24));

module.exports = async (req, res) => {
    try {
        const today = new Date();
        const cutoffDate = new Date();
        cutoffDate.setDate(today.getDate() - 180);

        // 1. Mark users inactive if no attendance for > 180 days or membership expired
        const { data: usersToMarkInactive } = await supabase
            .from("users")
            .select("id")
            .eq("status", "active")
            .or(`last_attendance_date.lt.${cutoffDate.toISOString().split("T")[0]},membership_expiry.lt.${today.toISOString().split("T")[0]}`);

        if (usersToMarkInactive && usersToMarkInactive.length > 0) {
            const idsToUpdate = usersToMarkInactive.map(u => u.id);
            await supabase.from("users").update({ status: "inactive" }).in("id", idsToUpdate);
            
            // Log audit
             const logs = idsToUpdate.map(id => ({
                action: "MARKED_INACTIVE",
                target_user: id,
                details: { reason: "180 days inactive or expired membership" }
            }));
            await supabase.from("audit_logs").insert(logs);
        }

        // 2. Archive users marked inactive for > 30 days
        const { data: usersToArchive } = await supabase
            .from("users")
            .select("*")
            .eq("status", "inactive");
            
        // Assuming we evaluate the date they became inactive via audit logs, or simplify here by setting 'grace' status.
        // For PRD: 30 day grace
        if (usersToArchive && usersToArchive.length > 0) {
            // Further logic would verify 30 days of inactivity using audit logs before archiving.
            // ...
        }

        return res.status(200).json({ success: true, message: "Daily cleanup successful", error_code: null });
    } catch (e) {
        return res.status(500).json({ success: false, message: e.message, error_code: "CRON_ERROR" });
    }
};
