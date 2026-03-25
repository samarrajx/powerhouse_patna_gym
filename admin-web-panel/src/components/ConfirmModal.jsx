import { X } from 'lucide-react';

export default function ConfirmModal({ title, message, onConfirm, onClose, loading }) {
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
