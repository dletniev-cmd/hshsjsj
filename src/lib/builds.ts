import { get, set, del, keys } from "idb-keyval";
import JSZip from "jszip";

export type BuildMeta = {
  id: string;
  name: string;
  createdAt: number;
  fileCount: number;
  totalSize: number;
};

const META_KEY = "builds:meta";

export async function listBuilds(): Promise<BuildMeta[]> {
  return (await get<BuildMeta[]>(META_KEY)) ?? [];
}

async function saveMeta(metas: BuildMeta[]) {
  await set(META_KEY, metas);
}

const MIME: Record<string, string> = {
  html: "text/html; charset=utf-8",
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
};
function mimeFor(path: string) {
  const ext = path.split(".").pop()?.toLowerCase() ?? "";
  return MIME[ext] ?? "application/octet-stream";
}

export type UploadProgress = (info: { phase: string; current: number; total: number }) => void;

export async function uploadZip(file: File, onProgress?: UploadProgress): Promise<BuildMeta> {
  const zip = await JSZip.loadAsync(file);
  const allEntries = Object.values(zip.files).filter((e) => !e.dir);

  // Detect a common root folder so /index.html ends up at top-level.
  // Find index.html with the shortest path.
  const indexEntry = allEntries
    .filter((e) => e.name.endsWith("index.html"))
    .sort((a, b) => a.name.length - b.name.length)[0];
  if (!indexEntry) {
    throw new Error("В архиве не найден index.html. Загрузите содержимое папки build/web (или build/web как корень архива).");
  }
  const rootPrefix = indexEntry.name.slice(0, indexEntry.name.length - "index.html".length);

  const id = crypto.randomUUID().slice(0, 8);
  let totalSize = 0;
  let fileCount = 0;
  const total = allEntries.length;
  let i = 0;
  for (const entry of allEntries) {
    i++;
    if (rootPrefix && !entry.name.startsWith(rootPrefix)) continue;
    const rel = entry.name.slice(rootPrefix.length);
    if (!rel) continue;
    const data = await entry.async("arraybuffer");
    totalSize += data.byteLength;
    fileCount++;
    await set(`build:${id}:${rel}`, { data, type: mimeFor(rel) });
    onProgress?.({ phase: "Распаковка", current: i, total });
  }

  const meta: BuildMeta = {
    id,
    name: file.name.replace(/\.zip$/i, ""),
    createdAt: Date.now(),
    fileCount,
    totalSize,
  };
  const metas = await listBuilds();
  metas.unshift(meta);
  await saveMeta(metas);
  return meta;
}

export async function deleteBuild(id: string) {
  const allKeys = await keys();
  const prefix = `build:${id}:`;
  await Promise.all(
    allKeys
      .filter((k) => typeof k === "string" && (k as string).startsWith(prefix))
      .map((k) => del(k)),
  );
  const metas = await listBuilds();
  await saveMeta(metas.filter((m) => m.id !== id));
}

export async function renameBuild(id: string, name: string) {
  const metas = await listBuilds();
  const m = metas.find((x) => x.id === id);
  if (m) {
    m.name = name;
    await saveMeta(metas);
  }
}

export function formatSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
}
