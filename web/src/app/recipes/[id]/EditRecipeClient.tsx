"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, Camera, CheckCircle2, Loader2, Upload } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import RecipeForm from "@/components/RecipeForm";
import RecipeImage from "@/components/RecipeImage";
import { ApiError } from "@/lib/api";
import { categoryLabel, getRecipe, updateRecipe, uploadRecipeImage, type RecipeForEdit } from "@/lib/recipes";
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

    if (!ALLOWED.includes(file.type)) return setUploadError("Sadece JPEG, PNG veya WebP yükleyebilirsiniz.");
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

  const back = (
    <Link href="/" className="mb-4 inline-flex items-center gap-1.5 text-sm font-semibold text-muted hover:text-ink">
      <ArrowLeft className="h-4 w-4" /> Tarifler
    </Link>
  );

  if (!recipe) {
    return (
      <AdminShell me={me} title="Tarif bulunamadı" back={back}>
        <p className="text-sm text-muted">{error}</p>
      </AdminShell>
    );
  }

  return (
    <AdminShell me={me} title={recipe.title} subtitle={categoryLabel(recipe.category)} back={back}>
      {saved && (
        <div className="mb-6 flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm font-semibold text-green-800">
          <CheckCircle2 className="h-4 w-4" /> Değişiklikler kaydedildi.
        </div>
      )}

      {/* Fotoğraf kartı */}
      <section className="mb-6 rounded-xl border border-line bg-white p-6">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 className="font-bold">Fotoğraf</h2>
            <p className="mt-0.5 text-sm text-muted">JPEG, PNG veya WebP · en fazla 5 MB</p>
          </div>
          <button
            type="button"
            onClick={() => fileInput.current?.click()}
            disabled={uploading}
            className="inline-flex items-center gap-2 rounded-lg border border-neutral-300 bg-white px-3.5 py-2 text-sm font-semibold transition hover:border-neutral-400 disabled:opacity-60"
          >
            {uploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Camera className="h-4 w-4" />}
            {uploading ? "Yükleniyor…" : "Fotoğrafı değiştir"}
          </button>
        </div>

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
          className="relative mt-5 aspect-[16/9] overflow-hidden rounded-lg"
        >
          <RecipeImage key={recipe.imageUrl} path={recipe.imageUrl} alt={recipe.title} />
          {dragging && (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 border-2 border-dashed border-white bg-ink/70 text-white">
              <Upload className="h-8 w-8" strokeWidth={1.5} />
              <span className="font-semibold">Bırakın, yükleyelim</span>
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

        {uploadError && (
          <p className="mt-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {uploadError}
          </p>
        )}
      </section>

      <RecipeForm
        initial={recipe}
        submitLabel="Değişiklikleri kaydet"
        onSubmit={async (data) => {
          await updateRecipe(id, data);
          setRecipe({ ...recipe, ...data });
          setSaved(true);
        }}
      />
    </AdminShell>
  );
}