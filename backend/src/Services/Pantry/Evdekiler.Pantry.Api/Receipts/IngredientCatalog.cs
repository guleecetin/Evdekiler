using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Evdekiler.Pantry.Api.Receipts;

// Katalog + eşanlamlıları bir kez yükler, 10 dakika önbellekte tutar
public sealed class IngredientCatalog(PantryDbContext db, IMemoryCache cache)
{
    private const string CacheKey = "receipt-matcher";

    public async Task<IngredientMatcher> GetMatcherAsync(CancellationToken ct)
    {
        var matcher = await cache.GetOrCreateAsync(CacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);

            var ingredients = await db.Ingredients.AsNoTracking()
                .Select(i => new CatalogIngredient(i.Id, i.Name, i.Emoji, i.Category, i.DefaultUnit))
                .ToListAsync(ct);

            var aliases = await db.Set<IngredientAlias>().AsNoTracking()
                .Select(a => new CatalogAlias(a.Alias, a.IngredientId))
                .ToListAsync(ct);

            return new IngredientMatcher(ingredients, aliases);
        });

        return matcher!;
    }

    // Katalog değişince çağrılır: bir sonraki fiş en güncel katalogla eşleştirilir
    public void Invalidate() => cache.Remove(CacheKey);
}