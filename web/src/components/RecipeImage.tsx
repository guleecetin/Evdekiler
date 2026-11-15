"use client";

import { useState } from "react";
import CategoryIcon, { categoryStyle } from "@/components/CategoryIcon";
import { mediaUrl } from "@/lib/recipes";

type Props = { path: string; alt: string; category?: string; className?: string };

// Fotoğraf yoksa kategorinin renginde, ikonlu bir yer tutucu gösterir
export default function RecipeImage({ path, alt, category, className = "" }: Props) {
  const [failed, setFailed] = useState(false);

  if (failed || !path) {
    return (
      <div className={`flex h-full w-full flex-col items-center justify-center gap-2 ${categoryStyle(category ?? null).soft} ${className}`}>
        <CategoryIcon category={category ?? null} className="h-10 w-10 opacity-70" />
        <span className="text-xs font-semibold opacity-70">Fotoğraf eklenmedi</span>
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