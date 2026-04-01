import { useState, useEffect } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { Bell, MessageSquare, CheckDouble, Clock, ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function UserNotifications() {
  const [notifs, setNotifs] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const load = async () => {
      try {
        // 1. Fetch current (possibly unread) notifications
        const res = await api.get('/notifications');
        setNotifs(res.data || []);
        
        // 2. Mark all as read for this user immediately on opening the list
        const unreadExists = res.data.some(n => !n.is_read);
        if (unreadExists) {
          await api.put('/notifications/read-all');
        }
      } catch (e) {
        toast.error('Failed to load notifications');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  if (loading) return <div className="loader-box"><div className="spinner" /></div>;

  return (
    <div className="notifs-page fade-up">
      <div className="notifs-header">
        <button className="back-btn" onClick={() => navigate('/user/home')}>
            <ArrowLeft size={20} />
        </button>
        <div>
            <h2 className="title">NOTIFICATIONS</h2>
            <p className="sub">All your alerts and announcements</p>
        </div>
      </div>

      <div className="notif-list full">
        {notifs.length > 0 ? notifs.map((n) => (
          <div key={n.id} className={`notif-card ${!n.is_read ? 'unread' : ''}`}>
             <div className="notif-icon-box">
                {n.type === 'announcement' ? <MessageSquare size={18} /> : <Bell size={18} />}
             </div>
             <div className="notif-details">
                <div className="notif-top">
                    <h4>{n.title}</h4>
                    {!n.is_read && <span className="new-tag">NEW</span>}
                </div>
                <p>{n.message}</p>
                <div className="notif-meta">
                    <Clock size={12} />
                    <span>{new Date(n.created_at).toLocaleDateString('en-IN', { day:'2-digit', month:'short', hour:'2-digit', minute:'2-digit' })}</span>
                </div>
             </div>
          </div>
        )) : (
          <div className="empty-state">
            <Bell size={48} />
            <p>Your notification tray is empty.</p>
          </div>
        )}
      </div>

      <style>{`
        .notifs-page { display: flex; flex-direction: column; gap: 24px; }
        .notifs-header { display: flex; align-items: center; gap: 16px; padding: 10px 0; }
        .back-btn { 
          background: var(--glass-bg-2); border: 1px solid var(--glass-border); 
          color: var(--text-2); padding: 8px; border-radius: 12px; cursor: pointer;
        }
        .notifs-header .title { font-family: var(--font-display); font-size: 1.4rem; font-weight: 900; line-height: 1.1; }
        .notifs-header .sub { font-size: 0.75rem; color: var(--text-3); font-weight: 600; margin-top: 2px; }

        .notif-list.full { display: flex; flex-direction: column; gap: 12px; }
        
        .notif-card {
          background: var(--glass-bg-2);
          border: 1px solid var(--glass-border);
          border-radius: 20px;
          display: flex;
          padding: 16px;
          gap: 16px;
          position: relative;
          transition: all 0.2s;
        }
        .notif-card.unread { 
          border-left: 4px solid var(--primary); 
          background: linear-gradient(90deg, var(--primary-dim) 0%, var(--glass-bg-2) 100%);
        }

        .notif-icon-box {
          width: 40px; height: 40px; border-radius: 12px;
          background: var(--bg); border: 1px solid var(--glass-border);
          display: flex; align-items: center; justify-content: center;
          color: var(--primary); flex-shrink: 0;
        }

        .notif-details { flex: 1; }
        .notif-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
        .notif-top h4 { font-size: 0.9rem; font-weight: 800; color: var(--text-1); }
        .new-tag { font-size: 0.6rem; font-weight: 900; color: var(--primary); background: var(--primary-dim); padding: 2px 6px; border-radius: 4px; letter-spacing: 0.5px; }

        .notif-details p { font-size: 0.8rem; color: var(--text-2); line-height: 1.5; }
        
        .notif-meta { 
          display: flex; align-items: center; gap: 6px; 
          margin-top: 10px; font-size: 0.65rem; color: var(--text-3); font-weight: 700;
        }

        .empty-state {
          padding: 80px 40px; text-align: center; color: var(--text-3);
          display: flex; flex-direction: column; align-items: center; gap: 20px;
          background: var(--glass-bg); border-radius: 24px; border: 1px dashed var(--glass-border-2);
        }
      `}</style>
    </div>
  );
}
