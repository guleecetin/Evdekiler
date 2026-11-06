using Evdekiler.Pantry.Api.Entities;

namespace Evdekiler.Pantry.Api.Data;

public static class IngredientSeed
{
    private static Ingredient I(int id, string name, string emoji, IngredientCategory c, MeasureUnit u) =>
        new() { Id = id, Name = name, Emoji = emoji, Category = c, DefaultUnit = u };

    public static readonly Ingredient[] All =
    [
        I(1,  "Domates",       "🍅", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(2,  "Salatalık",     "🥒", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(3,  "Biber",         "🫑", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(4,  "Soğan",         "🧅", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(5,  "Sarımsak",      "🧄", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(6,  "Patates",       "🥔", IngredientCategory.Vegetable, MeasureUnit.Kilogram),
        I(7,  "Havuç",         "🥕", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(8,  "Kabak",         "🥒", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(9,  "Patlıcan",      "🍆", IngredientCategory.Vegetable, MeasureUnit.Piece),
        I(10, "Ispanak",       "🥬", IngredientCategory.Vegetable, MeasureUnit.Gram),
        I(11, "Limon",         "🍋", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(12, "Elma",          "🍎", IngredientCategory.Fruit,     MeasureUnit.Piece),
        I(13, "Süt",           "🥛", IngredientCategory.Dairy,     MeasureUnit.Liter),
        I(14, "Yoğurt",        "🥣", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(15, "Beyaz peynir",  "🧀", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(16, "Kaşar peyniri", "🧀", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(17, "Tereyağı",      "🧈", IngredientCategory.Dairy,     MeasureUnit.Gram),
        I(18, "Yumurta",       "🥚", IngredientCategory.Dairy,     MeasureUnit.Piece),
        I(19, "Tavuk göğsü",   "🍗", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(20, "Kıyma",         "🥩", IngredientCategory.Meat,      MeasureUnit.Gram),
        I(21, "Pirinç",        "🍚", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(22, "Makarna",       "🍝", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(23, "Bulgur",        "🌾", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(24, "Un",            "🌾", IngredientCategory.Grain,     MeasureUnit.Gram),
        I(25, "Mercimek",      "🫘", IngredientCategory.Legume,    MeasureUnit.Gram),
        I(26, "Nohut",         "🫘", IngredientCategory.Legume,    MeasureUnit.Gram),
        I(27, "Salça",         "🥫", IngredientCategory.Other,     MeasureUnit.Gram),
        I(28, "Zeytinyağı",    "🫒", IngredientCategory.Other,     MeasureUnit.Milliliter),
        I(29, "Tuz",           "🧂", IngredientCategory.Spice,     MeasureUnit.Gram),
        I(30, "Pul biber",     "🌶️", IngredientCategory.Spice,     MeasureUnit.Gram)
    ];
}