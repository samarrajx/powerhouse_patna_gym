import { useState, useEffect, useRef } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { Zap, ShieldCheck } from 'lucide-react';
import { Topbar } from './Dashboard';

export default function QrStation() {
  const [qr, setQr] = useState(null);
  const [timeLeft, setTimeLeft] = useState(0);
  const [loading, setLoading] = useState(false);
  const timerRef = useRef(null);

  const fetchToken = async () => {
    setLoading(true);
    try {
      const res = await api.get('/qr/generate');
      const code = res.data?.qr_code || res.data?.code;
      setQr(code);
      setTimeLeft(60);
    } catch(e) {
      toast.error(e.message || 'Failed to generate QR');
      setQr(null);
      setTimeLeft(0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchToken();
    timerRef.current = setInterval(() => {
      setTimeLeft(prev => {
        if (prev <= 1) {
          fetchToken(); // Fetch a new one immediately when 0
          return 60;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timerRef.current);
  }, []);

  const pct = (timeLeft / 60) * 100;
  const danger = timeLeft <= 5;

  return (
    <>
      <Topbar title="QR Station" sub="Live autonomous attendance turnstile" />
      <div className="page-body">
        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'24px', maxWidth:'900px', margin:'0 auto' }}>

          {/* QR Panel */}
          <div className="card fade-up-1" style={{ display:'flex', flexDirection:'column', gap:'20px' }}>
            <div>
              <h3 style={{ fontSize:'1.1rem', fontWeight:'700', display:'flex', alignItems:'center', gap:'8px' }}>
                <Zap size={18} style={{ color:'var(--lime)' }} />
                Turnstile Access Token
              </h3>
              <p style={{ fontSize:'0.8rem', color:'var(--text-2)', marginTop:'4px' }}>
                Auto-refreshes every 60 seconds
              </p>
            </div>

            {/* QR frame */}
            <div className={`qr-frame ${qr ? 'active' : ''}`} style={{ minHeight:'280px', background:'white', padding:'30px', display:'flex', justifyContent:'center', alignItems:'center', borderRadius:'16px' }}>
              {loading && !qr ? (
                <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:'12px' }}>
                  <div className="spinner spinner-light" style={{ width:'32px', height:'32px', borderWidth:'3px', borderColor:'var(--lime)' }} />
                  <span style={{ color:'#666', fontSize:'0.85rem' }}>Generating secure hash...</span>
                </div>
              ) : qr ? (
                <img src={`https://api.qrserver.com/v1/create-qr-code/?data=${encodeURIComponent(qr)}&size=220x220`} alt="Active QR Code" width="220" height="220" style={{ display: 'block' }} />
              ) : (
                <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:'10px', color:'#999' }}>
                  <ShieldCheck size={40} style={{ opacity:0.3 }} />
                  <span style={{ fontSize:'0.85rem' }}>No active token</span>
                </div>
              )}
            </div>

            {/* Timer bar */}
            <div>
              <div style={{ display:'flex', justifyContent:'space-between', fontSize:'0.75rem', color: danger ? 'var(--coral)' : 'var(--text-2)', marginBottom:'6px' }}>
                <span>Token validity</span>
                <span style={{ fontWeight:'700', fontFamily:'monospace', fontSize:'0.9rem' }}>
                  00:{String(timeLeft).padStart(2,'0')}
                </span>
              </div>
              <div className="progress-bar">
                <div className="progress-fill" style={{ width:`${pct}%`, background: danger ? 'var(--coral)' : 'var(--lime)' }} />
              </div>
            </div>
          </div>

          {/* Info panel */}
          <div style={{ display:'flex', flexDirection:'column', gap:'14px' }}>
            {[
              { emoji:'🔒', title:'Single-Use Security', body:'Each QR token can only be scanned once and is invalidated immediately after use.' },
              { emoji:'⏱️', title:'60-Second Expiry', body:'Tokens auto-expire after 60 seconds to prevent screenshot-based replay attacks.' },
              { emoji:'📱', title:'Mobile Scanner', body:'Members scan using the Power House mobile app (Android). The app validates in real-time via the backend API.' },
              { emoji:'📊', title:'Audit Logged', body:'Every scan — successful or failed — is logged in the audit trail for security review.' },
            ].map(({ emoji, title, body }) => (
              <div key={title} className="card fade-up-2" style={{ padding:'18px 20px' }}>
                <div style={{ display:'flex', gap:'12px', alignItems:'flex-start' }}>
                  <div style={{ fontSize:'24px', flexShrink:0 }}>{emoji}</div>
                  <div>
                    <div style={{ fontWeight:'600', fontSize:'0.9rem', marginBottom:'4px' }}>{title}</div>
                    <div style={{ fontSize:'0.8rem', color:'var(--text-2)', lineHeight:1.5 }}>{body}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
