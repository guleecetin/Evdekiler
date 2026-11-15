import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getMe, type Me } from "./api";

// Sayfayı sadece admin'e açar; değilse giriş ekranına gönderir
export function useAdmin(): Me | null {
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

  return me;
}