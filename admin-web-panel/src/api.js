import axios from 'axios';
import toast from 'react-hot-toast';

const api = axios.create({
  baseURL: import.meta.env.MODE === 'production' ? '/api' : 'http://localhost:3000/api',
  timeout: 10000,
});

api.interceptors.request.use((cfg) => {
  const token = localStorage.getItem('ph_token');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

api.interceptors.response.use(
  (r) => r.data,
  (err) => {
    const msg = err.response?.data?.message || 'Network error';
    if (err.response?.status === 401) {
      localStorage.removeItem('ph_token');
      localStorage.removeItem('ph_user');
      window.location.href = '/login';
    }
    return Promise.reject({ message: msg, data: err.response?.data, status: err.response?.status });
  }
);

export default api;
