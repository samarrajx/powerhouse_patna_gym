import { Lightbulb, AlertTriangle, TrendingUp, Clock } from 'lucide-react';

// eslint-disable-next-line no-unused-vars
function InsightCard({ icon: Icon, color, title, message, delay }) {
  return (
    <div
      className={`card fade-up-${delay}`}
      style={{
        borderLeft: `3px solid ${color}`,
        padding: '16px 20px',
        display: 'flex',
        alignItems: 'flex-start',
        gap: '14px',
        cursor: 'default',
      }}
    >
      <div style={{
        width: '36px', height: '36px', borderRadius: '8px',
        background: `${color}18`, display: 'flex', alignItems: 'center',
        justifyContent: 'center', flexShrink: 0,
      }}>
        <Icon size={16} style={{ color }} />
      </div>
      <div>
        <div style={{ fontWeight: 700, fontSize: '0.85rem', marginBottom: '4px' }}>{title}</div>
        <div style={{ fontSize: '0.78rem', color: 'var(--text-2)', lineHeight: 1.5 }}>{message}</div>
      </div>
    </div>
  );
}

export default function StorageInsights({ overview, tables }) {
  if (!overview || !tables || tables.length === 0) return null;

  const insights = [];

  // 1. Largest table insight
  const topTable = [...tables].sort((a, b) => b.size_bytes - a.size_bytes)[0];
  if (topTable) {
    insights.push({
      icon: TrendingUp,
      color: topTable.percent_of_total >= 50 ? 'var(--coral)' : '#F59E0B',
      title: `"${topTable.table_name}" dominates storage`,
      message: `The ${topTable.table_name} table consumes ${topTable.percent_of_total}% of your tracked storage (${topTable.size_mb} MB, ${topTable.row_count.toLocaleString()} rows). Consider archiving old records.`,
      delay: 1,
    });
  }

  // 2. Storage health
  const pct = overview.used_percent;
  if (pct >= 90) {
    insights.push({
      icon: AlertTriangle,
      color: 'var(--coral)',
      title: 'Critical: Storage almost full',
      message: `You've used ${pct}% of your 500 MB quota. Only ${overview.remaining_mb} MB remaining. Immediate cleanup or upgrade recommended.`,
      delay: 2,
    });
  } else if (pct >= 70) {
    insights.push({
      icon: AlertTriangle,
      color: '#F59E0B',
      title: 'Warning: Storage usage is high',
      message: `At ${pct}% usage, you have ${overview.remaining_mb} MB remaining. Run a cleanup on older attendance records to free up space.`,
      delay: 2,
    });
  } else {
    insights.push({
      icon: Lightbulb,
      color: '#4CAF50',
      title: 'Storage looks healthy',
      message: `Only ${pct}% of 500 MB used. You have ${overview.remaining_mb} MB of headroom. Keep monitoring as attendance data grows over time.`,
      delay: 2,
    });
  }

  // 3. Estimated days remaining (simple linear projection)
  // Assume ~0.5 MB per day average growth (rough estimate for small gym app)
  const avgDailyGrowthMB = 0.5;
  const daysRemaining = Math.floor(overview.remaining_mb / avgDailyGrowthMB);
  if (daysRemaining < 60) {
    insights.push({
      icon: Clock,
      color: '#A855F7',
      title: `Estimated runway: ~${daysRemaining} days`,
      message: `Based on typical growth patterns (~${avgDailyGrowthMB} MB/day), you may run out of free storage in approximately ${daysRemaining} days. Schedule periodic cleanups.`,
      delay: 3,
    });
  }

  return (
    <div style={{ marginTop: '24px' }}>
      <div style={{ marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        <Lightbulb size={15} style={{ color: 'var(--primary)' }} />
        <h3 style={{ fontSize: '0.85rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px', color: 'var(--text-2)' }}>
          Smart Insights
        </h3>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '12px' }}>
        {insights.map((ins, i) => (
          <InsightCard key={i} {...ins} />
        ))}
      </div>
    </div>
  );
}
