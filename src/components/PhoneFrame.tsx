import { useEffect, useRef, useState } from "react";

export type Device = {
  id: string;
  label: string;
  width: number;
  height: number;
  dpr: number;
};

export const DEVICES: Device[] = [
  { id: "iphone-15", label: "iPhone 15", width: 393, height: 852, dpr: 3 },
  { id: "iphone-se", label: "iPhone SE", width: 375, height: 667, dpr: 2 },
  { id: "pixel-7", label: "Pixel 7", width: 412, height: 915, dpr: 2.625 },
  { id: "galaxy-s8", label: "Galaxy S8", width: 360, height: 740, dpr: 3 },
  { id: "ipad-mini", label: "iPad Mini", width: 768, height: 1024, dpr: 2 },
  { id: "desktop", label: "Desktop", width: 1280, height: 800, dpr: 1 },
];

type Props = {
  src: string;
  device: Device;
  rotated: boolean;
  reloadKey: number;
};

export function PhoneFrame({ src, device, rotated, reloadKey }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);

  const w = rotated ? device.height : device.width;
  const h = rotated ? device.width : device.height;
  const isPhone = device.id !== "desktop";

  useEffect(() => {
    function recalc() {
      const el = containerRef.current;
      if (!el) return;
      const pad = Math.min(40, Math.max(16, el.clientWidth * 0.08));
      const availW = el.clientWidth - pad;
      const availH = el.clientHeight - pad;
      const frameW = w + (isPhone ? 24 : 0);
      const frameH = h + (isPhone ? 24 : 0);
      const s = Math.min(availW / frameW, availH / frameH, 1);
      setScale(s);
    }
    recalc();
    const ro = new ResizeObserver(recalc);
    if (containerRef.current) ro.observe(containerRef.current);
    return () => ro.disconnect();
  }, [w, h, isPhone]);

  return (
    <div ref={containerRef} className="flex h-full w-full items-center justify-center overflow-hidden p-2 sm:p-4">
      <div
        style={{
          transform: `scale(${scale})`,
          transformOrigin: "center center",
          transition: "transform 0.2s ease",
        }}
      >
        <div
          className={
            isPhone
              ? "rounded-[44px] bg-card p-2 shadow-[0_24px_70px_-24px_var(--color-background)] ring-1 ring-border sm:p-3"
              : "rounded-md bg-card p-1 shadow-[0_24px_70px_-24px_var(--color-background)] ring-1 ring-border"
          }
        >
          <iframe
            key={reloadKey}
            title="preview"
            src={src}
            style={{ width: w, height: h }}
            className={isPhone ? "rounded-[32px] bg-background" : "rounded-sm bg-background"}
            allow="clipboard-read; clipboard-write; accelerometer; gyroscope; camera; microphone; fullscreen"
          />
        </div>
      </div>
    </div>
  );
}
