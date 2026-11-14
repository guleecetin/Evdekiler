import { api } from "./api";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5000";

export type RecipeListItem = {
  id: number;
  slug: string;
  title: string;
  imageUrl: string;
  prepMinutes: number;
  ingredientCount: number;
};

export type Paged<T> = {
  items: T[];
  page: number;
  pageSize: number;
  totalCount: number;
};

// "/media/recipes/x.jpg" -> "http://localhost:5000/media/recipes/x.jpg"
export function mediaUrl(path: string): string {
  return `${API_URL}${path}`;
}

export function listRecipes(page: number, pageSize: number, search: string) {
  const query = new URLSearchParams({ page: String(page), pageSize: String(pageSize) });
  if (search) query.set("search", search);
  return api<Paged<RecipeListItem>>(`/api/admin/recipes?${query}`);
}

export function deleteRecipe(id: number) {
  return api<void>(`/api/admin/recipes/${id}`, { method: "DELETE" });
}