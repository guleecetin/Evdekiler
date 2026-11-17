"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Bricolage_Grotesque } from "next/font/google";
import { BookOpen, Carrot, ChevronRight, LogOut, Sparkles, Users } from "lucide-react";
import Logo from "@/components/Logo";
import { logout, type Me } from "@/lib/api";
import { listSuggestions } from "@/lib/suggestions";
import { clearAdminCache } from "@/lib/useAdmin";

const display = Bricolage_Grotesque({
  subsets: ["latin", "latin-ext"],
  weight: ["600", "700", "800"],
  display: "swap",
});

type Props = {
  me: Me;
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  back?: React.ReactNode;
  children: React.ReactNode;
};

const SECTIONS = [
  {
    label: "İçerik",
    items: [
      { href: "/", label: "Tarifler", icon: BookOpen },
      { href: "/ingredients", label: "Malzemeler", icon: Carrot },
    ],
  },
  {
    label: "Topluluk",
    items: [
      { href: "/suggestions", label: "Öneriler", icon: Sparkles },
      { href: "/users", label: "Kullanıcılar", icon: Users },
    ],
  },
];

const ALL_ITEMS = SECTIONS.flatMap((s) => s.items);

function isActive(href: string, pathname: string) {
  if (href === "/") return pathname === "/" || pathname.startsWith("/recipes");
  return pathname.startsWith(href);
}

// ─── Öneri rozeti: kısa süreli önbellek ─────────────────────
// Her sayfa kendi AdminShell'ini kurduğu için sayıyı modül seviyesinde tutuyoruz.
// 30 sn içinde tekrar sorulursa sunucuya gitmez; aynı anda gelen çağrılar tek isteği bekler.
const PENDING_TTL_MS = 30_000;
let pendingCache: { value: number; at: number } | null = null;
let pendingRequest: Promise<number> | null = null;

function getPendingCount(force: boolean): Promise<number> {
  if (!force && pendingCache && Date.now() - pendingCache.at < PENDING_TTL_MS) {
    return Promise.resolve(pendingCache.value);
  }
  pendingRequest ??= listSuggestions()
    .then((list) => {
      pendingCache = { value: list.length, at: Date.now() };
      return list.length;
    })
    .finally(() => {
      pendingRequest = null;
    });
  return pendingRequest;
}

// Bütün animasyonlar burada. Sadece transform/opacity: ekran kartıyla çizilir, işlemciyi yormaz.
// "Animasyonları azalt" açık olan kullanıcılarda hiçbiri çalışmaz.
const ANIMATIONS = `
@keyframes evdekiler-page-in {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes evdekiler-steam {
  0%   { opacity: 0;   transform: translateY(6px)  scaleY(0.9); }
  35%  { opacity: 1; }
  100% { opacity: 0;   transform: translateY(-10px) scaleY(1.1); }
}
@keyframes evdekiler-drift-a {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50%      { transform: translate(-120px, 80px) scale(1.15); }
}
@keyframes evdekiler-drift-b {
  0%, 100% { transform: translate(0, 0) scale(1.1); }
  50%      { transform: translate(140px, -60px) scale(0.95); }
}
@keyframes evdekiler-sway {
  0%, 100% { transform: rotate(-2deg); }
  50%      { transform: rotate(2.5deg); }
}

.steam { transform-box: fill-box; transform-origin: bottom center; opacity: 0.7; }

@media (prefers-reduced-motion: no-preference) {
  /* "backwards": bittikten sonra transform bırakmaz; yoksa içerideki fixed pencereler bozulur */
  .page-enter { animation: evdekiler-page-in 0.35s cubic-bezier(0.22, 1, 0.36, 1) backwards; }

  .steam   { animation: evdekiler-steam 3.2s ease-in-out infinite; opacity: 0; }
  .steam-2 { animation-delay: 0.9s; }
  .steam-3 { animation-delay: 1.8s; }

  .glow-a { animation: evdekiler-drift-a 26s ease-in-out infinite; }
  .glow-b { animation: evdekiler-drift-b 32s ease-in-out infinite; }

  .herb-sway { transform-origin: 10% 100%; animation: evdekiler-sway 9s ease-in-out infinite; }
}
`;

