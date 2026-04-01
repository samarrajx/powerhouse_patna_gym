import { useState, useEffect } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { Home, Scan, History, User, LogOut, Bell } from 'lucide-react';
import { useAuth } from '../AuthContext';
import Logo from './Logo';

export default function UserLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="user-shell mobile-first">
      {/* Top Header */}
      <header className="user-header">
        <div className="header-left">
          <Logo size={32} />
          <span className="brand-text">POWER HOUSE</span>
        </div>
        <div className="header-right">
          <button className="icon-btn" title="Notifications"><Bell size={20} /></button>
          <button className="icon-btn logout" onClick={logout} title="Logout"><LogOut size={20} /></button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="user-main">
        <Outlet />
      </main>

      {/* Bottom Navigation */}
      <nav className="bottom-nav">
        <NavLink to="/user/home" className={({isActive})=>`nav-tab${isActive?' active':''}`}>
          <Home size={22} />
          <span>Home</span>
        </NavLink>
        <NavLink to="/user/scan" className={({isActive})=>`nav-tab${isActive?' active':''}`}>
          <div className="scan-hex">
            <Scan size={24} color="#fff" />
          </div>
          <span>Scan</span>
        </NavLink>
        <NavLink to="/user/history" className={({isActive})=>`nav-tab${isActive?' active':''}`}>
          <History size={22} />
          <span>History</span>
        </NavLink>
        <NavLink to="/settings" className={({isActive})=>`nav-tab${isActive?' active':''}`}>
          <User size={22} />
          <span>Profile</span>
        </NavLink>
      </nav>

      <style>{`
        .user-shell {
          min-height: 100vh;
          display: flex;
          flex-direction: column;
          background: var(--bg);
          color: var(--text-1);
          padding-bottom: 80px; /* Space for bottom nav */
        }
        .user-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 16px 20px;
          background: var(--glass-bg);
          backdrop-filter: blur(10px);
          border-bottom: 1px solid var(--glass-border);
          position: sticky;
          top: 0;
          z-index: 100;
        }
        .header-left { display: flex; alignItems: center; gap: 12px; }
        .brand-text { font-family: var(--font-display); font-weight: 800; letter-spacing: 0.5px; font-size: 0.9rem; }
        .header-right { display: flex; gap: 12px; }
        .icon-btn { 
          background: var(--glass-bg-2); 
          border: 1px solid var(--glass-border); 
          color: var(--text-2); 
          padding: 8px; 
          border-radius: 10px; 
          cursor: pointer; 
        }
        .icon-btn.logout { color: var(--coral); }
        
        .user-main {
          flex: 1;
          padding: 20px;
          max-width: 600px;
          margin: 0 auto;
          width: 100%;
        }

        .bottom-nav {
          position: fixed;
          bottom: 0;
          left: 0;
          right: 0;
          height: 72px;
          background: var(--glass-bg-2);
          backdrop-filter: blur(20px);
          border-top: 1px solid var(--glass-border-2);
          display: flex;
          justify-content: space-around;
          align-items: center;
          z-index: 1000;
          padding-bottom: env(safe-area-inset-bottom);
        }
        .nav-tab {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 4px;
          color: var(--text-3);
          text-decoration: none;
          font-size: 0.65rem;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          transition: all 0.2s;
        }
        .nav-tab.active { color: var(--primary); }
        
        .scan-hex {
          background: var(--primary);
          width: 52px;
          height: 52px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 16px;
          margin-top: -30px;
          box-shadow: 0 8px 20px var(--primary-glow);
          border: 4px solid var(--bg);
        }
      `}</style>
    </div>
  );
}
