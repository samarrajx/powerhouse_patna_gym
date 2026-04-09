import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import App from './App.jsx';

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

if ('serviceWorker' in navigator) {
  window.addEventListener('load', async () => {
    try {
      const registration = await navigator.serviceWorker.register('/sw.js');
      let refreshing = false;

      navigator.serviceWorker.addEventListener('controllerchange', () => {
        if (refreshing) return;
        refreshing = true;
        window.location.reload();
      });

      const promptForUpdate = (installingWorker) => {
        installingWorker.addEventListener('statechange', () => {
          if (installingWorker.state === 'installed' && navigator.serviceWorker.controller) {
            const shouldRefresh = window.confirm('New version available. Refresh?');
            if (shouldRefresh) {
              installingWorker.postMessage({ type: 'SKIP_WAITING' });
            }
          }
        });
      };

      if (registration.waiting) {
        const shouldRefresh = window.confirm('New version available. Refresh?');
        if (shouldRefresh) {
          registration.waiting.postMessage({ type: 'SKIP_WAITING' });
        }
      }

      registration.addEventListener('updatefound', () => {
        const installingWorker = registration.installing;
        if (installingWorker) {
          promptForUpdate(installingWorker);
        }
      });

      setInterval(() => {
        registration.update().catch(() => {});
      }, 60 * 60 * 1000);
    } catch (error) {
      console.error('SW registration failed:', error);
    }
  });
}
