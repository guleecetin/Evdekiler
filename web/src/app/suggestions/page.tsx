"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ArrowRight,
  Check,
  CheckCircle2,
  Clock,
  Loader2,
  Receipt,
  Sparkles,
  TrendingUp,
  Users,
  X,
  XCircle,
} from "lucide-react";
import AdminShell from "@/components/AdminShell";
import PageLoader from "@/components/PageLoader";
import { ApiError } from "@/lib/api";
import { mediaUrl } from "@/lib/recipes";
import { approveSuggestion, listSuggestions, rejectSuggestion, type Suggestion } from "@/lib/suggestions";
import { useAdmin } from "@/lib/useAdmin";

type Toast = { ok: boolean; text: string };

const relative = new Intl.RelativeTimeFormat("tr", { numeric: "auto" });

function timeAgo(iso: string) {
  const minutes = Math.round((new Date(iso).getTime() - Date.now()) / 60_000);
  if (minutes > -1) return "az önce";
  if (minutes > -60) return relative.format(minutes, "minute");
  if (minutes > -1440) return relative.format(Math.round(minutes / 60), "hour");
  return relative.format(Math.round(minutes / 1440), "day");
}

export default function SuggestionsPage() {
  const me = useAdmin();
  const [items, setItems] = useState<Suggestion[] | null>(null);
  const [toast, setToast] = useState<Toast | null>(null);

  const load = useCallback(async () => {
    setItems(await listSuggestions());
  }, []);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3500);
    return () => clearTimeout(timer);
  }, [toast]);

  const stats = useMemo(() => {
    const list = items ?? [];
    const corrections = list.reduce((sum, s) => sum + s.count, 0);
    const top = list.reduce<Suggestion | null>((best, s) => (!best || s.count > best.count ? s : best), null);
    const maxCount = Math.max(1, ...list.map((s) => s.count));
    return { corrections, top, maxCount };
  }, [items]);

  if (!me) return <PageLoader />;

  function finish(id: number, t: Toast) {
    if (t.ok) setItems((list) => list?.filter((s) => s.id !== id) ?? null);
    setToast(t);
  }

  return (
    <AdminShell
      me={me}
      title="Öneriler"
      subtitle="Kullanıcıların fişte elle eşleştirdiği satırlar. Onayladıkların herkesin fişinde otomatik tanınır."
    >
      {/* İstatistikler */}
      <div className="grid gap-4 sm:grid-cols-3">
        <StatCard icon={Sparkles} tone="tomato" value={String(items?.length ?? 0)} label="Bekleyen öneri" />
        <StatCard icon={Users} tone="forest" value={String(stats.corrections)} label="Kullanıcı düzeltmesi" />
        <StatCard
          icon={TrendingUp}
          tone="sky"
          value={stats.top ? `${stats.top.count}×` : "—"}
          label={stats.top ? `En güçlü: ${stats.top.ingredientName}` : "En güçlü öneri"}
        />
      </div>

      {/* Nasıl çalışır */}
      <div className="mt-6 flex flex-wrap items-center gap-x-3 gap-y-2 rounded-2xl bg-white px-5 py-4 text-sm text-muted shadow-sm ring-1 ring-line">
        <Step n={1} text="Kullanıcı tanınmayan satıra ürün seçer" />
        <ArrowRight className="h-4 w-4 text-neutral-300" />
        <Step n={2} text="Öneri burada birikir" />
        <ArrowRight className="h-4 w-4 text-neutral-300" />
        <Step n={3} text="Sen sadeleştirip onaylarsın" />
        <ArrowRight className="h-4 w-4 text-neutral-300" />
        <Step n={4} text="Herkesin fişinde tanınır" />
      </div>

      {/* Liste */}
      <div className="mt-6 space-y-4">
        {items === null &&
          Array.from({ length: 2 }).map((_, i) => (
            <div key={i} className="h-48 animate-pulse rounded-2xl bg-white shadow-sm ring-1 ring-line" />
          ))}

        {items?.length === 0 && (
          <div className="flex flex-col items-center gap-3 rounded-2xl bg-white px-6 py-20 text-center shadow-sm ring-1 ring-line">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#e3ece4]">
              <CheckCircle2 className="h-8 w-8 text-forest" strokeWidth={1.75} />
            </div>
            <p className="text-lg font-bold text-forest">Her şey güncel</p>
            <p className="max-w-sm text-sm text-muted">
              Bekleyen öneri yok. Kullanıcılar fişte tanınmayan bir satıra ürün seçtiğinde burada görünecek.
            </p>
          </div>
        )}

        {items?.map((s) => (
          <SuggestionCard key={s.id} suggestion={s} maxCount={stats.maxCount} onDone={finish} />
        ))}
      </div>

      {toast && <ToastMessage toast={toast} onClose={() => setToast(null)} />}
    </AdminShell>
  );
}

