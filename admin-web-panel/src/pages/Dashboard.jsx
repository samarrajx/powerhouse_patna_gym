import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import toast from 'react-hot-toast';
import { useTheme } from '../ThemeContext';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';
import { Users, TrendingUp, UserX, Timer, RefreshCcw, Menu } from 'lucide-react';
import { useSidebar } from '../SidebarContext';
import { Topbar } from '../components/Topbar';
import { formatIST } from '../utils/dateUtils';

// Removed MOCK_CHART as we now use real backend data


export default function Dashboard() {
  const nav = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [gymOpen, setGymOpen] = useState(true);
  const [gymStatus, setGymStatus] = useState(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const [s, g] = await Promise.all([
        api.get('/admin/dashboard'),
        api.get('/gym/status'),
      ]);
      setStats(s.data);
      setGymOpen(g.data?.is_open ?? true);
      setGymStatus(g.data || null);
    } catch (e) {
      toast.error('Failed to load stats');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadData(); }, []);

  const StatCard = ({ label, value, icon: Icon, sub, accent, delay }) => (
    <div className={`card stat-card fade-up-${delay}`}>
      <div className="icon-bg">
        <Icon size={16} style={{ color: accent || 'var(--text-2)' }} />
      </div>
      <div className="card-title">{label}</div>
      {loading
        ? <div className="shimmer" style={{ height: '44px', width: '80px', marginBottom: '4px', marginTop: '8px' }} />
        : <div className="card-value" style={{ color: accent }}>{value ?? '—'}</div>
      }
      <div className="card-sub">{sub}</div>
    </div>
  );

  return (
    <>
      <Topbar title="Command Center" sub={`Today — ${formatIST(new Date())}`} />
      <div className="page-body">

        {/* Gym status banner (Control Center) */}
        <div className={`card fade-up-1`} style={{
          marginBottom:'24px',
          borderColor: gymOpen ? 'var(--badge-green-border, rgba(76, 175, 80, 0.2))' : 'var(--badge-red-border, rgba(238, 125, 119, 0.2))',
          display:'flex', alignItems:'center', justifyContent:'space-between',
          padding:'18px 24px',
        }}>
          <div style={{ display:'flex', alignItems:'center', gap:'20px' }}>
            <div style={{ 
              width: '48px', height: '48px',
              borderRadius: '12px', 
              background: gymOpen ? 'rgba(76, 175, 80, 0.1)' : 'rgba(238, 125, 119, 0.1)',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              {gymOpen ? <Timer size={24} color="#4CAF50" /> : <Timer size={24} color="#EE7D77" />}
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ fontWeight:'900', fontSize: '1rem', color: gymOpen ? '#4CAF50' : '#EE7D77', letterSpacing: '1px', textTransform: 'uppercase' }}>
                  {gymOpen ? 'Gym is Operational' : 'Gym is Closed'}
                </div>
                {gymStatus?.is_holiday && (
                  <span className="badge badge-red" style={{ fontSize: '10px', padding: '2px 8px' }}>Holiday</span>
                )}
              </div>
              <div style={{ fontSize:'0.75rem', color:'var(--text-3)', marginTop: '4px', fontWeight: '600' }}>
                {gymStatus?.is_holiday ? `Closed for: ${gymStatus.holiday_reason || 'Holiday'}` : (gymStatus?.is_open_today ? 'Today is an operational day' : 'Gym is scheduled to be closed today')}
                <span style={{ margin: '0 8px', opacity: 0.3 }}>|</span>
                Slot: {formatTimeStr12h(gymStatus?.batches?.morning?.start_time)}-{formatTimeStr12h(gymStatus?.batches?.morning?.end_time)} & {formatTimeStr12h(gymStatus?.batches?.evening?.start_time)}-{formatTimeStr12h(gymStatus?.batches?.evening?.end_time)}
              </div>
            </div>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={loadData} style={{ borderRadius: '8px', padding: '8px 16px' }}>
            <RefreshCcw size={14} />
            <span style={{ marginLeft: '6px', fontWeight: '800', fontSize: '11px', letterSpacing: '0.5px' }}>REFRESH STATUS</span>
          </button>
        </div>

        {/* Stats */}
        <div className="stat-grid">
          <StatCard label="Active Members"   value={stats?.total_users}       icon={Users}     accent="var(--text-1)" sub="Total registered"  delay="1" />
          <StatCard label="Today's Scans"    value={stats?.today_attendance}  icon={TrendingUp} accent="var(--primary)"   sub="Check-ins so far" delay="2" />
          <StatCard label="Inactive Members" value={stats?.inactive_users}    icon={UserX}      accent="var(--coral)"  sub="Need attention"   delay="3" />
          <StatCard label="Expiring in 7d"   value={stats?.expiring_soon ?? 0} icon={Timer}     accent="var(--blue)"   sub="Membership alerts" delay="4" />
        </div>

        {/* Chart + Actions grid */}
        <div className="grid-2">
          {/* Weekly chart */}
          <div className="card fade-up-5">
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'20px' }}>
              <div>
                <h3 style={{ fontSize:'1rem', fontWeight:'600' }}>Weekly Footfall</h3>
                <p style={{ fontSize:'0.78rem', color:'var(--text-2)', marginTop:'2px' }}>Gym attendance last 7 days</p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={180}>
              <AreaChart data={stats?.weekly_footfall || []}>

                <defs>
                  <linearGradient id="primaryGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
                <XAxis dataKey="day" tick={{ fill:'var(--text-3)', fontSize:11 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill:'var(--text-3)', fontSize:11 }} axisLine={false} tickLine={false} />
                <Tooltip 
                  contentStyle={{ 
                    background:'var(--bg2)', 
                    border:'1px solid var(--glass-border-2)', 
                    borderRadius:'10px', 
                    color:'var(--text-1)' 
                  }} 
                  itemStyle={{ color: 'var(--text-1)' }}
                />
                <Area type="monotone" dataKey="scans" stroke="var(--primary)" strokeWidth={3} fill="url(#primaryGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* Quick actions */}
          <div style={{ display:'flex', flexDirection:'column', gap:'12px' }}>
            {[
              { label:'Generate QR Code', sub:'Create 30-second attendance token', color:'var(--primary)', path:'/qr-station', emoji:'🔐' },
              { label:'Manage Members', sub:'Add, edit, or deactivate memberships', color:'var(--blue)', path:'/members', emoji:'👥' },
              { label:'View Attendance', sub:"Monitor today's check-in logs", color:'var(--coral)', path:'/attendance', emoji:'📋' },
            ].map(({ label, sub, color, path, emoji }) => (
              <div key={path} className="card fade-up-4"
                onClick={() => nav(path)}
                style={{ cursor:'pointer', borderLeft:`3px solid ${color}` }}
                onMouseEnter={e => { e.currentTarget.style.transform='translateX(4px)'; }}
                onMouseLeave={e => { e.currentTarget.style.transform='translateX(0)'; }}
              >
                <div style={{ display:'flex', alignItems:'center', gap:'14px' }}>
                  <div style={{ fontSize:'24px' }}>{emoji}</div>
                  <div>
                    <div style={{ fontWeight:'600', fontSize:'0.9rem' }}>{label}</div>
                    <div style={{ fontSize:'0.78rem', color:'var(--text-2)', marginTop:'2px' }}>{sub}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}

// Dashboard component is default exported
