"use client";

import { useEffect, useState, type SyntheticEvent } from "react";
import { ChevronDown, ChevronUp, Plus, Search, Trash2, X } from "lucide-react";
import CategoryIcon from "@/components/CategoryIcon";
import { ApiError } from "@/lib/api";
import {
  CATEGORIES,
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
  category: "MainCourse",
  prepMinutes: 30,
  servings: 2,
  ingredients: [],
  steps: [""],
};

const inputClass =
  "w-full rounded-lg border border-neutral-300 bg-white px-3.5 py-2.5 text-sm outline-none transition focus:border-ink focus:ring-1 focus:ring-ink";
const labelClass = "mb-1.5 block text-sm font-semibold text-neutral-700";

function Card({ title, description, children }: { title: string; description?: string; children: React.ReactNode }) {
  return (
    <section className="rounded-xl border border-line bg-white p-6">
      <h2 className="font-bold">{title}</h2>
      {description && <p className="mt-0.5 text-sm text-muted">{description}</p>}
      <div className="mt-5">{children}</div>
    </section>
  );
}

export default function RecipeForm({ initial, submitLabel, onSubmit }: Props) {
  const [form, setForm] = useState<RecipeInput>(initial ?? EMPTY);
  const [query, setQuery] = useState("");
  const [options, setOptions] = useState<IngredientOption[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

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
    update("ingredients", form.ingredients.map((i, idx) => (idx === index ? { ...i, ...patch } : i)));
  }

  function removeIngredient(index: number) {
    update("ingredients", form.ingredients.filter((_, idx) => idx !== index));
  }

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
    <form onSubmit={handleSubmit} className="space-y-6 pb-28">
      <Card title="Genel bilgiler" description="Tarifin adı, kısa tanıtımı, süresi ve porsiyonu.">
        <div className="space-y-4">
          <div>
            <label className={labelClass}>Tarif adı</label>
            <input
              required
              value={form.title}
              onChange={(e) => update("title", e.target.value)}
              placeholder="ör. Karnıyarık"
              className={inputClass}
            />
          </div>
          <div>
            <label className={labelClass}>Açıklama</label>
            <textarea
              value={form.description}
              onChange={(e) => update("description", e.target.value)}
              placeholder="Tarifi birkaç cümleyle tanıtın"
              rows={3}
              className={inputClass}
            />
          </div>
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
            <div>
              <label className={labelClass}>Süre (dakika)</label>
              <input
                type="number"
                min={1}
                value={form.prepMinutes}
                onChange={(e) => update("prepMinutes", Number(e.target.value) || 0)}
                className={inputClass}
              />
            </div>
            <div>
              <label className={labelClass}>Porsiyon</label>
              <input
                type="number"
                min={1}
                value={form.servings}
                onChange={(e) => update("servings", Number(e.target.value) || 0)}
                className={inputClass}
              />
            </div>
            <div>
              <label className={labelClass}>Mobil simge</label>
              <input
                value={form.emoji}
                onChange={(e) => update("emoji", e.target.value)}
                className={`${inputClass} text-center`}
              />
            </div>
          </div>
        </div>
      </Card>

      <Card title="Kategori" description="Tarifin uygulamada hangi bölümde görüneceğini seçin.">
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {CATEGORIES.map((c) => {
            const selected = form.category === c.value;
            return (
              <button
                key={c.value}
                type="button"
                onClick={() => update("category", c.value)}
                className={`flex items-center gap-3 rounded-lg border p-3 text-left text-sm font-semibold transition ${
                  selected
                    ? "border-ink bg-neutral-50 ring-1 ring-ink"
                    : "border-neutral-300 hover:border-neutral-400"
                }`}
              >
                <span
                  className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${
                    selected ? "bg-ink text-white" : "bg-neutral-100 text-neutral-600"
                  }`}
                >
                  <CategoryIcon category={c.value} className="h-[18px] w-[18px]" />
                </span>
                {c.label}
              </button>
            );
          })}
        </div>
      </Card>

      <Card title="Malzemeler" description="Katalogdan arayıp ekleyin; miktar ve birimi belirleyin.">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Malzeme ara… (ör. domates)"
            className={`${inputClass} pl-10`}
          />
          {visibleOptions.length > 0 && (
            <ul className="absolute z-10 mt-2 max-h-72 w-full overflow-auto rounded-lg border border-line bg-white p-1.5 shadow-[0_8px_30px_rgba(0,0,0,0.12)]">
              {visibleOptions.map((o) => (
                <li key={o.id}>
                  <button
                    type="button"
                    onClick={() => addIngredient(o)}
                    className="flex w-full items-center gap-3 rounded-md px-2.5 py-2 text-left text-sm transition hover:bg-neutral-100"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img src={mediaUrl(o.imageUrl)} alt="" className="h-8 w-8 rounded-md object-cover" />
                    <span className="font-semibold">{o.name}</span>
                    <Plus className="ml-auto h-4 w-4 text-muted" />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        {form.ingredients.length === 0 ? (
          <p className="mt-4 rounded-lg border border-dashed border-neutral-300 py-6 text-center text-sm text-muted">
            Henüz malzeme eklenmedi.
          </p>
        ) : (
          <ul className="mt-4 divide-y divide-line rounded-lg border border-line">
            {form.ingredients.map((ing, index) => (
              <li key={ing.ingredientId} className="flex items-center gap-3 px-3 py-2.5">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={mediaUrl(`/images/ingredients/${ing.ingredientId}.jpg`)}
                  alt=""
                  className="h-9 w-9 rounded-md object-cover"
                />
                <span className="flex-1 text-sm font-semibold">{ing.name}</span>
                <input
                  type="number"
                  min={0}
                  step="any"
                  value={ing.quantity}
                  onChange={(e) => updateIngredient(index, { quantity: Number(e.target.value) || 0 })}
                  className="w-20 rounded-md border border-neutral-300 px-2.5 py-1.5 text-right text-sm outline-none focus:border-ink"
                />
                <select
                  value={ing.unit}
                  onChange={(e) => updateIngredient(index, { unit: e.target.value })}
                  className="rounded-md border border-neutral-300 px-2 py-1.5 text-sm outline-none focus:border-ink"
                >
                  {UNITS.map((u) => (
                    <option key={u.value} value={u.value}>
                      {u.label}
                    </option>
                  ))}
                </select>
                <label className="flex items-center gap-1.5 text-xs font-medium text-muted">
                  <input
                    type="checkbox"
                    checked={ing.isOptional}
                    onChange={(e) => updateIngredient(index, { isOptional: e.target.checked })}
                    className="accent-ink"
                  />
                  İsteğe bağlı
                </label>
                <button
                  type="button"
                  onClick={() => removeIngredient(index)}
                  title="Kaldır"
                  className="rounded-md p-1.5 text-muted transition hover:bg-neutral-100 hover:text-red-600"
                >
                  <X className="h-4 w-4" />
                </button>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <Card title="Hazırlanışı" description="Adımları sırasıyla yazın; oklarla yerlerini değiştirebilirsiniz.">
        <div className="space-y-3">
          {form.steps.map((step, index) => (
            <div key={index} className="flex gap-3">
              <span className="mt-1.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-neutral-100 text-xs font-bold text-neutral-700">
                {index + 1}
              </span>
              <textarea
                value={step}
                onChange={(e) => updateStep(index, e.target.value)}
                placeholder="Bu adımda neler yapılıyor?"
                rows={2}
                className={inputClass}
              />
              <div className="flex flex-col">
                <button type="button" onClick={() => moveStep(index, -1)} title="Yukarı" className="rounded-md p-1 text-muted hover:bg-neutral-100 hover:text-ink">
                  <ChevronUp className="h-4 w-4" />
                </button>
                <button type="button" onClick={() => moveStep(index, 1)} title="Aşağı" className="rounded-md p-1 text-muted hover:bg-neutral-100 hover:text-ink">
                  <ChevronDown className="h-4 w-4" />
                </button>
                <button type="button" onClick={() => removeStep(index)} title="Sil" className="rounded-md p-1 text-muted hover:bg-neutral-100 hover:text-red-600">
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
          ))}
          <button
            type="button"
            onClick={() => update("steps", [...form.steps, ""])}
            className="inline-flex items-center gap-2 rounded-lg border border-dashed border-neutral-400 px-4 py-2 text-sm font-semibold text-neutral-700 transition hover:border-ink hover:text-ink"
          >
            <Plus className="h-4 w-4" /> Adım ekle
          </button>
        </div>
      </Card>

      {/* Alt sabit çubuk */}
      <div className="fixed inset-x-0 bottom-0 z-20 border-t border-line bg-white/95 backdrop-blur lg:left-64">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-6 py-4 lg:px-10">
          <p className="text-sm font-medium text-red-700">{error}</p>
          <button
            type="submit"
            disabled={saving}
            className="rounded-lg bg-ink px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-neutral-800 disabled:opacity-60"
          >
            {saving ? "Kaydediliyor…" : submitLabel}
          </button>
        </div>
      </div>
    </form>
  );
}