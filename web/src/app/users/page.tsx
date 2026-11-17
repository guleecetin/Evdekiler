"use client";

import { useCallback, useEffect, useState } from "react";
import {
  CheckCircle2,
  Clock,
  Loader2,
  LogOut,
  Search,
  SearchX,
  ShieldCheck,
  ShieldOff,
  UserRound,
  Users,
  X,
  XCircle,
} from "lucide-react";
import AdminShell from "@/components/AdminShell";
import PageLoader from "@/components/PageLoader";
import { ApiError } from "@/lib/api";
import { changeRole, listUsers, type AdminUser, type Role } from "@/lib/users";
import { useAdmin } from "@/lib/useAdmin";

const PAGE_SIZE = 20;

// Her kişiye adından türetilen sabit bir renk
const AVATAR_COLORS = [
  "bg-[#e3ece4] text-[#1d3a2a]",
  "bg-[#fde8e1] text-[#9a3412]",
  "bg-[#e0ecf8] text-[#1e40af]",
  "bg-[#f3e8fd] text-[#6b21a8]",
  "bg-[#fef3c7] text-[#92400e]",
  "bg-[#dcf5f0] text-[#115e59]",
];

function avatarColor(seed: string) {
  let hash = 0;
  for (const ch of seed) hash = (hash * 31 + ch.charCodeAt(0)) >>> 0;
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts.length > 1 ? parts[parts.length - 1][0] : "")).toLocaleUpperCase("tr-TR");
}

const relative = new Intl.RelativeTimeFormat("tr", { numeric: "auto" });

function timeAgo(iso: string) {
  const days = Math.round((new Date(iso).getTime() - Date.now()) / 86_400_000);
  if (days > -1) return "bugün";
  if (days > -30) return relative.format(days, "day");
  if (days > -365) return relative.format(Math.round(days / 30), "month");
  return relative.format(Math.round(days / 365), "year");
}

type Toast = { ok: boolean; text: string };

