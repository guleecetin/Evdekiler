"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useParams, useSearchParams } from "next/navigation";
import { AlertTriangle, ArrowLeft, Camera, CheckCircle2, ExternalLink, ImageOff, Loader2, Upload } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import PageLoader from "@/components/PageLoader";
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
  const searchParams = useSearchParams();
  const id = Number(params.id);
  const fileInput = useRef<HTMLInputElement>(null);

  const [recipe, setRecipe] = useState<RecipeForEdit | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [busy, setBusy] = useState<"upload" | "remove" | null>(null);
  const [photoError, setPhotoError] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);
  const [confirmRemove, setConfirmRemove] = useState(false);

  // Yeni tarif sayfasından gelindiyse: oluşturuldu / fotoğraf yüklenemedi bilgisi
  const [notice, setNotice] = useState<"created" | "photo-failed" | null>(() =>
    searchParams.get("photo") === "failed" ? "photo-failed" : searchParams.get("created") ? "created" : null,
  );

  useEffect(() => {
    if (!me) return;
    getRecipe(id)
      .then(setRecipe)
      .catch(() => setError("Tarif bulunamadı."));
  }, [me, id]);

  useEffect(() => {
    if (!saved) return;
    const timer = setTimeout(() => setSaved(false), 4000);
    return () => clearTimeout(timer);
  }, [saved]);

  useEffect(() => {
    if (notice !== "created") return;
    const timer = setTimeout(() => setNotice(null), 5000);
    return () => clearTimeout(timer);
  }, [notice]);

  async function handleFile(file: File | undefined) {
    if (!file || !recipe) return;
    setPhotoError(null);
    setConfirmRemove(false);

    if (!ALLOWED.includes(file.type)) return setPhotoError("Sadece JPEG, PNG veya WebP yükleyebilirsiniz.");
    if (file.size > MAX_BYTES) return setPhotoError("Fotoğraf 5 MB'ı geçemez.");

    setBusy("upload");
    try {
      const result = await uploadRecipeImage(id, file);
      setRecipe({ ...recipe, imageUrl: result.imageUrl });
      if (notice === "photo-failed") setNotice(null);
    } catch (err) {
      setPhotoError(err instanceof ApiError ? err.message : "Fotoğraf yüklenemedi.");
    } finally {
      setBusy(null);
      if (fileInput.current) fileInput.current.value = "";
    }
  }

  async function handleRemove() {
    if (!recipe) return;
    setPhotoError(null);
    setBusy("remove");
    try {
      await removeRecipeImage(id);
      setRecipe({ ...recipe, imageUrl: "" });
      setConfirmRemove(false);
    } catch (err) {
      setPhotoError(err instanceof ApiError ? err.message : "Fotoğraf kaldırılamadı.");
    } finally {
      setBusy(null);
    }
  }

  if (!me || (!recipe && !error)) return <PageLoader />;

  const back = (
    <Link href="/" className="mb-4 inline-flex items-center gap-1.5 text-sm font-semibold text-muted transition hover:text-forest">
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
  const hasImage = Boolean(recipe.imageUrl);

  return (
    <AdminShell me={me} title={recipe.title} subtitle={categoryLabel(recipe.category)} back={back}>
      {notice === "created" && (
        <div className="mb-6 flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-semibold text-green-800">
          <CheckCircle2 className="h-4 w-4" /> Tarif oluşturuldu. Buradan düzenlemeye devam edebilirsiniz.
        </div>
      )}
      {notice === "photo-failed" && (
        <div className="mb-6 flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
          <p>
            <span className="font-semibold">Tarif kaydedildi ama fotoğraf yüklenemedi.</span> Aşağıdaki fotoğraf
            alanından tekrar deneyebilirsiniz.
          </p>
        </div>
      )}
      {saved && (
        <div className="mb-6 flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-semibold text-green-800">
          <CheckCircle2 className="h-4 w-4" /> Değişiklikler kaydedildi.
        </div>
      )}

      <section className="mb-6 rounded-2xl bg-white p-6 shadow-sm ring-1 ring-line">
        <div className="flex flex-col gap-6 sm:flex-row">
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
            className="relative aspect-[4/3] w-full shrink-0 overflow-hidden rounded-xl ring-1 ring-line sm:w-[300px]"
          >
            <RecipeImage key={recipe.imageUrl} path={recipe.imageUrl} alt={recipe.title} category={recipe.category} />

            {busy === "upload" && (
              <div className="absolute inset-0 flex items-center justify-center bg-white/70">
                <Loader2 className="h-7 w-7 animate-spin text-basil" />
              </div>
            )}

            {dragging && (
              <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 border-2 border-dashed border-white bg-forest/80 text-white">
                <Upload className="h-7 w-7" strokeWidth={1.5} />
                <span className="text-sm font-semibold">Bırakın, yükleyelim</span>
              </div>
            )}
          </div>

          <div className="flex min-w-0 flex-1 flex-col">
            <h2 className="text-[17px] font-bold text-forest">Fotoğraf</h2>
            <p className="mt-0.5 text-sm text-muted">
              {hasImage
                ? "Mobil uygulamada ve tarif listesinde bu fotoğraf görünür."
                : "Bu tarifin henüz fotoğrafı yok; listede kategori renginde bir yer tutucu görünüyor."}
            </p>
            <p className="mt-2 flex items-center gap-1.5 text-xs text-neutral-500">
              <Upload className="h-3.5 w-3.5" /> JPEG, PNG ya da WebP, en fazla 5 MB. Önizlemenin üzerine sürükleyip
              bırakabilirsiniz.
            </p>

            <div className="mt-5 flex flex-wrap items-center gap-2">
              <button
                type="button"
                onClick={() => fileInput.current?.click()}
                disabled={busy !== null}
                className="inline-flex items-center gap-2 rounded-lg bg-basil px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-basil-dark disabled:opacity-60"
              >
                <Camera className="h-4 w-4" />
                {hasImage ? "Fotoğrafı değiştir" : "Fotoğraf yükle"}
              </button>

              {hasImage && !confirmRemove && (
                <button
                  type="button"
                  onClick={() => setConfirmRemove(true)}
                  disabled={busy !== null}
                  className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-neutral-600 ring-1 ring-neutral-200 transition hover:bg-red-50 hover:text-red-600 hover:ring-red-200 disabled:opacity-60"
                >
                  <ImageOff className="h-4 w-4" /> Kaldır
                </button>
              )}

              {hasImage && confirmRemove && (
                <div className="flex items-center gap-2 rounded-lg bg-red-50 py-1 pl-3 pr-1 ring-1 ring-red-200">
                  <span className="text-sm font-medium text-red-700">Fotoğraf kaldırılsın mı?</span>
                  <button
                    type="button"
                    onClick={handleRemove}
                    disabled={busy !== null}
                    className="inline-flex items-center gap-1.5 rounded-md bg-red-600 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-red-700 disabled:opacity-60"
                  >
                    {busy === "remove" && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
                    Evet, kaldır
                  </button>
                  <button
                    type="button"
                    onClick={() => setConfirmRemove(false)}
                    disabled={busy !== null}
                    className="rounded-md px-2.5 py-1.5 text-xs font-semibold text-red-700 hover:bg-red-100"
                  >
                    Vazgeç
                  </button>
                </div>
              )}
            </div>

            {photoError && (
              <p className="mt-3 rounded-lg border border-red-200 bg-red-50 px-3.5 py-2.5 text-sm font-medium text-red-700">
                {photoError}
              </p>
            )}

            <div className="mt-auto flex flex-wrap items-center gap-2 border-t border-line pt-4 text-sm max-sm:mt-5">
              <span className="text-muted">Ücretsiz fotoğraf bul:</span>
              <a
                href={`https://www.pexels.com/search/${searchTerm}/`}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 font-semibold ring-1 ring-line transition hover:text-basil hover:ring-basil"
              >
                Pexels <ExternalLink className="h-3.5 w-3.5" />
              </a>
              <a
                href={`https://unsplash.com/s/photos/${searchTerm}?license=free`}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 font-semibold ring-1 ring-line transition hover:text-basil hover:ring-basil"
              >
                Unsplash <ExternalLink className="h-3.5 w-3.5" />
              </a>
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
      </section>

      <RecipeForm
        initial={recipe}
        submitLabel="Değişiklikleri kaydet"
        onSubmit={async (data) => {
          await updateRecipe(id, data);
          setRecipe({ ...recipe, ...data });
          setSaved(true);
          window.scrollTo({ top: 0, behavior: "smooth" });
        }}
      />
    </AdminShell>
  );
}