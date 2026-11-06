using System.Security.Claims;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Pantry.Api.Endpoints;

public record IngredientResponse(
    int Id, string Name, IngredientCategory Category, MeasureUnit DefaultUnit);

public record PantryItemResponse(
    Guid Id, int IngredientId, string IngredientName, IngredientCategory Category,
    decimal Quantity, MeasureUnit Unit, DateOnly? ExpiresAt, uint Version);

public record CreatePantryItemRequest(
    int IngredientId, decimal Quantity, MeasureUnit? Unit, DateOnly? ExpiresAt);

public record UpdatePantryItemRequest(
    decimal Quantity, MeasureUnit Unit, DateOnly? ExpiresAt, uint Version);

public static class PantryEndpoints
{
    public static void MapPantryEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/pantry").RequireAuthorization();

        group.MapGet("/ingredients", SearchIngredients);
        group.MapGet("/items", GetItems);
        group.MapPost("/items", CreateItem);
        group.MapPut("/items/{id:guid}", UpdateItem);
        group.MapDelete("/items/{id:guid}", DeleteItem);
    }

    // GET /api/pantry/ingredients?search=dom
    private static async Task<IResult> SearchIngredients(
        string? search, PantryDbContext db, CancellationToken ct)
    {
        var query = db.Ingredients.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(i => EF.Functions.ILike(i.Name, $"%{search.Trim()}%"));

        var result = await query
            .OrderBy(i => i.Name)
            .Take(20)
            .Select(i => new IngredientResponse(i.Id, i.Name, i.Category, i.DefaultUnit))
            .ToListAsync(ct);

        return Results.Ok(result);
    }

    // GET /api/pantry/items
    private static async Task<IResult> GetItems(
        ClaimsPrincipal user, PantryDbContext db, CancellationToken ct)
    {
        var userId = user.GetUserId();

        var items = await db.PantryItems
            .AsNoTracking()
            .Where(p => p.UserId == userId)
            .OrderBy(p => p.ExpiresAt == null)
            .ThenBy(p => p.ExpiresAt)
            .ThenBy(p => p.Ingredient.Name)
            .Select(p => new PantryItemResponse(
                p.Id, p.IngredientId, p.Ingredient.Name, p.Ingredient.Category,
                p.Quantity, p.Unit, p.ExpiresAt, p.Version))
            .ToListAsync(ct);

        return Results.Ok(items);
    }

    // POST /api/pantry/items
    private static async Task<IResult> CreateItem(
        CreatePantryItemRequest request, ClaimsPrincipal user,
        PantryDbContext db, CancellationToken ct)
    {
        if (request.Quantity is <= 0 or > 100_000)
            return QuantityError();

        var ingredient = await db.Ingredients.FindAsync([request.IngredientId], ct);
        if (ingredient is null)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["ingredientId"] = ["Böyle bir malzeme yok."]
            });

        var now = DateTime.UtcNow;
        var item = new PantryItem
        {
            Id = Guid.CreateVersion7(),
            UserId = user.GetUserId(),
            IngredientId = ingredient.Id,
            Quantity = request.Quantity,
            Unit = request.Unit ?? ingredient.DefaultUnit,
            ExpiresAt = request.ExpiresAt,
            CreatedAt = now,
            UpdatedAt = now
        };

        db.PantryItems.Add(item);
        await db.SaveChangesAsync(ct);

        return Results.Created($"/api/pantry/items/{item.Id}", ToResponse(item, ingredient));
    }

    // PUT /api/pantry/items/{id}
    private static async Task<IResult> UpdateItem(
        Guid id, UpdatePantryItemRequest request, ClaimsPrincipal user,
        PantryDbContext db, CancellationToken ct)
    {
        if (request.Quantity is <= 0 or > 100_000)
            return QuantityError();

        var userId = user.GetUserId();
        var item = await db.PantryItems
            .Include(p => p.Ingredient)
            .SingleOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (item is null)
            return Results.NotFound();

        // Optimistic concurrency: istemcinin gördüğü sürümü EF Core'a bildir
        db.Entry(item).Property(p => p.Version).OriginalValue = request.Version;

        item.Quantity = request.Quantity;
        item.Unit = request.Unit;
        item.ExpiresAt = request.ExpiresAt;
        item.UpdatedAt = DateTime.UtcNow;

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            return Results.Problem(
                "Bu ürün sen bakarken değiştirildi. Listeyi yenileyip tekrar dene.",
                statusCode: StatusCodes.Status409Conflict);
        }

        return Results.Ok(ToResponse(item, item.Ingredient));
    }

    // DELETE /api/pantry/items/{id}
    private static async Task<IResult> DeleteItem(
        Guid id, ClaimsPrincipal user, PantryDbContext db, CancellationToken ct)
    {
        var userId = user.GetUserId();

        var deleted = await db.PantryItems
            .Where(p => p.Id == id && p.UserId == userId)
            .ExecuteDeleteAsync(ct);

        return deleted == 0 ? Results.NotFound() : Results.NoContent();
    }

    private static PantryItemResponse ToResponse(PantryItem p, Ingredient i) =>
        new(p.Id, i.Id, i.Name, i.Category, p.Quantity, p.Unit, p.ExpiresAt, p.Version);

    private static IResult QuantityError() =>
        Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["quantity"] = ["Miktar 0'dan büyük ve makul bir değer olmalı."]
        });
}