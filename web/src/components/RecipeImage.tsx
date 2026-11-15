"use client";

import { useState } from "react";
import { mediaUrl } from "@/lib/recipes";

// Fotoğraf yoksa ya da yüklenemezse yer tutucu gösterir
export default function RecipeImage({ path, alt, className = "" }: { path: string; alt: string; className?: string }) {
  const [failed, setFailed] = useState(false);

  if (failed || !path) {
    return (
      <div className={`flex h-full w-full flex-col items-center justify-center gap-1 bg-cream text-muted ${className}`}>
        <span className="text-3xl">📷</span>
        <span className="text-xs font-semibold">Fotoğraf yok</span>
      </div>
    );
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={mediaUrl(path)}
      alt={alt}
      onError={() => setFailed(true)}
      className={`h-full w-full object-cover ${className}`}
    />
  );
}