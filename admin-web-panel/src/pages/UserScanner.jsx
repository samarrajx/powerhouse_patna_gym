import { useEffect, useState, useRef } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import { useNavigate } from 'react-router-dom';
import { Camera, X, RefreshCw, Zap, ShieldCheck } from 'lucide-react';
import api from '../api';
import toast from 'react-hot-toast';

export default function UserScanner() {
  const [scanning, setScanning] = useState(false);
  const [camReady, setCamReady] = useState(false);
  const [error, setError] = useState(null);
  const scannerRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    // Initial start
    startScanner();
    return () => stopScanner();
  }, []);

  const startScanner = async () => {
    setError(null);
    setScanning(true);
    try {
      const html5QrCode = new Html5Qrcode("reader");
      scannerRef.current = html5QrCode;

      const config = { 
        fps: 10, 
        qrbox: { width: 250, height: 250 },
        aspectRatio: 1.0
      };

      await html5QrCode.start(
        { facingMode: "environment" }, 
        config,
        onScanSuccess,
        onScanFailure
      );
      setCamReady(true);
    } catch (err) {
      console.error(err);
      setError("Camera access denied or not found");
      setScanning(false);
    }
  };

  const stopScanner = async () => {
    if (scannerRef.current && scannerRef.current.isScanning) {
      await scannerRef.current.stop();
    }
  };

  const onScanSuccess = async (decodedText) => {
    // Stop scanner immediately on success to prevent multiple scans
    await stopScanner();
    setScanning(false);

    const loadingToast = toast.loading('Verifying scan...');
    try {
      const res = await api.post('/qr/scan', { code_hash: decodedText });
      toast.dismiss(loadingToast);
      
      if (res.success) {
        toast.success(`Checked ${res.data.action} successfully!`, { duration: 5000 });
        if (res.data.streak?.isNewRecord) {
          toast('New Best Streak! 🔥', { icon: '🏆' });
        }
        navigate('/user/home');
      } else {
        toast.error(res.message || 'Scan failed');
        // Restart scanner after a short delay if failed
        setTimeout(startScanner, 2000);
      }
    } catch (err) {
      toast.dismiss(loadingToast);
      toast.error(err.message || 'System error during scan');
      setTimeout(startScanner, 2000);
    }
  };

  const onScanFailure = (error) => {
    // We don't want to spam the console or UI with failures while searching
  };

  return (
    <div className="scanner-container fade-up">
      <div className="scanner-header">
        <h2 className="scanner-title">MARK ATTENDANCE</h2>
        <p className="scanner-sub">Scan the QR code displayed at the gym desk</p>
      </div>

      <div className="reader-wrapper">
        <div id="reader"></div>
        {scanning && <div className="scan-overlay"><div className="scan-line" /></div>}
        
        {!scanning && error && (
          <div className="error-overlay">
            <X size={48} color="var(--coral)" />
            <p>{error}</p>
            <button className="btn btn-primary" onClick={startScanner}>Grant Camera Access</button>
          </div>
        )}
      </div>

      <div className="scanner-footer">
        <div className="tip-box">
          <ShieldCheck size={18} color="var(--primary)" />
          <span>Keep the QR centered and avoid glare</span>
        </div>
        
        <button className="btn btn-ghost close-btn" onClick={() => navigate('/user/home')}>
          Cancel
        </button>
      </div>

      <style>{`
        .scanner-container {
          display: flex;
          flex-direction: column;
          min-height: calc(100vh - 120px);
          gap: 24px;
          padding-top: 20px;
        }
        .scanner-header { text-align: center; }
        .scanner-title { font-family: var(--font-display); font-size: 1.4rem; font-weight: 900; color: var(--text-1); letter-spacing: 1px; }
        .scanner-sub { font-size: 0.8rem; color: var(--text-3); margin-top: 4px; font-weight: 500; }

        .reader-wrapper {
          position: relative;
          width: 100%;
          max-width: 400px;
          margin: 0 auto;
          aspect-ratio: 1;
          background: #000;
          border-radius: 24px;
          overflow: hidden;
          border: 1px solid var(--glass-border-2);
          box-shadow: var(--card-shadow);
        }
        #reader { width: 100% !important; border: none !important; }
        #reader video { object-fit: cover !important; border-radius: 24px; }
        #reader__dashboard { display: none !important; } /* Hide internal html5-qrcode UI */

        .scan-overlay {
          position: absolute;
          inset: 0;
          border: 2px solid var(--primary);
          border-radius: 24px;
          pointer-events: none;
          z-index: 10;
          opacity: 0.4;
        }
        .scan-line {
          position: absolute;
          top: 0; left: 0; right: 0;
          height: 3px;
          background: var(--primary);
          box-shadow: 0 0 15px var(--primary-glow);
          animation: scan 2.5s infinite ease-in-out;
        }
        @keyframes scan {
          0%, 100% { top: 10%; }
          50% { top: 90%; }
        }

        .error-overlay {
          position: absolute; inset: 0;
          display: flex; flex-direction: column; align-items: center; justify-content: center;
          gap: 16px; background: rgba(0,0,0,0.9); padding: 30px; text-align: center;
        }
        .error-overlay p { font-size: 0.85rem; font-weight: 600; color: var(--text-2); }

        .scanner-footer { display: flex; flex-direction: column; gap: 20px; align-items: center; }
        .tip-box {
          display: flex; align-items: center; gap: 10px;
          background: var(--primary-dim); padding: 12px 20px; border-radius: 12px;
          font-size: 0.75rem; font-weight: 600; color: var(--text-2);
        }
        .close-btn { color: var(--text-3); font-weight: 700; width: 100%; max-width: 200px; }
      `}</style>
    </div>
  );
}
