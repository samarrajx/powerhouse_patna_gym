import { createContext, useContext, useState, useEffect } from 'react';
import api from './api';

const AuthCtx = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ph_user')); } catch { return null; }
  });
  const [loading, setLoading] = useState(false);

  const login = async (phone, password) => {
    setLoading(true);
    try {
      const res = await api.post('/auth/login', { phone, password });
      localStorage.setItem('ph_token', res.data.token);
      localStorage.setItem('ph_user', JSON.stringify(res.data.user));
      setUser(res.data.user);
      setLoading(false);
      return { ok: true };
    } catch (e) {
      setLoading(false);
      return { ok: false, message: e.message };
    }
  };

  const logout = () => {
    localStorage.removeItem('ph_token');
    localStorage.removeItem('ph_user');
    setUser(null);
  };

  return (
    <AuthCtx.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthCtx.Provider>
  );
}

export const useAuth = () => useContext(AuthCtx);
