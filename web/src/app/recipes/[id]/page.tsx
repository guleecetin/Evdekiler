import { Suspense } from "react";
import PageLoader from "../../../components/PageLoader";
import EditRecipeClient from "./EditRecipeClient";

// useSearchParams kullanan bileşen Suspense içinde olmalı (Next.js kuralı)
export default function EditRecipePage() {
  return (
    <Suspense fallback={<PageLoader />}>
      <EditRecipeClient />
    </Suspense>
  );
}