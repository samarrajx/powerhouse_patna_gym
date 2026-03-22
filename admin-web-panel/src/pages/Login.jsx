import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import Logo from '../components/Logo';


export default function Login() {
  const { login, loading } = useAuth();
  const nav = useNavigate();
  const [phone, setPhone] = useState('');
  const [pass, setPass] = useState('');
  const [show, setShow] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    const res = await login(phone, pass);
    if (res.ok) nav('/dashboard', { replace: true });
    else setError(res.message || 'Invalid credentials');
  };

  return (
    <div className="login-page">
      <div className="login-card fade-up">
        <div className="login-logo-container" style={{ display:'flex', justifyContent:'center', marginBottom:'20px' }}>
          <Logo size={80} />
        </div>

        <h1 className="login-title">Admin Login</h1>
        <p className="login-sub">Power House Gym Management Console</p>

        {error && <div className="error-box">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="input-wrap">
            <label className="input-label">Phone Number</label>
            <input
              className="input-field"
              type="tel"
              placeholder="9999999999"
              value={phone}
              onChange={e => setPhone(e.target.value)}
              required
            />
          </div>
          <div className="input-wrap">
            <label className="input-label">Password</label>
            <div style={{ position: 'relative' }}>
              <input
                className="input-field"
                type={show ? 'text' : 'password'}
                placeholder="Enter password"
                value={pass}
                onChange={e => setPass(e.target.value)}
                required
                style={{ paddingRight: '44px' }}
              />
              <button type="button" onClick={() => setShow(!show)}
                style={{ position:'absolute', right:'12px', top:'50%', transform:'translateY(-50%)', background:'none', border:'none', cursor:'pointer', color:'var(--text-3)' }}>
                {show ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <button className="btn btn-primary" type="submit" disabled={loading}
            style={{ width:'100%', justifyContent:'center', marginTop:'8px', padding:'13px' }}>
            {loading ? <><div className="spinner" style={{ borderTopColor:'#000' }} /> Signing in...</> : 'Sign In to Console'}
          </button>
        </form>

      </div>
    </div>
  );
}
