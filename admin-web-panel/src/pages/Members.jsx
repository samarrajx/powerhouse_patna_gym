import { useState, useCallback, useRef, useEffect } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { UserPlus, Search, RefreshCcw, X, Upload, Download, Edit2, Key, Shield, MessageCircle, CalendarCheck, Pause, Play } from 'lucide-react';
import AttendanceModal from '../components/AttendanceModal';


import { Topbar } from './Dashboard';

function MemberModal({ user, batches, onClose, onSave }) {
  const [f, setF] = useState(user ? {
    name: user.name||'', phone: user.phone||'', phone_alt: user.phone_alt||'', roll_no: user.roll_no||'',
    address: user.address||'', father_name: user.father_name||'',
    date_of_joining: user.date_of_joining ? String(user.date_of_joining).split('T')[0] : new Date().toISOString().split('T')[0],
    body_type: user.body_type||'normal', membership_plan: user.membership_plan||'Standard',
    batch_id: user.batch_id||(batches?.[0]?.id || ''),
    membership_expiry: user.membership_expiry ? String(user.membership_expiry).split('T')[0] : '',
    fees_status: user.fees_status||'paid', notes: user.notes||''
  } : { 
    name:'', phone:'', phone_alt:'', roll_no:'', address:'', father_name:'',
    date_of_joining: new Date().toISOString().split('T')[0], body_type:'normal',
    batch_id: batches?.[0]?.id || '',
    membership_plan:'Standard', membership_expiry:'', fees_status:'paid', notes:'' 
  });
  
  const [saving, setSaving] = useState(false);
  const set = (k, v) => setF(prev => ({ ...prev, [k]: v }));

  const submit = async (e) => {
    e.preventDefault(); setSaving(true);
    try {
      if (user) {
        await api.put(`/admin/users/${user.id}`, f);
        toast.success('Member updated');
      } else {
        await api.post('/admin/users/onboard', { ...f, password:'samgym' });
        toast.success('Member created! Password: samgym'); 
      }
      onSave();
    } catch(err) { toast.error(err.message||'Failed'); }
    finally { setSaving(false); }
  };

  const PLANS = ['Standard','Monthly','Quarterly','Semi-Annual','Annual'];
  const BODY_TYPES = ['skinny','normal','fatty'];


  return (
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal-box">
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'18px' }}>
          <div>
            <div className="modal-title">{user ? 'Edit Member' : 'New Member'}</div>
            {!user && <div className="modal-sub">Default password: <b>samgym</b></div>}
          </div>
          <button onClick={onClose} className="btn btn-ghost btn-sm" style={{ padding:'7px' }}><X size={15}/></button>
        </div>
        <form onSubmit={submit}>
          <p style={{ fontSize:'0.72rem', color:'var(--text-3)', marginBottom:'12px', textTransform:'uppercase', letterSpacing:'0.08em' }}>Personal Info</p>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'0 14px' }}>
            <div className="input-wrap"><label className="input-label">Full Name *</label><input className="input-field" value={f.name} onChange={e=>set('name',e.target.value)} required/></div>
            <div className="input-wrap"><label className="input-label">Phone *</label><input className="input-field" type="tel" value={f.phone} onChange={e=>set('phone',e.target.value)} required/></div>
            <div className="input-wrap"><label className="input-label">Alt. Phone</label><input className="input-field" type="tel" value={f.phone_alt} onChange={e=>set('phone_alt',e.target.value)}/></div>
            <div className="input-wrap"><label className="input-label">Roll No.</label><input className="input-field" value={f.roll_no} onChange={e=>set('roll_no',e.target.value)}/></div>
          </div>
          <div className="input-wrap"><label className="input-label">Father's Name</label><input className="input-field" value={f.father_name} onChange={e=>set('father_name',e.target.value)}/></div>
          <div className="input-wrap"><label className="input-label">Address</label><input className="input-field" value={f.address} onChange={e=>set('address',e.target.value)}/></div>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'0 14px' }}>
            <div className="input-wrap"><label className="input-label">Date of Joining</label><input type="date" className="input-field" value={f.date_of_joining} onChange={e=>set('date_of_joining',e.target.value)}/></div>
            <div className="input-wrap"><label className="input-label">Body Type</label><select className="input-field" value={f.body_type} onChange={e=>set('body_type',e.target.value)}>{BODY_TYPES.map(b=><option key={b}>{b}</option>)}</select></div>
          </div>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'0 14px' }}>
            <div className="input-wrap">
              <label className="input-label">Batch</label>
              <select className="input-field" value={f.batch_id} onChange={e=>set('batch_id',e.target.value)}>
                {batches.map(b=><option key={b.id} value={b.id}>{b.name}</option>)}
                {batches.length === 0 && <option value="">No Batches</option>}
              </select>
            </div>
            <div className="input-wrap">
              <label className="input-label">Plan</label>
              <select className="input-field" value={f.membership_plan} onChange={e=>set('membership_plan',e.target.value)}>
                {PLANS.map(p=><option key={p}>{p}</option>)}
              </select>
            </div>
          </div>
          <p style={{ fontSize:'0.72rem', color:'var(--text-3)', margin:'4px 0 12px', textTransform:'uppercase', letterSpacing:'0.08em' }}>Membership</p>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'0 14px' }}>
            <div className="input-wrap"><label className="input-label">Expiry</label><input type="date" className="input-field" value={f.membership_expiry} onChange={e=>set('membership_expiry',e.target.value)}/></div>
            <div className="input-wrap"><label className="input-label">Fees</label><select className="input-field" value={f.fees_status} onChange={e=>set('fees_status',e.target.value)}><option value="paid">Paid</option><option value="pending">Pending</option><option value="overdue">Overdue</option></select></div>
          </div>
          <div className="input-wrap"><label className="input-label">Notes</label><input className="input-field" placeholder="Optional notes" value={f.notes} onChange={e=>set('notes',e.target.value)}/></div>
          <div className="modal-footer">
            <button type="button" className="btn btn-ghost" style={{ flex:1, justifyContent:'center' }} onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-primary" style={{ flex:1, justifyContent:'center' }} disabled={saving}>{saving?(user?'Saving...':'Creating...'):(user?'Save Changes':'Create Member')}</button>
          </div>
        </form>
      </div>
    </div>
  );
}

