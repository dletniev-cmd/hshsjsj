import "@tanstack/react-start";
import { createFileRoute } from "@tanstack/react-router";

const serviceWorkerSource = `
const DB_NAME = "keyval-store";
const STORE_NAME = "keyval";

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
    const tx = db.transaction(STORE_NAME, "readonly");
    const req = tx.objectStore(STORE_NAME).get(key);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

const MIME = {
  html: "text/html; charset=utf-8",
  htm: "text/html; charset=utf-8",
  js: "application/javascript; charset=utf-8",
  mjs: "application/javascript; charset=utf-8",
  css: "text/css; charset=utf-8",
  json: "application/json; charset=utf-8",
  wasm: "application/wasm",
  svg: "image/svg+xml",
  png: "image/png",
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  gif: "image/gif",
  webp: "image/webp",
  ico: "image/x-icon",
  ttf: "font/ttf",
  otf: "font/otf",
  woff: "font/woff",
  woff2: "font/woff2",
  txt: "text/plain; charset=utf-8",
  map: "application/json; charset=utf-8",
  xml: "application/xml; charset=utf-8"
};

function mimeFor(path) {
  const ext = path.split(".").pop().toLowerCase();
  return MIME[ext] || "application/octet-stream";
}

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  const match = url.pathname.match(/^\\/preview\\/([^/]+)\\/(.*)$/);
  if (!match) return;

  event.respondWith((async () => {
    const buildId = match[1];
    let path = match[2] || "index.html";
    if (path === "" || path.endsWith("/")) path += "index.html";

    const keys = [
      "build:" + buildId + ":" + path,
      "build:" + buildId + ":" + path + "/index.html"
    ];

    let entry = null;
    for (const key of keys) {
      entry = await idbGet(key);
      if (entry) break;
    }

    if (!entry && event.request.mode === "navigate") {
      path = "index.html";
      entry = await idbGet("build:" + buildId + ":index.html");
    }

    if (!entry) {
      return new Response("Not found: " + path, { status: 404 });
    }

    return new Response(entry.data, {
      status: 200,
      headers: {
        "Content-Type": entry.type || mimeFor(path),
        "Cache-Control": "no-store"
      }
    });
  })());
});
`;

export const Route = createFileRoute("/api/public/preview-sw")({
  server: {
    handlers: {
      GET: async () =>
        new Response(serviceWorkerSource, {
          headers: {
            "Content-Type": "application/javascript; charset=utf-8",
            "Cache-Control": "no-store",
            "Service-Worker-Allowed": "/",
          },
        }),
    },
  },
});