using Evdekiler.Pantry.Api.Entities;

namespace Evdekiler.Pantry.Api.Data;

public static class IngredientSeed
{
    public static readonly Ingredient[] All =
    [
        new() { Id = 1,  Name = "Domates",       Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 2,  Name = "Salatalık",     Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 3,  Name = "Biber",         Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 4,  Name = "Soğan",         Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 5,  Name = "Sarımsak",      Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 6,  Name = "Patates",       Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Kilogram },
        new() { Id = 7,  Name = "Havuç",         Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 8,  Name = "Kabak",         Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 9,  Name = "Patlıcan",      Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Piece },
        new() { Id = 10, Name = "Ispanak",       Category = IngredientCategory.Vegetable, DefaultUnit = MeasureUnit.Gram },
        new() { Id = 11, Name = "Limon",         Category = IngredientCategory.Fruit,     DefaultUnit = MeasureUnit.Piece },
        new() { Id = 12, Name = "Elma",          Category = IngredientCategory.Fruit,     DefaultUnit = MeasureUnit.Piece },
        new() { Id = 13, Name = "Süt",           Category = IngredientCategory.Dairy,     DefaultUnit = MeasureUnit.Liter },
        new() { Id = 14, Name = "Yoğurt",        Category = IngredientCategory.Dairy,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 15, Name = "Beyaz peynir",  Category = IngredientCategory.Dairy,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 16, Name = "Kaşar peyniri", Category = IngredientCategory.Dairy,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 17, Name = "Tereyağı",      Category = IngredientCategory.Dairy,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 18, Name = "Yumurta",       Category = IngredientCategory.Dairy,     DefaultUnit = MeasureUnit.Piece },
        new() { Id = 19, Name = "Tavuk göğsü",   Category = IngredientCategory.Meat,      DefaultUnit = MeasureUnit.Gram },
        new() { Id = 20, Name = "Kıyma",         Category = IngredientCategory.Meat,      DefaultUnit = MeasureUnit.Gram },
        new() { Id = 21, Name = "Pirinç",        Category = IngredientCategory.Grain,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 22, Name = "Makarna",       Category = IngredientCategory.Grain,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 23, Name = "Bulgur",        Category = IngredientCategory.Grain,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 24, Name = "Un",            Category = IngredientCategory.Grain,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 25, Name = "Mercimek",      Category = IngredientCategory.Legume,    DefaultUnit = MeasureUnit.Gram },
        new() { Id = 26, Name = "Nohut",         Category = IngredientCategory.Legume,    DefaultUnit = MeasureUnit.Gram },
        new() { Id = 27, Name = "Salça",         Category = IngredientCategory.Other,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 28, Name = "Zeytinyağı",    Category = IngredientCategory.Other,     DefaultUnit = MeasureUnit.Milliliter },
        new() { Id = 29, Name = "Tuz",           Category = IngredientCategory.Spice,     DefaultUnit = MeasureUnit.Gram },
        new() { Id = 30, Name = "Pul biber",     Category = IngredientCategory.Spice,     DefaultUnit = MeasureUnit.Gram }
    ];
}