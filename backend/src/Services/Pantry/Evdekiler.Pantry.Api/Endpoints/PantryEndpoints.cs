using System.Security.Claims;
using System.Text.RegularExpressions;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Pantry.Api.Endpoints;

public record IngredientResponse(
    int Id, string Name, string Emoji, string ImageUrl,
    IngredientCategory Category, MeasureUnit DefaultUnit);

public record PantryItemResponse(
    Guid Id, int IngredientId, string IngredientName, string IngredientEmoji, string ImageUrl,
    IngredientCategory Category, decimal Quantity, MeasureUnit Unit,
    DateOnly? ExpiresAt, uint Version);

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

    // GET /api/pantry/ingredients?search=SIR
    private static async Task<IResult> SearchIngredients(
        string? search, PantryDbContext db, CancellationToken ct)
    {
        var q = Regex.Replace(search?.Trim() ?? "", @"[%_\\]", "");

        List<Ingredient> ingredients;

        if (q.Length == 0)
        {
            ingredients = await db.Ingredients.AsNoTracking()
                .OrderBy(i => i.Name)
                .Take(20)
                .ToListAsync(ct);
        }
        else
        {
            var fuzzy = q.Length >= 3;

            // tr_key: Türkçe kurallarla küçük harf ("SIR" -> "sır")
            // search_key: Türkçe karakterler sadeleşmiş ("SIR" -> "sir", "Soğan" -> "sogan")
            ingredients = await db.Ingredients.FromSql($"""
                SELECT * FROM "Ingredients"
                WHERE search_key("Name") LIKE '%' || search_key({q}) || '%'
                   OR ({fuzzy} AND similarity(search_key("Name"), search_key({q})) > 0.3)
                ORDER BY
                    CASE
                        WHEN tr_key("Name") LIKE tr_key({q}) || '%' THEN 0
                        WHEN tr_key("Name") LIKE '%' || tr_key({q}) || '%' THEN 1
                        WHEN search_key("Name") LIKE search_key({q}) || '%' THEN 2
                        WHEN search_key("Name") LIKE '% ' || search_key({q}) || '%' THEN 3
                        WHEN search_key("Name") LIKE '%' || search_key({q}) || '%' THEN 4
                        ELSE 5
                    END,
                    similarity(search_key("Name"), search_key({q})) DESC,
                    "Name"
                LIMIT 20
                """)
                .AsNoTracking()
                .ToListAsync(ct);
        }

        var result = ingredients.Select(i => new IngredientResponse(
            i.Id, i.Name, i.Emoji, $"/images/ingredients/{i.Id}.jpg", i.Category, i.DefaultUnit));

        return Results.Ok(result);
    }

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
                p.Id, p.IngredientId, p.Ingredient.Name, p.Ingredient.Emoji,
                "/images/ingredients/" + p.IngredientId + ".jpg",
                p.Ingredient.Category, p.Quantity, p.Unit, p.ExpiresAt, p.Version))
            .ToListAsync(ct);

        return Results.Ok(items);
    }

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
        new(p.Id, i.Id, i.Name, i.Emoji, $"/images/ingredients/{i.Id}.jpg",
            i.Category, p.Quantity, p.Unit, p.ExpiresAt, p.Version);

    private static IResult QuantityError() =>
        Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["quantity"] = ["Miktar 0'dan büyük ve makul bir değer olmalı."]
        });
}