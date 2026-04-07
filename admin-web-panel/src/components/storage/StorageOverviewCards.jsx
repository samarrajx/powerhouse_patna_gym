import { HardDrive, Gauge, TrendingUp, Package } from 'lucide-react';

// eslint-disable-next-line no-unused-vars
function StorageCard({ label, value, sub, icon: Icon, accent, delay, loading }) {
  return (
    <div className={`card stat-card fade-up-${delay}`} style={{ '--hover-accent': accent }}>
      <div className="icon-bg" style={{ background: `${accent}15`, borderRadius: '8px' }}>
        <Icon size={16} style={{ color: accent }} />
      </div>
      <div className="card-title">{label}</div>
      {loading
        ? <div className="shimmer" style={{ height: '44px', width: '90px', marginBottom: '4px', marginTop: '8px' }} />
        : <div className="card-value" style={{ color: accent }}>{value ?? '—'}</div>
      }
      <div className="card-sub">{sub}</div>
    </div>
  );
}

export default function StorageOverviewCards({ overview, loading }) {
  const pct = overview?.used_percent ?? 0;
  const progressColor = pct >= 90 ? 'var(--coral)' : pct >= 70 ? '#F59E0B' : '#4CAF50';

  return (
    <div className="stat-grid fade-up-1">
      <StorageCard
        label="Total Used"
        value={overview ? `${overview.size_mb} MB` : null}
        sub="Database size"
        icon={HardDrive}
        accent="var(--primary)"
        delay="1"
        loading={loading}
      />
      <StorageCard
        label="Storage Limit"
        value={overview ? `${overview.storage_limit_mb} MB` : null}
        sub="Free tier quota"
        icon={Package}
        accent="var(--blue)"
        delay="2"
        loading={loading}
      />

      {/* Usage % card with animated progress bar */}
      <div className="card stat-card fade-up-3" style={{ position: 'relative', overflow: 'hidden' }}>
        <div className="icon-bg" style={{ background: `${progressColor}15`, borderRadius: '8px' }}>
          <Gauge size={16} style={{ color: progressColor }} />
        </div>
        <div className="card-title">Usage</div>
        {loading
          ? <div className="shimmer" style={{ height: '44px', width: '70px', marginBottom: '4px', marginTop: '8px' }} />
          : <div className="card-value" style={{ color: progressColor }}>{pct}%</div>
        }
        <div className="card-sub" style={{ marginBottom: '10px' }}>of total quota</div>
        {!loading && (
          <div className="progress-bar" style={{ height: '6px', marginTop: '4px' }}>
            <div
              className="progress-fill"
              style={{
                width: `${Math.min(pct, 100)}%`,
                background: progressColor,
                transition: 'width 1.2s cubic-bezier(0.16,1,0.3,1)',
                boxShadow: `0 0 8px ${progressColor}60`,
              }}
            />
          </div>
        )}
        {loading && (
          <div className="shimmer" style={{ height: '6px', borderRadius: '3px', marginTop: '4px' }} />
        )}
      </div>

      <StorageCard
        label="Remaining"
        value={overview ? `${overview.remaining_mb} MB` : null}
        sub="Available space"
        icon={TrendingUp}
        accent="#4CAF50"
        delay="4"
        loading={loading}
      />
    </div>
  );
}
