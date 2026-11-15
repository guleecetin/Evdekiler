import { api } from "./api";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5000";

// Backend'deki RecipeCategory enum'unun karşılığı
export const CATEGORIES = [
  { value: "MainCourse", label: "Ana yemek", emoji: "🍲" },
  { value: "Soup", label: "Çorba", emoji: "🥣" },
  { value: "Salad", label: "Salata", emoji: "🥗" },
  { value: "Breakfast", label: "Kahvaltılık", emoji: "🍳" },
  { value: "Pastry", label: "Hamur işi", emoji: "🥐" },
  { value: "Dessert", label: "Tatlı", emoji: "🍰" },
  { value: "Snack", label: "Atıştırmalık", emoji: "🥨" },
] as const;

export type RecipeCategory = (typeof CATEGORIES)[number]["value"];

export function categoryLabel(value: string): string {
  return CATEGORIES.find((c) => c.value === value)?.label ?? value;
}

export const UNITS = [
  { value: "Piece", label: "adet" },
  { value: "Gram", label: "g" },
  { value: "Kilogram", label: "kg" },
  { value: "Milliliter", label: "ml" },
  { value: "Liter", label: "L" },
];

export type RecipeListItem = {
  id: number;
  slug: string;
  title: string;
  imageUrl: string;
  category: RecipeCategory;
  prepMinutes: number;
  ingredientCount: number;
};

export type Paged<T> = { items: T[]; page: number; pageSize: number; totalCount: number };

export type IngredientOption = {
  id: number;
  name: string;
  emoji: string;
  imageUrl: string;
  defaultUnit: string;
};

export type RecipeIngredientInput = {
  ingredientId: number;
  name: string;
  quantity: number;
  unit: string;
  isOptional: boolean;
};

export type RecipeInput = {
  title: string;
  description: string;
  emoji: string;
  category: RecipeCategory;
  prepMinutes: number;
  servings: number;
  ingredients: RecipeIngredientInput[];
  steps: string[];
};

export type RecipeForEdit = RecipeInput & { id: number; imageUrl: string };

export function mediaUrl(path: string): string {
  return `${API_URL}${path}`;
}

export function listRecipes(page: number, pageSize: number, search: string, category: string | null) {
  const query = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (search) query.set("search", search);
  if (category) query.set("category", category);
  return api<Paged<RecipeListItem>>(`/api/admin/recipes?${query}`);
}

export async function getRecipe(id: number): Promise<RecipeForEdit> {
  const r = await api<RecipeForEdit>(`/api/recipes/${id}`);
  return {
    id: r.id,
    imageUrl: r.imageUrl,
    title: r.title,
    description: r.description,
    emoji: r.emoji,
    category: r.category,
    prepMinutes: r.prepMinutes,
    servings: r.servings,
    ingredients: r.ingredients.map((i) => ({
      ingredientId: i.ingredientId,
      name: i.name,
      quantity: i.quantity,
      unit: i.unit,
      isOptional: i.isOptional,
    })),
    steps: r.steps,
  };
}

export function createRecipe(input: RecipeInput) {
  return api<{ id: number; slug: string }>("/api/admin/recipes", { method: "POST", body: input });
}

export function updateRecipe(id: number, input: RecipeInput) {
  return api<void>(`/api/admin/recipes/${id}`, { method: "PUT", body: input });
}

export function deleteRecipe(id: number) {
  return api<void>(`/api/admin/recipes/${id}`, { method: "DELETE" });
}

export function searchIngredients(query: string) {
  return api<IngredientOption[]>(`/api/pantry/ingredients?search=${encodeURIComponent(query)}`);
}

export function uploadRecipeImage(id: number, file: File) {
  const form = new FormData();
  form.append("file", file);
  return api<{ id: number; imageUrl: string }>(`/api/admin/recipes/${id}/image`, {
    method: "POST",
    body: form,
  });
}