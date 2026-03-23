import { createContext, useContext, useState } from 'react';

const SidebarCtx = createContext(null);

export function SidebarProvider({ children }) {
  const [isOpen, setIsOpen] = useState(false);
  const toggle = () => setIsOpen(!isOpen);

  return (
    <SidebarCtx.Provider value={{ isOpen, toggle }}>
      {children}
    </SidebarCtx.Provider>
  );
}

export const useSidebar = () => {
  const context = useContext(SidebarCtx);
  if (context === undefined) {
    throw new Error('useSidebar must be used within a SidebarProvider');
  }
  return context;
};
