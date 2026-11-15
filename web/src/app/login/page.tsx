"use client";

import { useState, type SyntheticEvent } from "react";
import { useRouter } from "next/navigation";
import { Carrot, Loader2 } from "lucide-react";
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
    "w-full rounded-lg border border-neutral-300 bg-white px-3.5 py-2.5 text-sm outline-none transition focus:border-ink focus:ring-1 focus:ring-ink";

  return (
    <main className="flex min-h-screen items-center justify-center bg-neutral-50 px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-basil">
            <Carrot className="h-6 w-6 text-white" strokeWidth={2} />
          </div>
          <h1 className="mt-4 text-xl font-extrabold tracking-tight">Evdekiler Yönetim</h1>
          <p className="mt-1 text-sm text-muted">Devam etmek için yönetici hesabınızla giriş yapın.</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 rounded-xl border border-line bg-white p-6">
          <div>
            <label className="mb-1.5 block text-sm font-semibold text-neutral-700">E-posta</label>
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className={inputClass}
            />
          </div>
          <div>
            <label className="mb-1.5 block text-sm font-semibold text-neutral-700">Şifre</label>
            <input
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className={inputClass}
            />
          </div>

          {error && (
            <p className="rounded-lg border border-red-200 bg-red-50 px-3.5 py-2.5 text-sm font-medium text-red-700">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="inline-flex w-full items-center justify-center gap-2 rounded-lg bg-ink py-2.5 text-sm font-semibold text-white transition hover:bg-neutral-800 disabled:opacity-60"
          >
            {loading && <Loader2 className="h-4 w-4 animate-spin" />}
            {loading ? "Giriş yapılıyor…" : "Giriş yap"}
          </button>
        </form>
      </div>
    </main>
  );
}