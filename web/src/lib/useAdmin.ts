"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getMe, type Me } from "./api";

// Oturum boyunca tek istek: ilk çağıran başlatır, herkes aynı Promise'i bekler.
// Strict Mode'un çift effect'i, aynı sayfadaki birden fazla bileşen ve
// sayfa geçişleri sunucuya tekrar gitmez.
let request: Promise<Me> | null = null;
let current: Me | null = null;

function loadAdmin(): Promise<Me> {
  request ??= getMe()
    .then((user) => {
      if (user.role !== "Admin") throw new Error("Yetkisiz");
      current = user;
      return user;
    })
    .catch((err) => {
      // Başarısızsa önbellekte tutma; bir sonraki deneme yeniden istesin
      request = null;
      current = null;
      throw err;
    });
  return request;
}

// Çıkışta çağrılır: başka hesapla girilince eski kullanıcı görünmesin
export function clearAdminCache() {
  request = null;
  current = null;
}

// Sayfayı sadece admin'e açar; değilse giriş ekranına gönderir
export function useAdmin(): Me | null {
  const router = useRouter();
  // Daha önce yüklendiyse ilk render'da hazır: yükleme ekranı yanıp sönmez,
  // ve her sayfada AYNI nesne döner (effect'ler boşuna tekrar çalışmaz)
  const [me, setMe] = useState<Me | null>(current);

  useEffect(() => {
    if (current) return;
    let alive = true;
    loadAdmin()
      .then((user) => {
        if (alive) setMe(user);
      })
      .catch(() => router.replace("/login"));
    return () => {
      alive = false;
    };
  }, [router]);

  return me;
}