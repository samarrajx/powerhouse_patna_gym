import { useState } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { useAuth } from '../AuthContext';
import { ShieldCheck, Bell, Database, Zap } from 'lucide-react';
import { Topbar } from '../components/Topbar';

export default function Settings() {
  const { user } = useAuth();
  const [phone, setPhone] = useState(user?.phone || '');
  const [oldPass, setOldPass] = useState('');
  const [newPass, setNewPass] = useState('');
  const [saving, setSaving] = useState(false);

  const changePass = async (e) => {
    e.preventDefault();
    if (newPass.length < 6) { toast.error('Password must be at least 6 characters'); return; }
    setSaving(true);
    try {
      await api.post('/auth/change-password', { oldPassword: oldPass, newPassword: newPass });
      toast.success('Password updated successfully');
      setOldPass(''); setNewPass('');
    } catch(err) {
      toast.error(err.message || 'Failed to update password');
    } finally { setSaving(false); }
  };

  return (
    <>
      <Topbar title={user?.role === 'admin' ? "Settings" : "Profile"} sub={user?.role === 'admin' ? "System configuration and security" : "Manage your account and security"} />
      <div className="page-body">
        <div style={{ maxWidth:'680px', display:'flex', flexDirection:'column', gap:'20px' }}>

          {/* Profile Card */}
          <div className="card fade-up-1">
            <div style={{ display:'flex', alignItems:'center', gap:'16px', marginBottom:'20px' }}>
              <div className="avatar-circle" style={{ width:'52px', height:'52px', fontSize:'1.3rem' }}>
                {(user?.name||'U')[0].toUpperCase()}
              </div>
              <div>
                <div style={{ fontWeight:'700', fontSize:'1.1rem' }}>{user?.name || 'Member'}</div>
                <div style={{ color:'var(--text-2)', fontSize:'0.82rem' }}>
                  {user?.role === 'admin' ? 'Super Administrator' : 'Gym Member'} • {user?.phone}
                </div>
                <span className="badge badge-green" style={{ marginTop:'6px' }}>
                  <span className="badge-dot" /> {user?.status ? user.status.toUpperCase() : 'ACTIVE'}
                </span>
              </div>
            </div>
            <div style={{ display:'grid', gridTemplateColumns: user?.role === 'admin' ? '1fr 1fr 1fr' : '1fr 1fr', gap:'12px' }}>
              {[
                ...(user?.role === 'admin' ? [{ label:'Role', value:'Administrator' }] : []),
                { label:'Phone', value: user?.phone || '—' },
                { label: user?.role === 'admin' ? 'Access Level' : 'Member ID', value: user?.role === 'admin' ? 'Full Access' : (user?.roll_no || '—') },
              ].map(({ label, value }) => (
                <div key={label} style={{ background:'var(--glass-bg-2)', border:'1px solid var(--glass-border)', borderRadius:'10px', padding:'12px 14px' }}>
                  <div style={{ fontSize:'0.68rem', color:'var(--text-3)', textTransform:'uppercase', letterSpacing:'0.08em', marginBottom:'4px' }}>{label}</div>
                  <div style={{ fontWeight:'600', fontSize:'0.875rem' }}>{value}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Change Password */}
          <div className="card fade-up-2">
            <div style={{ display:'flex', alignItems:'center', gap:'10px', marginBottom:'18px' }}>
              <ShieldCheck size={18} style={{ color:'var(--primary)' }} />
              <h3 style={{ fontSize:'1rem', fontWeight:'600' }}>Change Password</h3>
            </div>
            <form onSubmit={changePass}>
              <div className="input-wrap">
                <label className="input-label">Current Password</label>
                <input className="input-field" type="password" placeholder="••••••••" value={oldPass} onChange={e=>setOldPass(e.target.value)} required />
              </div>
              <div className="input-wrap">
                <label className="input-label">New Password</label>
                <input className="input-field" type="password" placeholder="Min. 6 characters" value={newPass} onChange={e=>setNewPass(e.target.value)} required />
              </div>
              <button className="btn btn-primary" type="submit" disabled={saving} style={{ marginTop:'4px' }}>
                {saving ? 'Saving...' : 'Update Password'}
              </button>
            </form>
          </div>

          {/* System Info - ONLY FOR ADMINS */}
          {user?.role === 'admin' && (
            <div className="card fade-up-3">
              <div style={{ display:'flex', alignItems:'center', gap:'10px', marginBottom:'18px' }}>
                <Database size={18} style={{ color:'var(--blue)' }} />
                <h3 style={{ fontSize:'1rem', fontWeight:'600' }}>System Status</h3>
              </div>
              {[
                { label:'Database', value:'PostgreSQL 15 (Supabase)', status:'Healthy', color:'var(--primary)' },
                { label:'API Server', value:'Node.js on Vercel', status:'Running', color:'var(--primary)' },
                { label:'Authentication', value:'JWT + Bcrypt', status:'Secured', color:'var(--primary)' },
                { label:'Security', value:'RLS Policies Active', status:'Enforced', color:'var(--primary)' },
                { label:'Daily CRON', value:'Inactivity cleanup at 02:00 IST', status:'Scheduled', color:'var(--blue)' },
              ].map(({ label, value, status, color }) => (
                <div key={label} style={{ display:'flex', justifyContent:'space-between', alignItems:'center', padding:'12px 0', borderBottom:'1px solid var(--glass-border)' }}>
                  <div>
                    <div style={{ fontWeight:'500', fontSize:'0.875rem' }}>{label}</div>
                    <div style={{ fontSize:'0.75rem', color:'var(--text-3)', marginTop:'2px' }}>{value}</div>
                  </div>
                  <span className="badge" style={{ 
                    background: color === 'var(--primary)' ? 'var(--badge-red)' : 'rgba(96,165,250,0.1)', 
                    color: color === 'var(--primary)' ? 'var(--badge-red-text)' : color, 
                    border:`1px solid ${color === 'var(--primary)' ? 'var(--badge-red-border)' : 'rgba(96,165,250,0.2)'}` 
                  }}>
                    <span className="badge-dot" style={{ background: color === 'var(--primary)' ? 'var(--badge-red-text)' : color }} />{status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  );
}
