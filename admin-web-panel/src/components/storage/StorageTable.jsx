import { useState } from 'react';
import { ArrowUpDown, ArrowUp, ArrowDown, Trash2, ChevronDown, ChevronDownSquare, ChevronUpSquare } from 'lucide-react';

const COL_KEYS = ['table_name', 'size_mb', 'percent_of_total', 'row_count'];

function SortIcon({ col, sortKey, sortDir }) {
  if (col !== sortKey) return <ArrowUpDown size={12} style={{ opacity: 0.3 }} />;
  return sortDir === 'asc' ? <ArrowUp size={12} style={{ color: 'var(--primary)' }} /> : <ArrowDown size={12} style={{ color: 'var(--primary)' }} />;
}

export default function StorageTable({ tables, loading, onQuickClean }) {
  const [sortKey, setSortKey] = useState('size_mb');
  const [sortDir, setSortDir] = useState('desc');
  const [openDropdown, setOpenDropdown] = useState(null);
  const [isExpanded, setIsExpanded] = useState(false);
  const INITIAL_ROWS = 6;

  const toggleSort = (key) => {
    if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    else { setSortKey(key); setSortDir('desc'); }
  };

  const sorted = [...(tables || [])].sort((a, b) => {
    const va = a[sortKey];
    const vb = b[sortKey];
    if (typeof va === 'string') return sortDir === 'asc' ? va.localeCompare(vb) : vb.localeCompare(va);
    return sortDir === 'asc' ? va - vb : vb - va;
  });

  const headers = [
    { key: 'table_name', label: 'Table Name' },
    { key: 'size_mb', label: 'Size (MB)' },
    { key: 'percent_of_total', label: '% of Total' },
    { key: 'row_count', label: 'Rows' },
    { key: 'actions', label: 'Actions', sortable: false },
  ];

  const ShimmerRow = ({ i }) => (
    <tr key={i} style={{ animation: `fadeUp 0.4s ${i * 0.05}s both` }}>
      {[1, 2, 3, 4, 5].map(j => (
        <td key={j}><div className="shimmer" style={{ height: '16px', borderRadius: '6px', width: j === 1 ? '120px' : '60px' }} /></td>
      ))}
    </tr>
  );

  return (
    <div className="card table-card fade-up-3" style={{ marginTop: '24px' }}>
      <div className="table-header">
        <div>
          <h3>Storage by Table</h3>
          <p style={{ fontSize: '0.78rem', color: 'var(--text-2)', marginTop: '2px' }}>
            Click column headers to sort
          </p>
        </div>
        <span className="badge badge-blue">{(tables || []).length} tables</span>
      </div>

      <div className="table-responsive">
        <table>
          <thead>
            <tr>
              {headers.map(h => (
                <th
                  key={h.key}
                  onClick={h.sortable !== false ? () => toggleSort(h.key) : undefined}
                  style={{
                    cursor: h.sortable !== false ? 'pointer' : 'default',
                    userSelect: 'none',
                    whiteSpace: 'nowrap',
                  }}
                >
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '5px' }}>
                    {h.label}
                    {h.sortable !== false && <SortIcon col={h.key} sortKey={sortKey} sortDir={sortDir} />}
                  </span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading
              ? Array.from({ length: 5 }, (_, i) => <ShimmerRow key={i} i={i} />)
              : sorted.length === 0
                ? (
                  <tr>
                    <td colSpan={5}>
                      <div className="empty-state">
                        <span>No table data available</span>
                      </div>
                    </td>
                  </tr>
                )
                : (() => {
                    const visibleRows = isExpanded ? sorted : sorted.slice(0, INITIAL_ROWS);
                    return visibleRows.map((row, i) => {
                      const barColor = row.percent_of_total >= 50 ? 'var(--coral)' : row.percent_of_total >= 25 ? '#F59E0B' : '#4CAF50';
                    return (
                      <tr key={row.table_name} style={{ animation: `fadeUp 0.35s ${i * 0.04}s both` }}>
                        <td>
                          <span style={{ fontWeight: 600, fontFamily: 'var(--font-display)' }}>
                            {row.table_name}
                          </span>
                          {row.is_deletable && (
                            <span className="badge badge-blue" style={{ marginLeft: '8px', fontSize: '0.6rem', padding: '2px 6px' }}>
                              Cleanable
                            </span>
                          )}
                        </td>
                        <td style={{ fontWeight: 600 }}>{row.size_mb} MB</td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                            <div className="progress-bar" style={{ width: '70px', height: '5px' }}>
                              <div
                                className="progress-fill"
                                style={{
                                  width: `${Math.min(row.percent_of_total, 100)}%`,
                                  background: barColor,
                                  boxShadow: `0 0 6px ${barColor}50`,
                                }}
                              />
                            </div>
                            <span style={{ fontSize: '0.8rem', color: barColor, fontWeight: 700, minWidth: '36px' }}>
                              {row.percent_of_total}%
                            </span>
                          </div>
                        </td>
                        <td style={{ color: 'var(--text-2)', fontVariantNumeric: 'tabular-nums' }}>
                          {row.row_count.toLocaleString()}
                        </td>
                        <td>
                          {row.is_deletable ? (
                            <div style={{ position: 'relative', display: 'inline-block' }}>
                              <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
                                <button
                                  className="btn btn-danger btn-sm"
                                  onClick={() => onQuickClean(row.table_name, 'clear_all')}
                                  style={{ padding: '5px 10px', fontSize: '0.75rem' }}
                                  title="Clear all data from this table"
                                >
                                  <Trash2 size={12} />
                                  Clear
                                </button>
                                <button
                                  className="btn btn-ghost btn-sm"
                                  onClick={() => setOpenDropdown(openDropdown === row.table_name ? null : row.table_name)}
                                  style={{ padding: '5px 8px' }}
                                >
                                  <ChevronDown size={12} />
                                </button>
                              </div>

                              {openDropdown === row.table_name && (
                                <div style={{
                                  position: 'absolute', right: 0, top: '100%', marginTop: '6px', zIndex: 200,
                                  background: 'var(--bg2)', border: '1px solid var(--glass-border-2)',
                                  borderRadius: 'var(--radius-sm)', padding: '6px', minWidth: '175px',
                                  boxShadow: 'var(--shadow-lg)',
                                  animation: 'fadeUp 0.2s ease',
                                }}>
                                  {[
                                    { label: 'Clear last 30 days', action: 'clear_30d' },
                                    { label: 'Clear last 90 days', action: 'clear_90d' },
                                    { label: '⚠ Clear all', action: 'clear_all' },
                                    { label: 'Custom dates...', action: 'custom' },
                                  ].map(opt => (
                                    <button
                                      key={opt.action}
                                      onClick={() => { setOpenDropdown(null); onQuickClean(row.table_name, opt.action); }}
                                      style={{
                                        display: 'block', width: '100%', textAlign: 'left',
                                        padding: '8px 12px', fontSize: '0.8rem', fontWeight: 500,
                                        cursor: 'pointer', background: 'none', border: 'none',
                                        color: opt.action === 'clear_all' ? 'var(--coral)' : 'var(--text-1)',
                                        borderRadius: '6px',
                                      }}
                                      onMouseEnter={e => e.currentTarget.style.background = 'var(--primary-dim)'}
                                      onMouseLeave={e => e.currentTarget.style.background = 'none'}
                                    >
                                      {opt.label}
                                    </button>
                                  ))}
                                </div>
                              )}
                            </div>
                          ) : (
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-3)' }}>System table</span>
                          )}
                        </td>
                      </tr>
                    );
                  })
                })()
            }
          </tbody>
        </table>
      </div>

      {!loading && sorted.length > INITIAL_ROWS && (
        <div style={{ padding: '12px 20px', borderTop: '1px solid var(--glass-border-2)', display: 'flex', justifyContent: 'center' }}>
          <button 
            className="btn btn-ghost btn-sm" 
            onClick={() => setIsExpanded(!isExpanded)}
            style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--text-2)' }}
          >
            {isExpanded ? (
              <>Show Less <ChevronUpSquare size={14} style={{ marginLeft: '6px' }} /></>
            ) : (
              <>Show All {sorted.length} Tables <ChevronDownSquare size={14} style={{ marginLeft: '6px' }} /></>
            )}
          </button>
        </div>
      )}
    </div>
  );
}
