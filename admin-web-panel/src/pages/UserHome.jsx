import { useState, useEffect } from 'react';
import { useAuth } from '../AuthContext';
import api from '../api';
import toast from 'react-hot-toast';
import { 
  TrendingUp, Award, Calendar, Zap, 
  ChevronRight, ArrowRight, CheckCircle2, Clock
} from 'lucide-react';
import { 
  BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Cell, Tooltip 
} from 'recharts';

export default function UserHome() {
  const { user } = useAuth();
  const [gym, setGym] = useState(null);
  const [history, setHistory] = useState([]);
  const [notifs, setNotifs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [gRes, hRes] = await Promise.all([
          api.get('/gym/status'),
          api.get('/attendance/history')
        ]);
        setGym(gRes.data);
        setHistory(hRes.data || []);
      } catch (e) {
        toast.error('Failed to sync gym data');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  // Process data for chart (Last 7 days)
  const chartData = [6,5,4,3,2,1,0].map(d => {
    const date = new Date();
    date.setDate(date.getDate() - d);
    const dateStr = date.toISOString().split('T')[0];
    const rec = history.find(r => r.date === dateStr);
    
    let hours = 0;
    if (rec && rec.time_in && rec.time_out) {
      const diff = (new Date(rec.time_out) - new Date(rec.time_in)) / (1000 * 60 * 60);
      hours = Math.min(Math.max(diff, 0.5), 4); // Clamp between 0.5 and 4 for visual
    } else if (rec && rec.time_in) {
      hours = 1; // Active session
    }

    return {
      day: date.toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase(),
      hours: hours,
      fullDate: dateStr,
      active: !!rec
    };
  });

  const getTier = (s) => {
    if (s <= 3) return { name: 'Iron', rank: 'E', color: '#94A3B8' };
    if (s <= 10) return { name: 'Bronze', rank: 'D', color: '#CD7F32' };
    if (s <= 20) return { name: 'Silver', rank: 'C', color: '#C0C0C0' };
    if (s <= 35) return { name: 'Gold', rank: 'B', color: '#FFD700' };
    if (s <= 50) return { name: 'Platinum', rank: 'A', color: '#E5E4E2' };
    return { name: 'Legendary', rank: 'S', color: '#E53935' };
  };

  const tier = getTier(user?.current_streak || 0);

  if (loading) return <div className="loader-box"><div className="spinner" /></div>;

  const expiry = user?.membership_expiry ? new Date(user.membership_expiry) : null;
  const daysLeft = expiry ? Math.ceil((expiry - new Date()) / (1000 * 60 * 60 * 24)) : 0;

  return (
    <div className="user-dashboard fade-up">
      {/* 1. Header & Welcome */}
      <section className="welcome-section">
        <p className="sub-text">WELCOME BACK,</p>
        <h1 className="user-title">{user?.name?.toUpperCase() || 'MEMBER'}</h1>
      </section>

      {/* 2. Gym Status Bar */}
      <div className={`gym-badge ${gym?.is_open ? 'open' : 'closed'}`}>
          <div className="status-dot" />
          <span>GYM IS {gym?.is_open ? 'OPERATIONAL' : 'CLOSED NOW'}</span>
          {gym?.is_holiday && <span className="holiday-label">HOLIDAY</span>}
      </div>

      {/* 3. Membership Card */}
      <div className="card membership-card">
        <div className="card-top">
          <div>
            <p className="card-label">PLAN</p>
            <h3 className="card-val">{user?.membership_plan || 'Standard'}</h3>
          </div>
          <div className="status-chip active">ACTIVE</div>
        </div>
        <div className="card-progress">
          <div className="progress-bar">
             <div className="fill" style={{ width: `${Math.min(Math.max((daysLeft/30)*100, 10), 100)}%` }} />
          </div>
          <div className="progress-labels">
            <span>{daysLeft} days remaining</span>
            <span>Expires {user?.membership_expiry?.split('T')[0]}</span>
          </div>
        </div>
      </div>

      {/* 4. Streak & Ranking */}
      <div className="grid-2x1">
        <div className="card streak-card">
          <div className="streak-circle" style={{ borderColor: tier.color }}>
             <Zap size={24} fill={tier.color} color={tier.color} />
             <div className="streak-num">
               <h2>{user?.current_streak || 0}</h2>
               <p>DAYS</p>
             </div>
          </div>
          <div className="streak-details">
            <h4 style={{ color: tier.color }}>{tier.name.toUpperCase()}</h4>
            <p>RANK {tier.rank}</p>
          </div>
        </div>

        <div className="card stat-mini">
           <Award size={20} className="icon-red" />
           <p className="label">BEST STREAK</p>
           <h3 className="val">{user?.best_streak || 0}d</h3>
        </div>
      </div>

      {/* 5. Activity Chart */}
      <div className="card chart-card">
         <div className="card-header">
           <h3 className="section-title">WEEKLY ACTIVITY</h3>
           <TrendingUp size={16} />
         </div>
         <div className="chart-wrapper">
           <ResponsiveContainer width="100%" height={140}>
              <BarChart data={chartData}>
                <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: 'var(--text-3)' }} />
                <Tooltip 
                  cursor={{ fill: 'transparent' }}
                  content={({active, payload}) => {
                    if (active && payload && payload.length) {
                      return <div className="custom-tooltip">{payload[0].value > 0 ? `${payload[0].value.toFixed(1)} hrs` : 'No data'}</div>;
                    }
                    return null;
                  }}
                />
                <Bar dataKey="hours" radius={[4, 4, 0, 0]} barSize={12}>
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.active ? 'var(--primary)' : 'var(--glass-border-2)'} />
                  ))}
                </Bar>
              </BarChart>
           </ResponsiveContainer>
         </div>
      </div>

      {/* 6. Today's Attendance (if checked in) */}
      {history[0]?.date === new Date().toISOString().split('T')[0] && (
        <div className="today-log">
           <Clock size={16} />
           <span>Today: Checked in at {new Date(history[0].time_in).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}</span>
           {history[0].time_out ? (
             <span className="out">Out: {new Date(history[0].time_out).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}</span>
           ) : (
             <span className="active-tag">Active</span>
           )}
        </div>
      )}

      <style>{`
        .user-dashboard {
          display: flex;
          flex-direction: column;
          gap: 20px;
          animation: slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1);
        }
        @keyframes slideUp { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }

        .welcome-section { text-align: center; margin-bottom: 4px; }
        .sub-text { font-size: 0.7rem; font-weight: 900; color: var(--text-3); letter-spacing: 2px; }
        .user-title { font-family: var(--font-display); font-size: 1.8rem; font-weight: 900; margin-top: 4px; color: var(--text-1); }

        .gym-badge {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          padding: 10px 16px;
          border-radius: 100px;
          font-size: 0.7rem;
          font-weight: 800;
          letter-spacing: 0.5px;
          margin: 0 auto;
          border: 1px solid transparent;
        }
        .gym-badge.open { background: var(--badge-green); color: var(--badge-green-text); border-color: var(--badge-green-border); }
        .gym-badge.closed { background: var(--badge-red); color: var(--badge-red-text); border-color: var(--badge-red-border); }
        .status-dot { width: 6px; height: 6px; border-radius: 50%; background: currentColor; box-shadow: 0 0 8px currentColor; }
        .holiday-label { background: var(--coral); color: white; padding: 2px 6px; border-radius: 4px; font-size: 0.6rem; }

        .membership-card {
          background: linear-gradient(135deg, rgba(229, 57, 53, 0.1) 0%, rgba(13, 13, 26, 0.95) 100%);
          border: 1px solid var(--glass-border-2);
          padding: 22px;
          display: flex;
          flex-direction: column;
          gap: 20px;
        }
        .card-top { display: flex; justify-content: space-between; align-items: flex-start; }
        .card-label { font-size: 0.65rem; font-weight: 800; color: var(--text-3); letter-spacing: 1px; }
        .card-val { font-family: var(--font-display); font-size: 1.3rem; font-weight: 800; margin-top: 4px; }
        .status-chip { font-size: 0.65rem; font-weight: 900; padding: 4px 10px; border-radius: 6px; }
        .status-chip.active { background: var(--badge-green); color: var(--badge-green-text); }
        
        .progress-bar { height: 6px; background: rgba(255,255,255,0.05); border-radius: 10px; overflow: hidden; margin-bottom: 8px; }
        .progress-bar .fill { height: 100%; background: var(--primary); box-shadow: 0 0 10px var(--primary-glow); }
        .progress-labels { display: flex; justify-content: space-between; font-size: 0.72rem; color: var(--text-2); font-weight: 600; }

        .grid-2x1 { display: grid; grid-template-columns: 1.5fr 1fr; gap: 16px; }
        
        .streak-card { display: flex; align-items: center; gap: 16px; padding: 16px; }
        .streak-circle {
          width: 72px; height: 72px; border: 4px solid; border-radius: 50%;
          display: flex; flex-direction: column; align-items: center; justify-content: center;
          background: rgba(255,255,255,0.02);
        }
        .streak-num { text-align: center; margin-top: -2px; }
        .streak-num h2 { font-size: 1.2rem; font-weight: 900; line-height: 1; }
        .streak-num p { font-size: 0.5rem; font-weight: 800; opacity: 0.6; }
        .streak-details h4 { font-size: 0.85rem; font-weight: 900; margin-bottom: 2px; }
        .streak-details p { font-size: 0.65rem; font-weight: 800; color: var(--text-3); }

        .stat-mini { display: flex; flex-direction: column; justify-content: center; align-items: center; padding: 16px; gap: 4px; }
        .stat-mini .label { font-size: 0.6rem; font-weight: 900; color: var(--text-3); text-align: center; }
        .stat-mini .val { font-size: 1.2rem; font-weight: 900; }
        .icon-red { color: var(--primary); }

        .chart-card { padding: 18px; }
        .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; color: var(--text-3); }
        .section-title { font-size: 0.75rem; font-weight: 900; color: var(--text-3); letter-spacing: 1px; }
        .custom-tooltip { background: var(--bg2); padding: 4px 8px; border-radius: 4px; font-size: 0.7rem; border: 1px solid var(--glass-border); }

        .today-log {
          display: flex; align-items: center; gap: 10px; background: var(--glass-bg);
          padding: 14px 18px; border-radius: 12px; font-size: 0.75rem; border: 1px solid var(--glass-border);
          color: var(--text-2); font-weight: 600;
        }
        .today-log .active-tag { color: var(--badge-green-text); font-weight: 800; background: var(--badge-green); padding: 2px 6px; border-radius: 4px; }
        .today-log .out { opacity: 0.5; margin-left: auto; }
      `}</style>
    </div>
  );
}
