import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  type BuildMeta,
  deleteBuild,
  formatSize,
  listBuilds,
  renameBuild,
  uploadZip,
} from "@/lib/builds";
import { DEVICES, PhoneFrame } from "@/components/PhoneFrame";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Flutter Web Preview — мгновенный просмотр сборок" },
      { name: "description", content: "Загрузите zip с flutter build web и сразу смотрите приложение в эмулированном телефоне." },
    ],
  }),
  component: Index,
});

function useSwReady() {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    if (!("serviceWorker" in navigator)) {
      setError("Service Worker не поддерживается этим браузером.");
      return;
    }
    navigator.serviceWorker
      .register("/api/public/preview-sw", { scope: "/" })
      .then(async (reg) => {
        await navigator.serviceWorker.ready;
        if (!navigator.serviceWorker.controller) {
          // First load — claim happens on activate, but page may need reload to be controlled.
          reg.active && setReady(true);
        } else {
          setReady(true);
        }
      })
      .catch((e) => setError(String(e)));
  }, []);
  return { ready, error };
}

function Index() {
  const { ready: swReady, error: swError } = useSwReady();
  const [builds, setBuilds] = useState<BuildMeta[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [deviceId, setDeviceId] = useState(DEVICES[0].id);
  const [mobilePanel, setMobilePanel] = useState<"builds" | "preview">("preview");
  const [rotated, setRotated] = useState(false);
  const [reloadKey, setReloadKey] = useState(0);
  const [progress, setProgress] = useState<{ current: number; total: number } | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const refresh = async () => {
    const list = await listBuilds();
    setBuilds(list);
    if (!activeId && list.length) setActiveId(list[0].id);
  };
  useEffect(() => {
    refresh();
  }, []);

  const handleFiles = async (files: FileList | null) => {
    if (!files || !files[0]) return;
    const f = files[0];
    if (!/\.zip$/i.test(f.name)) {
      alert("Нужен .zip архив");
      return;
    }
    setProgress({ current: 0, total: 1 });
    try {
      const meta = await uploadZip(f, (p) => setProgress({ current: p.current, total: p.total }));
      await refresh();
      setActiveId(meta.id);
      setMobilePanel("preview");
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setProgress(null);
    }
  };

  const device = DEVICES.find((d) => d.id === deviceId) ?? DEVICES[0];
  const previewSrc = activeId ? `/preview/${activeId}/index.html` : "";

  return (
    <div className="flex h-[100dvh] flex-col overflow-hidden bg-background text-foreground">
      <header className="flex shrink-0 items-center justify-between gap-3 border-b border-border/60 px-4 py-3 sm:px-6">
        <div className="flex min-w-0 items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground font-bold">F</div>
          <div className="min-w-0">
            <h1 className="truncate text-base font-semibold leading-tight">Flutter Web Preview</h1>
            <p className="hidden text-xs text-muted-foreground min-[380px]:block">Мгновенный просмотр без APK</p>
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <input
            ref={fileRef}
            type="file"
            accept=".zip"
            className="hidden"
            onChange={(e) => handleFiles(e.target.files)}
          />
          <Button className="h-10 px-3 sm:px-4" onClick={() => fileRef.current?.click()} disabled={!!progress}>
            {progress ? `Загрузка ${progress.current}/${progress.total}` : "Загрузить ZIP"}
          </Button>
        </div>
      </header>

      <div className="grid shrink-0 grid-cols-2 border-b border-border/60 p-2 lg:hidden">
        <Button variant={mobilePanel === "builds" ? "default" : "ghost"} onClick={() => setMobilePanel("builds")}>
          Сборки {builds.length ? `(${builds.length})` : ""}
        </Button>
        <Button variant={mobilePanel === "preview" ? "default" : "ghost"} onClick={() => setMobilePanel("preview")}>
          Превью
        </Button>
      </div>

      <div className="flex min-h-0 flex-1 flex-col overflow-hidden lg:flex-row">
        {/* Sidebar */}
        <aside className={`min-h-0 flex-col border-border/60 bg-card/40 lg:flex lg:w-72 lg:border-r ${mobilePanel === "builds" ? "flex flex-1" : "hidden"}`}>
          <div className="shrink-0 border-b border-border/60 px-4 py-3">
            <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Сборки</h2>
          </div>
          <div className="flex-1 overflow-y-auto p-2">
            {builds.length === 0 && (
              <div
                onDragOver={(e) => {
                  e.preventDefault();
                  setDragOver(true);
                }}
                onDragLeave={() => setDragOver(false)}
                onDrop={(e) => {
                  e.preventDefault();
                  setDragOver(false);
                  handleFiles(e.dataTransfer.files);
                }}
                className={`m-2 rounded-lg border-2 border-dashed p-6 text-center text-sm transition-colors ${
                  dragOver ? "border-primary bg-primary/10" : "border-border/60 text-muted-foreground"
                }`}
              >
                Перетащите сюда zip с папкой <code className="text-foreground">build/web</code>
              </div>
            )}
            {builds.map((b) => (
              <button
                key={b.id}
                onClick={() => setActiveId(b.id)}
                className={`mb-1 w-full rounded-md px-3 py-2 text-left transition-colors ${
                  activeId === b.id ? "bg-primary/15 ring-1 ring-primary/30" : "hover:bg-accent"
                }`}
              >
                <div className="truncate text-sm font-medium">{b.name}</div>
                <div className="mt-0.5 flex justify-between text-xs text-muted-foreground">
                  <span>{b.fileCount} файлов</span>
                  <span>{formatSize(b.totalSize)}</span>
                </div>
                <div className="mt-1 flex gap-3 text-xs">
                  <span
                    onClick={(e) => {
                      e.stopPropagation();
                      const name = prompt("Новое имя", b.name);
                      if (name) renameBuild(b.id, name).then(refresh);
                    }}
                    className="text-muted-foreground hover:text-foreground"
                  >
                    переименовать
                  </span>
                  <span
                    onClick={async (e) => {
                      e.stopPropagation();
                      if (confirm(`Удалить «${b.name}»?`)) {
                        await deleteBuild(b.id);
                        if (activeId === b.id) setActiveId(null);
                        refresh();
                      }
                    }}
                    className="text-destructive/80 hover:text-destructive"
                  >
                    удалить
                  </span>
                </div>
              </button>
            ))}
          </div>
          <div className="shrink-0 border-t border-border/60 p-3 text-xs text-muted-foreground">
            <p className="mb-1 font-medium text-foreground">Как получить zip:</p>
            <code className="block rounded bg-muted px-2 py-1 text-[11px] text-foreground">
              flutter build web
            </code>
            <p className="mt-2">
              затем сожмите папку <code>build/web</code> в zip — или настройте GitHub Action,
              который выкладывает её как артефакт.
            </p>
          </div>
        </aside>

        {/* Main */}
        <main className={`min-h-0 flex-1 flex-col ${mobilePanel === "preview" ? "flex" : "hidden lg:flex"}`}>
          <div className="shrink-0 border-b border-border/60 px-3 py-2 sm:px-4">
            <div className="grid grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-2 sm:flex sm:overflow-x-visible">
              <Select value={deviceId} onValueChange={setDeviceId}>
                <SelectTrigger className="h-10 w-[172px] shrink-0 sm:w-44">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {DEVICES.map((d) => (
                    <SelectItem key={d.id} value={d.id}>
                      {d.label} · {d.width}×{d.height}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button className="shrink-0 px-3" variant="outline" size="sm" onClick={() => setRotated((r) => !r)} disabled={device.id === "desktop"} title="Повернуть">
                ↻<span className="hidden min-[390px]:inline"> Повернуть</span>
              </Button>
              <Button className="shrink-0 px-3" variant="outline" size="sm" onClick={() => setReloadKey((k) => k + 1)} disabled={!activeId} title="Перезагрузить">
                ⟳<span className="hidden sm:inline"> Перезагрузить</span>
              </Button>
              {activeId && (
                <a
                  href={previewSrc}
                  target="_blank"
                  rel="noreferrer"
                  className="col-span-3 text-center text-xs text-muted-foreground underline hover:text-foreground sm:col-span-1"
                >
                  открыть в новой вкладке ↗
                </a>
              )}
            </div>
          </div>

          <div className="relative min-h-0 flex-1 bg-background">
            {!swReady && (
              <Overlay>
                {swError ? `Ошибка Service Worker: ${swError}` : "Инициализация Service Worker…"}
              </Overlay>
            )}
            {swReady && !activeId && (
              <Overlay>
                {builds.length === 0
                  ? "Загрузите ZIP-архив с папкой build/web."
                  : "Выберите сборку во вкладке «Сборки»."}
              </Overlay>
            )}
            {swReady && activeId && (
              <PhoneFrame src={previewSrc} device={device} rotated={rotated} reloadKey={reloadKey} />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}

function Overlay({ children }: { children: React.ReactNode }) {
  return (
    <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
      <Card className="pointer-events-auto bg-card/80 px-6 py-4 text-sm text-muted-foreground backdrop-blur">
        {children}
      </Card>
    </div>
  );
}