export default function AdminShell({ me, title, subtitle, actions, back, children }: Props) {
  const router = useRouter();
  const pathname = usePathname();
  // Önbellekte varsa ilk render'da göster: rozet sayfa geçişinde kaybolup geri gelmesin
  const [pending, setPending] = useState<number | null>(pendingCache?.value ?? null);
  const [today, setToday] = useState("");

  useEffect(() => {
    let alive = true;
    // Öneriler sayfasındayken her zaman taze sayı
    getPendingCount(pathname.startsWith("/suggestions"))
      .then((n) => {
        if (alive) setPending(n);
      })
      .catch(() => {});
    return () => {
      alive = false;
    };
  }, [pathname]);

  useEffect(() => {
    setToday(new Date().toLocaleDateString("tr-TR", { weekday: "long", day: "numeric", month: "long" }));
  }, []);

  const current = ALL_ITEMS.find((i) => isActive(i.href, pathname));
  const crumbs = [current?.label ?? "Panel", ...(current && current.label !== title ? [title] : [])];

  async function handleLogout() {
    await logout();
    clearAdminCache();
    pendingCache = null;
    router.replace("/login");
  }

  return (
    <div className="min-h-screen bg-cream text-ink">
      <style>{ANIMATIONS}</style>

      {/* ─── Zeminde süzülen ışıklar ───────────────────── */}
      <div aria-hidden="true" className="pointer-events-none fixed inset-0 overflow-hidden">
        <div className="glow-a absolute -right-40 -top-40 h-[560px] w-[560px] rounded-full bg-[#9cc79a]/25 blur-3xl" />
        <div className="glow-b absolute -bottom-48 left-[22%] h-[520px] w-[520px] rounded-full bg-[#D8BD82]/20 blur-3xl" />
      </div>

      {/* ─── Sol menü ─────────────────────────────────── */}
      <aside className="fixed inset-y-0 left-0 z-30 hidden w-[264px] flex-col overflow-hidden bg-gradient-to-b from-forest to-[#132a1d] text-white lg:flex">
        <div className="herb-sway pointer-events-none absolute -left-6 bottom-20 w-[300px]">
          <HerbArt className="w-full text-[#D8BD82]/[0.12]" />
        </div>

        <Link href="/" className="relative flex items-center gap-3 px-6 pb-8 pt-7">
          <Logo size={40} />
          <div className="leading-none">
            <p className={`${display.className} text-[22px] font-extrabold tracking-tight`}>Evdekiler</p>
            <p className="mt-1 text-xs text-[#D8BD82]/70">Yönetim paneli</p>
          </div>
        </Link>

        <nav className="relative flex-1 space-y-7 px-4">
          {SECTIONS.map((section) => (
            <div key={section.label}>
              <p className="px-3 pb-2 text-xs font-medium text-white/40">{section.label}</p>
              <div className="space-y-1">
                {section.items.map((item) => {
                  const Icon = item.icon;
                  const active = isActive(item.href, pathname);
                  const badge = item.href === "/suggestions" && pending ? pending : null;
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      aria-current={active ? "page" : undefined}
                      className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-[15px] font-semibold transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D8BD82] ${
                        active
                          ? "bg-cream text-forest shadow-[0_6px_18px_rgba(0,0,0,0.25)]"
                          : "text-white/70 hover:bg-white/[0.07] hover:text-white"
                      }`}
                    >
                      <Icon className={`h-[18px] w-[18px] ${active ? "text-basil" : ""}`} strokeWidth={2} />
                      {item.label}
                      {badge && (
                        <span className="ml-auto min-w-[22px] rounded-full bg-tomato px-1.5 py-0.5 text-center text-[11px] font-bold text-white">
                          {badge}
                        </span>
                      )}
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        <div className="relative border-t border-white/10 p-4">
          <div className="flex items-center gap-3 rounded-xl px-2 py-1.5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#D8BD82] text-sm font-bold text-forest ring-2 ring-white/15">
              {me.displayName.charAt(0).toLocaleUpperCase("tr-TR")}
            </div>
            <div className="min-w-0 flex-1 leading-tight">
              <p className="truncate text-sm font-semibold">{me.displayName}</p>
              <p className="truncate text-xs text-white/50">{me.email}</p>
            </div>
            <button
              onClick={handleLogout}
              title="Çıkış yap"
              aria-label="Çıkış yap"
              className="rounded-lg p-2 text-white/50 transition hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D8BD82]"
            >
              <LogOut className="h-[18px] w-[18px]" strokeWidth={1.75} />
            </button>
          </div>
        </div>
      </aside>

      {/* ─── Sağ taraf ─────────────────────────────────── */}
      <div className="relative lg:pl-[264px]">
        <header className="sticky top-0 z-20 border-b border-line/70 bg-cream/75 backdrop-blur-md">
          <div className="flex h-16 items-center justify-between gap-4 px-6 lg:px-10">
            <nav aria-label="Konum" className="flex min-w-0 items-center gap-1.5 text-sm">
              <span className="hidden text-muted sm:inline">Panel</span>
              {crumbs.map((c, i) => (
                <span key={c} className="flex min-w-0 items-center gap-1.5">
                  <ChevronRight className="hidden h-4 w-4 shrink-0 text-neutral-300 sm:block" />
                  <span className={`truncate ${i === crumbs.length - 1 ? "font-semibold text-forest" : "text-muted"}`}>{c}</span>
                </span>
              ))}
            </nav>
            <div className="flex items-center gap-3">
              {today && (
                <span className="hidden rounded-full bg-white/80 px-3 py-1 text-sm capitalize text-muted ring-1 ring-line md:inline">
                  {today}
                </span>
              )}
              <div className="lg:hidden">
                <Logo size={32} />
              </div>
            </div>
          </div>

          <nav className="flex gap-2 overflow-x-auto px-6 pb-3 lg:hidden">
            {ALL_ITEMS.map((item) => {
              const active = isActive(item.href, pathname);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`shrink-0 rounded-full px-3.5 py-1.5 text-sm font-semibold ${
                    active ? "bg-forest text-white" : "bg-white text-muted ring-1 ring-line"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </header>

        <main key={pathname} className="page-enter mx-auto max-w-[1360px] px-6 pb-16 pt-8 lg:px-10">
          {back}

          <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#dfeadf]/90 via-[#edf3ea]/90 to-[#faf7f2]/90 px-7 py-7 ring-1 ring-[#d3e1d4] backdrop-blur-sm sm:px-9">
            <KitchenArt className="pointer-events-none absolute -bottom-5 right-8 hidden h-[150px] text-forest/[0.2] md:block" />
            <div className="relative max-w-2xl">
              <h1 className={`${display.className} text-[36px] font-extrabold leading-tight tracking-tight text-forest`}>
                {title}
              </h1>
              {subtitle && <p className="mt-1.5 text-[15px] text-forest/70">{subtitle}</p>}
              {actions && <div className="mt-5 flex flex-wrap items-center gap-2">{actions}</div>}
            </div>
          </div>

          <div className="mt-8">{children}</div>
        </main>
      </div>
    </div>
  );
}

// ─── İllüstrasyonlar ──────────────────────────────────────────

// Başlık bandı: buharı tüten tencere (buhar çizgileri ayrı ayrı canlanır), havuç, yaprak
function KitchenArt({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 260 150" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className} aria-hidden="true">
      <path className="steam steam-1" d="M92 40c-6-8 6-12 0-20" stroke="#b39459" />
      <path className="steam steam-2" d="M112 36c-6-8 6-12 0-20" stroke="#b39459" />
      <path className="steam steam-3" d="M132 40c-6-8 6-12 0-20" stroke="#b39459" />
      <path d="M70 58h84M104 50h16" />
      <path d="M74 58c0-6 18-10 38-10s38 4 38 10" />
      <path d="M76 66h72v46a14 14 0 0 1-14 14H90a14 14 0 0 1-14-14V66Z" />
      <path d="M76 76H62M148 76h14" />
      <path d="M190 128l30-58c4-7 14-4 12 4l-26 58c-4 7-19 4-16-4Z" />
      <path d="M200 112l8 4M208 96l7 4M216 82l6 3" />
      <path d="M228 66c-2-10 4-16 12-18M232 70c4-8 12-10 20-8M226 68c-8-6-8-14-4-20" />
      <path d="M20 128c4-28 22-44 50-46-2 28-20 44-50 46Z" />
      <path d="M22 126c12-14 24-24 40-34" />
    </svg>
  );
}

// Menü: rüzgârda hafifçe sallanan ot dalı (şampanya altını, çok silik)
function HerbArt({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 300 260" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" className={className} aria-hidden="true">
      <path d="M30 250C80 200 120 140 150 40" />
      <path d="M140 72c-30-6-48-24-52-50 28 4 46 22 52 50Z" />
      <path d="M150 64c26-14 50-14 70 0-22 16-46 16-70 0Z" />
      <path d="M118 128c-32 0-54-14-66-40 30-2 52 12 66 40Z" />
      <path d="M128 118c22-22 46-28 72-20-16 24-40 30-72 20Z" />
      <path d="M90 180c-30 6-56-2-74-24 28-8 54 0 74 24Z" />
      <path d="M100 168c16-26 38-38 66-36-12 28-34 40-66 36Z" />
    </svg>
  );
}