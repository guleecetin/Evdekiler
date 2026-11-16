using System.Security.Claims;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Pantry.Api.Endpoints;

public record BulkItemRequest(int IngredientId, decimal Quantity, MeasureUnit Unit, DateOnly? ExpiresAt);

public record BulkCreateRequest(List<BulkItemRequest> Items);

public static class PantryBulkEndpoints
{
    public static void MapPantryBulkEndpoints(this IEndpointRouteBuilder app)
    {
        // POST /api/pantry/items/bulk  { "items": [ { "ingredientId": 13, "quantity": 2, "unit": "Liter" }, ... ] }
        app.MapPost("/api/pantry/items/bulk", CreateMany).RequireAuthorization();
    }

    private static async Task<IResult> CreateMany(
        BulkCreateRequest request, ClaimsPrincipal user, PantryDbContext db, CancellationToken ct)
    {
        // 1. Doğrulama: hepsi geçerli değilse hiçbiri eklenmez
        if (request.Items is not { Count: > 0 and <= 50 })
            return Error("items", "1-50 arası ürün gönderilmeli.");

        if (request.Items.Any(i => i.Quantity is <= 0 or > 100_000 || !Enum.IsDefined(i.Unit)))
            return Error("items", "Her ürünün miktarı 0'dan büyük ve birimi geçerli olmalı.");

        var ids = request.Items.Select(i => i.IngredientId).Distinct().ToList();
        var ingredients = await db.Ingredients
            .Where(i => ids.Contains(i.Id))
            .ToDictionaryAsync(i => i.Id, ct);

        var unknown = ids.Where(id => !ingredients.ContainsKey(id)).ToList();
        if (unknown.Count > 0)
            return Error("items", $"Bilinmeyen malzeme: {string.Join(", ", unknown)}");

        // 2. Hepsini oluştur
        var userId = user.GetUserId();
        var now = DateTime.UtcNow;

        var items = request.Items.Select(i => new PantryItem
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            IngredientId = i.IngredientId,
            Quantity = i.Quantity,
            Unit = i.Unit,
            ExpiresAt = i.ExpiresAt,
            CreatedAt = now,
            UpdatedAt = now
        }).ToList();

        // 3. Tek SaveChanges = tek transaction: ya hepsi eklenir ya hiçbiri
        db.PantryItems.AddRange(items);
        await db.SaveChangesAsync(ct);

        var response = items.Select(p =>
        {
            var ing = ingredients[p.IngredientId];
            return new PantryItemResponse(
                p.Id, ing.Id, ing.Name, ing.Emoji, $"/images/ingredients/{ing.Id}.jpg",
                ing.Category, p.Quantity, p.Unit, p.ExpiresAt, p.Version);
        });

        return Results.Ok(response);
    }

    private static IResult Error(string key, string message) =>
        Results.ValidationProblem(new Dictionary<string, string[]> { [key] = [message] });
}