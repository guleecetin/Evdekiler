"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, Camera, ImageOff, ImagePlus, Upload } from "lucide-react";
import AdminShell from "@/components/AdminShell";
import PageLoader from "@/components/PageLoader";
import RecipeForm from "@/components/RecipeForm";
import { createRecipe, uploadRecipeImage } from "@/lib/recipes";
import { useAdmin } from "@/lib/useAdmin";

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = ["image/jpeg", "image/png", "image/webp"];

export default function NewRecipePage() {
  const me = useAdmin();
  const router = useRouter();
  const fileInput = useRef<HTMLInputElement>(null);

  const [photo, setPhoto] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [photoError, setPhotoError] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);

  // Seçilen dosyanın tarayıcıdaki geçici adresi; dosya değişince eskisi bellekten silinir
  useEffect(() => {
    if (!photo) {
      setPreview(null);
      return;
    }
    const url = URL.createObjectURL(photo);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [photo]);

  if (!me) return <PageLoader />;

  function pick(file: File | undefined) {
    if (!file) return;
    setPhotoError(null);
    if (!ALLOWED.includes(file.type)) return setPhotoError("Sadece JPEG, PNG ya da WebP seçebilirsiniz.");
    if (file.size > MAX_BYTES) return setPhotoError("Fotoğraf 5 MB'ı geçemez.");
    setPhoto(file);
    if (fileInput.current) fileInput.current.value = "";
  }

  return (
    <AdminShell
      me={me}
      title="Yeni tarif"
      subtitle="Fotoğrafı, bilgileri ve malzemeleri doldurun; hepsi tek seferde kaydedilir."
      back={
        <Link href="/" className="mb-4 inline-flex items-center gap-1.5 text-sm font-semibold text-muted transition hover:text-forest">
          <ArrowLeft className="h-4 w-4" /> Tarifler
        </Link>
      }
    >
      {/* Fotoğraf seçimi: kaydedilene kadar sadece önizleme */}
      <section className="mb-6 rounded-2xl bg-white p-6 shadow-sm ring-1 ring-line">
        <div className="flex flex-col gap-6 sm:flex-row">
          <button
            type="button"
            onClick={() => fileInput.current?.click()}
            onDragOver={(e) => {
              e.preventDefault();
              setDragging(true);
            }}
            onDragLeave={() => setDragging(false)}
            onDrop={(e) => {
              e.preventDefault();
              setDragging(false);
              pick(e.dataTransfer.files[0]);
            }}
            className={`relative aspect-[4/3] w-full shrink-0 overflow-hidden rounded-xl transition sm:w-[300px] ${
              preview ? "ring-1 ring-line" : "border-2 border-dashed border-neutral-300 bg-cream hover:border-basil"
            }`}
          >
            {preview ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={preview} alt="Seçilen fotoğraf" className="h-full w-full object-cover" />
            ) : (
              <span className="flex h-full flex-col items-center justify-center gap-2 text-muted">
                <ImagePlus className="h-9 w-9 text-basil" strokeWidth={1.5} />
                <span className="text-sm font-semibold text-forest">Fotoğraf seç</span>
                <span className="text-xs">ya da buraya sürükleyip bırak</span>
              </span>
            )}

            {dragging && (
              <span className="absolute inset-0 flex flex-col items-center justify-center gap-2 border-2 border-dashed border-white bg-forest/80 text-white">
                <Upload className="h-7 w-7" strokeWidth={1.5} />
                <span className="text-sm font-semibold">Bırakın</span>
              </span>
            )}
          </button>

          <div className="flex min-w-0 flex-1 flex-col">
            <h2 className="text-[17px] font-bold text-forest">Fotoğraf</h2>
            <p className="mt-0.5 text-sm text-muted">
              {photo
                ? `${photo.name} seçildi. Tarifi oluşturduğunuzda yüklenecek.`
                : "İsteğe bağlı. Fotoğrafsız tarifler listede kategori renginde bir yer tutucuyla görünür."}
            </p>
            <p className="mt-2 text-xs text-neutral-500">JPEG, PNG ya da WebP, en fazla 5 MB.</p>

            <div className="mt-5 flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => fileInput.current?.click()}
                className="inline-flex items-center gap-2 rounded-lg bg-basil px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-basil-dark"
              >
                <Camera className="h-4 w-4" />
                {photo ? "Başka fotoğraf seç" : "Fotoğraf seç"}
              </button>
              {photo && (
                <button
                  type="button"
                  onClick={() => setPhoto(null)}
                  className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-neutral-600 ring-1 ring-neutral-200 transition hover:bg-red-50 hover:text-red-600 hover:ring-red-200"
                >
                  <ImageOff className="h-4 w-4" /> Kaldır
                </button>
              )}
            </div>

            {photoError && (
              <p className="mt-3 rounded-lg border border-red-200 bg-red-50 px-3.5 py-2.5 text-sm font-medium text-red-700">
                {photoError}
              </p>
            )}
          </div>
        </div>

        <input
          ref={fileInput}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          className="hidden"
          onChange={(e) => pick(e.target.files?.[0])}
        />
      </section>

      <RecipeForm
        submitLabel="Tarifi oluştur"
        onSubmit={async (data) => {
          // 1. Tarifi oluştur: hata olursa form kendi hata mesajını gösterir
          const created = await createRecipe(data);

          // 2. Fotoğraf varsa dönen Id ile yükle. Tarif artık var; burada hata olsa bile
          //    bu sayfada kalmıyoruz (tekrar denemek aynı tarifi ikinci kez oluştururdu).
          let photoFailed = false;
          if (photo) {
            try {
              await uploadRecipeImage(created.id, photo);
            } catch {
              photoFailed = true;
            }
          }

          router.push(`/recipes/${created.id}?created=1${photoFailed ? "&photo=failed" : ""}`);
        }}
      />
    </AdminShell>
  );
}