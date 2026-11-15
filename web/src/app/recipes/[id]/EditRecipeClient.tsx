"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ArrowLeft, Camera, CheckCircle2, ExternalLink, ImageOff, Loader2, Upload } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import RecipeForm from "@/components/RecipeForm";
import RecipeImage from "@/components/RecipeImage";
import { ApiError } from "@/lib/api";
import {
  categoryLabel,
  getRecipe,
  removeRecipeImage,
  updateRecipe,
  uploadRecipeImage,
  type RecipeForEdit,
} from "@/lib/recipes";
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
  const [busy, setBusy] = useState<"upload" | "remove" | null>(null);
  const [photoError, setPhotoError] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);

  useEffect(() => {
    if (!me) return;
    getRecipe(id)
      .then(setRecipe)
      .catch(() => setError("Tarif bulunamadı."));
  }, [me, id]);

  async function handleFile(file: File | undefined) {
    if (!file || !recipe) return;
    setPhotoError(null);

    if (!ALLOWED.includes(file.type)) return setPhotoError("Sadece JPEG, PNG veya WebP yükleyebilirsiniz.");
    if (file.size > MAX_BYTES) return setPhotoError("Fotoğraf 5 MB'ı geçemez.");

    setBusy("upload");
    try {
      const result = await uploadRecipeImage(id, file);
      setRecipe({ ...recipe, imageUrl: result.imageUrl });
    } catch (err) {
      setPhotoError(err instanceof ApiError ? err.message : "Fotoğraf yüklenemedi.");
    } finally {
      setBusy(null);
      if (fileInput.current) fileInput.current.value = "";
    }
  }

  async function handleRemove() {
    if (!recipe || !confirm("Bu tarifin fotoğrafı kaldırılsın mı?")) return;
    setPhotoError(null);
    setBusy("remove");
    try {
      await removeRecipeImage(id);
      setRecipe({ ...recipe, imageUrl: "" });
    } catch (err) {
      setPhotoError(err instanceof ApiError ? err.message : "Fotoğraf kaldırılamadı.");
    } finally {
      setBusy(null);
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

  const searchTerm = encodeURIComponent(recipe.title);

  return (
    <AdminShell me={me} title={recipe.title} subtitle={categoryLabel(recipe.category)} back={back}>
      {saved && (
        <div className="mb-6 flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm font-semibold text-green-800">
          <CheckCircle2 className="h-4 w-4" /> Değişiklikler kaydedildi.
        </div>
      )}

      {/* Fotoğraf kartı */}
      <section className="mb-6 rounded-xl border border-line bg-white p-6">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h2 className="font-bold">Fotoğraf</h2>
            <p className="mt-0.5 text-sm text-muted">JPEG, PNG veya WebP · en fazla 5 MB · sürükle-bırak desteklenir</p>
          </div>
          <div className="flex gap-2">
            {recipe.imageUrl && (
              <button
                type="button"
                onClick={handleRemove}
                disabled={busy !== null}
                className="inline-flex items-center gap-2 rounded-lg border border-neutral-300 bg-white px-3.5 py-2 text-sm font-semibold text-neutral-700 transition hover:border-red-300 hover:text-red-600 disabled:opacity-60"
              >
                {busy === "remove" ? <Loader2 className="h-4 w-4 animate-spin" /> : <ImageOff className="h-4 w-4" />}
                Kaldır
              </button>
            )}
            <button
              type="button"
              onClick={() => fileInput.current?.click()}
              disabled={busy !== null}
              className="inline-flex items-center gap-2 rounded-lg bg-basil px-3.5 py-2 text-sm font-semibold text-white transition hover:bg-basil-dark disabled:opacity-60"
            >
              {busy === "upload" ? <Loader2 className="h-4 w-4 animate-spin" /> : <Camera className="h-4 w-4" />}
              {busy === "upload" ? "Yükleniyor…" : recipe.imageUrl ? "Değiştir" : "Fotoğraf yükle"}
            </button>
          </div>
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
          <RecipeImage key={recipe.imageUrl} path={recipe.imageUrl} alt={recipe.title} category={recipe.category} />
          {dragging && (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 border-2 border-dashed border-white bg-forest/75 text-white">
              <Upload className="h-8 w-8" strokeWidth={1.5} />
              <span className="font-semibold">Bırakın, yükleyelim</span>
            </div>
          )}
        </div>

        {/* Ücretsiz fotoğraf sitelerinde bu tarifi ara */}
        <div className="mt-4 flex flex-wrap items-center gap-2 text-sm">
          <span className="text-muted">Ücretsiz fotoğraf bul:</span>
          <a
            href={`https://www.pexels.com/search/${searchTerm}/`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-1.5 font-semibold transition hover:border-basil hover:text-basil"
          >
            Pexels <ExternalLink className="h-3.5 w-3.5" />
          </a>
          <a
            href={`https://unsplash.com/s/photos/${searchTerm}?license=free`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-1.5 font-semibold transition hover:border-basil hover:text-basil"
          >
            Unsplash <ExternalLink className="h-3.5 w-3.5" />
          </a>
        </div>

        <input
          ref={fileInput}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          className="hidden"
          onChange={(e) => handleFile(e.target.files?.[0])}
        />

        {photoError && (
          <p className="mt-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {photoError}
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