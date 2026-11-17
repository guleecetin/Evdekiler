"use client";

import { useCallback, useEffect, useState } from "react";
import { Info, Loader2, Search, SearchX, ShieldCheck, ShieldOff, UserRound } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import { ApiError } from "@/lib/api";
import { changeRole, listUsers, type AdminUser, type Role } from "@/lib/users";
import { useAdmin } from "@/lib/useAdmin";

const PAGE_SIZE = 20;

export default function UsersPage() {
  const me = useAdmin();
  const [items, setItems] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [adminCount, setAdminCount] = useState(0);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [role, setRole] = useState<Role | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

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
  }, [page, search, role]);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  if (!me) return <main className="p-10 text-muted">Yükleniyor…</main>;

  async function toggleRole(user: AdminUser) {
    const next: Role = user.role === "Admin" ? "User" : "Admin";
    const question =
      next === "Admin"
        ? `${user.displayName} yönetici yapılsın mı? Panele erişebilecek.`
        : `${user.displayName} kullanıcısının yöneticiliği alınsın mı? Oturumları kapatılacak.`;
    if (!window.confirm(question)) return;

    setBusyId(user.id);
    setMessage(null);
    try {
      await changeRole(user.id, next);
      setMessage({ ok: true, text: `${user.displayName} artık ${next === "Admin" ? "yönetici" : "kullanıcı"}.` });
      await load();
    } catch (err) {
      setMessage({ ok: false, text: err instanceof ApiError ? err.message : "Rol değiştirilemedi." });
    } finally {
      setBusyId(null);
    }
  }

  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const filters: { value: Role | null; label: string }[] = [
    { value: null, label: "Tümü" },
    { value: "Admin", label: "Yöneticiler" },
    { value: "User", label: "Kullanıcılar" },
  ];

  return (
    <AdminShell me={me} title="Kullanıcılar" subtitle={`${total} kullanıcı · ${adminCount} yönetici`}>
      <div className="mb-5 flex items-start gap-2.5 rounded-lg border border-line bg-white px-4 py-3 text-sm text-muted">
        <Info className="mt-0.5 h-4 w-4 shrink-0 text-basil" />
        <p>
          Rol değişikliği kullanıcının oturumlarını kapatır ve en geç 15 dakika içinde etkili olur. Kendi rolünüzü
          değiştiremezsiniz; sistemde her zaman en az bir yönetici kalır.
        </p>
      </div>

      {message && (
        <p
          className={`mb-5 rounded-lg border px-4 py-3 text-sm font-semibold ${
            message.ok ? "border-green-200 bg-green-50 text-green-800" : "border-red-200 bg-red-50 text-red-700"
          }`}
        >
          {message.text}
        </p>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <div className="relative w-full max-w-sm">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Ad ya da e-posta ara…"
            className="w-full rounded-lg border border-line bg-white py-2.5 pl-10 pr-4 text-sm outline-none transition focus:border-basil focus:ring-1 focus:ring-basil"
          />
        </div>
        <div className="flex rounded-lg border border-line bg-white p-1">
          {filters.map((f) => (
            <button
              key={f.label}
              onClick={() => {
                setRole(f.value);
                setPage(1);
              }}
              className={`rounded-md px-3 py-1.5 text-sm font-semibold transition ${
                role === f.value ? "bg-forest text-white" : "text-muted hover:text-ink"
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>
      </div>

      <div className="mt-6 overflow-hidden rounded-xl bg-white ring-1 ring-line">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-line bg-neutral-50 text-xs font-semibold uppercase tracking-wide text-muted">
            <tr>
              <th className="px-4 py-3">Kullanıcı</th>
              <th className="px-4 py-3">Rol</th>
              <th className="px-4 py-3">Kayıt tarihi</th>
              <th className="px-4 py-3 text-right">İşlem</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {items.map((u) => {
              const isMe = u.email === me.email;
              return (
                <tr key={u.id} className="transition hover:bg-cream">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[#e3ece4] text-sm font-bold text-forest">
                        {u.displayName.charAt(0).toUpperCase()}
                      </div>
                      <div className="leading-tight">
                        <p className="font-semibold text-forest">
                          {u.displayName}
                          {isMe && (
                            <span className="ml-2 rounded-full bg-neutral-100 px-2 py-0.5 text-[10px] font-bold uppercase text-muted">
                              Sen
                            </span>
                          )}
                        </p>
                        <p className="text-xs text-muted">{u.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    {u.role === "Admin" ? (
                      <span className="inline-flex items-center gap-1 rounded-md bg-forest px-2 py-1 text-xs font-semibold text-white">
                        <ShieldCheck className="h-3.5 w-3.5" /> Yönetici
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 rounded-md bg-neutral-100 px-2 py-1 text-xs font-semibold text-neutral-700">
                        <UserRound className="h-3.5 w-3.5" /> Kullanıcı
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-muted">{new Date(u.createdAt).toLocaleDateString("tr-TR")}</td>
                  <td className="px-4 py-3 text-right">
                    {isMe ? (
                      <span className="text-xs text-neutral-400">—</span>
                    ) : (
                      <button
                        onClick={() => toggleRole(u)}
                        disabled={busyId !== null}
                        className={`inline-flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-semibold transition disabled:opacity-50 ${
                          u.role === "Admin"
                            ? "border-neutral-300 text-neutral-700 hover:border-red-300 hover:text-red-600"
                            : "border-basil text-basil hover:bg-basil hover:text-white"
                        }`}
                      >
                        {busyId === u.id ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : u.role === "Admin" ? (
                          <ShieldOff className="h-3.5 w-3.5" />
                        ) : (
                          <ShieldCheck className="h-3.5 w-3.5" />
                        )}
                        {u.role === "Admin" ? "Yöneticiliği al" : "Yönetici yap"}
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {items.length === 0 && (
          <div className="flex flex-col items-center gap-2 py-14 text-center text-muted">
            <SearchX className="h-9 w-9 text-neutral-300" strokeWidth={1.5} />
            <p className="font-semibold text-ink">Kullanıcı bulunamadı</p>
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
    </AdminShell>
  );
}