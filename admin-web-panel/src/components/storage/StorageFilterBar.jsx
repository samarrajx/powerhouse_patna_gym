import { Calendar, Filter, X, Download, Trash2 } from 'lucide-react';

const DELETABLE_TABLES = ['attendance', 'notifications'];

export default function StorageFilterBar({
  filter, setFilter, tables,
  onApply, onClear, onExport, onDelete,
  loadingCount, rowCount, deleting,
}) {
  const canDelete = filter.table && filter.from && filter.to;

  return (
    <div className="card fade-up-4" style={{ marginTop: '24px', padding: '20px 24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
        <Filter size={16} style={{ color: 'var(--primary)' }} />
        <h3 style={{ fontSize: '0.9rem', fontWeight: 700 }}>Filter & Actions</h3>
        {rowCount !== null && (
          <span className="badge badge-red" style={{ marginLeft: 'auto', fontVariantNumeric: 'tabular-nums' }}>
            {loadingCount ? '...' : `${rowCount.toLocaleString()} rows match`}
          </span>
        )}
      </div>

      {/* Filter controls row */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
        gap: '14px',
        marginBottom: '16px',
      }}>
        {/* Table selector */}
        <div className="input-wrap" style={{ marginBottom: 0 }}>
          <label className="input-label">Table</label>
          <select
            className="input-field"
            value={filter.table}
            onChange={e => setFilter(f => ({ ...f, table: e.target.value }))}
          >
            <option value="">Select table...</option>
            {tables && tables.filter(t => t.is_deletable).map(t => (
              <option key={`${t.project}-${t.table_name}`} value={t.table_name}>
                {t.table_name} ({t.project})
              </option>
            ))}
          </select>
        </div>

        {/* From date */}
        <div className="input-wrap" style={{ marginBottom: 0 }}>
          <label className="input-label">
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '5px' }}>
              <Calendar size={12} /> From Date
            </span>
          </label>
          <input
            type="date"
            className="input-field"
            value={filter.from}
            max={filter.to || undefined}
            onChange={e => setFilter(f => ({ ...f, from: e.target.value }))}
          />
        </div>

        {/* To date */}
        <div className="input-wrap" style={{ marginBottom: 0 }}>
          <label className="input-label">
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '5px' }}>
              <Calendar size={12} /> To Date
            </span>
          </label>
          <input
            type="date"
            className="input-field"
            value={filter.to}
            min={filter.from || undefined}
            onChange={e => setFilter(f => ({ ...f, to: e.target.value }))}
          />
        </div>
      </div>

      {/* Action buttons row */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px', alignItems: 'center' }}>
        <button className="btn btn-primary btn-sm" onClick={onApply} disabled={!filter.from || !filter.to}>
          <Filter size={13} />
          Apply Filter
        </button>

        <button className="btn btn-ghost btn-sm" onClick={onClear}>
          <X size={13} />
          Clear Filter
        </button>

        <button className="btn btn-ghost btn-sm" onClick={onExport} style={{ marginLeft: 'auto' }}>
          <Download size={13} />
          Export CSV
        </button>

        <button
          className="btn btn-danger btn-sm"
          onClick={onDelete}
          disabled={!canDelete || deleting}
          title={!canDelete ? 'Select a table and date range first' : 'Delete filtered data'}
        >
          {deleting
            ? <div className="spinner" style={{ width: '13px', height: '13px' }} />
            : <Trash2 size={13} />
          }
          Delete Filtered Data
        </button>
      </div>

      {!canDelete && (filter.from || filter.to) && (
        <p style={{ fontSize: '0.75rem', color: 'var(--text-3)', marginTop: '10px' }}>
          ⚠ Select a table and both dates to enable deletion
        </p>
      )}
    </div>
  );
}
