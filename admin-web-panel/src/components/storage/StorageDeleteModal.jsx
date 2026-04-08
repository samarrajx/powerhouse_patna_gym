import { X, AlertTriangle, Trash2 } from 'lucide-react';

export default function StorageDeleteModal({
  table, project, fromDate, toDate, rowCount,
  onConfirm, onClose, loading,
  clearType, // 'custom' | 'clear_30d' | 'clear_90d' | 'clear_all'
}) {
  const isAll = clearType === 'clear_all';
  const rangeLabel = isAll
    ? 'all records'
    : `records from ${fromDate} to ${toDate}`;

  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal-box glass-2" style={{ maxWidth: '460px' }}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{
              width: '40px', height: '40px', borderRadius: '10px',
              background: 'rgba(238,125,119,0.12)', display: 'flex',
              alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <AlertTriangle size={18} style={{ color: 'var(--coral)' }} />
            </div>
            <div>
              <h3 className="modal-title" style={{ color: 'var(--coral)', fontSize: '1.05rem' }}>
                Confirm Data Deletion
              </h3>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: '2px' }}>
                This action cannot be undone
              </p>
            </div>
          </div>
          <button onClick={onClose} className="btn btn-ghost btn-sm" style={{ padding: '7px' }}>
            <X size={15} />
          </button>
        </div>

        {/* Info box */}
        <div style={{
          background: 'rgba(238,125,119,0.06)', border: '1px solid rgba(238,125,119,0.2)',
          borderRadius: 'var(--radius-sm)', padding: '16px', marginBottom: '20px',
        }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'auto 1fr', rowGap: '8px', columnGap: '12px', fontSize: '0.85rem' }}>
            <span style={{ color: 'var(--text-3)', fontWeight: 600 }}>Table:</span>
            <span style={{ fontWeight: 700, fontFamily: 'var(--font-display)' }}>{table}</span>

            <span style={{ color: 'var(--text-3)', fontWeight: 600 }}>Project:</span>
            <span style={{ fontWeight: 600 }}>
              <span className={`badge ${project === 'Core' ? 'badge-blue' : 'badge-purple'}`} style={{ fontSize: '0.7rem' }}>
                {project}
              </span>
            </span>

            <span style={{ color: 'var(--text-3)', fontWeight: 600 }}>Range:</span>
            <span style={{ fontWeight: 500 }}>{rangeLabel}</span>

            <span style={{ color: 'var(--text-3)', fontWeight: 600 }}>Rows:</span>
            <span>
              {rowCount === null
                ? <span className="shimmer" style={{ display: 'inline-block', width: '60px', height: '16px', borderRadius: '4px' }} />
                : <strong style={{ color: 'var(--coral)' }}>{rowCount?.toLocaleString() ?? '?'} rows will be permanently deleted</strong>
              }
            </span>
          </div>
        </div>

        <p style={{ fontSize: '0.82rem', color: 'var(--text-2)', lineHeight: 1.6, marginBottom: '20px' }}>
          Are you absolutely sure? This will permanently remove the selected records from the <strong>{table}</strong> table and{' '}
          <strong>cannot be recovered</strong>. This action will be logged in audit logs.
        </p>

        <div className="modal-footer" style={{ marginTop: 0 }}>
          <button
            type="button"
            className="btn btn-ghost"
            style={{ flex: 1, justifyContent: 'center' }}
            onClick={onClose}
            disabled={loading}
          >
            Cancel
          </button>
          <button
            type="button"
            className="btn btn-danger"
            style={{ flex: 1, justifyContent: 'center', background: 'rgba(238,125,119,0.18)', border: '1px solid rgba(238,125,119,0.35)' }}
            onClick={onConfirm}
            disabled={loading || rowCount === null}
          >
            {loading
              ? <><div className="spinner" style={{ width: '14px', height: '14px' }} /> Deleting...</>
              : <><Trash2 size={14} /> Delete {rowCount !== null && rowCount !== undefined ? rowCount.toLocaleString() : ''} Rows</>
            }
          </button>
        </div>
      </div>
    </div>
  );
}