export default function UsersPage() {
  const me = useAdmin();
  const [items, setItems] = useState<AdminUser[] | null>(null);
  const [total, setTotal] = useState(0);
  const [allTotal, setAllTotal] = useState(0);
  const [adminCount, setAdminCount] = useState(0);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [role, setRole] = useState<Role | null>(null);
  const [confirming, setConfirming] = useState<AdminUser | null>(null);
  const [toast, setToast] = useState<Toast | null>(null);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSearch(searchInput.trim());
      setPage(1);
    }, 250);
    return () => clearTimeout(timer);
  }, [searchInput]);

  const load = useCallback(async () => {
    const result = await listUsers(page, PAGE_SIZE, search, role);
    setItems(result.items);
    setTotal(result.totalCount);
    setAdminCount(result.adminCount);
    // Filtre yokken gelen toplam, istatistik kartındaki gerçek toplamdır
    if (!search && !role) setAllTotal(result.totalCount);
  }, [page, search, role]);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  // Bildirim 3 saniye sonra kaybolsun
  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3000);
    return () => clearTimeout(timer);
  }, [toast]);

  if (!me) return <PageLoader />;

  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const filters: { value: Role | null; label: string }[] = [
    { value: null, label: "Tümü" },
    { value: "Admin", label: "Yöneticiler" },
    { value: "User", label: "Kullanıcılar" },
  ];

  return (
    <AdminShell me={me} title="Kullanıcılar" subtitle="Uygulamaya kayıtlı kişiler ve panel yetkileri">
      {/* İstatistik kartları */}
      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard icon={Users} label="Toplam kullanıcı" value={allTotal} tone="forest" />
        <StatCard icon={ShieldCheck} label="Yönetici" value={adminCount} tone="tomato" />
        <StatCard icon={UserRound} label="Uygulama kullanıcısı" value={Math.max(0, allTotal - adminCount)} tone="sky" />
      </div>

      {/* Arama ve filtre */}
      <div className="mt-8 flex flex-wrap items-center justify-between gap-3">
        <div className="relative w-full max-w-sm">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Ad ya da e-posta ara…"
            className="w-full rounded-xl border border-line bg-white py-2.5 pl-10 pr-4 text-sm shadow-sm outline-none transition focus:border-basil focus:ring-2 focus:ring-basil/20"
          />
        </div>
        <div className="flex rounded-xl border border-line bg-white p-1 shadow-sm">
          {filters.map((f) => (
            <button
              key={f.label}
              onClick={() => {
                setRole(f.value);
                setPage(1);
              }}
              className={`rounded-lg px-3.5 py-1.5 text-sm font-semibold transition ${
                role === f.value ? "bg-forest text-white shadow" : "text-muted hover:text-ink"
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      {/* Liste */}
      <div className="mt-5 overflow-hidden rounded-2xl bg-white shadow-sm ring-1 ring-line">
        <div className="grid grid-cols-[1fr_140px_180px_170px] gap-4 border-b border-line bg-neutral-50/70 px-5 py-3 text-xs font-semibold uppercase tracking-wide text-muted max-md:hidden">
          <span>Kullanıcı</span>
          <span>Rol</span>
          <span>Katılım</span>
          <span className="text-right">Yetki</span>
        </div>

        {items === null &&
          Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="flex items-center gap-4 border-b border-line px-5 py-4 last:border-0">
              <div className="h-11 w-11 animate-pulse rounded-full bg-neutral-100" />
              <div className="flex-1 space-y-2">
                <div className="h-3 w-40 animate-pulse rounded bg-neutral-100" />
                <div className="h-3 w-56 animate-pulse rounded bg-neutral-100" />
              </div>
            </div>
          ))}

        {items?.map((u) => {
          const isMe = u.email === me.email;
          const isAdmin = u.role === "Admin";
          return (
            <div
              key={u.id}
              className={`grid grid-cols-[1fr_140px_180px_170px] items-center gap-4 border-b border-line px-5 py-4 transition last:border-0 max-md:grid-cols-1 ${
                isMe ? "bg-cream/60" : "hover:bg-cream/40"
              }`}
            >
              {/* Kişi */}
              <div className="flex min-w-0 items-center gap-3.5">
                <div className="relative">
                  <div
                    className={`flex h-11 w-11 items-center justify-center rounded-full text-sm font-bold ${avatarColor(u.email)}`}
                  >
                    {initials(u.displayName)}
                  </div>
                  {isAdmin && (
                    <span className="absolute -bottom-0.5 -right-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-forest ring-2 ring-white">
                      <ShieldCheck className="h-3 w-3 text-white" />
                    </span>
                  )}
                </div>
                <div className="min-w-0 leading-tight">
                  <p className="flex items-center gap-2 truncate font-semibold text-forest">
                    {u.displayName}
                    {isMe && (
                      <span className="rounded-full bg-tomato/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-tomato">
                        Sen
                      </span>
                    )}
                  </p>
                  <p className="mt-0.5 truncate text-sm text-muted">{u.email}</p>
                </div>
              </div>

              {/* Rol */}
              <div>
                {isAdmin ? (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-forest/10 px-2.5 py-1 text-xs font-bold text-forest">
                    <span className="h-1.5 w-1.5 rounded-full bg-forest" /> Yönetici
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 rounded-full bg-neutral-100 px-2.5 py-1 text-xs font-bold text-neutral-600">
                    <span className="h-1.5 w-1.5 rounded-full bg-neutral-400" /> Kullanıcı
                  </span>
                )}
              </div>

              {/* Katılım */}
              <div className="leading-tight">
                <p className="text-sm font-medium text-ink">{new Date(u.createdAt).toLocaleDateString("tr-TR", { day: "numeric", month: "long", year: "numeric" })}</p>
                <p className="mt-0.5 flex items-center gap-1 text-xs text-muted">
                  <Clock className="h-3 w-3" /> {timeAgo(u.createdAt)}
                </p>
              </div>

              {/* İşlem */}
              <div className="flex justify-end">
                {isMe ? (
                  <span className="text-xs text-neutral-400">Kendi rolünü değiştiremezsin</span>
                ) : (
                  <button
                    onClick={() => setConfirming(u)}
                    className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-xs font-semibold transition ${
                      isAdmin
                        ? "text-neutral-600 ring-1 ring-neutral-200 hover:bg-red-50 hover:text-red-600 hover:ring-red-200"
                        : "bg-basil text-white shadow-sm hover:bg-basil-dark"
                    }`}
                  >
                    {isAdmin ? <ShieldOff className="h-3.5 w-3.5" /> : <ShieldCheck className="h-3.5 w-3.5" />}
                    {isAdmin ? "Yöneticiliği al" : "Yönetici yap"}
                  </button>
                )}
              </div>
            </div>
          );
        })}

        {items?.length === 0 && (
          <div className="flex flex-col items-center gap-2 py-16 text-center text-muted">
            <SearchX className="h-10 w-10 text-neutral-300" strokeWidth={1.5} />
            <p className="font-semibold text-ink">Kullanıcı bulunamadı</p>
            <p className="text-sm">Aramayı ya da filtreyi değiştirmeyi dene.</p>
          </div>
        )}
      </div>

      {pageCount > 1 && (
        <div className="mt-6 flex items-center justify-between">
          <p className="text-sm text-muted">
            Sayfa {page} / {pageCount}
          </p>
          <div className="flex gap-2">
            <button
              disabled={page <= 1}
              onClick={() => setPage(page - 1)}
              className="rounded-lg border border-line bg-white px-4 py-2 text-sm font-semibold transition hover:border-basil hover:text-basil disabled:opacity-40"
            >
              Önceki
            </button>
            <button
              disabled={page >= pageCount}
              onClick={() => setPage(page + 1)}
              className="rounded-lg border border-line bg-white px-4 py-2 text-sm font-semibold transition hover:border-basil hover:text-basil disabled:opacity-40"
            >
              Sonraki
            </button>
          </div>
        </div>
      )}

      {confirming && (
        <ConfirmRoleDialog
          user={confirming}
          onClose={() => setConfirming(null)}
          onDone={async (t) => {
            setConfirming(null);
            setToast(t);
            if (t.ok) await load();
          }}
        />
      )}

      {toast && <ToastMessage toast={toast} onClose={() => setToast(null)} />}
    </AdminShell>
  );
}

