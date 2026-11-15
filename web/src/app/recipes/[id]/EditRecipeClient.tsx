"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import RecipeForm from "@/components/RecipeForm";
import RecipeImage from "@/components/RecipeImage";
import { getRecipe, updateRecipe, type RecipeForEdit } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

export default function EditRecipeClient() {
  const me = useAdmin();
  const params = useParams<{ id: string }>();
  const id = Number(params.id);
  const [recipe, setRecipe] = useState<RecipeForEdit | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (!me) return;
    getRecipe(id)
      .then(setRecipe)
      .catch(() => setError("Tarif bulunamadı."));
  }, [me, id]);

  if (!me || (!recipe && !error)) return <main className="p-10 text-muted">Yükleniyor…</main>;

  return (
    <main className="mx-auto max-w-3xl px-6 py-10">
      <Link href="/" className="text-sm font-semibold text-muted hover:text-ink">
        ← Tarifler
      </Link>

      {error && <p className="mt-6 text-red-700">{error}</p>}

      {recipe && (
        <>
          <h1 className="mt-2 text-3xl font-extrabold tracking-tight">{recipe.title}</h1>

          <div className="mt-6 aspect-[16/9] overflow-hidden rounded-2xl">
            <RecipeImage path={recipe.imageUrl} alt={recipe.title} />
          </div>
          <p className="mt-2 text-sm text-muted">Fotoğrafı bir sonraki adımda buradan değiştirebileceksin.</p>

          {saved && (
            <p className="mt-6 rounded-xl bg-green-50 px-4 py-3 text-sm font-semibold text-green-800">
              Değişiklikler kaydedildi ✓
            </p>
          )}

          <div className="mt-8">
            <RecipeForm
              initial={recipe}
              submitLabel="Değişiklikleri kaydet"
              onSubmit={async (data) => {
                await updateRecipe(id, data);
                setSaved(true);
              }}
            />
          </div>
        </>
      )}
    </main>
  );
}