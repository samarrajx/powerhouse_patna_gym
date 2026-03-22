import React, { useState, useEffect } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { Send, Bell, History, X } from 'lucide-react';

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [type, setType] = useState('announcement');
  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState([]);

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    try {
      const res = await api.get('/notifications');
      if (res.success) setHistory(res.data);
    } catch (e) {}
  };

  const handleSend = async (e) => {
    e.preventDefault();
    if (!title || !message) return toast.error('Please fill all fields');

    setLoading(true);
    try {
      const res = await api.post('/notifications/broadcast', { title, message, type });
      if (res.success) {
        toast.success('Broadcast sent successfully!');
        setTitle('');
        setMessage('');
        fetchHistory();
      }
    } catch (err) {
      toast.error(err.message || 'Failed to send broadcast');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="page-container">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <h2 className="page-title">NOTIFICATIONS & BROADCASTS</h2>
      </div>

      <div className="stats-grid">
        <div className="glass-card" style={{ gridColumn: 'span 2' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
            <Send size={18} color="var(--primary)" />
            <h3 style={{ margin: 0, fontSize: '1rem' }}>SEND NEW BROADCAST</h3>
          </div>
          <form onSubmit={handleSend}>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-3)', marginBottom: '8px' }}>NOTIFICATION TITLE</label>
              <input 
                className="glass-input" 
                placeholder="e.g. Holiday Alert, New Batch..." 
                value={title}
                onChange={e => setTitle(e.target.value)}
              />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-3)', marginBottom: '8px' }}>MESSAGE CONTENT</label>
              <textarea 
                className="glass-input" 
                rows={4} 
                placeholder="Write your message here..."
                value={message}
                onChange={e => setMessage(e.target.value)}
                style={{ resize: 'none' }}
              />
            </div>
            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-3)', marginBottom: '8px' }}>CATEGORY</label>
              <div style={{ display: 'flex', gap: '10px' }}>
                {['announcement', 'holiday', 'offer', 'urgent'].map(t => (
                  <button 
                    key={t}
                    type="button"
                    className={`btn btn-sm ${type === t ? 'btn-primary' : 'btn-ghost'}`}
                    onClick={() => setType(t)}
                    style={{ textTransform: 'capitalize' }}
                  >
                    {t}
                  </button>
                ))}
              </div>
            </div>
            <button className="btn btn-primary" style={{ width: '100%' }} disabled={loading}>
              {loading ? 'SENDING...' : 'BROADCAST TO ALL MEMBERS'}
            </button>
          </form>
        </div>

        <div className="glass-card">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
            <History size={18} color="var(--primary)" />
            <h3 style={{ margin: 0, fontSize: '1rem' }}>RECENT HISTORY</h3>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', maxHeight: '400px', overflowY: 'auto', paddingRight: '5px' }}>
            {history.length === 0 ? (
              <p style={{ color: 'var(--text-3)', fontSize: '0.85rem', textAlign: 'center', padding: '20px' }}>No history found</p>
            ) : history.map(h => (
              <div key={h.id} style={{ padding: '12px', borderRadius: '12px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--glass-border)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                  <span className="badge badge-gray" style={{ fontSize: '0.65rem' }}>{h.type}</span>
                  <span style={{ fontSize: '0.65rem', color: 'var(--text-3)' }}>{new Date(h.created_at).toLocaleDateString()}</span>
                </div>
                <div style={{ fontWeight: 600, fontSize: '0.85rem', marginBottom: '4px' }}>{h.title}</div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-2)', lineHeight: 1.4 }}>{h.message}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
