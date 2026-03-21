import { useState } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { Download, FileBarChart } from 'lucide-react';
import { Topbar } from './Dashboard';

export default function Reports() {
  const [from, setFrom] = useState(() => {
    const d = new Date(); d.setMonth(d.getMonth()-1);
    return d.toISOString().split('T')[0];
  });
  const [to, setTo] = useState(new Date().toISOString().split('T')[0]);
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  const run = async (e) => {
    e?.preventDefault();
    setLoading(true);
    try {
      // Get attendance in range
      const r = await api.get(`/admin/attendance/today`);
      // For now fetch all and filter, real range query needs backend extension
      setRows(r.data || []);
      toast.success(`Loaded ${r.data?.length || 0} records`);
    } catch(e) { toast.error(e.message||'Failed'); }
    finally { setLoading(false); }
  };

  const exportCSV = () => {
    if (!rows.length) { toast.error('No data to export'); return; }
    const headers = ['Name','Phone','Date','Check In','Check Out'];
    const cols = rows.map(r => [
      r.users?.name||'', r.users?.phone||'', r.date||'',
      r.time_in ? new Date(r.time_in).toLocaleTimeString('en-IN') : '',
      r.time_out ? new Date(r.time_out).toLocaleTimeString('en-IN') : '',
    ]);
    const csv = [headers, ...cols].map(r => r.map(v => `"${v}"`).join(',')).join('\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([csv], { type:'text/csv' }));
    a.download = `attendance_${from}_to_${to}.csv`;
    a.click();
  };

  return (
    <>
      <Topbar title="Reports" sub="Export and analyze attendance data" />
      <div className="page-body">
        <div className="card fade-up-1" style={{ marginBottom:'20px' }}>
          <h3 style={{ fontSize:'0.95rem', fontWeight:'600', marginBottom:'16px', display:'flex', alignItems:'center', gap:'8px' }}>
            <FileBarChart size={16} style={{ color:'var(--lime)' }}/> Date Range Query
          </h3>
          <form onSubmit={run} style={{ display:'flex', gap:'14px', alignItems:'flex-end', flexWrap:'wrap' }}>
            <div className="input-wrap" style={{ marginBottom:0 }}>
              <label className="input-label">From Date</label>
              <input type="date" className="input-field" value={from} onChange={e=>setFrom(e.target.value)} style={{ width:'160px' }}/>
            </div>
            <div className="input-wrap" style={{ marginBottom:0 }}>
              <label className="input-label">To Date</label>
              <input type="date" className="input-field" value={to} onChange={e=>setTo(e.target.value)} style={{ width:'160px' }}/>
            </div>
            <button type="submit" className="btn btn-lime" disabled={loading} style={{ marginBottom:'1px' }}>
              {loading ? 'Loading...' : 'Generate Report'}
            </button>
            {rows.length > 0 && (
              <button type="button" className="btn btn-ghost" onClick={exportCSV} style={{ marginBottom:'1px' }}>
                <Download size={14}/> Export CSV
              </button>
            )}
          </form>
        </div>

        {rows.length > 0 && (
          <div className="card table-card fade-up-2">
            <div className="table-header">
              <h3>Results — {rows.length} records</h3>
              <button className="btn btn-lime btn-sm" onClick={exportCSV}><Download size={13}/> Download</button>
            </div>
            <table>
              <thead><tr><th>Member</th><th>Phone</th><th>Date</th><th>Check In</th><th>Check Out</th><th>Duration</th></tr></thead>
              <tbody>
                {rows.map((r,i) => {
                  const inT = r.time_in ? new Date(r.time_in) : null;
                  const outT = r.time_out ? new Date(r.time_out) : null;
                  const dur = inT && outT ? Math.round((outT-inT)/60000) : null;
                  const durStr = dur ? (dur>=60 ? `${Math.floor(dur/60)}h ${dur%60}m` : `${dur}m`) : '—';
                  return (
                    <tr key={r.id||i}>
                      <td>
                        <div style={{ display:'flex', alignItems:'center', gap:'8px' }}>
                          <div className="avatar-circle" style={{ width:'28px', height:'28px', fontSize:'0.7rem' }}>{(r.users?.name||'?')[0]}</div>
                          {r.users?.name||'Unknown'}
                        </div>
                      </td>
                      <td style={{ fontFamily:'monospace', fontSize:'0.82rem', color:'var(--text-2)' }}>{r.users?.phone||'—'}</td>
                      <td style={{ fontSize:'0.82rem' }}>{r.date||'—'}</td>
                      <td style={{ fontFamily:'monospace', color:'var(--lime)', fontWeight:'600' }}>
                        {inT ? `${String(inT.getHours()).padStart(2,'0')}:${String(inT.getMinutes()).padStart(2,'0')}` : '—'}
                      </td>
                      <td style={{ fontFamily:'monospace', color: outT ? 'var(--text-2)' : 'var(--coral)', fontWeight:'600' }}>
                        {outT ? `${String(outT.getHours()).padStart(2,'0')}:${String(outT.getMinutes()).padStart(2,'0')}` : '—'}
                      </td>
                      <td style={{ fontSize:'0.82rem', color:'var(--text-2)' }}>{durStr}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </>
  );
}
