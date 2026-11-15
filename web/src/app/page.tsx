"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import RecipeImage from "@/components/RecipeImage";
import { logout } from "@/lib/api";
import { deleteRecipe, listRecipes, type RecipeListItem } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

const PAGE_SIZE = 12;

export default function HomePage() {
  const router = useRouter();
  const me = useAdmin();
  const [items, setItems] = useState<RecipeListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const timer = setTimeout(() => {
      setSearch(searchInput.trim());
      setPage(1);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  const load = useCallback(async () => {
    try {
      const result = await listRecipes(page, PAGE_SIZE, search);
      setItems(result.items);
      setTotal(result.totalCount);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Liste yüklenemedi.");
    }
  }, [page, search]);

  useEffect(() => {
    if (me) load();
  }, [me, load]);

  async function handleDelete(e: React.MouseEvent, recipe: RecipeListItem) {
    e.preventDefault();
    e.stopPropagation();
    if (!confirm(`"${recipe.title}" silinsin mi? Bu işlem geri alınamaz.`)) return;
    try {
      await deleteRecipe(recipe.id);
      await load();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Silinemedi.");
    }
  }

  if (!me) return <main className="p-10 text-muted">Yükleniyor…</main>;

  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <main className="mx-auto max-w-6xl px-6 py-10">
      <header className="flex items-center justify-between">
        <div>
          <p className="text-muted">Merhaba {me.displayName.split(" ")[0]} 👋</p>
          <h1 className="text-3xl font-extrabold tracking-tight">Tarifler</h1>
        </div>
        <div className="flex gap-3">
          <Link
            href="/recipes/new"
            className="rounded-xl bg-basil px-5 py-2.5 font-bold text-white transition hover:bg-basil-dark"
          >
            + Yeni tarif
          </Link>
          <button
            onClick={async () => {
              await logout();
              router.replace("/login");
            }}
            className="rounded-xl border border-ink px-5 py-2.5 font-bold transition hover:bg-neutral-100"
          >
            Çıkış yap
          </button>
        </div>
      </header>

      <div className="mt-8 flex items-center gap-4">
        <input
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          placeholder="Tarif ara…"
          className="w-full max-w-md rounded-full border border-line px-6 py-3.5 shadow-[0_3px_12px_rgba(0,0,0,0.08)] outline-none transition focus:border-ink"
        />
        <p className="text-sm text-muted">{total} tarif</p>
      </div>

      {error && (
        <p className="mt-6 rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-700">{error}</p>
      )}

      <div className="mt-8 grid grid-cols-1 gap-x-6 gap-y-10 sm:grid-cols-2 lg:grid-cols-4">
        {items.map((recipe) => (
          <Link key={recipe.id} href={`/recipes/${recipe.id}`} className="group">
            <div className="relative aspect-[4/3] overflow-hidden rounded-2xl">
              <RecipeImage
                path={recipe.imageUrl}
                alt={recipe.title}
                className="transition duration-300 group-hover:scale-105"
              />
              <button
                onClick={(e) => handleDelete(e, recipe)}
                className="absolute right-3 top-3 rounded-full bg-white px-3 py-1.5 text-xs font-bold text-red-600 opacity-0 shadow transition group-hover:opacity-100"
              >
                Sil
              </button>
            </div>
            <h2 className="mt-3 font-bold">{recipe.title}</h2>
            <p className="text-sm text-muted">
              {recipe.prepMinutes} dk · {recipe.ingredientCount} malzeme
            </p>
          </Link>
        ))}
      </div>

      {items.length === 0 && !error && <p className="mt-16 text-center text-muted">Tarif bulunamadı.</p>}

      {pageCount > 1 && (
        <div className="mt-12 flex items-center justify-center gap-4">
          <button
            disabled={page <= 1}
            onClick={() => setPage(page - 1)}
            className="rounded-full border border-line px-5 py-2 font-semibold transition hover:border-ink disabled:opacity-40"
          >
            ← Önceki
          </button>
          <span className="text-sm text-muted">
            {page} / {pageCount}
          </span>
          <button
            disabled={page >= pageCount}
            onClick={() => setPage(page + 1)}
            className="rounded-full border border-line px-5 py-2 font-semibold transition hover:border-ink disabled:opacity-40"
          >
            Sonraki →
          </button>
        </div>
      )}
    </main>
  );
}