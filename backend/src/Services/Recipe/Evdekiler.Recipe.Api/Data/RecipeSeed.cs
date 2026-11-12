using Evdekiler.Recipe.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Recipe.Api.Data;

public static class RecipeSeed
{
    // dotnet ef database update bu senkron sürümü çağırır
    public static void Seed(DbContext context)
    {
        var db = (RecipeDbContext)context;
        if (db.Recipes.Any()) return; // Tablo doluysa hiçbir şey yapma

        db.Recipes.AddRange(Create());
        db.SaveChanges();
    }

    // Uygulama içinden çağrıldığında asenkron sürüm
    public static async Task SeedAsync(DbContext context, CancellationToken ct)
    {
        var db = (RecipeDbContext)context;
        if (await db.Recipes.AnyAsync(ct)) return;

        db.Recipes.AddRange(Create());
        await db.SaveChangesAsync(ct);
    }

    private static Entities.Recipe R(
        string title, string emoji, int minutes, int servings, string description,
        RecipeIngredient[] ingredients, string[] steps) => new()
        {
            Title = title,
            Emoji = emoji,
            PrepMinutes = minutes,
            Servings = servings,
            Description = description,
            Ingredients = [.. ingredients],
            Steps = steps.Select((text, i) => new RecipeStep { Order = i + 1, Text = text }).ToList()
        };

    private static RecipeIngredient I(int ingredientId, string name, decimal qty, string unit, bool optional = false) =>
        new() { IngredientId = ingredientId, IngredientName = name, Quantity = qty, Unit = unit, IsOptional = optional };

