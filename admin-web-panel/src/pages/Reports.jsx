import { useState } from 'react';
import { getNowIST, getTodayISTStr, formatIST, getDaysLeftIST } from '../utils/dateUtils';
import api from '../api';
import toast from 'react-hot-toast';
import { Download, FileBarChart } from 'lucide-react';
import { Topbar } from '../components/Topbar';
import { fmtIST } from '../utils/time';

export default function Reports() {
  const [from, setFrom] = useState(() => {
    const d = new Date(); d.setMonth(d.getMonth()-1);
    return d.toISOString().split('T')[0];
  });
  const [to, setTo] = useState(getTodayISTStr());
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);

  const getDurationLabel = (timeIn, timeOut) => {
    const inT = timeIn ? new Date(timeIn) : null;
    const outT = timeOut ? new Date(timeOut) : null;
    const dur = inT && outT ? Math.round((outT - inT) / 60000) : null;
    if (!dur && dur !== 0) return '—';
    return dur >= 60 ? `${Math.floor(dur / 60)}h ${dur % 60}m` : `${dur}m`;
  };

  const run = async (e) => {
    e?.preventDefault();
    if (!from || !to) {
      toast.error('Please select both dates');
      return;
    }
    if (from > to) {
      toast.error('From date cannot be after To date');
      return;
    }
    setLoading(true);
    try {
      const r = await api.get('/admin/reports/attendance', { params: { from, to } });
      setRows(r.data || []);
      toast.success(`Loaded ${r.data?.length || 0} records`);
    } catch(e) { toast.error(e.message||'Failed'); }
    finally { setLoading(false); }
  };

  const downloadAttendanceCSV = async (preset) => {
    let queryFrom = from;
    let queryTo = to;

    if (preset === 'today') {
      const d = getTodayISTStr();
      queryFrom = d;
      queryTo = d;
    } else if (preset === 'month') {
      const d = new Date();
      queryFrom = new Date(d.getFullYear(), d.getMonth(), 1).toISOString().split('T')[0];
      queryTo = d.toISOString().split('T')[0];
    }

    setLoading(true);
    let dataToExport = [];
    try {
      const r = await api.get('/admin/reports/attendance', { params: { from: queryFrom, to: queryTo } });
      dataToExport = r.data || [];
      if (!dataToExport.length) { toast.error('No data found for this range'); return; }
    } catch (e) { toast.error('Failed to fetch data'); return; }
    finally { setLoading(false); }

    const headers = ['Name','Phone','Roll No','Date','Check In (IST)','Check Out (IST)','Duration'];
    const cols = dataToExport.map(r => [
      r.users?.name||'', r.users?.phone||'', r.users?.roll_no || '', r.date||'',
      fmtIST(r.time_in),
      fmtIST(r.time_out),
      getDurationLabel(r.time_in, r.time_out),
    ]);
    const csv = [headers, ...cols].map(r => r.map(v => `"${v}"`).join(',')).join('\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([csv], { type:'text/csv' }));
    a.download = `attendance_${preset || 'custom'}_${queryFrom}_to_${queryTo}.csv`;
    a.click();
  };

  return (
    <>
      <Topbar title="Reports" sub="Export and analyze attendance data (IST)" />
      <div className="page-body">
        <div className="card fade-up-1" style={{ marginBottom:'20px' }}>
          <h3 style={{ fontSize:'0.95rem', fontWeight:'600', marginBottom:'16px', display:'flex', alignItems:'center', gap:'8px' }}>
            <FileBarChart size={16} style={{ color:'var(--primary)' }}/> Date Range Query
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
            <button type="submit" className="btn btn-primary" disabled={loading} style={{ marginBottom:'1px' }}>
              {loading ? 'Loading...' : 'Generate Report'}
            </button>
          </form>
        </div>

        <div className="grid-2" style={{ marginBottom:'20px' }}>
          <div className="card fade-up-2">
            <h3 style={{ fontSize:'0.95rem', fontWeight:'600', marginBottom:'16px', display:'flex', alignItems:'center', gap:'8px' }}>
              <Download size={16} style={{ color:'var(--primary)' }}/> Attendance Downloads
            </h3>
            <p style={{ fontSize:'0.82rem', color:'var(--text-2)', marginBottom:'18px' }}>
              Select a quick preset or use the custom range above to export detailed check-in logs.
            </p>
            <div style={{ display:'flex', flexDirection:'column', gap:'10px' }}>
              <button className="btn btn-ghost" onClick={() => downloadAttendanceCSV('today')} disabled={loading} style={{ justifyContent:'center' }}>
                <Download size={15}/> Download Today's Report
              </button>
              <button className="btn btn-ghost" onClick={() => downloadAttendanceCSV('month')} disabled={loading} style={{ justifyContent:'center' }}>
                <Download size={15}/> Download This Month
              </button>
              <button className="btn btn-primary" onClick={() => downloadAttendanceCSV()} disabled={loading} style={{ justifyContent:'center' }}>
                <Download size={15}/> Export Custom Range
              </button>
            </div>
          </div>
          <div className="card fade-up-2" style={{ display:'flex', flexDirection:'column', justifyContent:'center' }}>
             <div style={{ display:'flex', alignItems:'center', gap:'12px', marginBottom:'16px' }}>
               <div style={{ padding:'10px', borderRadius:'10px', background:'var(--primary-dim)' }}>
                 <FileBarChart size={20} style={{ color:'var(--primary)' }}/>
               </div>
               <div>
                 <h4 style={{ fontSize:'0.9rem', fontWeight:'700' }}>System Health</h4>
                 <p style={{ fontSize:'0.75rem', color:'var(--text-3)' }}>Real-time reporting status</p>
               </div>
             </div>
             <p style={{ fontSize:'0.82rem', color:'var(--text-2)', lineHeight:'1.5' }}>
               All reports are generated using India Standard Time (IST). Ensure your local system clock is correctly synchronized for accurate check-in timestamps.
             </p>
          </div>
        </div>

        {rows.length > 0 && (
          <div className="card table-card fade-up-2">
            <div className="table-header">
              <h3>Results — {rows.length} records</h3>
            </div>
            <table>
              <thead><tr><th>Member</th><th>Phone</th><th>Date</th><th>Check In</th><th>Check Out</th><th>Duration</th></tr></thead>
              <tbody>
                {rows.map((r,i) => {
                  const outT = r.time_out ? new Date(r.time_out) : null;
                  const durStr = getDurationLabel(r.time_in, r.time_out);
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
                      <td style={{ fontFamily:'monospace', color:'var(--primary)', fontWeight:'600' }}>
                        {fmtIST(r.time_in)}
                      </td>
                      <td style={{ fontFamily:'monospace', color: outT ? 'var(--text-2)' : 'var(--coral)', fontWeight:'600' }}>
                        {fmtIST(r.time_out)}
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
