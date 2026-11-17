import { Suspense } from "react";
import EditRecipeClient from "./EditRecipeClient";

// Adresteki id ancak istek anında belli olduğu için o kısmı Suspense içine alıyoruz
export default function EditRecipePage() {
  return (
    <Suspense fallback={<PageLoader />}>
      <EditRecipeClient />
    </Suspense>
  );
}