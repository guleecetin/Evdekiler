"use client";

import { useCallback, useEffect, useState } from "react";
import { ArrowRight, Check, CheckCircle2, Loader2, Sparkles, Users, X } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import { ApiError } from "@/lib/api";
import { mediaUrl } from "@/lib/recipes";
import { approveSuggestion, listSuggestions, rejectSuggestion, type Suggestion } from "@/lib/suggestions";
import { useAdmin } from "@/lib/useAdmin";

export default function SuggestionsPage() {
  const me = useAdmin();
  const [items, setItems] = useState<Suggestion[] | null>(null);
  const [done, setDone] = useState<string | null>(null);

  const load = useCallback(async () => {
    setItems(await listSuggestions());
  }, []);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  if (!me) return <main className="p-10 text-muted">Yükleniyor…</main>;

  function removeFromList(id: number, message: string) {
    setItems((list) => list?.filter((s) => s.id !== id) ?? null);
    setDone(message);
  }

  return (
    <AdminShell
      me={me}
      title="Öneriler"
      subtitle="Kullanıcıların fişte elle eşleştirdiği satırlar. Onaylananlar eşanlamlı olur ve herkesin fişinde otomatik tanınır."
    >
      {done && (
        <div className="mb-5 flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm font-semibold text-green-800">
          <CheckCircle2 className="h-4 w-4" /> {done}
        </div>
      )}

      {items === null && <p className="text-muted">Yükleniyor…</p>}

      {items?.length === 0 && (
        <div className="flex flex-col items-center gap-3 rounded-xl bg-white py-16 text-center ring-1 ring-line">
          <Sparkles className="h-10 w-10 text-neutral-300" strokeWidth={1.5} />
          <p className="font-semibold text-ink">Bekleyen öneri yok</p>
          <p className="max-w-sm text-sm text-muted">
            Kullanıcılar fişte tanınmayan bir satıra malzeme seçtiğinde burada görünecek.
          </p>
        </div>
      )}

      <div className="space-y-3">
        {items?.map((s) => (
          <SuggestionCard key={s.id} suggestion={s} onDone={removeFromList} />
        ))}
      </div>
    </AdminShell>
  );
}

function SuggestionCard({
  suggestion: s,
  onDone,
}: {
  suggestion: Suggestion;
  onDone: (id: number, message: string) => void;
}) {
  const [alias, setAlias] = useState(s.text);
  const [busy, setBusy] = useState<"approve" | "reject" | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function approve() {
    setError(null);
    setBusy("approve");
    try {
      const result = await approveSuggestion(s.id, alias);
      onDone(s.id, `"${result.alias}" artık ${s.ingredientName} olarak tanınacak.`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Onaylanamadı.");
      setBusy(null);
    }
  }

  async function reject() {
    setError(null);
    setBusy("reject");
    try {
      await rejectSuggestion(s.id);
      onDone(s.id, "Öneri reddedildi.");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Reddedilemedi.");
      setBusy(null);
    }
  }

  return (
    <div className="rounded-xl bg-white p-5 ring-1 ring-line">
      <div className="flex flex-wrap items-center gap-4">
        {/* Fişteki satır */}
        <div className="min-w-0 flex-1">
          <p className="text-xs font-semibold uppercase tracking-wide text-muted">Fişteki satır</p>
          <p className="mt-1 truncate rounded-md bg-cream px-2.5 py-1.5 font-mono text-sm">{s.sampleLine}</p>
        </div>

        <ArrowRight className="h-5 w-5 shrink-0 text-muted" />

        {/* Önerilen malzeme */}
        <div className="flex items-center gap-3">
          <Thumb url={s.ingredientImageUrl} emoji={s.ingredientEmoji} />
          <div className="leading-tight">
            <p className="font-bold text-forest">{s.ingredientName}</p>
            <p className="inline-flex items-center gap-1 text-xs text-muted">
              <Users className="h-3.5 w-3.5" />
              {s.count} kez önerildi
            </p>
          </div>
        </div>
      </div>

      {/* Eşanlamlı olarak kaydedilecek metin */}
      <div className="mt-4 flex flex-wrap items-end gap-3 border-t border-line pt-4">
        <div className="min-w-[220px] flex-1">
          <label className="mb-1.5 block text-xs font-semibold text-neutral-700">
            Eşanlamlı olarak kaydedilecek metin (gerekirse sadeleştir: marka ve gramajı sil)
          </label>
          <input
            value={alias}
            onChange={(e) => setAlias(e.target.value)}
            className="w-full rounded-lg border border-neutral-300 px-3 py-2 font-mono text-sm outline-none focus:border-basil focus:ring-1 focus:ring-basil"
          />
        </div>
        <button
          onClick={reject}
          disabled={busy !== null}
          className="inline-flex items-center gap-1.5 rounded-lg border border-neutral-300 px-4 py-2 text-sm font-semibold text-neutral-700 transition hover:border-red-300 hover:text-red-600 disabled:opacity-50"
        >
          {busy === "reject" ? <Loader2 className="h-4 w-4 animate-spin" /> : <X className="h-4 w-4" />}
          Reddet
        </button>
        <button
          onClick={approve}
          disabled={busy !== null || alias.trim().length < 3}
          className="inline-flex items-center gap-1.5 rounded-lg bg-basil px-4 py-2 text-sm font-semibold text-white transition hover:bg-basil-dark disabled:opacity-50"
        >
          {busy === "approve" ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
          Onayla
        </button>
      </div>

      {error && <p className="mt-2 text-sm font-medium text-red-700">{error}</p>}
    </div>
  );
}

function Thumb({ url, emoji }: { url: string; emoji: string }) {
  const [failed, setFailed] = useState(false);
  if (failed) {
    return <span className="flex h-12 w-12 items-center justify-center rounded-lg bg-cream text-2xl">{emoji}</span>;
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={mediaUrl(url)} alt="" onError={() => setFailed(true)} className="h-12 w-12 rounded-lg object-cover" />
  );
}