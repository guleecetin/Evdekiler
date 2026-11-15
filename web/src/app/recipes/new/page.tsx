"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import RecipeForm from "@/components/RecipeForm";
import { createRecipe } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

export default function NewRecipePage() {
  const me = useAdmin();
  const router = useRouter();

  if (!me) return <main className="p-10 text-muted">Yükleniyor…</main>;

  return (
    <main className="mx-auto max-w-3xl px-6 py-10">
      <Link href="/" className="text-sm font-semibold text-muted hover:text-ink">
        ← Tarifler
      </Link>
      <h1 className="mt-2 text-3xl font-extrabold tracking-tight">Yeni tarif</h1>
      <div className="mt-8">
        <RecipeForm
          submitLabel="Tarifi oluştur"
          onSubmit={async (data) => {
            const created = await createRecipe(data);
            router.push(`/recipes/${created.id}`);
          }}
        />
      </div>
    </main>
  );
}