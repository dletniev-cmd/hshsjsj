// Service Worker that serves uploaded Flutter web builds from IndexedDB.
// URL scheme: /preview/<buildId>/<path-inside-build>

const DB_NAME = 'keyval-store';
const STORE_NAME = 'keyval';

function openDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => req.result.createObjectStore(STORE_NAME);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function idbGet(key) {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_NAME, 'readonly');
    const req = tx.objectStore(STORE_NAME).get(key);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

const MIME = {
  html: 'text/html; charset=utf-8',
  htm: 'text/html; charset=utf-8',
  js: 'application/javascript; charset=utf-8',
  mjs: 'application/javascript; charset=utf-8',
  css: 'text/css; charset=utf-8',
  json: 'application/json; charset=utf-8',
  wasm: 'application/wasm',
  svg: 'image/svg+xml',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  gif: 'image/gif',
  webp: 'image/webp',
  ico: 'image/x-icon',
  ttf: 'font/ttf',
  otf: 'font/otf',
  woff: 'font/woff',
  woff2: 'font/woff2',
  txt: 'text/plain; charset=utf-8',
  map: 'application/json; charset=utf-8',
  xml: 'application/xml; charset=utf-8',
};

function mimeFor(path) {
  const ext = path.split('.').pop().toLowerCase();
  return MIME[ext] || 'application/octet-stream';
}

self.addEventListener('install', (e) => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  const m = url.pathname.match(/^\/preview\/([^/]+)\/(.*)$/);
  if (!m) return;

  event.respondWith((async () => {
    const buildId = m[1];
    let path = m[2] || 'index.html';
    if (path === '' || path.endsWith('/')) path += 'index.html';

    const tryKeys = [
      `build:${buildId}:${path}`,
      `build:${buildId}:${path}/index.html`,
    ];
    let entry = null;
    for (const k of tryKeys) {
      entry = await idbGet(k);
      if (entry) break;
    }
    if (!entry) {
      return new Response('Not found: ' + path, { status: 404 });
    }
    const headers = new Headers({
      'Content-Type': entry.type || mimeFor(path),
      'Cache-Control': 'no-store',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
    });
    return new Response(entry.data, { status: 200, headers });
  })());
});
