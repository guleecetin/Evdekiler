import { api } from "./api";

export const INGREDIENT_CATEGORIES = [
  { value: "Vegetable", label: "Sebze" },
  { value: "Fruit", label: "Meyve" },
  { value: "Dairy", label: "Süt & Yumurta" },
  { value: "Meat", label: "Et, Tavuk & Balık" },
  { value: "Grain", label: "Tahıl & Unlu" },
  { value: "Legume", label: "Bakliyat" },
  { value: "Spice", label: "Baharat" },
  { value: "Other", label: "Diğer" },
] as const;

export const MEASURE_UNITS = [
  { value: "Piece", label: "Adet" },
  { value: "Gram", label: "Gram" },
  { value: "Kilogram", label: "Kilogram" },
  { value: "Milliliter", label: "Mililitre" },
  { value: "Liter", label: "Litre" },
] as const;

export type IngredientCategory = (typeof INGREDIENT_CATEGORIES)[number]["value"];
export type MeasureUnit = (typeof MEASURE_UNITS)[number]["value"];

export type AdminIngredient = {
  id: number;
  name: string;
  emoji: string;
  imageUrl: string;
  category: IngredientCategory;
  defaultUnit: MeasureUnit;
};

export type IngredientInput = Omit<AdminIngredient, "id" | "imageUrl">;

export type IngredientPage = { items: AdminIngredient[]; page: number; pageSize: number; totalCount: number };

export const ingredientCategoryLabel = (v: string) =>
  INGREDIENT_CATEGORIES.find((c) => c.value === v)?.label ?? v;

export const unitLabel = (v: string) => MEASURE_UNITS.find((u) => u.value === v)?.label ?? v;

export function listIngredients(page: number, pageSize: number, search: string, category: string | null) {
  const query = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (search) query.set("search", search);
  if (category) query.set("category", category);
  return api<IngredientPage>(`/api/admin/ingredients?${query}`);
}

export function createIngredient(input: IngredientInput) {
  return api<{ id: number }>("/api/admin/ingredients", { method: "POST", body: input });
}

export function updateIngredient(id: number, input: IngredientInput) {
  return api<void>(`/api/admin/ingredients/${id}`, { method: "PUT", body: input });
}