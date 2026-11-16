"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { BookOpen, Carrot, LogOut, Users } from "lucide-react";
import { logout, type Me } from "@/lib/api";

type Props = {
  me: Me;
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  back?: React.ReactNode;
  children: React.ReactNode;
};

const NAV = [
  { href: "/", label: "Tarifler", icon: BookOpen, ready: true },
  { href: "/ingredients", label: "Malzemeler", icon: Carrot, ready: true },
  { href: "#", label: "Kullanıcılar", icon: Users, ready: false },
];

function isActive(href: string, pathname: string) {
  if (href === "/") return pathname === "/" || pathname.startsWith("/recipes");
  return pathname.startsWith(href);
}

export default function AdminShell({ me, title, subtitle, actions, back, children }: Props) {
  const router = useRouter();
  const pathname = usePathname();

  return (
    <div className="min-h-screen bg-cream">
      <aside className="fixed inset-y-0 left-0 hidden w-64 flex-col bg-forest text-white lg:flex">
        <div className="flex items-center gap-3 px-6 py-7">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/10 ring-1 ring-white/15">
            <Carrot className="h-5 w-5 text-tomato" strokeWidth={2} />
          </div>
          <div className="leading-tight">
            <p className="text-lg font-extrabold tracking-tight">Evdekiler</p>
            <p className="text-xs text-white/55">Yönetim paneli</p>
          </div>
        </div>

        <p className="px-6 pb-2 text-[11px] font-bold uppercase tracking-widest text-white/40">Menü</p>
        <nav className="flex-1 space-y-1 px-3">
          {NAV.map((item) => {
            const Icon = item.icon;
            if (!item.ready) {
              return (
                <span
                  key={item.label}
                  className="flex cursor-not-allowed items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold text-white/35"
                >
                  <Icon className="h-[18px] w-[18px]" strokeWidth={1.75} />
                  {item.label}
                  <span className="ml-auto rounded-full bg-white/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-white/50">
                    Yakında
                  </span>
                </span>
              );
            }

            const active = isActive(item.href, pathname);
            return (
              <Link
                key={item.label}
                href={item.href}
                className={`flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition ${
                  active ? "bg-white/12 text-white shadow-inner" : "text-white/70 hover:bg-white/5 hover:text-white"
                }`}
              >
                <Icon className="h-[18px] w-[18px]" strokeWidth={1.75} />
                {item.label}
                {active && <span className="ml-auto h-1.5 w-1.5 rounded-full bg-tomato" />}
              </Link>
            );
          })}
        </nav>

        <div className="m-3 rounded-xl bg-white/5 p-3 ring-1 ring-white/10">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-tomato text-sm font-bold text-white">
              {me.displayName.charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1 leading-tight">
              <p className="truncate text-sm font-semibold">{me.displayName}</p>
              <p className="truncate text-xs text-white/55">{me.email}</p>
            </div>
            <button
              onClick={async () => {
                await logout();
                router.replace("/login");
              }}
              title="Çıkış yap"
              className="rounded-lg p-2 text-white/60 transition hover:bg-white/10 hover:text-white"
            >
              <LogOut className="h-[18px] w-[18px]" strokeWidth={1.75} />
            </button>
          </div>
        </div>
      </aside>

      <div className="lg:pl-64">
        <main className="mx-auto max-w-6xl px-6 py-8 lg:px-10">
          {back}
          <header className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <h1 className="text-3xl font-extrabold tracking-tight text-forest">{title}</h1>
              {subtitle && <p className="mt-1 text-sm text-muted">{subtitle}</p>}
            </div>
            {actions}
          </header>
          <div className="mt-8">{children}</div>
        </main>
      </div>
    </div>
  );
}