function ConfirmModal({ title, message, onConfirm, onClose, loading }) {
  return (
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal-box glass-2" style={{ maxWidth:'400px' }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'14px' }}>
          <h3 className="modal-title" style={{ fontSize:'1.1rem' }}>{title}</h3>
          <button onClick={onClose} className="btn btn-ghost btn-sm" style={{ padding:'7px' }}><X size={15}/></button>
        </div>
        <p style={{ fontSize:'0.85rem', color:'var(--text-2)', marginBottom:'20px', lineHeight:'1.5' }}>{message}</p>
        <div className="modal-footer" style={{ marginTop:'0' }}>
          <button type="button" className="btn btn-ghost" style={{ flex:1, justifyContent:'center' }} onClick={onClose} disabled={loading}>Cancel</button>
          <button type="button" className="btn btn-primary" style={{ flex:1, justifyContent:'center' }} onClick={onConfirm} disabled={loading}>
            {loading ? <div className="spinner spinner-dark" style={{ width:'14px', height:'14px' }}/> : 'Confirm'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function Members() {

  const [users, setUsers] = useState([]);
  const [batches, setBatches] = useState([]);
  const [templates, setTemplates] = useState([]);
  const [loading, setLoading] = useState(true);

  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [modalUser, setModalUser] = useState(null);
  const [confirmData, setConfirmData] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [acting, setActing] = useState(false);
  const [attendanceUser, setAttendanceUser] = useState(null);
  const fileRef = useRef();


  const load = useCallback(async () => {
    setLoading(true);
    try { 
      const [uRes, tRes, bRes] = await Promise.all([
        api.get('/admin/users').catch(e => ({ data: [] })),
        api.get('/admin/templates').catch(e => ({ data: [] })),
        api.get('/admin/batches').catch(e => ({ data: null }))
      ]);
      setUsers(uRes.data || []); 
      setTemplates(tRes.data || []);
      
      if (bRes.data && bRes.data.length > 0) {
        setBatches(bRes.data);
      } else {
        setBatches([
          { id: '0515f242-095a-4cae-8e5e-78d5780bbf99', name: 'Morning Batch' },
          { id: '74115ffe-6b7b-4071-96cc-f6a5cb4937f9', name: 'Evening Batch' }
        ]);
      }
    }
    catch (e) { 
      toast.error('Failed to load data'); 
      console.error(e);
    }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { 
    load(); 
  }, [load]);
  const downloadSample = () => {
    const headers = ['name','phone','phone_alt','roll_no','father_name','address','date_of_joining','body_type','membership_plan','membership_expiry','fees_status','notes'];
    const examples = [
      ['Rahul Sharma','9876543210','9876543211','GYM001','Ramesh Sharma','12 MG Road, Delhi','2026-01-15','athletic','Gold','2027-01-15','paid','Morning batch preferred'],
      ['Priya Singh','9123456780','','GYM002','Vijay Singh','45 Park Street, Mumbai','2026-02-01','slim','Standard','2026-08-01','paid',''],
    ];
    const csv = [headers, ...examples].map(row => row.map(v => `"${v}"`).join(',')).join('\n');
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    a.download = 'powerhouse_members_sample.csv';
    a.click();
  };

  const handleCSV = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    const form = new FormData();
    form.append('file', file);
    try {
      const r = await api.post('/admin/users/bulk', form, { headers:{ 'Content-Type':'multipart/form-data' }});
      toast.success(`${r.data.created} members imported, ${r.data.failed.length} failed`);
      load();
    } catch(e) { toast.error(e.message||'Upload failed'); }
    finally { setUploading(false); e.target.value=''; }
  };

  const handleResetPassword = async (id) => {
    setConfirmData({
      title: 'Reset Password',
      message: 'Reset this member\'s password to "samgym"? They will be forced to change it on their next login.',
      onConfirm: async () => {
        setActing(true);
        try {
          await api.post(`/admin/users/${id}/reset-password`);
          toast.success('Password reset to "samgym"');
          load();
          setConfirmData(null);
        } catch(e) { toast.error(e.message || 'Failed to reset password'); }
        finally { setActing(false); }
      }
    });
  };

  const handleRoleChange = async (user) => {
    const currentRole = user.role || 'user';
    const newRole = currentRole === 'admin' ? 'user' : 'admin';
    setConfirmData({
      title: 'Change Role',
      message: `Are you sure you want to change ${user.name}'s role to ${newRole.toUpperCase()}?`,
      onConfirm: async () => {
        setActing(true);
        try {
          await api.put(`/admin/users/${user.id}`, { role: newRole });
          toast.success(`Role changed to ${newRole}`);
          load();
          setConfirmData(null);
        } catch(e) {
          console.error('Role change error:', e);
          toast.error(e.message || 'Failed to change role');
        } finally { setActing(false); }
      }
    });
  };



  const handleWhatsApp = (user) => {
    const bodyType = (user.body_type || 'average').toLowerCase();
    const template = templates.find(t => t.category === bodyType) || templates[0];
    
    let msg = template ? template.message : "Hi {name}, how are you today?";
    msg = msg.replace('{name}', user.name);
    
    const phone = user.phone.replace(/\D/g, ''); // clean non-digits
    const waUrl = `https://wa.me/${phone.length === 10 ? '91'+phone : phone}?text=${encodeURIComponent(msg)}`;
    window.open(waUrl, '_blank');
  };

  const handleFreezeToggle = async (user) => {
    const isFrozen = user.is_frozen;
    setConfirmData({
      title: isFrozen ? 'Unfreeze Membership' : 'Freeze Membership',
      message: isFrozen 
        ? `Are you sure you want to unfreeze ${user.name}? Their expiry date will be pushed forward by the duration of the freeze.`
        : `Are you sure you want to freeze ${user.name}'s membership? They will be unable to check-in until unfrozen. Their membership clock will pause.`,
      onConfirm: async () => {
        setActing(true);
        try {
          const endpoint = isFrozen ? 'unfreeze' : 'freeze';
          const res = await api.post(`/admin/users/${user.id}/${endpoint}`);
          toast.success(res.message || (isFrozen ? 'Membership unfrozen' : 'Membership frozen'));
          load();
          setConfirmData(null);
        } catch(e) { toast.error(e.message || 'Action failed'); }
        finally { setActing(false); }
      }
    });
  };



  const filtered = users.filter(u => {
    const match = (u.name||'').toLowerCase().includes(search.toLowerCase()) ||
                  (u.phone||'').includes(search) ||
                  (u.roll_no||'').toLowerCase().includes(search.toLowerCase());
    
    if (!match) return false;
    if (filter === 'all') return true;
    if (filter === 'expired') {
      const today = new Date().toISOString().split('T')[0];
      return u.membership_expiry && u.membership_expiry < today;
    }
    if (filter === 'frozen') return u.is_frozen;
    return u.status === filter;
  });

  return (
    <>
      {modalUser && <MemberModal user={modalUser==='new'?null:modalUser} batches={batches} onClose={()=>setModalUser(null)} onSave={()=>{ setModalUser(null); load(); }}/>}
      {attendanceUser && (
        <AttendanceModal 
          userId={attendanceUser.id} 
          userName={attendanceUser.name} 
          onClose={() => setAttendanceUser(null)} 
          onSave={() => { setAttendanceUser(null); load(); }} 
        />
      )}
      {confirmData && <ConfirmModal {...confirmData} onClose={()=>setConfirmData(null)} loading={acting} />}
      <input ref={fileRef} type="file" accept=".csv" style={{ display:'none' }} onChange={handleCSV}/>

      <Topbar title="Members" sub={`${users.length} total members`}/>
      <div className="page-body">
        <div className="card table-card fade-up">
          <div className="table-header">
            <div style={{ display:'flex', alignItems:'center', gap:'10px', flexWrap:'wrap' }}>
              <div className="search-bar">
                <Search size={14} style={{ color:'var(--text-3)', flexShrink:0 }}/>
                <input placeholder="Name, phone, roll no..." value={search} onChange={e=>setSearch(e.target.value)}/>
                {search && <button onClick={()=>setSearch('')} style={{ background:'none',border:'none',cursor:'pointer',color:'var(--text-3)' }}><X size={13}/></button>}
              </div>
              {['all','active','inactive','grace','expired','frozen'].map(s=>(
                <button key={s} className={`btn btn-sm ${filter===s?'btn-primary':'btn-ghost'}`} onClick={()=>setFilter(s)} style={{ textTransform:'capitalize' }}>{s}</button>
              ))}
            </div>
            <div style={{ display:'flex', gap:'8px' }}>
              <button className="btn btn-ghost btn-sm" onClick={load}><RefreshCcw size={13}/></button>
              <button className="btn btn-ghost btn-sm" onClick={downloadSample} title="Download CSV template">
                <Download size={13}/> Sample
              </button>
              <button className="btn btn-ghost btn-sm" onClick={()=>fileRef.current?.click()} disabled={uploading}>
                <Upload size={13}/> {uploading?'Uploading...':'Upload CSV'}
              </button>
              <button className="btn btn-primary btn-sm" onClick={()=>setModalUser('new')}><UserPlus size={13}/> Add Member</button>
            </div>
          </div>
          {loading ? (
            <div style={{ padding:'40px', display:'flex', justifyContent:'center' }}><div className="spinner spinner-light" style={{ width:'26px', height:'26px' }}/></div>
          ) : (
            <div className="table-responsive">
              <table>
                <thead><tr><th>Member</th><th>Phone</th><th>Roll No</th><th>Plan</th><th>Batch</th><th>Role</th><th>Expires</th><th>Fees</th><th>Status</th><th>Actions</th></tr></thead>

                <tbody>
                  {filtered.length===0 ? (
                    <tr><td colSpan={10}><div className="empty-state"><p>No members found</p></div></td></tr>
                  ) : filtered.map(u=>(
                    <tr key={u.id}>
                      <td><div style={{ display:'flex', alignItems:'center', gap:'9px' }}><div className="avatar-circle" style={{ width:'30px', height:'30px', fontSize:'0.72rem' }}>{(u.name||'?')[0].toUpperCase()}</div><div><div style={{ fontWeight:'500' }}>{u.name}</div>{u.father_name&&<div style={{ fontSize:'0.7rem', color:'var(--text-3)' }}>S/o {u.father_name}</div>}</div></div></td>
                      <td style={{ fontFamily:'monospace', fontSize:'0.82rem', color:'var(--text-2)' }}>{u.phone}</td>
                      <td style={{ fontSize:'0.82rem', color:'var(--text-2)' }}>{u.roll_no||'—'}</td>
                      <td><span className="badge badge-blue">{u.membership_plan||'Standard'}</span></td>
                      <td><span className="badge badge-gray">{batches.find(b=>b.id===u.batch_id)?.name || '—'}</span></td>
                      <td><span className={`badge ${u.role==='admin'?'badge-purple':'badge-gray'}`} style={{ textTransform:'capitalize' }}>{u.role||'user'}</span></td>

                      <td style={{ fontSize:'0.82rem', color:'var(--text-2)' }}>{u.membership_expiry?new Date(u.membership_expiry).toLocaleDateString('en-IN'):'—'}</td>
                      <td><span className={`badge ${u.fees_status==='paid'?'badge-green':u.fees_status==='overdue'?'badge-red':'badge-gray'}`}><span className="badge-dot"/>{u.fees_status||'paid'}</span></td>
                      <td>
                        {u.is_frozen ? (
                          <span className="badge badge-purple"><span className="badge-dot"/>Frozen</span>
                        ) : (
                          <span className={`badge ${u.status==='active'?'badge-green':u.status==='grace'?'badge-red':'badge-gray'}`}><span className="badge-dot"/>{u.status||'active'}</span>
                        )}
                      </td>
                      <td>
                        <div style={{ display:'flex', gap:'5px' }}>
                          <button className="btn btn-ghost btn-sm" style={{ padding:'6px' }} onClick={()=>setModalUser(u)} title="Edit Member"><Edit2 size={13}/></button>
                          <button className="btn btn-ghost btn-sm" style={{ padding:'6px', color:'var(--blue)' }} onClick={() => setAttendanceUser(u)} title="Mark Attendance"><CalendarCheck size={13}/></button>
                          <button className="btn btn-ghost btn-sm" style={{ padding:'6px' }} onClick={()=>handleResetPassword(u.id)} title="Reset Password"><Key size={13}/></button>
                          <button className="btn btn-ghost btn-sm" style={{ padding:'6px', color:u.role==='admin'?'var(--purple)':'inherit' }} onClick={()=>handleRoleChange(u)} title="Assign Role"><Shield size={13}/></button>
                          <button className="btn btn-ghost btn-sm" style={{ padding:'6px', color:u.is_frozen?'var(--success)':'var(--primary)' }} onClick={()=>handleFreezeToggle(u)} title={u.is_frozen?'Unfreeze Membership':'Freeze Membership'}>{u.is_frozen?<Play size={13}/>:<Pause size={13}/>}</button>
                          <button className="btn btn-ghost btn-sm" style={{ padding:'6px', color:'#25D366' }} onClick={()=>handleWhatsApp(u)} title="Send WhatsApp"><MessageCircle size={13}/></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
