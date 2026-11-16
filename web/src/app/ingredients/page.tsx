"use client";

import { useCallback, useEffect, useRef, useState, type SyntheticEvent } from "react";
import { Camera, ImageOff, Loader2, Pencil, Plus, Search, SearchX, Tags, Upload, X } from "lucide-react";
import AdminShell from "@/components/AdminShell";
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
  type IngredientInput,
} from "@/lib/ingredients";
import { mediaUrl } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

const PAGE_SIZE = 24;
const EMPTY: IngredientInput = { name: "", emoji: "🛒", category: "Vegetable", defaultUnit: "Piece" };

export default function IngredientsPage() {
  const me = useAdmin();
  const [items, setItems] = useState<AdminIngredient[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState<string | null>(null);
  const [editing, setEditing] = useState<AdminIngredient | "new" | null>(null);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSearch(searchInput.trim());
      setPage(1);
    }, 250);
    return () => clearTimeout(timer);
  }, [searchInput]);

  const load = useCallback(async () => {
    const result = await listIngredients(page, PAGE_SIZE, search, category);
    setItems(result.items);
    setTotal(result.totalCount);
  }, [page, search, category]);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  if (!me) return <main className="p-10 text-muted">Yükleniyor…</main>;

  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));

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
            className="w-full rounded-lg border border-line bg-white py-2.5 pl-10 pr-4 text-sm outline-none transition focus:border-basil focus:ring-1 focus:ring-basil"
          />
        </div>
        <select
          value={category ?? ""}
          onChange={(e) => {
            setCategory(e.target.value || null);
            setPage(1);
          }}
          className="rounded-lg border border-line bg-white px-3 py-2.5 text-sm outline-none focus:border-basil"
        >
          <option value="">Tüm kategoriler</option>
          {INGREDIENT_CATEGORIES.map((c) => (
            <option key={c.value} value={c.value}>
              {c.label}
            </option>
          ))}
        </select>
      </div>

      <div className="mt-6 overflow-hidden rounded-xl bg-white ring-1 ring-line">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-line bg-neutral-50 text-xs font-semibold uppercase tracking-wide text-muted">
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
              <tr key={i.id} className="group cursor-pointer transition hover:bg-cream" onClick={() => setEditing(i)}>
                <td className="px-4 py-2.5">
                  <div className="flex items-center gap-3">
                    <IngredientThumb key={i.imageUrl} url={i.imageUrl} emoji={i.emoji} />
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

      {editing && (
        <IngredientDialog
          initial={editing === "new" ? null : editing}
          onClose={async () => {
            setEditing(null);
            await load();
          }}
        />
      )}
    </AdminShell>
  );
}

function IngredientThumb({ url, emoji, size = "h-10 w-10" }: { url: string; emoji: string; size?: string }) {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return <span className={`flex ${size} items-center justify-center rounded-lg bg-cream text-xl`}>{emoji}</span>;
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={mediaUrl(url)} alt="" onError={() => setFailed(true)} className={`${size} rounded-lg object-cover`} />
  );
}

const inputClass =
  "w-full rounded-lg border border-neutral-300 bg-white px-3.5 py-2.5 text-sm outline-none transition focus:border-basil focus:ring-1 focus:ring-basil";

