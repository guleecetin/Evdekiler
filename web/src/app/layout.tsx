import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const font = Plus_Jakarta_Sans({ subsets: ["latin", "latin-ext"] });

export const metadata: Metadata = {
  title: "Evdekiler Yönetim",
  description: "Evdekiler tarif yönetim paneli",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="tr">
      <body className={`${font.className} min-h-screen bg-white text-ink antialiased`}>
        {children}
      </body>
    </html>
  );
}