import { useState, useEffect } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { Calendar, Clock, History as HistoryIcon, ArrowRight, UserCheck } from 'lucide-react';

export default function UserHistory() {
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const res = await api.get('/attendance/history');
        setHistory(res.data || []);
      } catch (e) {
        toast.error('Failed to load history');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  if (loading) return <div className="loader-box"><div className="spinner" /></div>;

  return (
    <div className="history-page fade-up">
      <div className="history-header">
        <h2 className="title">WORKOUT LOGS</h2>
        <p className="sub">Last 60 training sessions</p>
      </div>

      <div className="history-list">
        {history.length > 0 ? history.map((rec, i) => (
          <div key={rec.id || i} className="history-card">
            <div className="card-left">
              <div className="date-box">
                <span className="day">{new Date(rec.date).getDate()}</span>
                <span className="month">{new Date(rec.date).toLocaleDateString('en-US', { month: 'short' }).toUpperCase()}</span>
              </div>
            </div>
            
            <div className="card-right">
              <div className="row">
                <div className="time-entry">
                  <span className="label">CHECK IN</span>
                  <span className="time">{new Date(rec.time_in).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}</span>
                </div>
                <ArrowRight size={14} className="sep" />
                <div className="time-entry">
                  <span className="label">CHECK OUT</span>
                  <span className="time">{rec.time_out ? new Date(rec.time_out).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }) : '--:--'}</span>
                </div>
              </div>
              <div className="footer">
                <span className="badge">
                   <UserCheck size={12} />
                   SUCCESSFUL SESSION
                </span>
                {rec.time_out && (
                  <span className="duration">
                    {Math.round((new Date(rec.time_out) - new Date(rec.time_in)) / (1000 * 60))} MIN
                  </span>
                )}
              </div>
            </div>
          </div>
        )) : (
          <div className="empty-state">
            <HistoryIcon size={48} />
            <p>No workout history yet. Scan in to start your first session!</p>
          </div>
        )}
      </div>

      <style>{`
        .history-page { display: flex; flex-direction: column; gap: 20px; }
        .history-header { text-align: left; padding: 10px 0; }
        .history-header .title { font-family: var(--font-display); font-size: 1.4rem; font-weight: 900; }
        .history-header .sub { font-size: 0.8rem; color: var(--text-3); font-weight: 500; }

        .history-list { display: flex; flex-direction: column; gap: 14px; }
        
        .history-card {
          background: var(--glass-bg-2);
          border: 1px solid var(--glass-border);
          border-radius: 18px;
          display: flex;
          padding: 16px;
          gap: 16px;
          transition: transform 0.2s;
        }
        .history-card:active { transform: scale(0.98); }

        .date-box {
          background: var(--primary-dim);
          border: 1px solid var(--primary-glow);
          border-radius: 12px;
          width: 54px;
          height: 60px;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          color: var(--primary);
        }
        .date-box .day { font-size: 1.1rem; font-weight: 900; line-height: 1; }
        .date-box .month { font-size: 0.55rem; font-weight: 800; opacity: 0.8; letter-spacing: 0.5px; }

        .card-right { flex: 1; display: flex; flex-direction: column; gap: 12px; }
        .card-right .row { display: flex; align-items: center; gap: 12px; }
        .time-entry { display: flex; flex-direction: column; }
        .time-entry .label { font-size: 0.55rem; font-weight: 900; color: var(--text-3); letter-spacing: 0.5px; margin-bottom: 2px; }
        .time-entry .time { font-family: var(--font-display); font-size: 0.95rem; font-weight: 700; color: var(--text-1); }
        .sep { color: var(--text-3); opacity: 0.5; margin-top: 10px; }

        .footer { display: flex; justify-content: space-between; align-items: center; }
        .badge { display: flex; align-items: center; gap: 6px; font-size: 0.6rem; font-weight: 800; color: var(--badge-green-text); background: var(--badge-green); padding: 4px 8px; border-radius: 6px; }
        .duration { font-size: 0.65rem; font-weight: 900; color: var(--text-2); background: rgba(255,255,255,0.04); padding: 4px 8px; border-radius: 6px; }

        .empty-state {
          padding: 60px 40px; text-align: center; color: var(--text-3);
          display: flex; flex-direction: column; align-items: center; gap: 20px;
          background: var(--glass-bg); border-radius: 24px; border: 1px dashed var(--glass-border-2);
        }
        .empty-state p { font-size: 0.85rem; font-weight: 600; line-height: 1.5; }
      `}</style>
    </div>
  );
}