function IngredientDialog({ initial, onClose }: { initial: AdminIngredient | null; onClose: () => void }) {
  const [form, setForm] = useState<IngredientInput>(
    initial
      ? { name: initial.name, emoji: initial.emoji, category: initial.category, defaultUnit: initial.defaultUnit }
      : EMPTY,
  );
  const [savedId, setSavedId] = useState<number | null>(initial?.id ?? null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  async function handleSubmit(e: SyntheticEvent) {
    e.preventDefault();
    setError(null);
    setSaved(false);
    setSaving(true);
    try {
      if (savedId) {
        await updateIngredient(savedId, form);
      } else {
        const created = await createIngredient(form);
        setSavedId(created.id);
      }
      setSaved(true);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Kaydedilemedi.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-forest/40 p-4 backdrop-blur-sm" onClick={onClose}>
      <div
        onClick={(e) => e.stopPropagation()}
        className="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl"
      >
        <form onSubmit={handleSubmit}>
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-lg font-extrabold text-forest">{savedId ? "Malzemeyi düzenle" : "Yeni malzeme"}</h2>
              <p className="mt-0.5 text-sm text-muted">Fiş eşleştirme değişikliği hemen kullanır.</p>
            </div>
            <button type="button" onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-neutral-100">
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="mt-6 space-y-4">
            <div className="flex gap-3">
              <div className="w-20">
                <label className="mb-1.5 block text-sm font-semibold text-neutral-700">Simge</label>
                <input
                  value={form.emoji}
                  onChange={(e) => setForm({ ...form, emoji: e.target.value })}
                  className={`${inputClass} text-center text-lg`}
                />
              </div>
              <div className="flex-1">
                <label className="mb-1.5 block text-sm font-semibold text-neutral-700">Ad</label>
                <input
                  required
                  autoFocus
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="ör. Siyah çay"
                  className={inputClass}
                />
              </div>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-neutral-700">Kategori</label>
              <select
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value as IngredientInput["category"] })}
                className={inputClass}
              >
                {INGREDIENT_CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>
                    {c.label}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-neutral-700">Varsayılan birim</label>
              <div className="grid grid-cols-5 gap-2">
                {MEASURE_UNITS.map((u) => (
                  <button
                    key={u.value}
                    type="button"
                    onClick={() => setForm({ ...form, defaultUnit: u.value })}
                    className={`rounded-lg border px-2 py-2 text-xs font-semibold transition ${
                      form.defaultUnit === u.value
                        ? "border-basil bg-basil text-white"
                        : "border-neutral-300 text-neutral-700 hover:border-neutral-400"
                    }`}
                  >
                    {u.label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {error && (
            <p className="mt-4 rounded-lg border border-red-200 bg-red-50 px-3.5 py-2.5 text-sm font-medium text-red-700">{error}</p>
          )}
          {saved && !error && (
            <p className="mt-4 rounded-lg border border-green-200 bg-green-50 px-3.5 py-2.5 text-sm font-semibold text-green-800">
              Kaydedildi ✓
            </p>
          )}

          <div className="mt-6 flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center gap-2 rounded-lg bg-basil px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-basil-dark disabled:opacity-60"
            >
              {saving && <Loader2 className="h-4 w-4 animate-spin" />}
              {savedId ? "Kaydet" : "Ekle"}
            </button>
          </div>
        </form>

        {savedId ? (
          <>
            <PhotoEditor
              ingredientId={savedId}
              emoji={form.emoji}
              initialUrl={initial?.imageUrl ?? `/images/ingredients/${savedId}.jpg`}
              initialCustom={initial?.hasCustomImage ?? false}
            />
            <AliasEditor ingredientId={savedId} />
          </>
        ) : (
          <p className="mt-6 border-t border-line pt-5 text-sm text-muted">
            Fotoğraf ve eşanlamlı ekleyebilmek için önce malzemeyi kaydedin.
          </p>
        )}
      </div>
    </div>
  );
}

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

function PhotoEditor({
  ingredientId,
  emoji,
  initialUrl,
  initialCustom,
}: {
  ingredientId: number;
  emoji: string;
  initialUrl: string;
  initialCustom: boolean;
}) {
  const fileInput = useRef<HTMLInputElement>(null);
  const [url, setUrl] = useState(initialUrl);
  const [custom, setCustom] = useState(initialCustom);
  const [busy, setBusy] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleFile(file: File | undefined) {
    if (!file) return;
    setError(null);
    if (!ALLOWED.includes(file.type)) return setError("Sadece JPEG, PNG veya WebP yükleyebilirsiniz.");
    if (file.size > MAX_BYTES) return setError("Fotoğraf 5 MB'ı geçemez.");

    setBusy(true);
    try {
      const result = await uploadIngredientImage(ingredientId, file);
      setUrl(result.imageUrl);
      setCustom(true);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Yüklenemedi.");
    } finally {
      setBusy(false);
      if (fileInput.current) fileInput.current.value = "";
    }
  }

  async function handleRemove() {
    setError(null);
    setBusy(true);
    try {
      await removeIngredientImage(ingredientId);
      setUrl(`/images/ingredients/${ingredientId}.jpg`);
      setCustom(false);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Kaldırılamadı.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mt-6 border-t border-line pt-5">
      <h3 className="flex items-center gap-2 font-bold text-forest">
        <Camera className="h-4 w-4" /> Fotoğraf
      </h3>

      <div
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          handleFile(e.dataTransfer.files[0]);
        }}
        className={`mt-3 flex items-center gap-4 rounded-xl border-2 border-dashed p-3 transition ${
          dragging ? "border-basil bg-[#e3ece4]" : "border-neutral-200"
        }`}
      >
        <div className="relative">
          <IngredientThumb key={url} url={url} emoji={emoji} size="h-20 w-20" />
          {busy && (
            <div className="absolute inset-0 flex items-center justify-center rounded-lg bg-white/70">
              <Loader2 className="h-5 w-5 animate-spin text-basil" />
            </div>
          )}
        </div>

        <div className="flex-1 text-sm">
          <p className="flex items-center gap-1.5 text-muted">
            <Upload className="h-4 w-4" /> Sürükleyip bırakın ya da seçin
          </p>
          <div className="mt-2 flex gap-2">
            <button
              type="button"
              onClick={() => fileInput.current?.click()}
              disabled={busy}
              className="rounded-lg bg-basil px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-basil-dark disabled:opacity-60"
            >
              {custom ? "Değiştir" : "Yükle"}
            </button>
            {custom && (
              <button
                type="button"
                onClick={handleRemove}
                disabled={busy}
                className="inline-flex items-center gap-1 rounded-lg border border-neutral-300 px-3 py-1.5 text-xs font-semibold text-neutral-700 transition hover:border-red-300 hover:text-red-600 disabled:opacity-60"
              >
                <ImageOff className="h-3.5 w-3.5" /> Kaldır
              </button>
            )}
          </div>
        </div>
      </div>

      <input
        ref={fileInput}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={(e) => handleFile(e.target.files?.[0])}
      />

      {error && <p className="mt-2 text-sm font-medium text-red-700">{error}</p>}
    </div>
  );
}

function AliasEditor({ ingredientId }: { ingredientId: number }) {
  const [aliases, setAliases] = useState<AliasItem[]>([]);
  const [input, setInput] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    listAliases(ingredientId).then(setAliases).catch(() => setAliases([]));
  }, [ingredientId]);

  async function add() {
    const value = input.trim();
    if (!value) return;
    setError(null);
    setBusy(true);
    try {
      const created = await addAlias(ingredientId, value);
      setAliases((list) => [...list, created].sort((a, b) => a.alias.localeCompare(b.alias)));
      setInput("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Eklenemedi.");
    } finally {
      setBusy(false);
    }
  }

  async function remove(alias: AliasItem) {
    setError(null);
    try {
      await deleteAlias(alias.id);
      setAliases((list) => list.filter((a) => a.id !== alias.id));
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Silinemedi.");
    }
  }

  return (
    <div className="mt-6 border-t border-line pt-5">
      <h3 className="flex items-center gap-2 font-bold text-forest">
        <Tags className="h-4 w-4" /> Fişteki yazılışları
      </h3>
      <p className="mt-0.5 text-sm text-muted">
        Fişte nasıl yazıyorsa öyle ekleyin: ör. <span className="font-mono">siyahcay</span>.
      </p>

      <div className="mt-3 flex flex-wrap gap-2">
        {aliases.length === 0 && <span className="text-sm text-neutral-400">Henüz eşanlamlı yok.</span>}
        {aliases.map((a) => (
          <span
            key={a.id}
            className="inline-flex items-center gap-1.5 rounded-full bg-[#e3ece4] py-1 pl-3 pr-1.5 font-mono text-xs font-semibold text-forest"
          >
            {a.alias}
            <button onClick={() => remove(a)} title="Kaldır" className="rounded-full p-0.5 hover:bg-white/70 hover:text-red-600">
              <X className="h-3.5 w-3.5" />
            </button>
          </span>
        ))}
      </div>

      <div className="mt-3 flex gap-2">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              add();
            }
          }}
          placeholder="Yeni yazılış ekle…"
          className={inputClass}
        />
        <button
          type="button"
          onClick={add}
          disabled={busy || !input.trim()}
          className="shrink-0 rounded-lg border border-basil px-4 text-sm font-semibold text-basil transition hover:bg-basil hover:text-white disabled:opacity-40"
        >
          Ekle
        </button>
      </div>

      {error && <p className="mt-2 text-sm font-medium text-red-700">{error}</p>}
    </div>
  );
}