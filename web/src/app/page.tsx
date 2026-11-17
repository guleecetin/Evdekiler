"use client";

import { Suspense, useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { Clock, ListChecks, Plus, Search, SearchX, Trash2 } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import PageLoader from "@/components/PageLoader";
import CategoryIcon, { categoryStyle } from "@/components/CategoryIcon";
import RecipeImage from "@/components/RecipeImage";
import {
  CATEGORIES,
  categoryLabel,
  deleteRecipe,
  getRecipeStats,
  listRecipes,
  type RecipeListItem,
} from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";
import { useListQuery } from "@/lib/useListQuery";

const PAGE_SIZE = 12;

// useSearchParams kullanan bileşen Suspense içinde olmalı (Next.js kuralı)
export default function HomePage() {
  return (
    <Suspense fallback={<PageLoader />}>
      <RecipeList />
    </Suspense>
  );
}

function RecipeList() {
  const me = useAdmin();
  const { page, search, category, query, update } = useListQuery();

  const [items, setItems] = useState<RecipeListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [searchInput, setSearchInput] = useState(search);
  const [error, setError] = useState<string | null>(null);

  // Yazmayı bırakınca adresteki aramayı güncelle (sadece gerçekten değiştiyse 1. sayfaya dön)
  useEffect(() => {
    const value = searchInput.trim();
    if (value === search) return;
    const timer = setTimeout(() => update({ q: value, page: null }), 300);
    return () => clearTimeout(timer);
  }, [searchInput, search, update]);

  const load = useCallback(async () => {
    try {
      const result = await listRecipes(page, PAGE_SIZE, search, category);
      setItems(result.items);
      setTotal(result.totalCount);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Liste yüklenemedi.");
    }
  }, [page, search, category]);

  // Kategori kartlarındaki sayılar: tek istek (eskiden 8 ayrı istekti)
  const loadCounts = useCallback(async () => {
    const stats = await getRecipeStats();
    const next: Record<string, number> = { all: stats.total };
    for (const c of CATEGORIES) next[c.value] = stats.byCategory[c.value] ?? 0;
    setCounts(next);
  }, []);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  useEffect(() => {
    if (me) loadCounts().catch(() => {});
  }, [me, loadCounts]);

  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));

  // Silme sonrası son sayfa boşaldıysa bir önceki sayfaya geç
  useEffect(() => {
    if (total > 0 && page > pageCount) update({ page: pageCount });
  }, [total, page, pageCount, update]);

  async function handleDelete(e: React.MouseEvent, recipe: RecipeListItem) {
    e.preventDefault();
    e.stopPropagation();
    if (!confirm(`"${recipe.title}" silinsin mi? Bu işlem geri alınamaz.`)) return;
    try {
      await deleteRecipe(recipe.id);
      await Promise.all([load(), loadCounts()]);
    } catch (err) {
      alert(err instanceof Error ? err.message : "Silinemedi.");
    }
  }

  if (!me) return <PageLoader />;

  const tabs: { value: string | null; key: string; label: string }[] = [
    { value: null, key: "all", label: "Tümü" },
    ...CATEGORIES.map((c) => ({ value: c.value as string, key: c.value as string, label: c.label })),
  ];

  // Düzenleme sayfası "← Tarifler" ile buraya, aynı sayfa ve filtreye dönebilsin
  const from = query ? `?from=${encodeURIComponent(query)}` : "";

  return (
    <AdminShell
      me={me}
      title="Tarifler"
      subtitle={`Merhaba ${me.displayName.split(" ")[0]}, bugün ${counts.all ?? "…"} tarifin var.`}
      actions={
        <Link
          href="/recipes/new"
          className="inline-flex items-center gap-2 rounded-lg bg-basil px-4 py-2.5 text-sm font-semibold text-white shadow-[0_4px_14px_rgba(58,125,68,0.35)] transition hover:bg-basil-dark"
        >
          <Plus className="h-4 w-4" strokeWidth={2.25} />
          Yeni tarif
        </Link>
      }
    >
      {/* Kategori kartları */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {tabs.map((t) => {
          const active = category === t.value;
          const style = categoryStyle(t.value);
          return (
            <button
              key={t.key}
              onClick={() => update({ category: t.value, page: null })}
              className={`flex items-center gap-3 rounded-xl bg-white p-3.5 text-left transition hover:-translate-y-0.5 hover:shadow-md ${
                active ? `ring-2 ${style.ring} shadow-md` : "ring-1 ring-line"
              }`}
            >
              <span className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${style.soft}`}>
                <CategoryIcon category={t.value} className="h-5 w-5" />
              </span>
              <span className="leading-tight">
                <span className="block text-sm font-semibold text-ink">{t.label}</span>
                <span className="text-xs text-muted">{counts[t.key] ?? "…"} tarif</span>
              </span>
            </button>
          );
        })}
      </div>

      {/* Arama */}
      <div className="mt-6 flex items-center justify-between gap-4">
        <div className="relative w-full max-w-md">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Tarif adında ara…"
            className="w-full rounded-lg border border-line bg-white py-2.5 pl-10 pr-4 text-sm outline-none transition focus:border-basil focus:ring-1 focus:ring-basil"
          />
        </div>
        <p className="shrink-0 text-sm text-muted">{total} sonuç</p>
      </div>

      {error && (
        <p className="mt-6 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
          {error}
        </p>
      )}

      {/* Tarif kartları */}
      <div className="mt-6 grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {items.map((recipe) => {
          const style = categoryStyle(recipe.category);
          return (
            <Link
              key={recipe.id}
              href={`/recipes/${recipe.id}${from}`}
              className="group overflow-hidden rounded-2xl bg-white ring-1 ring-line transition hover:-translate-y-1 hover:shadow-[0_12px_30px_rgba(29,58,42,0.12)]"
            >
              <div className="relative aspect-[4/3] overflow-hidden">
                <RecipeImage
                  path={recipe.imageUrl}
                  alt={recipe.title}
                  category={recipe.category}
                  className="transition duration-300 group-hover:scale-105"
                />
                <span className={`absolute left-3 top-3 inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-bold shadow-sm ${style.soft}`}>
                  <CategoryIcon category={recipe.category} className="h-3.5 w-3.5" />
                  {categoryLabel(recipe.category)}
                </span>
                <button
                  onClick={(e) => handleDelete(e, recipe)}
                  title="Sil"
                  className="absolute right-3 top-3 rounded-full bg-white/95 p-2 text-neutral-600 opacity-0 shadow-sm transition hover:text-red-600 group-hover:opacity-100"
                >
                  <Trash2 className="h-4 w-4" strokeWidth={1.75} />
                </button>
              </div>
              <div className="p-4">
                <h2 className="line-clamp-1 font-bold text-forest">{recipe.title}</h2>
                <div className="mt-2 flex items-center gap-4 text-xs text-muted">
                  <span className="inline-flex items-center gap-1">
                    <Clock className="h-3.5 w-3.5" /> {recipe.prepMinutes} dk
                  </span>
                  <span className="inline-flex items-center gap-1">
                    <ListChecks className="h-3.5 w-3.5" /> {recipe.ingredientCount} malzeme
                  </span>
                </div>
              </div>
            </Link>
          );
        })}
      </div>

      {items.length === 0 && !error && (
        <div className="mt-16 flex flex-col items-center gap-3 text-center text-muted">
          <SearchX className="h-10 w-10 text-neutral-300" strokeWidth={1.5} />
          <p className="font-semibold text-ink">Tarif bulunamadı</p>
          <p className="text-sm">Aramayı ya da kategoriyi değiştirmeyi deneyin.</p>
        </div>
      )}

      {pageCount > 1 && (
        <div className="mt-10 flex items-center justify-between border-t border-line pt-6">
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
    </AdminShell>
  );
}