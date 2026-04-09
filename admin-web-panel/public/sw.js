const SW_VERSION = '2026-04-09';
const STATIC_CACHE = `ph-static-${SW_VERSION}`;
const DYNAMIC_CACHE = `ph-dynamic-${SW_VERSION}`;

const APP_SHELL = [
  '/',
  '/index.html',
  '/manifest.json',
  '/favicon.svg',
  '/logo.jpg',
  '/icons.svg',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();

  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(APP_SHELL)),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((key) => key !== STATIC_CACHE && key !== DYNAMIC_CACHE)
          .map((key) => caches.delete(key)),
      );

      await self.clients.claim();
    })(),
  );
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const { request } = event;

  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);

  if (request.mode === 'navigate') {
    event.respondWith(networkFirstPage(request));
    return;
  }

  if (isStaticAsset(request, url)) {
    event.respondWith(staleWhileRevalidate(request));
    return;
  }

  if (isApiRequest(url)) {
    event.respondWith(networkFirstApi(request));
  }
});

function isStaticAsset(request, url) {
  if (url.origin !== self.location.origin) {
    return false;
  }

  return ['script', 'style', 'image', 'font'].includes(request.destination);
}

function isApiRequest(url) {
  return url.pathname.startsWith('/api/');
}

async function networkFirstPage(request) {
  const cache = await caches.open(DYNAMIC_CACHE);

  try {
    const response = await fetch(request);
    cache.put(request, response.clone());
    return response;
  } catch {
    const cached = await cache.match(request);
    if (cached) {
      return cached;
    }

    const fallback = await caches.match('/index.html');
    if (fallback) {
      return fallback;
    }

    return new Response('Offline', {
      status: 503,
      statusText: 'Offline',
      headers: { 'Content-Type': 'text/plain' },
    });
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(STATIC_CACHE);
  const cached = await cache.match(request);

  const networkFetch = fetch(request)
    .then((response) => {
      if (response && response.ok) {
        cache.put(request, response.clone());
      }
      return response;
    })
    .catch(() => undefined);

  return cached || networkFetch || new Response('', { status: 504, statusText: 'Gateway Timeout' });
}

async function networkFirstApi(request) {
  const cache = await caches.open(DYNAMIC_CACHE);

  try {
    const response = await fetch(request);
    if (response && response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch {
    const cached = await cache.match(request);
    if (cached) {
      return cached;
    }

    return new Response(
      JSON.stringify({ message: 'You are offline. Cached data not available.' }),
      {
        status: 503,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }
}
