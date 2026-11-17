"use client";

import { useCallback } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";

type Changes = Record<string, string | number | null>;

// Liste sayfalarının durumunu (sayfa, arama, kategori) adres çubuğunda tutar.
// Böylece geri dönünce / yenileyince / link paylaşınca aynı yer açılır.
export function useListQuery() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  const page = Math.max(1, Number(params.get("page")) || 1);
  const search = params.get("q") ?? "";
  const category = params.get("category");
  const query = params.toString();

  const update = useCallback(
    (changes: Changes) => {
      const next = new URLSearchParams(params.toString());
      for (const [key, value] of Object.entries(changes)) {
        // Varsayılan değerleri adrese yazma: /?page=1 yerine sadece /
        if (value === null || value === "" || (key === "page" && value === 1)) next.delete(key);
        else next.set(key, String(value));
      }
      const qs = next.toString();
      // replace: her sayfa değişimi geçmişe kayıt eklemesin; scroll: false: sayfa yukarı zıplamasın
      router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
    },
    [params, pathname, router],
  );

  return { page, search, category, query, update };
}