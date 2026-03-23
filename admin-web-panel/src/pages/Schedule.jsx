import { useState, useEffect, useCallback } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { RefreshCcw, Plus, Trash2, Calendar } from 'lucide-react';
import { Topbar } from '../components/Topbar';

const DAYS = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
const DAY_LABELS = { monday:'Monday', tuesday:'Tuesday', wednesday:'Wednesday', thursday:'Thursday', friday:'Friday', saturday:'Saturday', sunday:'Sunday' };

export default function Schedule() {
  const [schedule, setSchedule] = useState([]);
  const [holidays, setHolidays] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showHolidayForm, setShowHolidayForm] = useState(false);
  const [newHoliday, setNewHoliday] = useState({ date:'', reason:'', is_closed:true });
  const [saving, setSaving] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [s, h] = await Promise.all([api.get('/schedule/weekly'), api.get('/schedule/holidays')]);
      // Fill all 7 days even if some missing
      const map = {};
      (s.data||[]).forEach(d => { map[d.day_of_week] = d; });
      setSchedule(DAYS.map(day => map[day] || { day_of_week: day, is_open: true, open_time: '05:00', close_time: '22:00' }));
      setHolidays((h.data||[]).sort((a,b) => new Date(b.date) - new Date(a.date)));
    } catch { toast.error('Failed to load schedule'); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const updateDay = async (day, field, value) => {
    const updated = schedule.map(d => d.day_of_week === day ? { ...d, [field]: value } : d);
    setSchedule(updated);
    const row = updated.find(d => d.day_of_week === day);
    setSaving(day);
    try {
      await api.put(`/schedule/weekly/${day}`, { is_open: row.is_open, open_time: row.open_time, close_time: row.close_time });
      toast.success(`${DAY_LABELS[day]} updated`);
    } catch(e) { toast.error(e.message||'Save failed'); }
    finally { setSaving(''); }
  };

  const addHoliday = async (e) => {
    e.preventDefault();
    try {
      await api.post('/schedule/holidays', newHoliday);
      toast.success('Holiday added');
      setNewHoliday({ date:'', reason:'', is_closed:true });
      setShowHolidayForm(false);
      load();
    } catch(e) { toast.error(e.message||'Failed'); }
  };

  const deleteHoliday = async (id) => {
    if (!confirm('Remove this holiday?')) return;
    try { await api.delete(`/schedule/holidays/${id}`); toast.success('Removed'); load(); }
    catch(e) { toast.error(e.message||'Failed'); }
  };

  return (
    <>
      <Topbar title="Schedule & Holidays" sub="Manage gym timing and closures" />
      <div className="page-body">
        {/* Weekly schedule */}
        <div className="card fade-up-1" style={{ marginBottom:'20px' }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'18px' }}>
            <div>
              <h3 style={{ fontSize:'1rem', fontWeight:'600' }}>Weekly Operating Hours</h3>
              <p style={{ fontSize:'0.78rem', color:'var(--text-2)', marginTop:'2px' }}>Changes save automatically</p>
            </div>
            <button className="btn btn-ghost btn-sm" onClick={load}><RefreshCcw size={14}/></button>
          </div>
          {loading ? <div style={{ height:'200px', display:'flex', alignItems:'center', justifyContent:'center' }}><div className="spinner spinner-light" style={{ width:'28px', height:'28px' }}/></div> : (
            <div className="schedule-grid">
              {schedule.map(row => (
                <div key={row.day_of_week} className="schedule-row" style={{ opacity: saving === row.day_of_week ? 0.6 : 1 }}>
                  <span className="day-label">{DAY_LABELS[row.day_of_week]}</span>
                  <label className="toggle-switch">
                    <input type="checkbox" checked={row.is_open} onChange={e => updateDay(row.day_of_week, 'is_open', e.target.checked)} />
                    <span className="toggle-slider" />
                  </label>
                  <div style={{ display:'flex', alignItems:'center', gap:'6px' }}>
                    <span style={{ fontSize:'0.72rem', color:'var(--text-3)' }}>Open</span>
                    <input type="time" className="input-field" value={row.open_time?.slice(0,5)||'05:00'} style={{ width:'100px', padding:'5px 8px', opacity: row.is_open ? 1 : 0.3 }}
                      onChange={e => updateDay(row.day_of_week, 'open_time', e.target.value)} disabled={!row.is_open} />
                  </div>
                  <div style={{ display:'flex', alignItems:'center', gap:'6px' }}>
                    <span style={{ fontSize:'0.72rem', color:'var(--text-3)' }}>Close</span>
                    <input type="time" className="input-field" value={row.close_time?.slice(0,5)||'22:00'} style={{ width:'100px', padding:'5px 8px', opacity: row.is_open ? 1 : 0.3 }}
                      onChange={e => updateDay(row.day_of_week, 'close_time', e.target.value)} disabled={!row.is_open} />
                  </div>
                  <span className={`badge ${row.is_open ? 'badge-green' : 'badge-red'}`}>
                    <span className="badge-dot"/>{row.is_open ? 'Open' : 'Closed'}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Holidays */}
        <div className="card table-card fade-up-2">
          <div className="table-header">
            <div>
              <h3>Holiday Calendar</h3>
              <p style={{ fontSize:'0.75rem', color:'var(--text-2)', marginTop:'2px' }}>{holidays.length} entries</p>
            </div>
            <button className="btn btn-primary btn-sm" onClick={() => setShowHolidayForm(!showHolidayForm)}>
              <Plus size={14}/> Add Holiday
            </button>
          </div>

          {showHolidayForm && (
            <form onSubmit={addHoliday} style={{ padding:'18px 22px', borderBottom:'1px solid var(--glass-border)', display:'grid', gridTemplateColumns:'180px 1fr 130px auto', gap:'10px', alignItems:'end' }}>
              <div>
                <div className="input-label">Date</div>
                <input type="date" className="input-field" value={newHoliday.date} onChange={e=>setNewHoliday(h=>({...h,date:e.target.value}))} required/>
              </div>
              <div>
                <div className="input-label">Reason</div>
                <input className="input-field" placeholder="e.g. Republic Day" value={newHoliday.reason} onChange={e=>setNewHoliday(h=>({...h,reason:e.target.value}))} required/>
              </div>
              <div>
                <div className="input-label">Status</div>
                <select className="input-field" value={newHoliday.is_closed?.toString()} onChange={e=>setNewHoliday(h=>({...h,is_closed:e.target.value==='true'}))}>
                  <option value="true">Closed</option>
                  <option value="false">Open</option>
                </select>
              </div>
              <button type="submit" className="btn btn-primary btn-sm" style={{ alignSelf:'flex-end' }}>Save</button>
            </form>
          )}

          <table>
            <thead><tr><th>Date</th><th>Reason</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
              {holidays.length === 0 ? (
                <tr><td colSpan={4}><div className="empty-state"><Calendar size={32}/><p>No holidays recorded</p></div></td></tr>
              ) : holidays.map(h => (
                <tr key={h.id}>
                  <td style={{ fontFamily:'monospace', fontWeight:'600' }}>{new Date(h.date).toLocaleDateString('en-IN')}</td>
                  <td>{h.reason}</td>
                  <td><span className={`badge ${h.is_closed ? 'badge-red' : 'badge-green'}`}><span className="badge-dot"/>{h.is_closed?'Closed':'Open'}</span></td>
                  <td><button className="btn btn-danger btn-sm" onClick={() => deleteHoliday(h.id)}><Trash2 size={13}/></button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
