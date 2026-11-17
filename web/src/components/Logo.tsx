import { useId } from "react";

// Evdekiler logosu: koyu yeşil zeminde şampanya altını (#D8BD82) ev ve filiz.
// Mobildeki uygulama simgesi ve logo.svg aynı çizim.
export default function Logo({ size = 40 }: { size?: number }) {
  // Sayfada birden çok logo olursa degrade kimlikleri çakışmasın
  const id = useId().replace(/:/g, "");
  const bg = `bg-${id}`;
  const gold = `gold-${id}`;
  const leafA = `leafA-${id}`;
  const leafB = `leafB-${id}`;
  const shine = `shine-${id}`;

  return (
    <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true" className="shrink-0">
      <defs>
        <linearGradient id={bg} x1="0" y1="0" x2="0.6" y2="1">
          <stop offset="0" stopColor="#2a5a40" />
          <stop offset="1" stopColor="#122a1c" />
        </linearGradient>
        {/* Metalik altın: açık şampanya → #D8BD82 → bronz */}
        <linearGradient id={gold} gradientUnits="userSpaceOnUse" x1="12" y1="12" x2="52" y2="52">
          <stop offset="0" stopColor="#f3e3bb" />
          <stop offset="0.45" stopColor="#D8BD82" />
          <stop offset="1" stopColor="#a98b52" />
        </linearGradient>
        <linearGradient id={leafA} x1="0" y1="1" x2="1" y2="0">
          <stop offset="0" stopColor="#b89a5f" />
          <stop offset="1" stopColor="#f1deb0" />
        </linearGradient>
        <linearGradient id={leafB} x1="1" y1="1" x2="0" y2="0">
          <stop offset="0" stopColor="#a98b52" />
          <stop offset="1" stopColor="#e6cf9b" />
        </linearGradient>
        <radialGradient id={shine} cx="0.3" cy="0.15" r="0.8">
          <stop offset="0" stopColor="#ffffff" stopOpacity="0.16" />
          <stop offset="1" stopColor="#ffffff" stopOpacity="0" />
        </radialGradient>
      </defs>

      {/* zemin + ışık + ince altın kenar */}
      <rect width="64" height="64" rx="16" fill={`url(#${bg})`} />
      <rect width="64" height="64" rx="16" fill={`url(#${shine})`} />
      <rect x="1" y="1" width="62" height="62" rx="15" fill="none" stroke="#D8BD82" strokeOpacity="0.4" strokeWidth="0.8" />

      {/* ev ve baca */}
      <g fill="none" stroke={`url(#${gold})`} strokeWidth="3.6" strokeLinecap="round" strokeLinejoin="round">
        <path d="M12.5 30.5 32 13.5l19.5 17" />
        <path d="M17 27v18.5a4.5 4.5 0 0 0 4.5 4.5h21a4.5 4.5 0 0 0 4.5-4.5V27" />
        <path d="M41.5 20.5v-5.5" />
      </g>

      {/* filiz: sap, iki yaprak (damarlı), toprak */}
      <path d="M32 46.5c0-2.6-.1-5.4.3-8.4" stroke={`url(#${gold})`} strokeWidth="2.2" strokeLinecap="round" fill="none" />
      <path d="M32.3 38.6c.6-6.6 5.3-10.9 12.4-11.6-.4 7.2-5.1 11.3-12.4 11.6Z" fill={`url(#${leafA})`} />
      <path d="M33 37.8c2.6-2.6 5.6-5 9.6-8.8" stroke="#8a6f3d" strokeOpacity="0.55" strokeWidth="0.8" strokeLinecap="round" fill="none" />
      <path d="M31.8 40.8c-.5-5.1-4-8.5-9.6-9.1.3 5.6 3.9 8.8 9.6 9.1Z" fill={`url(#${leafB})`} />
      <path d="M31.2 40.1c-2-2-4.3-4-7.4-6.9" stroke="#8a6f3d" strokeOpacity="0.55" strokeWidth="0.8" strokeLinecap="round" fill="none" />
      <path d="M25.5 47c2-1.3 4.2-1.9 6.5-1.9s4.5.6 6.5 1.9" stroke={`url(#${gold})`} strokeWidth="2" strokeLinecap="round" fill="none" />
    </svg>
  );
}