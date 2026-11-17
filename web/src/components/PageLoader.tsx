import Logo from "@/components/Logo";

// Sayfa verisi gelene kadar ekranın ortasında görünen yükleme ekranı
export default function PageLoader() {
  return (
    <main
      role="status"
      aria-label="Yükleniyor"
      className="flex min-h-screen flex-col items-center justify-center gap-5 bg-cream"
    >
      <style>{`
        @keyframes loader-breathe { 0%,100% { transform: scale(1); } 50% { transform: scale(1.06); } }
        @keyframes loader-slide { from { transform: translateX(-100%); } to { transform: translateX(250%); } }
        @media (prefers-reduced-motion: no-preference) {
          .loader-logo { animation: loader-breathe 1.6s ease-in-out infinite; }
          .loader-bar { animation: loader-slide 1.1s cubic-bezier(0.65, 0, 0.35, 1) infinite; }
        }
      `}</style>

            <div className="loader-logo drop-shadow-[0_10px_24px_rgba(216,189,130,0.45)]">
        <Logo size={64} />
      </div>

      <div className="text-center">
        <p className="text-xl font-extrabold tracking-tight text-forest">Evdekiler</p>
        <p className="mt-0.5 text-sm text-muted">Mutfak hazırlanıyor…</p>
      </div>

      <div className="h-1 w-32 overflow-hidden rounded-full bg-forest/10">
        <div className="loader-bar h-full w-2/5 rounded-full bg-forest" />
      </div>
    </main>
  );
}