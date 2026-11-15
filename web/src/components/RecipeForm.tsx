"use client";

import { useEffect, useState, type SyntheticEvent } from "react";
import { ApiError } from "@/lib/api";
import {
  UNITS,
  mediaUrl,
  searchIngredients,
  type IngredientOption,
  type RecipeIngredientInput,
  type RecipeInput,
} from "@/lib/recipes";

type Props = {
  initial?: RecipeInput;
  submitLabel: string;
  onSubmit: (data: RecipeInput) => Promise<void>;
};

const EMPTY: RecipeInput = {
  title: "",
  description: "",
  emoji: "🍽️",
  prepMinutes: 30,
  servings: 2,
  ingredients: [],
  steps: [""],
};

const inputClass =
  "w-full rounded-xl border border-neutral-300 px-4 py-3 outline-none transition focus:border-ink focus:ring-1 focus:ring-ink";

export default function RecipeForm({ initial, submitLabel, onSubmit }: Props) {
  const [form, setForm] = useState<RecipeInput>(initial ?? EMPTY);
  const [query, setQuery] = useState("");
  const [options, setOptions] = useState<IngredientOption[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Malzeme arama: yazmayı bırakınca Pantry servisine sor
  useEffect(() => {
    const q = query.trim();
    if (!q) return;
    const timer = setTimeout(() => {
      searchIngredients(q).then(setOptions).catch(() => setOptions([]));
    }, 250);
    return () => clearTimeout(timer);
  }, [query]);

  function update<K extends keyof RecipeInput>(key: K, value: RecipeInput[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  // ─── Malzemeler ───────────────────────────────────────────
  function addIngredient(o: IngredientOption) {
    if (!form.ingredients.some((i) => i.ingredientId === o.id)) {
      update("ingredients", [
        ...form.ingredients,
        { ingredientId: o.id, name: o.name, quantity: 1, unit: o.defaultUnit, isOptional: false },
      ]);
    }
    setQuery("");
    setOptions([]);
  }

  function updateIngredient(index: number, patch: Partial<RecipeIngredientInput>) {
    update(
      "ingredients",
      form.ingredients.map((i, idx) => (idx === index ? { ...i, ...patch } : i)),
    );
  }

  function removeIngredient(index: number) {
    update("ingredients", form.ingredients.filter((_, idx) => idx !== index));
  }

  // ─── Adımlar ──────────────────────────────────────────────
  function updateStep(index: number, text: string) {
    update("steps", form.steps.map((s, idx) => (idx === index ? text : s)));
  }

  function moveStep(index: number, direction: -1 | 1) {
    const target = index + direction;
    if (target < 0 || target >= form.steps.length) return;
    const steps = [...form.steps];
    [steps[index], steps[target]] = [steps[target], steps[index]];
    update("steps", steps);
  }

  function removeStep(index: number) {
    update("steps", form.steps.filter((_, idx) => idx !== index));
  }

  async function handleSubmit(e: SyntheticEvent) {
    e.preventDefault();
    setError(null);
    setSaving(true);
    try {
      await onSubmit({ ...form, steps: form.steps.map((s) => s.trim()).filter(Boolean) });
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Kaydedilemedi.");
    } finally {
      setSaving(false);
    }
  }

  const visibleOptions = query.trim() ? options : [];

  return (
    <form onSubmit={handleSubmit} className="space-y-10 pb-28">
      {/* Genel bilgiler */}
      <section className="space-y-4">
        <h2 className="text-xl font-extrabold">Genel bilgiler</h2>
        <div className="flex gap-3">
          <input
            value={form.emoji}
            onChange={(e) => update("emoji", e.target.value)}
            className={`${inputClass} w-20 text-center text-2xl`}
            aria-label="Emoji"
          />
          <input
            required
            value={form.title}
            onChange={(e) => update("title", e.target.value)}
            placeholder="Tarif adı (ör. Karnıyarık)"
            className={inputClass}
          />
        </div>
        <textarea
          value={form.description}
          onChange={(e) => update("description", e.target.value)}
          placeholder="Kısa açıklama"
          rows={2}
          className={inputClass}
        />
        <div className="grid grid-cols-2 gap-3">
          <label className="text-sm font-semibold text-muted">
            Süre (dakika)
            <input
              type="number"
              min={1}
              value={form.prepMinutes}
              onChange={(e) => update("prepMinutes", Number(e.target.value) || 0)}
              className={`${inputClass} mt-1 text-base text-ink`}
            />
          </label>
          <label className="text-sm font-semibold text-muted">
            Kaç kişilik
            <input
              type="number"
              min={1}
              value={form.servings}
              onChange={(e) => update("servings", Number(e.target.value) || 0)}
              className={`${inputClass} mt-1 text-base text-ink`}
            />
          </label>
        </div>
      </section>

      {/* Malzemeler */}
      <section className="space-y-4">
        <h2 className="text-xl font-extrabold">Malzemeler</h2>

        <div className="relative">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Malzeme ara ve ekle… (ör. domates)"
            className={`${inputClass} rounded-full px-6`}
          />
          {visibleOptions.length > 0 && (
            <ul className="absolute z-10 mt-2 max-h-72 w-full overflow-auto rounded-2xl border border-line bg-white p-2 shadow-[0_8px_30px_rgba(0,0,0,0.12)]">
              {visibleOptions.map((o) => (
                <li key={o.id}>
                  <button
                    type="button"
                    onClick={() => addIngredient(o)}
                    className="flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left transition hover:bg-neutral-100"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={mediaUrl(o.imageUrl)} alt="" className="h-10 w-10 rounded-lg object-cover" />
                    <span className="font-semibold">{o.name}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        {form.ingredients.length === 0 && (
          <p className="text-sm text-muted">Henüz malzeme eklenmedi.</p>
        )}

        <ul className="divide-y divide-line">
          {form.ingredients.map((ing, index) => (
            <li key={ing.ingredientId} className="flex items-center gap-3 py-3">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={mediaUrl(`/images/ingredients/${ing.ingredientId}.jpg`)}
                alt=""
                className="h-12 w-12 rounded-xl object-cover"
              />
              <span className="flex-1 font-semibold">{ing.name}</span>
              <input
                type="number"
                min={0}
                step="any"
                value={ing.quantity}
                onChange={(e) => updateIngredient(index, { quantity: Number(e.target.value) || 0 })}
                className="w-24 rounded-lg border border-neutral-300 px-3 py-2 text-right outline-none focus:border-ink"
              />
              <select
                value={ing.unit}
                onChange={(e) => updateIngredient(index, { unit: e.target.value })}
                className="rounded-lg border border-neutral-300 px-3 py-2 outline-none focus:border-ink"
              >
                {UNITS.map((u) => (
                  <option key={u.value} value={u.value}>
                    {u.label}
                  </option>
                ))}
              </select>
              <label className="flex items-center gap-1.5 text-sm text-muted">
                <input
                  type="checkbox"
                  checked={ing.isOptional}
                  onChange={(e) => updateIngredient(index, { isOptional: e.target.checked })}
                />
                isteğe bağlı
              </label>
              <button
                type="button"
                onClick={() => removeIngredient(index)}
                className="rounded-full px-2 text-xl text-muted transition hover:text-red-600"
                aria-label="Malzemeyi kaldır"
              >
                ×
              </button>
            </li>
          ))}
        </ul>
      </section>

      {/* Hazırlanışı */}
      <section className="space-y-4">
        <h2 className="text-xl font-extrabold">Hazırlanışı</h2>
        {form.steps.map((step, index) => (
          <div key={index} className="flex gap-3">
            <span className="mt-2 flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 border-ink font-extrabold">
              {index + 1}
            </span>
            <textarea
              value={step}
              onChange={(e) => updateStep(index, e.target.value)}
              placeholder="Bu adımda ne yapılıyor?"
              rows={2}
              className={inputClass}
            />
            <div className="flex flex-col gap-1 text-muted">
              <button type="button" onClick={() => moveStep(index, -1)} className="hover:text-ink" aria-label="Yukarı">↑</button>
              <button type="button" onClick={() => moveStep(index, 1)} className="hover:text-ink" aria-label="Aşağı">↓</button>
              <button type="button" onClick={() => removeStep(index)} className="hover:text-red-600" aria-label="Sil">×</button>
            </div>
          </div>
        ))}
        <button
          type="button"
          onClick={() => update("steps", [...form.steps, ""])}
          className="rounded-xl border border-dashed border-neutral-400 px-5 py-2.5 font-semibold text-muted transition hover:border-ink hover:text-ink"
        >
          + Adım ekle
        </button>
      </section>

      {/* Alt sabit çubuk */}
      <div className="fixed inset-x-0 bottom-0 border-t border-line bg-white">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-6 py-4">
          <p className="text-sm font-medium text-red-700">{error}</p>
          <button
            type="submit"
            disabled={saving}
            className="rounded-xl bg-basil px-8 py-3.5 font-bold text-white transition hover:bg-basil-dark disabled:opacity-60"
          >
            {saving ? "Kaydediliyor…" : submitLabel}
          </button>
        </div>
      </div>
    </form>
  );
}