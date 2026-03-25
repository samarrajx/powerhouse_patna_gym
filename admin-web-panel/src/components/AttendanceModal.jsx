import { useState, useEffect } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { X, Search } from 'lucide-react';

export default function AttendanceModal({ userId, userName, onClose, onSave }) {
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState([]);
  const [search, setSearch] = useState('');
  const [selectedUser, setSelectedUser] = useState(userId || null);
  const [selectedUserName, setSelectedUserName] = useState(userName || '');
  
  const [f, setF] = useState({
    date: new Date().toISOString().split('T')[0],
    time_in: '',
    time_out: ''
  });

  useEffect(() => {
    if (!userId) {
      loadUsers();
    }
  }, [userId]);

  const loadUsers = async () => {
    try {
      const r = await api.get('/admin/users', { params: { all: true, limit: 200 } });
      setUsers(r.data || []);
    } catch (err) {
      toast.error('Failed to load users');
    }
  };

  const set = (k, v) => setF(prev => ({ ...prev, [k]: v }));

  const submit = async (e) => {
    e.preventDefault();
    if (!selectedUser) return toast.error('Please select a member');
    
    setLoading(true);
    try {
      await api.post('/admin/attendance/manual', {
        user_id: selectedUser,
        ...f
      });
      toast.success('Attendance recorded');
      onSave();
    } catch (err) {
      toast.error(err.message || 'Failed to save attendance');
    } finally {
      setLoading(false);
    }
  };

  const filteredUsers = users.filter(u => 
    u.name?.toLowerCase().includes(search.toLowerCase()) || 
    u.phone?.includes(search) ||
    u.roll_no?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal-box glass-1" style={{ maxWidth: '450px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '18px' }}>
          <div>
            <div className="modal-title">Manual Attendance</div>
            <div className="modal-sub">Add or update attendance record</div>
          </div>
          <button onClick={onClose} className="btn btn-ghost btn-sm" style={{ padding: '7px' }}><X size={15} /></button>
        </div>

        <form onSubmit={submit}>
          {!userId && (
            <div className="input-wrap">
              <label className="input-label">Select Member *</label>
              {selectedUser ? (
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'space-between',
                  padding: '10px 14px',
                  background: 'rgba(255,255,255,0.05)',
                  borderRadius: '10px',
                  border: '1px solid var(--border-color)'
                }}>
                  <span style={{ fontWeight: '500' }}>{selectedUserName}</span>
                  <button type="button" onClick={() => { setSelectedUser(null); setSelectedUserName(''); }} className="btn btn-ghost btn-sm" style={{ padding: '4px' }}>Change</button>
                </div>
              ) : (
                <div className="search-bar" style={{ width: '100%', marginBottom: '10px' }}>
                  <Search size={14} style={{ color: 'var(--text-3)' }} />
                  <input 
                    placeholder="Search by name, phone, or roll no..." 
                    value={search} 
                    onChange={e => setSearch(e.target.value)}
                    autoFocus
                  />
                </div>
              )}
              
              {!selectedUser && search.length > 0 && (
                <div style={{ 
                  maxHeight: '200px', 
                  overflowY: 'auto', 
                  borderRadius: '10px', 
                  background: 'var(--card-bg)', 
                  border: '1px solid var(--border-color)',
                  marginBottom: '15px'
                }}>
                  {filteredUsers.length === 0 ? (
                    <div style={{ padding: '15px', textAlign: 'center', color: 'var(--text-3)', fontSize: '0.85rem' }}>No members found</div>
                  ) : filteredUsers.map(u => (
                    <div 
                      key={u.id} 
                      onClick={() => { setSelectedUser(u.id); setSelectedUserName(u.name); }}
                      style={{ 
                        padding: '10px 15px', 
                        cursor: 'pointer',
                        borderBottom: '1px solid rgba(255,255,255,0.05)',
                        transition: 'background 0.2s'
                      }}
                      onMouseEnter={e => e.currentTarget.style.background = 'rgba(255,255,255,0.05)'}
                      onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
                    >
                      <div style={{ fontWeight: '500', fontSize: '0.9rem' }}>{u.name}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-3)' }}>{u.phone} • {u.roll_no || 'No Roll No'}</div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {userId && (
            <div className="input-wrap">
              <label className="input-label">Member</label>
              <div style={{ 
                padding: '10px 14px',
                background: 'rgba(255,255,255,0.05)',
                borderRadius: '10px',
                border: '1px solid var(--border-color)',
                fontWeight: '500'
              }}>
                {userName}
              </div>
            </div>
          )}

          <div className="input-wrap">
            <label className="input-label">Date *</label>
            <input 
              type="date" 
              className="input-field" 
              value={f.date} 
              onChange={e => set('date', e.target.value)} 
              required 
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
            <div className="input-wrap">
              <label className="input-label">Time In</label>
              <input 
                type="time" 
                className="input-field" 
                value={f.time_in} 
                onChange={e => set('time_in', e.target.value)} 
              />
              <p style={{ fontSize: '0.65rem', color: 'var(--text-3)', marginTop: '4px' }}>Leave empty for current time</p>
            </div>
            <div className="input-wrap">
              <label className="input-label">Time Out</label>
              <input 
                type="time" 
                className="input-field" 
                value={f.time_out} 
                onChange={e => set('time_out', e.target.value)} 
              />
            </div>
          </div>

          <div className="modal-footer" style={{ marginTop: '20px' }}>
            <button type="button" className="btn btn-ghost" style={{ flex: 1, justifyContent: 'center' }} onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-lime" style={{ flex: 1, justifyContent: 'center' }} disabled={loading || (!userId && !selectedUser)}>
              {loading ? 'Saving...' : 'Save Attendance'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
