import { useId } from "react";

// Evdekiler logosu: yeşil degrade zeminde krem bir ev, içinde filiz.
// Mobildeki uygulama simgesi ve logo da aynı çizim.
export default function Logo({ size = 40 }: { size?: number }) {
  // Sayfada birden çok logo olursa degrade kimlikleri çakışmasın
  const gradientId = `evdekiler-logo-${useId()}`;

  return (
    <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true" className="shrink-0">
      <defs>
        <linearGradient id={gradientId} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#8fd46b" />
          <stop offset="1" stopColor="#2f7a45" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="18" fill={`url(#${gradientId})`} />
      {/* ev */}
      <path
        d="M32 11.5c1.2 0 2.4.4 3.3 1.2l13.4 11.7c1.1 1 1.8 2.4 1.8 3.9V45.5a5.5 5.5 0 0 1-5.5 5.5h-26a5.5 5.5 0 0 1-5.5-5.5V28.3c0-1.5.7-2.9 1.8-3.9l13.4-11.7c.9-.8 2.1-1.2 3.3-1.2Z"
        fill="#faf7f2"
      />
      {/* filiz */}
      <path d="M32 46c0-8.6 5.2-14.2 13.6-15.3-.7 8.8-6 14.2-13.6 15.3Z" fill="#3f9150" />
      <path d="M32 46c-.3-5.4-3.5-9.3-9.3-10.4.3 5.9 3.7 9.5 9.3 10.4Z" fill="#74c062" />
      <path d="M32 45.5V49.5" stroke="#2f7a45" strokeWidth="2.6" strokeLinecap="round" />
    </svg>
  );
}