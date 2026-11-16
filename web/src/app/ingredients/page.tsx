"use client";

import { useCallback, useEffect, useState, type SyntheticEvent } from "react";
import { Loader2, Pencil, Plus, Search, SearchX, X } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import { ApiError } from "@/lib/api";
import {
  INGREDIENT_CATEGORIES,
  MEASURE_UNITS,
  createIngredient,
  ingredientCategoryLabel,
  listIngredients,
  unitLabel,
  updateIngredient,
  type AdminIngredient,
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
      {/* Arama ve kategori */}
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

      {/* Tablo */}
      <div className="mt-6 overflow-hidden rounded-xl bg-white ring-1 ring-line">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-line bg-neutral-50 text-xs font-semibold uppercase tracking-wide text-muted">
            <tr>
              <th className="px-4 py-3">Malzeme</th>
              <th className="px-4 py-3">Kategori</th>
              <th className="px-4 py-3">Varsayılan birim</th>
              <th className="px-4 py-3 text-right">Id</th>
              <th className="w-12 px-4 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {items.map((i) => (
              <tr key={i.id} className="group transition hover:bg-cream">
                <td className="px-4 py-2.5">
                  <div className="flex items-center gap-3">
                    <IngredientThumb ingredient={i} />
                    <span className="font-semibold text-forest">{i.name}</span>
                  </div>
                </td>
                <td className="px-4 py-2.5">
                  <span className="rounded-md bg-neutral-100 px-2 py-1 text-xs font-semibold text-neutral-700">
                    {ingredientCategoryLabel(i.category)}
                  </span>
                </td>
                <td className="px-4 py-2.5 text-muted">{unitLabel(i.defaultUnit)}</td>
                <td className="px-4 py-2.5 text-right font-mono text-xs text-muted">{i.id}</td>
                <td className="px-4 py-2.5 text-right">
                  <button
                    onClick={() => setEditing(i)}
                    title="Düzenle"
                    className="rounded-lg p-2 text-muted opacity-0 transition hover:bg-white hover:text-basil group-hover:opacity-100"
                  >
                    <Pencil className="h-4 w-4" />
                  </button>
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
          onClose={() => setEditing(null)}
          onSaved={async () => {
            setEditing(null);
            await load();
          }}
        />
      )}
    </AdminShell>
  );
}

// Fotoğrafı yoksa emojisini gösterir
function IngredientThumb({ ingredient }: { ingredient: AdminIngredient }) {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return (
      <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-cream text-xl">{ingredient.emoji}</span>
    );
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={mediaUrl(ingredient.imageUrl)}
      alt=""
      onError={() => setFailed(true)}
      className="h-10 w-10 rounded-lg object-cover"
    />
  );
}

function IngredientDialog({
  initial,
  onClose,
  onSaved,
}: {
  initial: AdminIngredient | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [form, setForm] = useState<IngredientInput>(
    initial
      ? { name: initial.name, emoji: initial.emoji, category: initial.category, defaultUnit: initial.defaultUnit }
      : EMPTY,
  );
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function handleSubmit(e: SyntheticEvent) {
    e.preventDefault();
    setError(null);
    setSaving(true);
    try {
      if (initial) await updateIngredient(initial.id, form);
      else await createIngredient(form);
      onSaved();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Kaydedilemedi.");
    } finally {
      setSaving(false);
    }
  }

  const inputClass =
    "w-full rounded-lg border border-neutral-300 bg-white px-3.5 py-2.5 text-sm outline-none transition focus:border-basil focus:ring-1 focus:ring-basil";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-forest/40 p-4 backdrop-blur-sm" onClick={onClose}>
      <form
        onSubmit={handleSubmit}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl"
      >
        <div className="flex items-start justify-between">
          <div>
            <h2 className="text-lg font-extrabold text-forest">{initial ? "Malzemeyi düzenle" : "Yeni malzeme"}</h2>
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
            <p className="mt-1.5 text-xs text-muted">Fişte birim yazmıyorsa bu kullanılır.</p>
          </div>
        </div>

        {error && (
          <p className="mt-4 rounded-lg border border-red-200 bg-red-50 px-3.5 py-2.5 text-sm font-medium text-red-700">
            {error}
          </p>
        )}

        <div className="mt-6 flex justify-end gap-2">
          <button type="button" onClick={onClose} className="rounded-lg px-4 py-2.5 text-sm font-semibold text-muted hover:bg-neutral-100">
            Vazgeç
          </button>
          <button
            type="submit"
            disabled={saving}
            className="inline-flex items-center gap-2 rounded-lg bg-basil px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-basil-dark disabled:opacity-60"
          >
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            {initial ? "Kaydet" : "Ekle"}
          </button>
        </div>
      </form>
    </div>
  );
}