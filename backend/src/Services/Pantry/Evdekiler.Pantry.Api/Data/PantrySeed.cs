using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Pantry.Api.Data;

// Başlangıç verisi: sadece EKSİK olanı ekler, var olana (admin değişikliklerine) dokunmaz
public static class PantrySeed
{
    private static readonly (string Alias, int IngredientId)[] Aliases =
    [
        ("domates salcasi", 27), ("biber salcasi", 27), ("unlu mam", 49), ("francala", 49),
        ("kasar", 16), ("beyaz peyn", 15), ("tavuk gogus", 19), ("pilic gogus", 19),
        ("pilic but", 108), ("aycicek", 60), ("zeytin yagi", 28), ("baldo", 21),
        ("osmancik", 21), ("spagetti", 22), ("penne", 22), ("kirmizi mercimek", 25),
        ("toz seker", 55), ("kup seker", 55), ("maydonoz", 31), ("dana kiyma", 20)
    ];

    public static void Seed(DbContext context) =>
        SeedAsync(context, CancellationToken.None).GetAwaiter().GetResult();

    public static async Task SeedAsync(DbContext context, CancellationToken ct)
    {
        var db = (PantryDbContext)context;

        // 1. Malzemeler: Id'si veritabanında olmayanları ekle
        var existingIds = (await db.Ingredients.Select(i => i.Id).ToListAsync(ct)).ToHashSet();
        var missing = IngredientSeed.All.Where(i => !existingIds.Contains(i.Id)).ToList();

        if (missing.Count > 0)
        {
            db.Ingredients.AddRange(missing.Select(i => new Ingredient
            {
                Id = i.Id, // tarif JSON'ları bu Id'lere bağlı, sabit kalmalı
                Name = i.Name,
                Emoji = i.Emoji,
                Category = i.Category,
                DefaultUnit = i.DefaultUnit
            }));
            await db.SaveChangesAsync(ct);

            // Id'leri elle verdik: otomatik sayacı en büyük Id'ye çek
            await db.Database.ExecuteSqlRawAsync("""
                SELECT setval(pg_get_serial_sequence('"Ingredients"', 'Id'),
                              (SELECT COALESCE(MAX("Id"), 1) FROM "Ingredients"));
                """, ct);
        }

        // 2. Eşanlamlılar: SADECE tablo bomboşsa (ilk kurulum).
        //    Admin bir eşanlamlıyı silmişse, seed onu geri getirmesin.
        if (!await db.Set<IngredientAlias>().AnyAsync(ct))
        {
            db.AddRange(Aliases.Select(a => new IngredientAlias { Alias = a.Alias, IngredientId = a.IngredientId }));
            await db.SaveChangesAsync(ct);
        }
    }
}