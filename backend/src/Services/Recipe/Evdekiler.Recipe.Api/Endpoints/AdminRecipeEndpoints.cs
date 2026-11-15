using System.Text;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Recipe.Api.Data;
using Evdekiler.Recipe.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Recipe.Api.Endpoints;

public record UpsertIngredient(
    int IngredientId, string Name, decimal Quantity, string Unit, bool IsOptional);

public record UpsertRecipeRequest(
    string Title, string Description, string Emoji, RecipeCategory Category,
    int PrepMinutes, int Servings, List<UpsertIngredient> Ingredients, List<string> Steps);

public record AdminRecipeListItem(
    int Id, string Slug, string Title, string ImageUrl, RecipeCategory Category,
    int PrepMinutes, int IngredientCount);

public record PagedResult<T>(List<T> Items, int Page, int PageSize, int TotalCount);

public static class AdminRecipeEndpoints
{
    private static readonly string[] AllowedUnits =
        ["Piece", "Gram", "Kilogram", "Milliliter", "Liter"];

    public static void MapAdminRecipeEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/recipes").RequireAuthorization(AuthPolicies.Admin);

        group.MapGet("/", GetPaged);
        group.MapPost("/", Create);
        group.MapPut("/{id:int}", Update);
        group.MapDelete("/{id:int}", Delete);
    }

    // GET /api/admin/recipes?page=1&pageSize=20&search=men&category=Soup
    private static async Task<IResult> GetPaged(
        int? page, int? pageSize, string? search, string? category,
        RecipeDbContext db, CancellationToken ct)
    {
        var currentPage = Math.Max(1, page ?? 1);
        var size = Math.Clamp(pageSize ?? 20, 1, 100);

        var query = db.Recipes.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(r => EF.Functions.ILike(r.Title, $"%{search.Trim()}%"));
        if (Enum.TryParse<RecipeCategory>(category, ignoreCase: true, out var cat))
            query = query.Where(r => r.Category == cat);

        var total = await query.CountAsync(ct);

        var items = await query
            .OrderBy(r => r.Title)
            .Skip((currentPage - 1) * size)
            .Take(size)
            .Select(r => new AdminRecipeListItem(
                r.Id, r.Slug, r.Title, r.ImageUrl, r.Category, r.PrepMinutes, r.Ingredients.Count))
            .ToListAsync(ct);

        return Results.Ok(new PagedResult<AdminRecipeListItem>(items, currentPage, size, total));
    }

    private static async Task<IResult> Create(
        UpsertRecipeRequest request, RecipeDbContext db, CancellationToken ct)
    {
        var errors = Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);

        var slug = Slugify(request.Title);
        if (await db.Recipes.AnyAsync(r => r.Slug == slug, ct))
            return SlugConflict();

        var recipe = new Entities.Recipe
        {
            Slug = slug,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim() ?? "",
            Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? "🍽️" : request.Emoji,
            Category = request.Category,
            PrepMinutes = request.PrepMinutes,
            Servings = request.Servings,
            ImageUrl = $"/images/recipes/{slug}.jpg",
            Ingredients = request.Ingredients.Select(ToIngredient).ToList(),
            Steps = ToSteps(request.Steps)
        };

        db.Recipes.Add(recipe);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            return SlugConflict();
        }

        return Results.Created($"/api/recipes/{recipe.Id}", new { recipe.Id, recipe.Slug });
    }

    private static async Task<IResult> Update(
        int id, UpsertRecipeRequest request, RecipeDbContext db, CancellationToken ct)
    {
        var errors = Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);

        await using var transaction = await db.Database.BeginTransactionAsync(ct);

        var recipe = await db.Recipes.SingleOrDefaultAsync(r => r.Id == id, ct);
        if (recipe is null) return Results.NotFound();

        await db.Set<RecipeIngredient>().Where(i => i.RecipeId == id).ExecuteDeleteAsync(ct);
        await db.Set<RecipeStep>().Where(s => s.RecipeId == id).ExecuteDeleteAsync(ct);

        recipe.Title = request.Title.Trim();
        recipe.Description = request.Description?.Trim() ?? "";
        recipe.Emoji = string.IsNullOrWhiteSpace(request.Emoji) ? recipe.Emoji : request.Emoji;
        recipe.Category = request.Category;
        recipe.PrepMinutes = request.PrepMinutes;
        recipe.Servings = request.Servings;

        db.AddRange(request.Ingredients.Select(i =>
        {
            var entity = ToIngredient(i);
            entity.RecipeId = id;
            return entity;
        }));
        db.AddRange(ToSteps(request.Steps).Select(s =>
        {
            s.RecipeId = id;
            return s;
        }));

        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        return Results.NoContent();
    }

    private static async Task<IResult> Delete(int id, RecipeDbContext db, CancellationToken ct)
    {
        var deleted = await db.Recipes.Where(r => r.Id == id).ExecuteDeleteAsync(ct);
        return deleted == 0 ? Results.NotFound() : Results.NoContent();
    }

    private static Dictionary<string, string[]> Validate(UpsertRecipeRequest r)
    {
        var errors = new Dictionary<string, string[]>();

        if (string.IsNullOrWhiteSpace(r.Title) || r.Title.Trim().Length is < 3 or > 150)
            errors["title"] = ["Başlık 3-150 karakter olmalı."];
        if (r.Description is { Length: > 500 })
            errors["description"] = ["Açıklama en fazla 500 karakter olabilir."];
        if (!Enum.IsDefined(r.Category))
            errors["category"] = ["Geçersiz kategori."];
        if (r.PrepMinutes is < 1 or > 600)
            errors["prepMinutes"] = ["Süre 1-600 dakika arasında olmalı."];
        if (r.Servings is < 1 or > 50)
            errors["servings"] = ["Porsiyon 1-50 arasında olmalı."];

        if (r.Ingredients is not { Count: > 0 and <= 30 })
            errors["ingredients"] = ["1-30 arası malzeme girilmeli."];
        else if (r.Ingredients.Any(i => i.Quantity <= 0 || string.IsNullOrWhiteSpace(i.Name)))
            errors["ingredients"] = ["Her malzemenin adı ve 0'dan büyük miktarı olmalı."];
        else if (r.Ingredients.Any(i => !AllowedUnits.Contains(i.Unit)))
            errors["ingredients"] = ["Geçersiz birim."];
        else if (r.Ingredients.Select(i => i.IngredientId).Distinct().Count() != r.Ingredients.Count)
            errors["ingredients"] = ["Aynı malzeme iki kez eklenemez."];

        if (r.Steps is not { Count: > 0 and <= 30 })
            errors["steps"] = ["1-30 arası adım girilmeli."];
        else if (r.Steps.Any(s => string.IsNullOrWhiteSpace(s) || s.Length > 1000))
            errors["steps"] = ["Adımlar boş olamaz ve 1000 karakteri geçemez."];

        return errors;
    }

    private static RecipeIngredient ToIngredient(UpsertIngredient i) => new()
    {
        IngredientId = i.IngredientId,
        IngredientName = i.Name.Trim(),
        Quantity = i.Quantity,
        Unit = i.Unit,
        IsOptional = i.IsOptional
    };

    private static List<RecipeStep> ToSteps(List<string> steps) =>
        steps.Select((text, index) => new RecipeStep { Order = index + 1, Text = text.Trim() }).ToList();

    private static string Slugify(string title)
    {
        var text = title.Trim().Replace('İ', 'i').Replace('I', 'i').ToLowerInvariant();
        var sb = new StringBuilder();

        foreach (var ch in text)
        {
            var c = ch switch
            {
                'ç' => 'c',
                'ğ' => 'g',
                'ı' => 'i',
                'ö' => 'o',
                'ş' => 's',
                'ü' => 'u',
                _ => ch
            };

            if (c is (>= 'a' and <= 'z') or (>= '0' and <= '9'))
                sb.Append(c);
            else if (sb.Length > 0 && sb[^1] != '-')
                sb.Append('-');
        }

        return sb.ToString().Trim('-');
    }

    private static IResult SlugConflict() =>
        Results.Problem("Bu isimde bir tarif zaten var.", statusCode: StatusCodes.Status409Conflict);
}