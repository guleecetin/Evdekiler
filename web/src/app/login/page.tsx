"use client";

import { useState, type SyntheticEvent } from "react";
import { useRouter } from "next/navigation";
import { ApiError, login } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: SyntheticEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(email, password);
      router.replace("/");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Sunucuya ulaşılamadı.");
    } finally {
      setLoading(false);
    }
  }

  const inputClass =
    "w-full rounded-xl border border-neutral-300 px-4 py-3.5 outline-none transition focus:border-ink focus:ring-1 focus:ring-ink";

  return (
    <main className="flex min-h-screen items-center justify-center bg-cream px-4">
      <div className="w-full max-w-md rounded-3xl bg-white p-10 shadow-[0_8px_40px_rgba(0,0,0,0.08)]">
        <div className="mb-8 flex items-center gap-3">
          <div className="flex h-12 w-12 -rotate-6 items-center justify-center rounded-2xl bg-basil text-2xl">
            🥕
          </div>
          <div>
            <p className="text-xl font-extrabold tracking-tight text-basil">Evdekiler</p>
            <p className="text-sm text-muted">Yönetim paneli</p>
          </div>
        </div>

        <h1 className="text-2xl font-extrabold tracking-tight">Tekrar hoş geldin</h1>
        <p className="mt-1 text-muted">Devam etmek için yönetici hesabınla giriş yap.</p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-4">
          <input
            type="email"
            required
            placeholder="E-posta"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className={inputClass}
          />
          <input
            type="password"
            required
            placeholder="Şifre"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className={inputClass}
          />

          {error && (
            <p className="rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-basil py-3.5 font-bold text-white transition hover:bg-basil-dark disabled:opacity-60"
          >
            {loading ? "Giriş yapılıyor…" : "Giriş yap"}
          </button>
        </form>
      </div>
    </main>
  );
}