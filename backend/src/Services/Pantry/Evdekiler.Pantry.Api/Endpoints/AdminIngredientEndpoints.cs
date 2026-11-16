using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Evdekiler.Pantry.Api.Receipts;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Pantry.Api.Endpoints;

public record AdminIngredientItem(
    int Id, string Name, string Emoji, string ImageUrl,
    IngredientCategory Category, MeasureUnit DefaultUnit, int AliasCount);

public record IngredientPage(List<AdminIngredientItem> Items, int Page, int PageSize, int TotalCount);

public record UpsertIngredientRequest(
    string Name, string Emoji, IngredientCategory Category, MeasureUnit DefaultUnit);

public record AliasItem(int Id, string Alias);

public record AddAliasRequest(string Alias);

public static class AdminIngredientEndpoints
{
    public static void MapAdminIngredientEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/ingredients").RequireAuthorization(AuthPolicies.Admin);

        group.MapGet("/", GetPaged);
        group.MapPost("/", Create);
        group.MapPut("/{id:int}", Update);
        // Bilerek DELETE yok: tarifler malzemelere Id ile bağlı (başka serviste, FK olmadan)

        // Eşanlamlılar: sadece Pantry kullanıyor, silmek güvenli
        group.MapGet("/{id:int}/aliases", GetAliases);
        group.MapPost("/{id:int}/aliases", AddAlias);
        group.MapDelete("/aliases/{aliasId:int}", DeleteAlias);
    }

    // ─── Malzemeler ─────────────────────────────────────────

    private static async Task<IResult> GetPaged(
        int? page, int? pageSize, string? search, string? category,
        PantryDbContext db, CancellationToken ct)
    {
        var currentPage = Math.Max(1, page ?? 1);
        var size = Math.Clamp(pageSize ?? 24, 1, 100);
        var q = search?.Trim() ?? "";

        var query = q.Length == 0
            ? db.Ingredients.AsNoTracking()
            : db.Ingredients.FromSql($"""
                SELECT * FROM "Ingredients"
                WHERE search_key("Name") LIKE '%' || search_key({q}) || '%'
                """).AsNoTracking();

        if (Enum.TryParse<IngredientCategory>(category, ignoreCase: true, out var cat))
            query = query.Where(i => i.Category == cat);

        var total = await query.CountAsync(ct);
        var items = await query
            .OrderBy(i => i.Name)
            .Skip((currentPage - 1) * size)
            .Take(size)
            .Select(i => new AdminIngredientItem(
                i.Id, i.Name, i.Emoji, "/images/ingredients/" + i.Id + ".jpg", i.Category, i.DefaultUnit,
                db.Set<IngredientAlias>().Count(a => a.IngredientId == i.Id)))
            .ToListAsync(ct);

        return Results.Ok(new IngredientPage(items, currentPage, size, total));
    }

    private static async Task<IResult> Create(
        UpsertIngredientRequest request, PantryDbContext db, IngredientCatalog catalog, CancellationToken ct)
    {
        var errors = Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);

        var name = request.Name.Trim();
        if (await NameExistsAsync(db, name, exceptId: 0, ct))
            return Conflict("Bu isimde bir malzeme zaten var.");

        var ingredient = new Ingredient
        {
            Name = name,
            Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? "🛒" : request.Emoji.Trim(),
            Category = request.Category,
            DefaultUnit = request.DefaultUnit
        };

        db.Ingredients.Add(ingredient);
        await db.SaveChangesAsync(ct);
        catalog.Invalidate();

        return Results.Created($"/api/admin/ingredients/{ingredient.Id}", new { ingredient.Id });
    }

    private static async Task<IResult> Update(
        int id, UpsertIngredientRequest request, PantryDbContext db, IngredientCatalog catalog, CancellationToken ct)
    {
        var errors = Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);

        var ingredient = await db.Ingredients.SingleOrDefaultAsync(i => i.Id == id, ct);
        if (ingredient is null) return Results.NotFound();

        var name = request.Name.Trim();
        if (await NameExistsAsync(db, name, exceptId: id, ct))
            return Conflict("Bu isimde bir malzeme zaten var.");

        ingredient.Name = name;
        ingredient.Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? ingredient.Emoji : request.Emoji.Trim();
        ingredient.Category = request.Category;
        ingredient.DefaultUnit = request.DefaultUnit;

        await db.SaveChangesAsync(ct);
        catalog.Invalidate();

        return Results.NoContent();
    }

    // ─── Eşanlamlılar ───────────────────────────────────────

    private static async Task<IResult> GetAliases(int id, PantryDbContext db, CancellationToken ct)
    {
        var aliases = await db.Set<IngredientAlias>().AsNoTracking()
            .Where(a => a.IngredientId == id)
            .OrderBy(a => a.Alias)
            .Select(a => new AliasItem(a.Id, a.Alias))
            .ToListAsync(ct);

        return Results.Ok(aliases);
    }

    private static async Task<IResult> AddAlias(
        int id, AddAliasRequest request, PantryDbContext db, IngredientCatalog catalog, CancellationToken ct)
    {
        if (!await db.Ingredients.AnyAsync(i => i.Id == id, ct))
            return Results.NotFound();

        // Eşleştiricinin kullandığı biçime çevir: "SIYAH ÇAY" -> "siyah cay"
        var key = string.Join(' ',
            IngredientMatcher.Key(request.Alias ?? "").Split(' ', StringSplitOptions.RemoveEmptyEntries));

        if (key.Length is < 3 or > 60)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["alias"] = ["Eşanlamlı 3-60 karakter olmalı."]
            });

        var owner = await db.Set<IngredientAlias>()
            .Where(a => a.Alias == key)
            .Select(a => a.Ingredient.Name)
            .FirstOrDefaultAsync(ct);
        if (owner is not null)
            return Conflict($"Bu eşanlamlı zaten \"{owner}\" için kullanılıyor.");

        var alias = new IngredientAlias { IngredientId = id, Alias = key };
        db.Add(alias);

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Kontrolle kayıt arasında başkası aynı eşanlamlıyı eklediyse
            return Conflict("Bu eşanlamlı az önce başka biri tarafından eklendi.");
        }

        catalog.Invalidate();
        return Results.Created($"/api/admin/ingredients/{id}/aliases", new AliasItem(alias.Id, alias.Alias));
    }

    private static async Task<IResult> DeleteAlias(
        int aliasId, PantryDbContext db, IngredientCatalog catalog, CancellationToken ct)
    {
        var deleted = await db.Set<IngredientAlias>().Where(a => a.Id == aliasId).ExecuteDeleteAsync(ct);
        if (deleted == 0) return Results.NotFound();

        catalog.Invalidate();
        return Results.NoContent();
    }

    // ─── Yardımcılar ────────────────────────────────────────

    private static Task<bool> NameExistsAsync(PantryDbContext db, string name, int exceptId, CancellationToken ct) =>
        db.Database.SqlQuery<bool>($"""
            SELECT EXISTS (
                SELECT 1 FROM "Ingredients"
                WHERE search_key("Name") = search_key({name}) AND "Id" <> {exceptId}
            ) AS "Value"
            """).SingleAsync(ct);

    private static Dictionary<string, string[]> Validate(UpsertIngredientRequest r)
    {
        var errors = new Dictionary<string, string[]>();

        if (string.IsNullOrWhiteSpace(r.Name) || r.Name.Trim().Length is < 2 or > 60)
            errors["name"] = ["Malzeme adı 2-60 karakter olmalı."];
        if (r.Emoji is { Length: > 16 })
            errors["emoji"] = ["Geçersiz simge."];
        if (!Enum.IsDefined(r.Category))
            errors["category"] = ["Geçersiz kategori."];
        if (!Enum.IsDefined(r.DefaultUnit))
            errors["defaultUnit"] = ["Geçersiz birim."];

        return errors;
    }

    private static IResult Conflict(string message) =>
        Results.Problem(message, statusCode: StatusCodes.Status409Conflict);
}