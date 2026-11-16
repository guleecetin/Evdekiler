import { api } from "./api";

export type Suggestion = {
  id: number;
  text: string;
  sampleLine: string;
  count: number;
  lastSeenAt: string;
  ingredientId: number;
  ingredientName: string;
  ingredientEmoji: string;
  ingredientImageUrl: string;
};

export function listSuggestions() {
  return api<Suggestion[]>("/api/admin/ingredients/suggestions");
}

export function approveSuggestion(id: number, alias: string) {
  return api<{ alias: string }>(`/api/admin/ingredients/suggestions/${id}/approve`, {
    method: "POST",
    body: { alias },
  });
}

export function rejectSuggestion(id: number) {
  return api<void>(`/api/admin/ingredients/suggestions/${id}`, { method: "DELETE" });
}