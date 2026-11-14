"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getMe, logout, type Me } from "@/lib/api";

export default function HomePage() {
  const router = useRouter();
  const [me, setMe] = useState<Me | null>(null);

  useEffect(() => {
    getMe()
      .then((user) => {
        if (user.role !== "Admin") throw new Error("Yetkisiz");
        setMe(user);
      })
      .catch(() => router.replace("/login"));
  }, [router]);

  if (!me) {
    return <main className="p-10 text-muted">Yükleniyor…</main>;
  }

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      <header className="flex items-center justify-between border-b border-line pb-6">
        <div>
          <p className="text-muted">Merhaba {me.displayName.split(" ")[0]} 👋</p>
          <h1 className="text-3xl font-extrabold tracking-tight">Tarifler</h1>
        </div>
        <button
          onClick={async () => {
            await logout();
            router.replace("/login");
          }}
          className="rounded-xl border border-ink px-5 py-2.5 font-bold transition hover:bg-neutral-100"
        >
          Çıkış yap
        </button>
      </header>

      <p className="mt-10 text-muted">Tarif listesi bir sonraki adımda buraya gelecek.</p>
    </main>
  );
}