// ─── İstatistik kartı ───────────────────────────────────────

const TONES = {
  forest: "bg-forest/10 text-forest",
  tomato: "bg-tomato/10 text-tomato",
  sky: "bg-[#e0ecf8] text-[#1e40af]",
};

function StatCard({
  icon: Icon,
  label,
  value,
  tone,
}: {
  icon: typeof Users;
  label: string;
  value: number;
  tone: keyof typeof TONES;
}) {
  return (
    <div className="flex items-center gap-4 rounded-2xl bg-white p-5 shadow-sm ring-1 ring-line">
      <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${TONES[tone]}`}>
        <Icon className="h-6 w-6" strokeWidth={1.75} />
      </div>
      <div>
        <p className="text-3xl font-extrabold tracking-tight text-forest">{value}</p>
        <p className="text-sm text-muted">{label}</p>
      </div>
    </div>
  );
}

// ─── Rol değiştirme onayı ───────────────────────────────────

function ConfirmRoleDialog({
  user,
  onClose,
  onDone,
}: {
  user: AdminUser;
  onClose: () => void;
  onDone: (toast: Toast) => void;
}) {
  const [busy, setBusy] = useState(false);
  const promote = user.role !== "Admin";
  const next: Role = promote ? "Admin" : "User";

  async function confirm() {
    setBusy(true);
    try {
      await changeRole(user.id, next);
      onDone({ ok: true, text: `${user.displayName} artık ${promote ? "yönetici" : "kullanıcı"}.` });
    } catch (err) {
      onDone({ ok: false, text: err instanceof ApiError ? err.message : "Rol değiştirilemedi." });
    }
  }

  const effects = promote
    ? ["Yönetim paneline giriş yapabilir", "Tarif, malzeme ve kullanıcıları yönetebilir", "Mevcut oturumları kapatılır, yeniden giriş yapar"]
    : ["Yönetim paneline erişimi kalkar", "Mobil uygulamayı kullanmaya devam eder", "Oturumları kapatılır; en geç 15 dakikada etkili olur"];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-forest/40 p-4 backdrop-blur-sm" onClick={busy ? undefined : onClose}>
      <div onClick={(e) => e.stopPropagation()} className="w-full max-w-md overflow-hidden rounded-2xl bg-white shadow-2xl">
        <div className={`flex items-start justify-between p-6 pb-4 ${promote ? "bg-[#e3ece4]/60" : "bg-red-50/70"}`}>
          <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${promote ? "bg-forest text-white" : "bg-red-100 text-red-600"}`}>
            {promote ? <ShieldCheck className="h-6 w-6" /> : <ShieldOff className="h-6 w-6" />}
          </div>
          <button onClick={onClose} disabled={busy} className="rounded-lg p-1.5 text-muted hover:bg-white/70">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="px-6 pb-6">
          <h2 className="text-lg font-extrabold text-forest">
            {promote ? "Yönetici yapılsın mı?" : "Yöneticilik alınsın mı?"}
          </h2>

          <div className="mt-4 flex items-center gap-3 rounded-xl bg-neutral-50 p-3 ring-1 ring-line">
            <div className={`flex h-10 w-10 items-center justify-center rounded-full text-sm font-bold ${avatarColor(user.email)}`}>
              {initials(user.displayName)}
            </div>
            <div className="min-w-0 leading-tight">
              <p className="truncate font-semibold text-forest">{user.displayName}</p>
              <p className="truncate text-sm text-muted">{user.email}</p>
            </div>
          </div>

          <ul className="mt-4 space-y-2">
            {effects.map((e, i) => (
              <li key={e} className="flex items-start gap-2 text-sm text-neutral-700">
                {i === effects.length - 1 ? (
                  <LogOut className="mt-0.5 h-4 w-4 shrink-0 text-muted" />
                ) : promote ? (
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-basil" />
                ) : (
                  <XCircle className="mt-0.5 h-4 w-4 shrink-0 text-red-500" />
                )}
                {e}
              </li>
            ))}
          </ul>

          <div className="mt-6 flex justify-end gap-2">
            <button onClick={onClose} disabled={busy} className="rounded-lg px-4 py-2.5 text-sm font-semibold text-muted hover:bg-neutral-100">
              Vazgeç
            </button>
            <button
              onClick={confirm}
              disabled={busy}
              className={`inline-flex items-center gap-2 rounded-lg px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition disabled:opacity-60 ${
                promote ? "bg-basil hover:bg-basil-dark" : "bg-red-600 hover:bg-red-700"
              }`}
            >
              {busy && <Loader2 className="h-4 w-4 animate-spin" />}
              {promote ? "Yönetici yap" : "Yöneticiliği al"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Bildirim ───────────────────────────────────────────────

function ToastMessage({ toast, onClose }: { toast: Toast; onClose: () => void }) {
  return (
    <div className="fixed right-6 top-6 z-[60] flex max-w-sm items-start gap-3 rounded-xl bg-white p-4 shadow-2xl ring-1 ring-line">
      {toast.ok ? (
        <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-basil" />
      ) : (
        <XCircle className="mt-0.5 h-5 w-5 shrink-0 text-red-500" />
      )}
      <p className="text-sm font-medium text-ink">{toast.text}</p>
      <button onClick={onClose} className="ml-2 rounded p-0.5 text-muted hover:bg-neutral-100">
        <X className="h-4 w-4" />
      </button>
    </div>
  );
}