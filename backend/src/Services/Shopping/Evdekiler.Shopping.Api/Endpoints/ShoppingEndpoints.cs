using System.Security.Claims;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.BuildingBlocks.Contracts;
using Evdekiler.Shopping.Api.Data;
using Evdekiler.Shopping.Api.Entities;
using MassTransit;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Shopping.Api.Endpoints;

public record AddItemRequest(int IngredientId, string IngredientName, decimal Quantity, string Unit);
public record AddItemsRequest(List<AddItemRequest> Items);

public record ShoppingItemResponse(
    Guid Id, int IngredientId, string IngredientName, decimal Quantity, string Unit,
    bool IsPurchased, DateTime? PurchasedAt);

public static class ShoppingEndpoints
{
    public static void MapShoppingEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/shopping").RequireAuthorization();

        group.MapGet("/items", GetItems);
        group.MapPost("/items", AddItems);
        group.MapPost("/items/{id:guid}/purchase", Purchase);
        group.MapDelete("/items/{id:guid}", Delete);
    }

    // GET /api/shopping/items → alınmamışlar + son 2 günde alınanlar
    private static async Task<IResult> GetItems(
        ClaimsPrincipal user, ShoppingDbContext db, CancellationToken ct)
    {
        var userId = user.GetUserId();
        var since = DateTime.UtcNow.AddDays(-2);

        var items = await db.ShoppingItems
            .AsNoTracking()
            .Where(i => i.UserId == userId && (!i.IsPurchased || i.PurchasedAt >= since))
            .OrderBy(i => i.IsPurchased)
            .ThenBy(i => i.IngredientName)
            .Select(i => ToResponse(i))
            .ToListAsync(ct);

        return Results.Ok(items);
    }

    // POST /api/shopping/items → bir veya birden çok ürün ekle (tarifin eksikleri gibi)
    private static async Task<IResult> AddItems(
        AddItemsRequest request, ClaimsPrincipal user, ShoppingDbContext db, CancellationToken ct)
    {
        if (request.Items is not { Count: > 0 and <= 50 })
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["items"] = ["1 ile 50 arasında ürün gönderilmeli."]
            });

        var userId = user.GetUserId();
        var ids = request.Items.Select(i => i.IngredientId).ToList();

        // Listede zaten olan (alınmamış) ürünler
        var existing = await db.ShoppingItems
            .Where(i => i.UserId == userId && !i.IsPurchased && ids.Contains(i.IngredientId))
            .ToDictionaryAsync(i => i.IngredientId, ct);

        foreach (var req in request.Items.Where(i => i.Quantity > 0))
        {
            if (existing.TryGetValue(req.IngredientId, out var item))
            {
                // Zaten listede: yeni satır açma, miktarı artır
                if (item.Unit == req.Unit) item.Quantity += req.Quantity;
            }
            else
            {
                var created = new ShoppingItem
                {
                    Id = Guid.CreateVersion7(),
                    UserId = userId,
                    IngredientId = req.IngredientId,
                    IngredientName = req.IngredientName,
                    Quantity = req.Quantity,
                    Unit = req.Unit,
                    CreatedAt = DateTime.UtcNow
                };
                db.ShoppingItems.Add(created);
                existing[req.IngredientId] = created;
            }
        }

        await db.SaveChangesAsync(ct);
        return Results.Ok(existing.Values.Select(ToResponse));
    }

    // POST /api/shopping/items/{id}/purchase → alındı işaretle + olay yayınla
    private static async Task<IResult> Purchase(
        Guid id, ClaimsPrincipal user, ShoppingDbContext db,
        IPublishEndpoint publisher, CancellationToken ct)
    {
        var userId = user.GetUserId();
        var item = await db.ShoppingItems
            .SingleOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null) return Results.NotFound();
        if (item.IsPurchased) return Results.Ok(ToResponse(item)); // idempotent: zaten alınmış

        item.IsPurchased = true;
        item.PurchasedAt = DateTime.UtcNow;

        // Outbox sayesinde bu, RabbitMQ'ya değil Outbox tablosuna yazılır
        await publisher.Publish(new ShoppingItemPurchased(
            item.Id, item.UserId, item.IngredientId, item.Quantity, item.Unit,
            item.PurchasedAt.Value), ct);

        // Ürün güncellemesi + olay TEK transaction'da kaydedilir
        await db.SaveChangesAsync(ct);

        return Results.Ok(ToResponse(item));
    }

    // DELETE /api/shopping/items/{id}
    private static async Task<IResult> Delete(
        Guid id, ClaimsPrincipal user, ShoppingDbContext db, CancellationToken ct)
    {
        var userId = user.GetUserId();
        var deleted = await db.ShoppingItems
            .Where(i => i.Id == id && i.UserId == userId)
            .ExecuteDeleteAsync(ct);

        return deleted == 0 ? Results.NotFound() : Results.NoContent();
    }

    private static ShoppingItemResponse ToResponse(ShoppingItem i) =>
        new(i.Id, i.IngredientId, i.IngredientName, i.Quantity, i.Unit, i.IsPurchased, i.PurchasedAt);
}