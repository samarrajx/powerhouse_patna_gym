import React from 'react';
import { useTheme } from '../ThemeContext';
import { useSidebar } from '../SidebarContext';
import { Menu } from 'lucide-react';

export function Topbar({ title, sub }) {
  const { theme, toggle } = useTheme();
  const { toggle: toggleSidebar } = useSidebar();

  return (
    <div className="topbar">
      <div className="topbar-left" style={{ display:'flex', alignItems:'center', gap:'12px' }}>
        <button className="mobile-menu-btn" onClick={toggleSidebar}>
          <Menu size={20} />
        </button>
        <div>
          <h1>{title}</h1>
          {sub && <p style={{ fontSize:'0.78rem', color:'var(--text-2)', marginTop:'2px' }}>{sub}</p>}
        </div>
      </div>
      <div className="topbar-right">
        <div className="status-pill">
          <span className="pulse-dot" />
          System Live
        </div>
        <button
          className="theme-toggle"
          onClick={toggle}
          title={`Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`}
          aria-label="Toggle theme"
        >
          {theme === 'dark' ? '☀️' : '🌙'}
        </button>
      </div>
    </div>
  );
}
