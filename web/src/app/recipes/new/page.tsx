"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import RecipeForm from "@/components/RecipeForm";
import { createRecipe } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

export default function NewRecipePage() {
  const me = useAdmin();
  const router = useRouter();

  if (!me) return <main className="p-10 text-muted">Yükleniyor…</main>;

  return (
    <AdminShell
      me={me}
      title="Yeni tarif"
      subtitle="Tarifi kaydettikten sonra fotoğrafını ekleyebilirsiniz."
      back={
        <Link href="/" className="mb-4 inline-flex items-center gap-1.5 text-sm font-semibold text-muted hover:text-ink">
          <ArrowLeft className="h-4 w-4" /> Tarifler
        </Link>
      }
    >
      <RecipeForm
        submitLabel="Tarifi oluştur"
        onSubmit={async (data) => {
          const created = await createRecipe(data);
          router.push(`/recipes/${created.id}`);
        }}
      />
    </AdminShell>
  );
}