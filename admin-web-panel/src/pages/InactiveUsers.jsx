import { useState, useEffect, useCallback } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { RefreshCcw, UserCheck } from 'lucide-react';
import { Topbar } from './Dashboard';

export default function InactiveUsers() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [restoring, setRestoring] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const r = await api.get('/admin/users/inactive');
      setUsers(r.data || []);
    } catch { toast.error('Failed to load inactive members'); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const restore = async (id, name) => {
    if (!confirm(`Restore ${name} to active status?`)) return;
    setRestoring(id);
    try {
      await api.post(`/admin/users/${id}/restore`);
      toast.success(`${name} restored to active`);
      load();
    } catch(e) { toast.error(e.message||'Restore failed'); }
    finally { setRestoring(null); }
  };

  return (
    <>
      <Topbar title="Inactive Members" sub={`${users.length} members need attention`} />
      <div className="page-body">

        {/* Info banner */}
        <div className="card fade-up-1" style={{ marginBottom:'18px', borderColor:'rgba(255,107,107,0.2)', background:'rgba(255,107,107,0.04)', padding:'14px 20px' }}>
          <div style={{ display:'flex', alignItems:'center', gap:'12px' }}>
            <span style={{ fontSize:'20px' }}>⚠️</span>
            <div>
              <div style={{ fontWeight:'600', fontSize:'0.9rem' }}>Inactivity Policy</div>
              <div style={{ fontSize:'0.78rem', color:'var(--text-2)', marginTop:'2px' }}>
                Members are marked inactive after 180 days without attendance or with expired membership. 
                After a 30-day grace period, their accounts are archived.
              </div>
            </div>
          </div>
        </div>

        <div className="card table-card fade-up-2">
          <div className="table-header">
            <h3>Inactive / Grace Period Members</h3>
            <button className="btn btn-ghost btn-sm" onClick={load}><RefreshCcw size={14}/></button>
          </div>
          {loading ? (
            <div style={{ padding:'40px', display:'flex', justifyContent:'center' }}>
              <div className="spinner spinner-light" style={{ width:'26px', height:'26px' }}/>
            </div>
          ) : (
            <table>
              <thead>
                <tr><th>Member</th><th>Phone</th><th>Plan</th><th>Expired</th><th>Status</th><th>Action</th></tr>
              </thead>
              <tbody>
                {users.length === 0 ? (
                  <tr><td colSpan={6}><div className="empty-state"><UserCheck size={32}/><p>No inactive members — great retention!</p></div></td></tr>
                ) : users.map(u => (
                  <tr key={u.id}>
                    <td>
                      <div style={{ display:'flex', alignItems:'center', gap:'10px' }}>
                        <div className="avatar-circle" style={{ width:'30px', height:'30px', fontSize:'0.72rem' }}>
                          {(u.name||'?')[0].toUpperCase()}
                        </div>
                        <div>
                          <div style={{ fontWeight:'500' }}>{u.name}</div>
                          {u.roll_no && <div style={{ fontSize:'0.72rem', color:'var(--text-3)' }}>#{u.roll_no}</div>}
                        </div>
                      </div>
                    </td>
                    <td style={{ fontFamily:'monospace', fontSize:'0.82rem', color:'var(--text-2)' }}>{u.phone}</td>
                    <td><span className="badge badge-blue">{u.membership_plan||'Standard'}</span></td>
                    <td style={{ fontSize:'0.82rem', color:'var(--coral)' }}>{u.membership_expiry ? new Date(u.membership_expiry).toLocaleDateString('en-IN') : '—'}</td>
                    <td><span className={`badge ${u.status==='grace' ? 'badge-red' : 'badge-gray'}`}><span className="badge-dot"/>{u.status}</span></td>
                    <td>
                      <button className="btn btn-primary btn-sm" onClick={() => restore(u.id, u.name)} disabled={restoring===u.id}>
                        {restoring===u.id ? '...' : <><UserCheck size={13}/> Restore</>}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </>
  );
}
