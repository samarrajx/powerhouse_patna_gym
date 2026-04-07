import { useState, useEffect, useCallback } from 'react';
import toast from 'react-hot-toast';
import { RefreshCcw, HardDrive, Database } from 'lucide-react';
import api from '../api';
import { Topbar } from '../components/Topbar';
import StorageOverviewCards from '../components/storage/StorageOverviewCards';
import StorageTable from '../components/storage/StorageTable';
import StorageFilterBar from '../components/storage/StorageFilterBar';
import StorageInsights from '../components/storage/StorageInsights';
import StorageDeleteModal from '../components/storage/StorageDeleteModal';

// ─── Hero Progress Bar ────────────────────────────────────────────────────────
function HeroProgressBar({ overview, loading }) {
  const pct = overview?.used_percent ?? 0;
  const sizeMB = overview?.size_mb ?? 0;
  const limitMB = overview?.storage_limit_mb ?? 500;
  const progressColor = pct >= 90 ? '#EE7D77' : pct >= 70 ? '#F59E0B' : '#4CAF50';

  return (
    <div className="card fade-up-2" style={{ marginBottom: '24px', padding: '22px 28px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Database size={18} style={{ color: progressColor }} />
          <h3 style={{ fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: '1rem' }}>
            Database Storage Usage
          </h3>
        </div>
        {loading
          ? <div className="shimmer" style={{ width: '200px', height: '18px', borderRadius: '6px' }} />
          : (
            <span style={{
              fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: '0.9rem',
              color: progressColor,
              background: `${progressColor}15`,
              padding: '4px 12px', borderRadius: '99px',
              border: `1px solid ${progressColor}40`,
            }}>
              {sizeMB} MB / {limitMB} MB used ({pct}%)
            </span>
          )
        }
      </div>

      {/* Bar track */}
      <div style={{
        height: '14px', borderRadius: '8px', overflow: 'hidden',
        background: 'var(--glass-bg-2)', border: '1px solid var(--glass-border)',
      }}>
        {loading
          ? <div className="shimmer" style={{ height: '100%', borderRadius: '8px' }} />
          : (
            <div style={{
              height: '100%',
              borderRadius: '8px',
              width: `${Math.min(pct, 100)}%`,
              background: `linear-gradient(90deg, ${progressColor}cc, ${progressColor})`,
              boxShadow: `0 0 12px ${progressColor}60`,
              transition: 'width 1.4s cubic-bezier(0.16, 1, 0.3, 1)',
            }} />
          )
        }
      </div>

      {/* Tick labels */}
      <div style={{
        display: 'flex', justifyContent: 'space-between',
        fontSize: '0.7rem', color: 'var(--text-3)', marginTop: '6px', fontWeight: 600,
      }}>
        <span>0 MB</span>
        <span style={{ color: '#F59E0B' }}>350 MB (70%)</span>
        <span style={{ color: '#EE7D77' }}>450 MB (90%)</span>
        <span>500 MB</span>
      </div>
    </div>
  );
}

// ─── CSV Export helper ─────────────────────────────────────────────────────────
function exportCSV(tables) {
  if (!tables || tables.length === 0) { toast.error('No data to export'); return; }
  const headers = ['Table Name', 'Size (MB)', '% of Total', 'Row Count', 'Deletable'];
  const rows = tables.map(t => [
    t.table_name, t.size_mb, t.percent_of_total, t.row_count, t.is_deletable ? 'Yes' : 'No',
  ]);
  const csv = [headers, ...rows].map(r => r.join(',')).join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = `storage_report_${new Date().toISOString().split('T')[0]}.csv`;
  a.click(); URL.revokeObjectURL(url);
  toast.success('CSV exported');
}

// ─── Main Page ─────────────────────────────────────────────────────────────────
export default function StorageControl() {
  const [overview, setOverview]         = useState(null);
  const [tables, setTables]             = useState([]);
  const [loadingOverview, setLoadingOverview] = useState(true);
  const [loadingTables, setLoadingTables]     = useState(true);
  const [lastUpdated, setLastUpdated]   = useState(null);

  // Filter state
  const [filter, setFilter] = useState({ table: '', from: '', to: '' });
  const [rowCount, setRowCount]         = useState(null);
  const [loadingCount, setLoadingCount] = useState(false);

  // Delete modal state
  const [deleteModal, setDeleteModal]   = useState(null); // { table, from, to, clearType }
  const [deleting, setDeleting]         = useState(false);

  // ─── Data fetchers ────────────────────────────────────────────────────────
  const fetchOverview = useCallback(async () => {
    setLoadingOverview(true);
    try {
      const res = await api.get('/admin/storage/overview');
      setOverview(res.data);
    } catch {
      toast.error('Failed to load storage overview');
    } finally {
      setLoadingOverview(false);
    }
  }, []);

  const fetchTables = useCallback(async () => {
    setLoadingTables(true);
    try {
      const res = await api.get('/admin/storage/tables');
      setTables(res.data || []);
    } catch {
      toast.error('Failed to load table sizes');
    } finally {
      setLoadingTables(false);
    }
  }, []);

  const refreshAll = useCallback(() => {
    setLastUpdated(new Date());
    fetchOverview();
    fetchTables();
    setRowCount(null);
  }, [fetchOverview, fetchTables]);

  useEffect(() => { refreshAll(); }, []);

  // ─── Row count preview ────────────────────────────────────────────────────
  const fetchRowCount = useCallback(async (table, from, to) => {
    if (!table || !from || !to) { setRowCount(null); return; }
    setLoadingCount(true);
    try {
      const res = await api.get('/admin/storage/count', { params: { table, from_date: from, to_date: to } });
      setRowCount(res.data?.row_count ?? 0);
    } catch {
      setRowCount(null);
    } finally {
      setLoadingCount(false);
    }
  }, []);

  // ─── Filter apply ─────────────────────────────────────────────────────────
  const handleApply = () => {
    if (filter.table && filter.from && filter.to) {
      fetchRowCount(filter.table, filter.from, filter.to);
    }
  };

  const handleClear = () => {
    setFilter({ table: '', from: '', to: '' });
    setRowCount(null);
  };

  // ─── Quick clean from table row ───────────────────────────────────────────
  const handleQuickClean = (tableName, action) => {
    const today = new Date().toISOString().split('T')[0];
    let fromDate = '';
    let toDate = today;

    if (action === 'clear_30d') {
      const d = new Date(); d.setDate(d.getDate() - 30);
      fromDate = d.toISOString().split('T')[0];
    } else if (action === 'clear_90d') {
      const d = new Date(); d.setDate(d.getDate() - 90);
      fromDate = d.toISOString().split('T')[0];
    } else if (action === 'clear_all') {
      fromDate = '2000-01-01';
    } else if (action === 'custom') {
      setFilter({ table: tableName, from: '', to: '' });
      document.getElementById('storage-filter-bar')?.scrollIntoView({ behavior: 'smooth' });
      return;
    }

    setDeleteModal({ table: tableName, from: fromDate, to: toDate, clearType: action });
    // Pre-fetch row count for modal
    fetchRowCount(tableName, fromDate, toDate).then(() => {});
  };

  // ─── Delete from filter bar ───────────────────────────────────────────────
  const handleFilterDelete = () => {
    if (!filter.table || !filter.from || !filter.to) return;
    setDeleteModal({ table: filter.table, from: filter.from, to: filter.to, clearType: 'custom' });
    fetchRowCount(filter.table, filter.from, filter.to);
  };

  // ─── Confirm delete ───────────────────────────────────────────────────────
  const confirmDelete = async () => {
    if (!deleteModal) return;
    setDeleting(true);
    try {
      const res = await api.delete('/admin/storage/clean', {
        data: { table: deleteModal.table, from_date: deleteModal.from, to_date: deleteModal.to },
      });
      toast.success(res.message || 'Data deleted successfully');
      setDeleteModal(null);
      setRowCount(null);
      setFilter({ table: '', from: '', to: '' });
      setTimeout(refreshAll, 500);
    } catch (e) {
      toast.error(e.message || 'Failed to delete data');
    } finally {
      setDeleting(false);
    }
  };

  // ─── Render ───────────────────────────────────────────────────────────────
  const formattedTime = lastUpdated
    ? lastUpdated.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
    : null;

  const isLoading = loadingOverview || loadingTables;

  return (
    <>
      <Topbar
        title="Storage & Data Control"
        sub="Monitor and manage database usage efficiently"
      />

      <div className="page-body">
        {/* Refresh action row */}
        <div className="fade-up-1" style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          marginBottom: '20px', flexWrap: 'wrap', gap: '10px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <HardDrive size={16} style={{ color: 'var(--primary)' }} />
            <span style={{ fontSize: '0.8rem', color: 'var(--text-2)', fontWeight: 600 }}>
              Supabase PostgreSQL — Free Tier
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {formattedTime && (
              <span style={{ fontSize: '0.72rem', color: 'var(--text-3)', fontWeight: 600 }}>
                Updated {formattedTime}
              </span>
            )}
            <button
              className="btn btn-ghost btn-sm"
              onClick={refreshAll}
              disabled={isLoading}
            >
              <RefreshCcw
                size={14}
                style={{ animation: isLoading ? 'spin 1s linear infinite' : 'none' }}
              />
              {isLoading ? 'Loading...' : 'Refresh'}
            </button>
          </div>
        </div>

        {/* Overview cards */}
        <StorageOverviewCards overview={overview} loading={loadingOverview} />

        {/* Hero progress bar */}
        <HeroProgressBar overview={overview} loading={loadingOverview} />

        {/* Smart Insights */}
        {!loadingOverview && !loadingTables && (
          <StorageInsights overview={overview} tables={tables} />
        )}

        {/* Table breakdown */}
        <StorageTable
          tables={tables}
          loading={loadingTables}
          onQuickClean={handleQuickClean}
        />

        {/* Filter + Action bar */}
        <div id="storage-filter-bar">
          <StorageFilterBar
            filter={filter}
            setFilter={setFilter}
            tables={tables}
            onApply={handleApply}
            onClear={handleClear}
            onExport={() => exportCSV(tables)}
            onDelete={handleFilterDelete}
            loadingCount={loadingCount}
            rowCount={rowCount}
            deleting={deleting}
          />
        </div>

      </div>

      {/* Delete confirmation modal */}
      {deleteModal && (
        <StorageDeleteModal
          table={deleteModal.table}
          fromDate={deleteModal.from}
          toDate={deleteModal.to}
          rowCount={rowCount}
          clearType={deleteModal.clearType}
          onConfirm={confirmDelete}
          onClose={() => setDeleteModal(null)}
          loading={deleting}
        />
      )}
    </>
  );
}
