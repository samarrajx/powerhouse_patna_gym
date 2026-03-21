import { BrowserRouter, Routes, Route, NavLink, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider, useAuth } from './AuthContext';
import { ThemeProvider, useTheme } from './ThemeContext';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Members from './pages/Members';
import QrStation from './pages/QrStation';
import Attendance from './pages/Attendance';
import Settings from './pages/Settings';
import Schedule from './pages/Schedule';
import InactiveUsers from './pages/InactiveUsers';
import Reports from './pages/Reports';
import TemplateManager from './pages/TemplateManager';
import { LayoutDashboard, Users, Scan, ClipboardList, Settings2, Calendar, UserX, BarChart3, LogOut, MessageSquare } from 'lucide-react';
import Logo from './components/Logo';




function ThemeToggle() {
  const { theme, toggle } = useTheme();
  return (
    <button className="theme-toggle" onClick={toggle} title={`Switch to ${theme==='dark'?'light':'dark'} mode`} aria-label="Toggle theme">
      {theme === 'dark' ? '☀️' : '🌙'}
    </button>
  );
}

function Sidebar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const navItems = [
    { to:'/dashboard', icon: LayoutDashboard, label:'Dashboard', section:'NAVIGATION' },
    { to:'/members',   icon: Users,            label:'Members' },
    { to:'/qr-station',icon: Scan,             label:'QR Station' },
    { to:'/attendance',icon: ClipboardList,    label:'Attendance' },
    { to:'/templates', icon: MessageSquare,    label:'Templates' },
    { to:'/reports',   icon: BarChart3,        label:'Reports' },

    { section:'MANAGEMENT' },
    { to:'/schedule',  icon: Calendar,         label:'Schedule' },
    { to:'/inactive',  icon: UserX,            label:'Inactive Users' },
    { section:'SYSTEM' },
    { to:'/settings',  icon: Settings2,        label:'Settings' },
  ];

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <Logo size={42} />
        <div>

          <div className="brand-name">POWER HOUSE</div>
          <div className="brand-sub">Admin Console</div>
        </div>
      </div>
      <nav className="sidebar-nav">
        {navItems.map((item, i) =>
          item.section ? (
            <div key={i} className="nav-section-label">{item.section}</div>
          ) : (
            <NavLink key={item.to} to={item.to} className={({isActive})=>`nav-item${isActive?' active':''}`}>
              <item.icon className="nav-icon"/>
              {item.label}
            </NavLink>
          )
        )}
      </nav>
      <div className="sidebar-footer">
        <div className="user-chip" onClick={() => navigate('/settings')}>
          <div className="avatar-circle">{(user?.name||'A')[0].toUpperCase()}</div>
          <div className="user-info">
            <div className="user-name">{user?.name||'Admin'}</div>
            <div className="user-role">Super Administrator</div>
          </div>
          <LogOut size={14} style={{ color:'var(--coral)', cursor:'pointer', flexShrink:0 }} onClick={(e)=>{ e.stopPropagation(); logout(); }}/>
        </div>
      </div>
    </aside>
  );
}

function ProtectedLayout() {
  const { user, loading } = useAuth();
  if (loading) return (
    <div style={{ height:'100vh', display:'flex', alignItems:'center', justifyContent:'center', background:'var(--bg)' }}>
      <div className="spinner spinner-light" style={{ width:'32px', height:'32px' }}/>
    </div>
  );
  if (!user) return <Navigate to="/login" replace/>;
  return (
    <div className="admin-shell">
      <Sidebar/>
      <main className="main-area">
        <Routes>
          <Route path="/dashboard"  element={<Dashboard/>}/>
          <Route path="/members"    element={<Members/>}/>
          <Route path="/qr-station" element={<QrStation/>}/>
          <Route path="/attendance" element={<Attendance/>}/>
          <Route path="/templates"  element={<TemplateManager/>}/>
          <Route path="/settings"   element={<Settings/>}/>

          <Route path="/schedule"   element={<Schedule/>}/>
          <Route path="/inactive"   element={<InactiveUsers/>}/>
          <Route path="/reports"    element={<Reports/>}/>
          <Route path="*"           element={<Navigate to="/dashboard" replace/>}/>
        </Routes>
      </main>
    </div>
  );
}

// Export the Topbar component so pages can use it
// (it needs ThemeToggle which needs ThemeContext)
export { ThemeToggle };

function AppRoutes() {
  const { user, loading } = useAuth();
  if (loading) return null;
  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/dashboard" replace/> : <Login/>}/>
      <Route path="/*"     element={<ProtectedLayout/>}/>
    </Routes>
  );
}

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <BrowserRouter basename="/admin">
          <AppRoutes/>

          <Toaster position="top-right" toastOptions={{
            style: { background:'var(--bg2, #0D0D1A)', color:'var(--text-1, #fff)', border:'1px solid var(--glass-border-2)', borderRadius:'12px', fontSize:'0.875rem' },
            success: { iconTheme: { primary:'#C8FA00', secondary:'#000' }},
            error:   { iconTheme: { primary:'#FF6B6B', secondary:'#fff' }},
          }}/>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}