// ─── Öneri kartı ────────────────────────────────────────────

function SuggestionCard({
  suggestion: s,
  maxCount,
  onDone,
}: {
  suggestion: Suggestion;
  maxCount: number;
  onDone: (id: number, toast: Toast) => void;
}) {
  // Önerinin kelimeleri: tıklayarak eşanlamlıya dahil et / çıkar
  const words = useMemo(() => s.text.split(" ").filter(Boolean), [s.text]);
  const [kept, setKept] = useState<boolean[]>(() => words.map(() => true));
  const [busy, setBusy] = useState<"approve" | "reject" | null>(null);

  const alias = words.filter((_, i) => kept[i]).join(" ");
  const tooShort = alias.replace(/\s/g, "").length < 3;

  function toggle(i: number) {
    setKept((list) => list.map((k, j) => (j === i ? !k : k)));
  }

  async function approve() {
    setBusy("approve");
    try {
      const result = await approveSuggestion(s.id, alias);
      onDone(s.id, { ok: true, text: `"${result.alias}" artık ${s.ingredientName} olarak tanınacak.` });
    } catch (err) {
      onDone(s.id, { ok: false, text: err instanceof ApiError ? err.message : "Onaylanamadı." });
      setBusy(null);
    }
  }

  async function reject() {
    setBusy("reject");
    try {
      await rejectSuggestion(s.id);
      onDone(s.id, { ok: true, text: "Öneri reddedildi." });
    } catch (err) {
      onDone(s.id, { ok: false, text: err instanceof ApiError ? err.message : "Reddedilemedi." });
      setBusy(null);
    }
  }

  const strength = Math.round((s.count / maxCount) * 100);

  return (
    <div className="overflow-hidden rounded-2xl bg-white shadow-sm ring-1 ring-line">
      {/* Üst: fiş satırı → malzeme */}
      <div className="grid items-center gap-5 p-5 md:grid-cols-[1fr_auto_260px]">
        {/* Fiş satırı, fiş kâğıdı gibi */}
        <div>
          <p className="mb-1.5 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-muted">
            <Receipt className="h-3.5 w-3.5" /> Fişteki satır
          </p>
          <div className="relative rounded-md border border-dashed border-neutral-300 bg-[#fffdf7] px-4 py-3 font-mono text-sm text-neutral-800 shadow-[inset_0_1px_0_rgba(0,0,0,0.03)]">
            {s.sampleLine}
          </div>
        </div>

        <div className="flex justify-center max-md:rotate-90">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[#e3ece4]">
            <ArrowRight className="h-4 w-4 text-forest" />
          </div>
        </div>

        {/* Önerilen malzeme */}
        <div className="flex items-center gap-3 rounded-xl bg-neutral-50 p-3 ring-1 ring-line">
          <Thumb url={s.ingredientImageUrl} emoji={s.ingredientEmoji} />
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate font-bold text-forest">{s.ingredientName}</p>
            <p className="mt-1 flex items-center gap-1 text-xs text-muted">
              <Users className="h-3 w-3" /> {s.count} kişi önerdi
            </p>
            {/* Güven çubuğu */}
            <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-neutral-200">
              <div className="h-full rounded-full bg-basil transition-all" style={{ width: `${strength}%` }} />
            </div>
          </div>
        </div>
      </div>

      {/* Alt: sadeleştirme ve karar */}
      <div className="border-t border-line bg-neutral-50/60 px-5 py-4">
        <p className="text-xs font-semibold text-neutral-700">
          Eşanlamlıya girecek kelimeler{" "}
          <span className="font-normal text-muted">· marka ve gramajı çıkarmak için dokun</span>
        </p>

        <div className="mt-2 flex flex-wrap gap-2">
          {words.map((w, i) => (
            <button
              key={`${w}-${i}`}
              onClick={() => toggle(i)}
              disabled={busy !== null}
              className={`rounded-full px-3 py-1 font-mono text-xs font-semibold transition ${
                kept[i]
                  ? "bg-forest text-white shadow-sm"
                  : "bg-white text-neutral-400 line-through ring-1 ring-neutral-200 hover:text-neutral-600"
              }`}
            >
              {w}
            </button>
          ))}
        </div>

        <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
          <p className="text-sm text-muted">
            {tooShort ? (
              <span className="text-red-600">En az 3 harf seçili olmalı.</span>
            ) : (
              <>
                Fişte <span className="rounded bg-white px-1.5 py-0.5 font-mono font-semibold text-forest ring-1 ring-line">{alias}</span>{" "}
                geçen satırlar <span className="font-semibold text-forest">{s.ingredientName}</span> olarak tanınacak
              </>
            )}
          </p>

          <div className="flex items-center gap-2">
            <span className="mr-1 hidden items-center gap-1 text-xs text-neutral-400 sm:flex">
              <Clock className="h-3 w-3" /> {timeAgo(s.lastSeenAt)}
            </span>
            <button
              onClick={reject}
              disabled={busy !== null}
              className="inline-flex items-center gap-1.5 rounded-lg px-3.5 py-2 text-sm font-semibold text-neutral-600 ring-1 ring-neutral-200 transition hover:bg-red-50 hover:text-red-600 hover:ring-red-200 disabled:opacity-50"
            >
              {busy === "reject" ? <Loader2 className="h-4 w-4 animate-spin" /> : <X className="h-4 w-4" />}
              Reddet
            </button>
            <button
              onClick={approve}
              disabled={busy !== null || tooShort}
              className="inline-flex items-center gap-1.5 rounded-lg bg-basil px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-basil-dark disabled:opacity-50"
            >
              {busy === "approve" ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
              Onayla
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Küçük parçalar ─────────────────────────────────────────

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
  value: string;
  tone: keyof typeof TONES;
}) {
  return (
    <div className="flex items-center gap-4 rounded-2xl bg-white p-5 shadow-sm ring-1 ring-line">
      <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ${TONES[tone]}`}>
        <Icon className="h-6 w-6" strokeWidth={1.75} />
      </div>
      <div className="min-w-0">
        <p className="text-3xl font-extrabold tracking-tight text-forest">{value}</p>
        <p className="truncate text-sm text-muted">{label}</p>
      </div>
    </div>
  );
}

function Step({ n, text }: { n: number; text: string }) {
  return (
    <span className="inline-flex items-center gap-2">
      <span className="flex h-5 w-5 items-center justify-center rounded-full bg-forest text-[11px] font-bold text-white">{n}</span>
      {text}
    </span>
  );
}

function Thumb({ url, emoji }: { url: string; emoji: string }) {
  const [failed, setFailed] = useState(false);
  if (failed) {
    return <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-cream text-2xl">{emoji}</span>;
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={mediaUrl(url)} alt="" onError={() => setFailed(true)} className="h-14 w-14 shrink-0 rounded-xl object-cover" />
  );
}

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