    private static List<Entities.Recipe> Create() =>
    [
        R("Menemen", "🍳", 15, 2, "Domates, biber ve yumurtanın klasik buluşması.",
            [I(1, "Domates", 3, "Piece"), I(3, "Biber", 2, "Piece"), I(18, "Yumurta", 3, "Piece"),
             I(17, "Tereyağı", 20, "Gram"), I(29, "Tuz", 5, "Gram", true), I(30, "Pul biber", 5, "Gram", true)],
            ["Biberleri doğrayıp tereyağında 3-4 dakika kavur.",
             "Doğranmış domatesleri ekle, suyunu çekene kadar pişir.",
             "Yumurtaları kır, hafifçe karıştır ve kıvamını alınca ocaktan al."]),

        R("Mercimek Çorbası", "🥣", 35, 4, "Limonla servis edilen, içi ısıtan klasik çorba.",
            [I(25, "Mercimek", 200, "Gram"), I(4, "Soğan", 1, "Piece"), I(7, "Havuç", 1, "Piece"),
             I(17, "Tereyağı", 30, "Gram"), I(27, "Salça", 15, "Gram"), I(11, "Limon", 1, "Piece", true)],
            ["Soğan ve havucu doğrayıp tereyağında kavur, salçayı ekle.",
             "Yıkanmış mercimeği ve 1,5 litre sıcak suyu ekle, 25 dakika pişir.",
             "Blenderdan geçir, limonla servis et."]),

        R("Patates Yemeği", "🥔", 40, 4, "Salçalı, sulu, ekmekle yenen ev yemeği.",
            [I(6, "Patates", 0.5m, "Kilogram"), I(4, "Soğan", 1, "Piece"), I(3, "Biber", 1, "Piece"),
             I(27, "Salça", 20, "Gram"), I(28, "Zeytinyağı", 30, "Milliliter")],
            ["Soğan ve biberi zeytinyağında kavur, salçayı ekle.",
             "Küp doğranmış patatesleri ve üzerini geçecek kadar su ekle.",
             "Patatesler yumuşayana kadar kısık ateşte pişir."]),

        R("Kıymalı Makarna", "🍝", 25, 3, "Domates soslu, doyurucu bir akşam yemeği.",
            [I(22, "Makarna", 250, "Gram"), I(20, "Kıyma", 200, "Gram"), I(1, "Domates", 2, "Piece"),
             I(4, "Soğan", 1, "Piece"), I(27, "Salça", 15, "Gram")],
            ["Makarnayı tuzlu suda haşla, süz.",
             "Soğanı ve kıymayı kavur, salça ve doğranmış domatesi ekle.",
             "Sosu makarnayla karıştırıp servis et."]),

        R("Tavuk Sote", "🍗", 30, 3, "Biberli, domatesli, pratik tavuk.",
            [I(19, "Tavuk göğsü", 400, "Gram"), I(3, "Biber", 2, "Piece"), I(1, "Domates", 2, "Piece"),
             I(4, "Soğan", 1, "Piece"), I(28, "Zeytinyağı", 30, "Milliliter")],
            ["Tavukları kuşbaşı doğra, zeytinyağında suyunu salıp çekene kadar pişir.",
             "Soğan ve biberleri ekle, 5 dakika kavur.",
             "Domatesleri ekle, 10 dakika pişirip servis et."]),

        R("Domatesli Bulgur Pilavı", "🍚", 25, 4, "Her yemeğin yanına giden pilav.",
            [I(23, "Bulgur", 200, "Gram"), I(4, "Soğan", 1, "Piece"), I(1, "Domates", 1, "Piece"),
             I(27, "Salça", 15, "Gram"), I(17, "Tereyağı", 20, "Gram")],
            ["Soğanı tereyağında kavur, salça ve domatesi ekle.",
             "Bulguru ekleyip karıştır, iki katı sıcak su ekle.",
             "Kısık ateşte suyunu çekene kadar pişir, 10 dakika demlendir."]),

        R("Çoban Salatası", "🥗", 10, 2, "Taze ve hafif, her öğüne uyar.",
            [I(1, "Domates", 3, "Piece"), I(2, "Salatalık", 2, "Piece"), I(3, "Biber", 1, "Piece"),
             I(4, "Soğan", 1, "Piece"), I(11, "Limon", 1, "Piece", true), I(28, "Zeytinyağı", 20, "Milliliter", true)],
            ["Domates, salatalık, biber ve soğanı küçük küp doğra.",
             "Limon suyu ve zeytinyağı ile karıştırıp servis et."]),

        R("Ispanaklı Yumurta", "🥬", 15, 2, "Hızlı, sağlıklı bir kahvaltı ya da akşam yemeği.",
            [I(10, "Ispanak", 300, "Gram"), I(18, "Yumurta", 2, "Piece"), I(4, "Soğan", 1, "Piece"),
             I(28, "Zeytinyağı", 20, "Milliliter"), I(14, "Yoğurt", 100, "Gram", true)],
            ["Soğanı zeytinyağında kavur, doğranmış ıspanağı ekle.",
             "Ispanak sönünce ortasını açıp yumurtaları kır.",
             "Yumurtalar pişince yoğurtla servis et."]),

        R("Tereyağlı Pirinç Pilavı", "🍚", 25, 4, "Tane tane, tereyağı kokulu pilav.",
            [I(21, "Pirinç", 200, "Gram"), I(17, "Tereyağı", 30, "Gram"), I(29, "Tuz", 5, "Gram", true)],
            ["Pirinci ılık suda 20 dakika beklet, süz.",
             "Tereyağında pirinçleri şeffaflaşana kadar kavur.",
             "Pirincin 1,5 katı sıcak su ekle, kısık ateşte pişir, demlendir."]),

        R("Fırında Patlıcan Kıyma", "🍆", 50, 4, "Kıymalı, domatesli fırın yemeği.",
            [I(9, "Patlıcan", 4, "Piece"), I(20, "Kıyma", 200, "Gram"), I(1, "Domates", 2, "Piece"),
             I(3, "Biber", 2, "Piece"), I(4, "Soğan", 1, "Piece")],
            ["Patlıcanları dilimleyip fırında 15 dakika pişir.",
             "Soğan, biber ve kıymayı kavur, domatesi ekle.",
             "Patlıcanları tepsiye diz, kıymalı harcı üzerine yay, 20 dakika fırınla."])
    ];
}