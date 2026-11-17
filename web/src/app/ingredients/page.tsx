"use client";

import { Suspense, useCallback, useEffect, useRef, useState, type SyntheticEvent } from "react";
import {
  Apple,
  Beef,
  Bean,
  Camera,
  Carrot,
  CheckCircle2,
  Egg,
  ImageOff,
  Loader2,
  Package,
  Pencil,
  Plus,
  Search,
  SearchX,
  Tags,
  Upload,
  Wheat,
  X,
  XCircle,
  type LucideIcon,
} from "lucide-react";
import AdminShell from "@/components/AdminShell";
import PageLoader from "@/components/PageLoader";
import { ApiError } from "@/lib/api";
import {
  INGREDIENT_CATEGORIES,
  MEASURE_UNITS,
  addAlias,
  createIngredient,
  deleteAlias,
  ingredientCategoryLabel,
  listAliases,
  listIngredients,
  removeIngredientImage,
  unitLabel,
  updateIngredient,
  uploadIngredientImage,
  type AdminIngredient,
  type AliasItem,
  type IngredientCategory,
  type IngredientInput,
} from "@/lib/ingredients";
import { mediaUrl } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";
import { useListQuery } from "@/lib/useListQuery";

const PAGE_SIZE = 24;
const EMPTY: IngredientInput = { name: "", emoji: "🛒", category: "Vegetable", defaultUnit: "Piece" };
const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

const CATEGORY_ICONS: Record<IngredientCategory, LucideIcon> = {
  Vegetable: Carrot,
  Fruit: Apple,
  Dairy: Egg,
  Meat: Beef,
  Grain: Wheat,
  Legume: Bean,
  Spice: Package,
  Other: Package,
};

type Toast = { ok: boolean; text: string };

// useSearchParams kullanan bileşen Suspense içinde olmalı (Next.js kuralı)
export default function IngredientsPage() {
  return (
    <Suspense fallback={<PageLoader />}>
      <IngredientList />
    </Suspense>
  );
}

