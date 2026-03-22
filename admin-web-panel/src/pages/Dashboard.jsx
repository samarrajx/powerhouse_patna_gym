import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import toast from 'react-hot-toast';
import { useTheme } from '../ThemeContext';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';
import { Users, TrendingUp, UserX, Timer, RefreshCcw, Menu } from 'lucide-react';
import { useSidebar } from '../App';

function Topbar({ title, sub }) {
  const { theme, toggle } = useTheme();
  const { isOpen, toggle: toggleSidebar } = useSidebar();
  return (
    <div className="topbar">
      <div className="topbar-left" style={{ display:'flex', alignItems:'center', gap:'12px' }}>
        <button className="mobile-menu-btn" onClick={toggleSidebar}>
          <Menu size={20} />
        </button>
        <div>
          <h1>{title}</h1>
          {sub && <p style={{ fontSize:'0.78rem', color:'var(--text-2)', marginTop:'2px' }}>{sub}</p>}
        </div>
      </div>
      <div className="topbar-right">
        <div className="status-pill">
          <span className="pulse-dot" />
          System Live
        </div>
        <button
          className="theme-toggle"
          onClick={toggle}
          title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
          aria-label="Toggle theme"
        >
          {theme === 'dark' ? '☀️' : '🌙'}
        </button>
      </div>
    </div>
  );
}

// Removed MOCK_CHART as we now use real backend data


export default function Dashboard() {
  const nav = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [gymOpen, setGymOpen] = useState(true);

  const fetch = async () => {
    setLoading(true);
    try {
      const [s, g] = await Promise.all([
        api.get('/admin/dashboard'),
        api.get('/gym/status'),
      ]);
      setStats(s.data);
      setGymOpen(g.data?.is_open ?? true);
    } catch (e) {
      toast.error('Failed to load stats');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetch(); }, []);

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
      <Topbar title="Command Center" sub={`Today — ${new Date().toLocaleDateString('en-IN', { weekday:'long', day:'numeric', month:'long' })}`} />
      <div className="page-body">

        {/* Gym status banner */}
        <div className={`card fade-up-1`} style={{
          marginBottom:'20px',
          borderColor: gymOpen ? 'rgba(200,250,0,0.2)' : 'rgba(255,107,107,0.2)',
          background: gymOpen ? 'rgba(200,250,0,0.04)' : 'rgba(255,107,107,0.04)',
          display:'flex', alignItems:'center', justifyContent:'space-between',
          padding:'16px 24px',
        }}>
          <div style={{ display:'flex', alignItems:'center', gap:'10px' }}>
            <div style={{ width:'10px', height:'10px', borderRadius:'50%', background: gymOpen ? 'var(--primary)' : 'var(--coral)', boxShadow:`0 0 8px ${gymOpen ? 'var(--primary-glow)' : 'rgba(255,107,107,0.5)'}` }} />
            <span style={{ fontWeight:'600', color: gymOpen ? 'var(--primary)' : 'var(--coral)' }}>
              {gymOpen ? '🏋️  Facility is OPEN for today' : '🔒  Facility is CLOSED today'}
            </span>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={fetch}>
            <RefreshCcw size={14} />
            Refresh
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
                <Tooltip contentStyle={{ background:'rgba(10,10,20,0.9)', border:'1px solid rgba(255,255,255,0.1)', borderRadius:'10px', color:'#fff' }} />
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
                style={{ cursor:'pointer', borderLeft:`3px solid ${color}`, transition:'transform 0.2s, box-shadow 0.2s' }}
                onMouseEnter={e => { e.currentTarget.style.transform='translateX(4px)'; e.currentTarget.style.boxShadow='var(--shadow)'; }}
                onMouseLeave={e => { e.currentTarget.style.transform='translateX(0)'; e.currentTarget.style.boxShadow='none'; }}
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

// Export Topbar for reuse
export { Topbar };
