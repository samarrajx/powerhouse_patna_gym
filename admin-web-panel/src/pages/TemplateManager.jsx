import { useState, useEffect } from 'react';
import api from '../api';
import toast from 'react-hot-toast';
import { MessageSquare, Megaphone, Save, Trash2, Plus, X, Edit2 } from 'lucide-react';
import { Topbar } from '../components/Topbar';

export default function TemplateManager() {
  const [templates, setTemplates] = useState([]);
  const [announcements, setAnnouncements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAnnounceModal, setShowAnnounceModal] = useState(false);
  const [editingAnnounce, setEditingAnnounce] = useState(null);
  const [messages, setMessages] = useState({});

  const load = async () => {
    try {
      setLoading(true);
      const [tRes, aRes] = await Promise.all([
        api.get('/admin/templates'),
        api.get('/admin/announcements')
      ]);
      setTemplates(tRes.data);
      const initialMessages = {};
      (tRes.data || []).forEach((t) => { initialMessages[t.id] = t.message || ''; });
      setMessages(initialMessages);
      setAnnouncements(aRes.data);
    } catch (e) {
      toast.error('Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleUpdateTemplate = async (id, newMessage) => {
    try {
      await api.put(`/admin/templates/${id}`, { message: newMessage });
      toast.success('Template updated');
      load();
    } catch (e) {
      toast.error('Update failed');
    }
  };

  const handleSaveAnnounce = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const data = {
      title: formData.get('title'),
      content: formData.get('content'),
      is_active: formData.get('is_active') === 'on'
    };

    try {
      if (editingAnnounce) {
        await api.put(`/admin/announcements/${editingAnnounce.id}`, data);
        toast.success('Announcement updated');
      } else {
        await api.post('/admin/announcements', data);
        toast.success('Announcement added');
      }
      setShowAnnounceModal(false);
      setEditingAnnounce(null);
      load();
    } catch (e) {
      toast.error('Action failed');
    }
  };

  const handleDeleteAnnounce = async (id) => {
    if (!window.confirm('Delete this announcement?')) return;
    try {
      await api.delete(`/admin/announcements/${id}`);
      toast.success('Deleted');
      load();
    } catch (e) {
      toast.error('Delete failed');
    }
  };

  return (
    <>
      <Topbar title="Templates & Announcements" sub="Manage message templates and gym announcements" />
      <div className="page-body">
        
        {/* --- Message Templates Section --- */}
        <div style={{ marginBottom: '32px' }} className="fade-up">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
            <div className="brand-icon" style={{ width:'32px', height:'32px', fontSize:'14px' }}><MessageSquare size={16}/></div>
            <h2 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Body-Type Templates</h2>
          </div>
          <p style={{ color: 'var(--text-3)', fontSize: '0.85rem', marginBottom: '20px' }}>
            Personalized messages used for one-click WhatsApp communication based on member body type. Use <code>{"{name}"}</code> as a placeholder.
          </p>

          <div className="grid-2">
            {templates.map(t => (
              <div key={t.id} className="card" style={{ padding: '20px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                  <span className="badge badge-purple" style={{ textTransform: 'capitalize' }}>{t.category}</span>
                  <span style={{ fontSize: '0.7rem', color: 'var(--text-3)' }}>
                    Last updated: {new Date(t.updated_at).toLocaleDateString()}
                  </span>
                </div>
                <textarea 
                  className="input-field" 
                  rows={4} 
                  value={messages[t.id] ?? t.message}
                  onChange={(e) => setMessages((m) => ({ ...m, [t.id]: e.target.value }))}
                  style={{ marginBottom: '12px', resize: 'none', fontSize: '0.82rem' }}
                />
                <button 
                  className="btn btn-primary btn-sm"
                  onClick={() => handleUpdateTemplate(t.id, messages[t.id] ?? t.message)}
                  style={{ width: '100%', justifyContent: 'center' }}
                >
                  <Save size={14}/> Save Template
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* --- Announcements Section --- */}
        <div className="fade-up-1">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div className="brand-icon" style={{ width:'32px', height:'32px', fontSize:'14px', background: 'var(--blue)', boxShadow: '0 4px 16px rgba(96,165,250,0.3)' }}><Megaphone size={16}/></div>
              <h2 style={{ fontSize: '1.2rem', fontWeight: 700 }}>Gym Announcements</h2>
            </div>
            <button className="btn btn-primary btn-sm" onClick={() => { setEditingAnnounce(null); setShowAnnounceModal(true); }}>
              <Plus size={16}/> New Announcement
            </button>
          </div>

          <div className="card table-card">
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Content</th>
                  <th>Status</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {announcements.length === 0 ? (
                  <tr><td colSpan={5} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-3)' }}>No announcements yet</td></tr>
                ) : (
                  announcements.map(a => (
                    <tr key={a.id}>
                      <td style={{ fontWeight: 600 }}>{a.title}</td>
                      <td style={{ fontSize: '0.8rem', color: 'var(--text-2)', maxWidth: '300px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.content}</td>
                      <td><span className={`badge ${a.is_active ? 'badge-green' : 'badge-gray'}`}>{a.is_active ? 'Active' : 'Draft'}</span></td>
                      <td style={{ fontSize: '0.8rem', color: 'var(--text-3)' }}>{new Date(a.created_at).toLocaleDateString()}</td>
                      <td>
                        <div style={{ display: 'flex', gap: '5px' }}>
                          <button className="btn btn-ghost btn-sm" onClick={() => { setEditingAnnounce(a); setShowAnnounceModal(true); }}><Edit2 size={12}/></button>
                          <button className="btn btn-danger btn-sm" onClick={() => handleDeleteAnnounce(a.id)}><Trash2 size={12}/></button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* --- Announcement Modal --- */}
      {showAnnounceModal && (
        <div className="modal-overlay">
          <div className="modal-box glass-2">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h3 className="modal-title">{editingAnnounce ? 'Edit' : 'New'} Announcement</h3>
              <button className="btn btn-ghost btn-sm" style={{ padding: '6px' }} onClick={() => setShowAnnounceModal(false)}><X size={16}/></button>
            </div>
            <form onSubmit={handleSaveAnnounce}>
              <div className="input-wrap">
                <label className="input-label">Title</label>
                <input name="title" className="input-field" defaultValue={editingAnnounce?.title} required />
              </div>
              <div className="input-wrap">
                <label className="input-label">Content</label>
                <textarea name="content" className="input-field" rows={5} defaultValue={editingAnnounce?.content} required style={{ resize: 'none' }} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '10px', marginBottom: '20px' }}>
                <input type="checkbox" name="is_active" defaultChecked={editingAnnounce ? editingAnnounce.is_active : true} />
                <label style={{ fontSize: '0.85rem' }}>Active & Visible to Users</label>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-ghost" onClick={() => setShowAnnounceModal(false)} style={{ flex: 1 }}>Cancel</button>
                <button type="submit" className="btn btn-primary" style={{ flex: 1 }}>{editingAnnounce ? 'Update' : 'Publish'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
