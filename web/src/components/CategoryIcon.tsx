import {
  CakeSlice,
  CookingPot,
  Cookie,
  Croissant,
  EggFried,
  LayoutGrid,
  Salad,
  Soup,
  type LucideIcon,
} from "lucide-react";

const ICONS: Record<string, LucideIcon> = {
  MainCourse: CookingPot,
  Soup: Soup,
  Salad: Salad,
  Breakfast: EggFried,
  Pastry: Croissant,
  Dessert: CakeSlice,
  Snack: Cookie,
};

// Her kategorinin renk paleti: açık zemin, koyu yazı, seçili çerçeve
export const CATEGORY_STYLES: Record<string, { soft: string; ring: string }> = {
  all: { soft: "bg-[#e3ece4] text-[#1d3a2a]", ring: "ring-[#1d3a2a]" },
  MainCourse: { soft: "bg-[#fbe9e2] text-[#b4532a]", ring: "ring-[#b4532a]" },
  Soup: { soft: "bg-[#fdf1d8] text-[#a86a0c]", ring: "ring-[#a86a0c]" },
  Salad: { soft: "bg-[#e4f1e1] text-[#2f7a3b]", ring: "ring-[#2f7a3b]" },
  Breakfast: { soft: "bg-[#fef6c9] text-[#8a6d00]", ring: "ring-[#8a6d00]" },
  Pastry: { soft: "bg-[#f4e8d8] text-[#8b5a2b]", ring: "ring-[#8b5a2b]" },
  Dessert: { soft: "bg-[#fbe4ec] text-[#b23a68]", ring: "ring-[#b23a68]" },
  Snack: { soft: "bg-[#ece6fa] text-[#6b46c1]", ring: "ring-[#6b46c1]" },
};

export function categoryStyle(category: string | null) {
  return CATEGORY_STYLES[category ?? "all"] ?? CATEGORY_STYLES.all;
}

export default function CategoryIcon({ category, className }: { category: string | null; className?: string }) {
  const Icon = (category && ICONS[category]) || LayoutGrid;
  return <Icon className={className} strokeWidth={1.75} />;
}