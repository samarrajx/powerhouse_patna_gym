import { useState, useEffect, useCallback } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { RefreshCcw, Clock, Plus } from 'lucide-react';
import AttendanceModal from '../components/AttendanceModal';
import { Topbar } from './Dashboard';

export default function Attendance() {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const r = await api.get('/admin/attendance/today');
      setRecords(r.data || []);
    } catch { toast.error('Failed to load attendance'); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const fmt = (iso) => {
    if (!iso) return '—';
    try { const d = new Date(iso); return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`; }
    catch { return '—'; }
  };

  return (
    <>
      <Topbar title="Attendance" sub={`Today — ${new Date().toLocaleDateString('en-IN', { weekday:'long', day:'numeric', month:'long' })}`} />
      <div className="page-body">
        {showModal && (
          <AttendanceModal 
            onClose={() => setShowModal(false)} 
            onSave={() => { setShowModal(false); load(); }} 
          />
        )}

        {/* Summary row */}
        <div className="grid-3" style={{ marginBottom:'20px' }}>
          {[
            { label:'Total Check-ins', value: records.length, color:'var(--lime)' },
            { label:'Still Present', value: records.filter(r=>!r.time_out).length, color:'var(--blue)' },
            { label:'Checked Out', value: records.filter(r=>r.time_out).length, color:'var(--text-2)' },
          ].map(({ label, value, color }, i) => (
            <div key={label} className={`card fade-up-${i+1}`} style={{ padding:'20px 24px' }}>
              <div className="card-title">{label}</div>
              <div className="card-value" style={{ fontSize:'2rem', color }}>{loading ? '—' : value}</div>
            </div>
          ))}
        </div>

        {/* Table */}
        <div className="card table-card fade-up-4">
          <div className="table-header">
            <h3>Check-in Log</h3>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button className="btn btn-ghost btn-sm" onClick={load}>
                <RefreshCcw size={14} /> Refresh
              </button>
              <button className="btn btn-lime btn-sm" onClick={() => setShowModal(true)}>
                <Plus size={14} /> Manual Entry
              </button>
            </div>
          </div>
          {loading ? (
            <div style={{ padding:'40px', display:'flex', justifyContent:'center' }}>
              <div className="spinner spinner-light" style={{ width:'28px', height:'28px' }} />
            </div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Member</th>
                  <th>Phone</th>
                  <th>Check In</th>
                  <th>Check Out</th>
                  <th>Duration</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {records.length === 0 ? (
                  <tr><td colSpan={6}>
                    <div className="empty-state">
                      <Clock size={36} />
                      <p>No check-ins recorded today yet</p>
                    </div>
                  </td></tr>
                ) : records.map((r, i) => {
                  const inTime = r.time_in ? new Date(r.time_in) : null;
                  const outTime = r.time_out ? new Date(r.time_out) : null;
                  let duration = '—';
                  if (inTime && outTime) {
                    const mins = Math.round((outTime - inTime) / 60000);
                    duration = mins >= 60 ? `${Math.floor(mins/60)}h ${mins%60}m` : `${mins}m`;
                  }
                  return (
                    <tr key={r.id || i}>
                      <td>
                        <div style={{ display:'flex', alignItems:'center', gap:'10px' }}>
                          <div className="avatar-circle" style={{ width:'30px', height:'30px', fontSize:'0.72rem' }}>
                            {(r.users?.name||'?')[0].toUpperCase()}
                          </div>
                          <span style={{ fontWeight:'500' }}>{r.users?.name || 'Unknown'}</span>
                        </div>
                      </td>
                      <td style={{ color:'var(--text-2)', fontFamily:'monospace', fontSize:'0.82rem' }}>{r.users?.phone || '—'}</td>
                      <td style={{ fontFamily:'monospace', color:'var(--lime)', fontWeight:'600' }}>{fmt(r.time_in)}</td>
                      <td style={{ fontFamily:'monospace', color: outTime ? 'var(--text-2)' : 'var(--coral)', fontWeight:'600' }}>{fmt(r.time_out)}</td>
                      <td style={{ color:'var(--text-2)', fontSize:'0.82rem' }}>{duration}</td>
                      <td>
                        {r.time_out
                          ? <span className="badge badge-gray"><span className="badge-dot"/>Checked Out</span>
                          : <span className="badge badge-green"><span className="badge-dot"/>Present</span>
                        }
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </>
  );
}
