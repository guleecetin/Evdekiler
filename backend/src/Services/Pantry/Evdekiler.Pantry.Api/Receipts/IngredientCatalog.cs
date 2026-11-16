using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Evdekiler.Pantry.Api.Receipts;

public sealed class IngredientCatalog(PantryDbContext db, IMemoryCache cache)
{
    private const string CacheKey = "receipt-matcher";

    public async Task<IngredientMatcher> GetMatcherAsync(CancellationToken ct)
    {
        var matcher = await cache.GetOrCreateAsync(CacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);

            var ingredients = await db.Ingredients.AsNoTracking()
                .Select(i => new CatalogIngredient(
                    i.Id, i.Name, i.Emoji, i.Category, i.DefaultUnit,
                    i.ImageUrl ?? "/images/ingredients/" + i.Id + ".jpg"))
                .ToListAsync(ct);

            var aliases = await db.Set<IngredientAlias>().AsNoTracking()
                .Select(a => new CatalogAlias(a.Alias, a.IngredientId))
                .ToListAsync(ct);

            return new IngredientMatcher(ingredients, aliases);
        });

        return matcher!;
    }

    public void Invalidate() => cache.Remove(CacheKey);
}