function IngredientList() {
  const me = useAdmin();
  const { page, search, category, update } = useListQuery();

  const [items, setItems] = useState<AdminIngredient[]>([]);
  const [total, setTotal] = useState(0);
  const [searchInput, setSearchInput] = useState(search);
  const [editing, setEditing] = useState<AdminIngredient | "new" | null>(null);
  const [toast, setToast] = useState<Toast | null>(null);

  // Yazmayı bırakınca adresteki aramayı güncelle (sadece gerçekten değiştiyse 1. sayfaya dön)
  useEffect(() => {
    const value = searchInput.trim();
    if (value === search) return;
    const timer = setTimeout(() => update({ q: value, page: null }), 250);
    return () => clearTimeout(timer);
  }, [searchInput, search, update]);

  const load = useCallback(async () => {
    const result = await listIngredients(page, PAGE_SIZE, search, category);
    setItems(result.items);
    setTotal(result.totalCount);
  }, [page, search, category]);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3500);
    return () => clearTimeout(timer);
  }, [toast]);

  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));

  // Adresteki sayfa artık yoksa (ör. elle ?page=99 yazıldı) son sayfaya geç
  useEffect(() => {
    if (total > 0 && page > pageCount) update({ page: pageCount });
  }, [total, page, pageCount, update]);

  if (!me) return <PageLoader />;

  return (
    <AdminShell
      me={me}
      title="Malzemeler"
      subtitle={`Katalogda ${total} malzeme var. Fiş eşleştirme ve tarifler bu listeyi kullanır.`}
      actions={
        <button
          onClick={() => setEditing("new")}
          className="inline-flex items-center gap-2 rounded-lg bg-basil px-4 py-2.5 text-sm font-semibold text-white shadow-[0_4px_14px_rgba(58,125,68,0.35)] transition hover:bg-basil-dark"
        >
          <Plus className="h-4 w-4" strokeWidth={2.25} /> Yeni malzeme
        </button>
      }
    >
      <div className="flex flex-wrap items-center gap-3">
        <div className="relative w-full max-w-sm">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Malzeme ara… (ör. sogan)"
            className="w-full rounded-xl border border-line bg-white py-2.5 pl-10 pr-4 text-sm shadow-sm outline-none transition focus:border-basil focus:ring-2 focus:ring-basil/20"
          />
        </div>
        <select
          value={category ?? ""}
          onChange={(e) => update({ category: e.target.value || null, page: null })}
          className="rounded-xl border border-line bg-white px-3 py-2.5 text-sm shadow-sm outline-none focus:border-basil"
        >
          <option value="">Tüm kategoriler</option>
          {INGREDIENT_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>
      </div>

      <div className="mt-6 overflow-hidden rounded-2xl bg-white shadow-sm ring-1 ring-line">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-line bg-neutral-50/70 text-xs font-semibold uppercase tracking-wide text-muted">
            <tr>
              <th className="px-4 py-3">Malzeme</th>
              <th className="px-4 py-3">Kategori</th>
              <th className="px-4 py-3">Varsayılan birim</th>
              <th className="px-4 py-3">Eşanlamlı</th>
              <th className="px-4 py-3 text-right">Id</th>
              <th className="w-12 px-4 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {items.map((i) => (
              <tr key={i.id} className="group cursor-pointer transition hover:bg-cream/60" onClick={() => setEditing(i)}>
                <td className="px-4 py-2.5">
                  <div className="flex items-center gap-3">
                    <Thumb key={i.imageUrl} url={i.imageUrl} emoji={i.emoji} />
                    <span className="font-semibold text-forest">{i.name}</span>
                  </div>
                </td>
                <td className="px-4 py-2.5">
                  <span className="rounded-md bg-neutral-100 px-2 py-1 text-xs font-semibold text-neutral-700">
                    {ingredientCategoryLabel(i.category)}
                  </span>
                </td>
                <td className="px-4 py-2.5 text-muted">{unitLabel(i.defaultUnit)}</td>
                <td className="px-4 py-2.5">
                  {i.aliasCount > 0 ? (
                    <span className="inline-flex items-center gap-1 rounded-md bg-[#e3ece4] px-2 py-1 text-xs font-semibold text-forest">
                      <Tags className="h-3.5 w-3.5" /> {i.aliasCount}
                    </span>
                  ) : (
                    <span className="text-xs text-neutral-400">—</span>
                  )}
                </td>
                <td className="px-4 py-2.5 text-right font-mono text-xs text-muted">{i.id}</td>
                <td className="px-4 py-2.5 text-right">
                  <Pencil className="ml-auto h-4 w-4 text-muted opacity-0 transition group-hover:opacity-100" />
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {items.length === 0 && (
          <div className="flex flex-col items-center gap-2 py-14 text-center text-muted">
            <SearchX className="h-9 w-9 text-neutral-300" strokeWidth={1.5} />
            <p className="font-semibold text-ink">Malzeme bulunamadı</p>
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
              onClick={() => update({ page: page - 1 })}
              className="rounded-lg border border-line bg-white px-4 py-2 text-sm font-semibold transition hover:border-basil hover:text-basil disabled:opacity-40"
            >
              Önceki
            </button>
            <button
              disabled={page >= pageCount}
              onClick={() => update({ page: page + 1 })}
              className="rounded-lg border border-line bg-white px-4 py-2 text-sm font-semibold transition hover:border-basil hover:text-basil disabled:opacity-40"
            >
              Sonraki
            </button>
          </div>
        </div>
      )}

      {editing && (
        <IngredientDialog
          initial={editing === "new" ? null : editing}
          onClose={async (message) => {
            setEditing(null);
            if (message) setToast(message);
            await load(); // aynı sayfayı yeniden yükler, 1. sayfaya atmaz
          }}
        />
      )}

      {toast && (
        <div className="fixed right-6 top-6 z-[60] flex max-w-sm items-start gap-3 rounded-xl bg-white p-4 shadow-2xl ring-1 ring-line">
          {toast.ok ? (
            <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-basil" />
          ) : (
            <XCircle className="mt-0.5 h-5 w-5 shrink-0 text-red-500" />
          )}
          <p className="text-sm font-medium text-ink">{toast.text}</p>
          <button onClick={() => setToast(null)} className="ml-2 rounded p-0.5 text-muted hover:bg-neutral-100">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}
    </AdminShell>
  );
}

function Thumb({ url, emoji, className = "h-10 w-10 rounded-lg" }: { url: string; emoji: string; className?: string }) {
  const [failed, setFailed] = useState(false);
  if (failed) {
    return <span className={`flex items-center justify-center bg-cream text-xl ${className}`}>{emoji}</span>;
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={mediaUrl(url)} alt="" onError={() => setFailed(true)} className={`object-cover ${className}`} />
  );
}

// ─── Ekleme / düzenleme penceresi ───────────────────────────

const inputClass =
  "w-full rounded-xl border border-neutral-300 bg-white px-3.5 py-2.5 text-sm outline-none transition focus:border-basil focus:ring-2 focus:ring-basil/20";

function IngredientDialog({
  initial,
  onClose,
}: {
  initial: AdminIngredient | null;
  onClose: (toast?: Toast) => void;
}) {
  const isNew = initial === null;
  const fileInput = useRef<HTMLInputElement>(null);

  const [form, setForm] = useState<IngredientInput>(
    initial
      ? { name: initial.name, emoji: initial.emoji, category: initial.category, defaultUnit: initial.defaultUnit }
      : EMPTY,
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fotoğraf: yeni malzemede bekleyen dosya, düzenlemede anında yüklenir
  const [pendingPhoto, setPendingPhoto] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [imageUrl, setImageUrl] = useState(initial?.imageUrl ?? "");
  const [hasCustom, setHasCustom] = useState(initial?.hasCustomImage ?? false);
  const [photoBusy, setPhotoBusy] = useState(false);
  const [dragging, setDragging] = useState(false);

  // Fişteki yazılışlar: yeni malzemede bekleyen metinler, düzenlemede kayıtlı liste
  const [aliases, setAliases] = useState<AliasItem[]>([]);
  const [pendingAliases, setPendingAliases] = useState<string[]>([]);
  const [aliasInput, setAliasInput] = useState("");
  const [aliasBusy, setAliasBusy] = useState(false);

  useEffect(() => {
    if (initial) listAliases(initial.id).then(setAliases).catch(() => setAliases([]));
  }, [initial]);

  useEffect(() => {
    if (!pendingPhoto) {
      setPreview(null);
      return;
    }
    const url = URL.createObjectURL(pendingPhoto);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [pendingPhoto]);

  // Esc ile kapat
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && !saving) onClose();
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [saving, onClose]);

  async function pickPhoto(file: File | undefined) {
    if (!file) return;
    setError(null);
    if (!ALLOWED.includes(file.type)) return setError("Fotoğraf JPEG, PNG ya da WebP olmalı.");
    if (file.size > MAX_BYTES) return setError("Fotoğraf 5 MB'ı geçemez.");

    if (isNew) {
      setPendingPhoto(file);
    } else {
      setPhotoBusy(true);
      try {
        const result = await uploadIngredientImage(initial.id, file);
        setImageUrl(result.imageUrl);
        setHasCustom(true);
      } catch (err) {
        setError(err instanceof ApiError ? err.message : "Fotoğraf yüklenemedi.");
      } finally {
        setPhotoBusy(false);
      }
    }
    if (fileInput.current) fileInput.current.value = "";
  }

  async function removePhoto() {
    if (isNew) return setPendingPhoto(null);
    setPhotoBusy(true);
    try {
      await removeIngredientImage(initial.id);
      setImageUrl(`/images/ingredients/${initial.id}.jpg`);
      setHasCustom(false);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Fotoğraf kaldırılamadı.");
    } finally {
      setPhotoBusy(false);
    }
  }

  async function addAliasClick() {
    const value = aliasInput.trim();
    if (value.length < 3) return;
    setError(null);

    if (isNew) {
      if (!pendingAliases.includes(value)) setPendingAliases([...pendingAliases, value]);
      setAliasInput("");
      return;
    }

    setAliasBusy(true);
    try {
      const created = await addAlias(initial.id, value);
      setAliases((list) => [...list, created].sort((a, b) => a.alias.localeCompare(b.alias)));
      setAliasInput("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Eklenemedi.");
    } finally {
      setAliasBusy(false);
    }
  }

  async function removeAlias(alias: AliasItem) {
    try {
      await deleteAlias(alias.id);
      setAliases((list) => list.filter((a) => a.id !== alias.id));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Silinemedi.");
    }
  }

  async function handleSubmit(e: SyntheticEvent) {
    e.preventDefault();
    setError(null);
    setSaving(true);

    try {
      if (!isNew) {
        await updateIngredient(initial.id, form);
        onClose({ ok: true, text: `${form.name} kaydedildi.` });
        return;
      }

      // 1. Malzemeyi oluştur
      const created = await createIngredient(form);

      // 2. Fotoğraf ve yazılışlar: malzeme artık var, bunlardaki hata kaydı geri almaz
      const problems: string[] = [];
      if (pendingPhoto) {
        try {
          await uploadIngredientImage(created.id, pendingPhoto);
        } catch {
          problems.push("fotoğraf");
        }
      }
      for (const alias of pendingAliases) {
        try {
          await addAlias(created.id, alias);
        } catch {
          problems.push(`"${alias}"`);
        }
      }

      onClose(
        problems.length === 0
          ? { ok: true, text: `${form.name} kataloğa eklendi.` }
          : { ok: false, text: `${form.name} eklendi ama şunlar kaydedilemedi: ${problems.join(", ")}. Malzemeyi açıp tekrar deneyin.` },
      );
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Kaydedilemedi.");
      setSaving(false);
    }
  }

  const shownImage = isNew ? preview : imageUrl;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-forest/45 p-4 backdrop-blur-sm"
      onClick={() => !saving && onClose()}
    >
      <form
        onSubmit={handleSubmit}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="ingredient-dialog-title"
        className="flex max-h-[92vh] w-full max-w-xl flex-col overflow-hidden rounded-3xl bg-white shadow-2xl"
      >
        {/* Başlık */}
        <div className="flex items-start justify-between border-b border-line px-7 py-5">
          <div>
            <h2 id="ingredient-dialog-title" className="text-xl font-extrabold tracking-tight text-forest">
              {isNew ? "Yeni malzeme" : form.name || "Malzeme"}
            </h2>
            <p className="mt-0.5 text-sm text-muted">
              {isNew ? "Kaydettiğiniz anda fiş eşleştirmede kullanılır." : "Değişiklikler fiş eşleştirmeye hemen yansır."}
            </p>
          </div>
          <button
            type="button"
            onClick={() => onClose()}
            disabled={saving}
            aria-label="Kapat"
            className="rounded-lg p-1.5 text-muted transition hover:bg-neutral-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Gövde */}
        <div className="flex-1 space-y-6 overflow-y-auto px-7 py-6">
          {/* Fotoğraf + ad */}
          <div className="flex gap-5">
            <div className="shrink-0">
              <button
                type="button"
                onClick={() => fileInput.current?.click()}
                onDragOver={(e) => {
                  e.preventDefault();
                  setDragging(true);
                }}
                onDragLeave={() => setDragging(false)}
                onDrop={(e) => {
                  e.preventDefault();
                  setDragging(false);
                  pickPhoto(e.dataTransfer.files[0]);
                }}
                aria-label="Fotoğraf seç"
                className={`relative flex h-32 w-32 items-center justify-center overflow-hidden rounded-2xl transition ${
                  shownImage ? "ring-1 ring-line" : "border-2 border-dashed border-neutral-300 bg-cream hover:border-basil"
                }`}
              >
                {shownImage ? (
                  isNew ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={shownImage} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <Thumb key={shownImage} url={shownImage} emoji={form.emoji} className="h-full w-full text-5xl" />
                  )
                ) : (
                  <span className="flex flex-col items-center gap-1.5 text-muted">
                    <Camera className="h-7 w-7 text-basil" strokeWidth={1.75} />
                    <span className="text-xs font-semibold text-forest">Fotoğraf ekle</span>
                  </span>
                )}

                {(photoBusy || dragging) && (
                  <span className="absolute inset-0 flex items-center justify-center bg-forest/70 text-white">
                    {photoBusy ? <Loader2 className="h-6 w-6 animate-spin" /> : <Upload className="h-6 w-6" />}
                  </span>
                )}
              </button>

              {(isNew ? pendingPhoto : hasCustom) && (
                <button
                  type="button"
                  onClick={removePhoto}
                  disabled={photoBusy}
                  className="mt-2 flex w-32 items-center justify-center gap-1 text-xs font-semibold text-muted transition hover:text-red-600"
                >
                  <ImageOff className="h-3.5 w-3.5" /> Fotoğrafı kaldır
                </button>
              )}
            </div>

            <div className="min-w-0 flex-1 space-y-4">
              <div>
                <label htmlFor="ingredient-name" className="mb-1.5 block text-sm font-semibold text-neutral-700">
                  Ad
                </label>
                <input
                  id="ingredient-name"
                  required
                  autoFocus
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="ör. Siyah çay"
                  className={`${inputClass} text-base font-semibold`}
                />
              </div>
              <div>
                <label htmlFor="ingredient-emoji" className="mb-1.5 block text-sm font-semibold text-neutral-700">
                  Yedek simge
                </label>
                <div className="flex items-center gap-3">
                  <input
                    id="ingredient-emoji"
                    value={form.emoji}
                    onChange={(e) => setForm({ ...form, emoji: e.target.value })}
                    className={`${inputClass} w-16 text-center text-xl`}
                  />
                  <p className="text-xs leading-snug text-muted">Fotoğraf yoksa mobil uygulamada bu görünür.</p>
                </div>
              </div>
            </div>
          </div>

          {/* Kategori */}
          <fieldset>
            <legend className="mb-2 text-sm font-semibold text-neutral-700">Kategori</legend>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
              {INGREDIENT_CATEGORIES.map((c) => {
                const Icon = CATEGORY_ICONS[c.value];
                const selected = form.category === c.value;
                return (
                  <button
                    key={c.value}
                    type="button"
                    aria-pressed={selected}
                    onClick={() => setForm({ ...form, category: c.value })}
                    className={`flex items-center gap-2 rounded-xl px-3 py-2.5 text-left text-xs font-semibold transition ${
                      selected
                        ? "bg-forest text-white shadow-sm"
                        : "bg-neutral-50 text-neutral-700 ring-1 ring-neutral-200 hover:ring-neutral-300"
                    }`}
                  >
                    <Icon className={`h-4 w-4 shrink-0 ${selected ? "text-[#a6e07c]" : "text-basil"}`} />
                    <span className="truncate">{c.label}</span>
                  </button>
                );
              })}
            </div>
          </fieldset>

          {/* Birim */}
          <fieldset>
            <legend className="mb-2 text-sm font-semibold text-neutral-700">Varsayılan birim</legend>
            <div className="flex rounded-xl bg-neutral-100 p-1">
              {MEASURE_UNITS.map((u) => (
                <button
                  key={u.value}
                  type="button"
                  aria-pressed={form.defaultUnit === u.value}
                  onClick={() => setForm({ ...form, defaultUnit: u.value })}
                  className={`flex-1 rounded-lg py-2 text-xs font-semibold transition ${
                    form.defaultUnit === u.value ? "bg-white text-forest shadow-sm" : "text-muted hover:text-ink"
                  }`}
                >
                  {u.label}
                </button>
              ))}
            </div>
            <p className="mt-1.5 text-xs text-muted">Fişte birim yazmıyorsa bu kullanılır.</p>
          </fieldset>

          {/* Fişteki yazılışlar */}
          <div>
            <p className="flex items-center gap-1.5 text-sm font-semibold text-neutral-700">
              <Tags className="h-4 w-4 text-basil" /> Fişteki yazılışlar
            </p>
            <p className="mt-0.5 text-xs text-muted">
              Fişte farklı yazılıyorsa ekleyin: ör. <span className="font-mono">siyahcay</span>. İsteğe bağlı.
            </p>

            <div className="mt-2.5 flex gap-2">
              <input
                value={aliasInput}
                onChange={(e) => setAliasInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    addAliasClick();
                  }
                }}
                placeholder="Yazılış ekle ve Enter'a bas"
                className={inputClass}
              />
              <button
                type="button"
                onClick={addAliasClick}
                disabled={aliasBusy || aliasInput.trim().length < 3}
                className="shrink-0 rounded-xl px-4 text-sm font-semibold text-basil ring-1 ring-basil transition hover:bg-basil hover:text-white disabled:opacity-40"
              >
                {aliasBusy ? <Loader2 className="h-4 w-4 animate-spin" /> : "Ekle"}
              </button>
            </div>

            {(aliases.length > 0 || pendingAliases.length > 0) && (
              <div className="mt-3 flex flex-wrap gap-2">
                {aliases.map((a) => (
                  <AliasChip key={a.id} text={a.alias} onRemove={() => removeAlias(a)} />
                ))}
                {pendingAliases.map((a) => (
                  <AliasChip key={a} text={a} onRemove={() => setPendingAliases(pendingAliases.filter((p) => p !== a))} />
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Alt çubuk */}
        <div className="flex items-center justify-between gap-3 border-t border-line bg-neutral-50/70 px-7 py-4">
          <p className="min-w-0 text-sm font-medium text-red-700">{error}</p>
          <div className="flex shrink-0 gap-2">
            <button
              type="button"
              onClick={() => onClose()}
              disabled={saving}
              className="rounded-xl px-4 py-2.5 text-sm font-semibold text-muted transition hover:bg-neutral-200/60"
            >
              Vazgeç
            </button>
            <button
              type="submit"
              disabled={saving || form.name.trim().length < 2}
              className="inline-flex items-center gap-2 rounded-xl bg-basil px-5 py-2.5 text-sm font-semibold text-white shadow-[0_4px_14px_rgba(58,125,68,0.35)] transition hover:bg-basil-dark disabled:opacity-50"
            >
              {saving && <Loader2 className="h-4 w-4 animate-spin" />}
              {isNew ? "Malzemeyi ekle" : "Kaydet"}
            </button>
          </div>
        </div>

        <input
          ref={fileInput}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          className="hidden"
          onChange={(e) => pickPhoto(e.target.files?.[0])}
        />
      </form>
    </div>
  );
}

function AliasChip({ text, onRemove }: { text: string; onRemove: () => void }) {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full bg-[#e3ece4] py-1 pl-3 pr-1.5 font-mono text-xs font-semibold text-forest">
      {text}
      <button type="button" onClick={onRemove} aria-label={`${text} kaldır`} className="rounded-full p-0.5 hover:bg-white/70 hover:text-red-600">
        <X className="h-3.5 w-3.5" />
      </button>
    </span>
  );
}