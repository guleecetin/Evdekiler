"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import RecipeForm from "@/components/RecipeForm";
import RecipeImage from "@/components/RecipeImage";
import { ApiError } from "@/lib/api";
import { getRecipe, updateRecipe, uploadRecipeImage, type RecipeForEdit } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

export default function EditRecipeClient() {
  const me = useAdmin();
  const params = useParams<{ id: string }>();
  const id = Number(params.id);
  const fileInput = useRef<HTMLInputElement>(null);

  const [recipe, setRecipe] = useState<RecipeForEdit | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);

  useEffect(() => {
    if (!me) return;
    getRecipe(id)
      .then(setRecipe)
      .catch(() => setError("Tarif bulunamadı."));
  }, [me, id]);

  async function handleFile(file: File | undefined) {
    if (!file || !recipe) return;
    setUploadError(null);

    // Hızlı geri bildirim için tarayıcıda da kontrol (asıl kontrol backend'de)
    if (!ALLOWED.includes(file.type)) return setUploadError("Sadece JPEG, PNG veya WebP yükleyebilirsin.");
    if (file.size > MAX_BYTES) return setUploadError("Fotoğraf 5 MB'ı geçemez.");

    setUploading(true);
    try {
      const result = await uploadRecipeImage(id, file);
      setRecipe({ ...recipe, imageUrl: result.imageUrl });
    } catch (err) {
      setUploadError(err instanceof ApiError ? err.message : "Fotoğraf yüklenemedi.");
    } finally {
      setUploading(false);
      if (fileInput.current) fileInput.current.value = "";
    }
  }

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

          {/* Fotoğraf alanı: tıkla ya da sürükle-bırak */}
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
            className={`group relative mt-6 aspect-[16/9] overflow-hidden rounded-2xl transition ${
              dragging ? "ring-4 ring-basil" : ""
            }`}
          >
            {/* key: adres değişince bileşen sıfırlansın (eski "fotoğraf yok" durumu kalmasın) */}
            <RecipeImage key={recipe.imageUrl} path={recipe.imageUrl} alt={recipe.title} />

            <div className="absolute inset-0 flex items-center justify-center bg-black/0 transition group-hover:bg-black/30">
              <button
                type="button"
                onClick={() => fileInput.current?.click()}
                disabled={uploading}
                className="rounded-full bg-white px-6 py-3 font-bold opacity-0 shadow-lg transition group-hover:opacity-100 disabled:opacity-100"
              >
                {uploading ? "Yükleniyor…" : "📷 Fotoğrafı değiştir"}
              </button>
            </div>

            {dragging && (
              <div className="absolute inset-0 flex items-center justify-center bg-basil/80 text-xl font-bold text-white">
                Bırak, yükleyelim
              </div>
            )}
          </div>

          <input
            ref={fileInput}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0])}
          />

          <p className="mt-2 text-sm text-muted">
            Üzerine gelip tıkla ya da fotoğrafı sürükleyip bırak. JPEG, PNG veya WebP, en fazla 5 MB.
          </p>
          {uploadError && (
            <p className="mt-2 rounded-xl bg-red-50 px-4 py-3 text-sm font-medium text-red-700">{uploadError}</p>
          )}

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