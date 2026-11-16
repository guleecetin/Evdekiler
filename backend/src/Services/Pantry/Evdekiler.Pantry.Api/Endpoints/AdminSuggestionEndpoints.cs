using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using Evdekiler.Pantry.Api.Receipts;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Pantry.Api.Endpoints;

public record SuggestionItem(
    int Id, string Text, string SampleLine, int Count, DateTime LastSeenAt,
    int IngredientId, string IngredientName, string IngredientEmoji, string IngredientImageUrl);

public record ApproveSuggestionRequest(string? Alias);

public static class AdminSuggestionEndpoints
{
    public static void MapAdminSuggestionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/ingredients/suggestions").RequireAuthorization(AuthPolicies.Admin);

        group.MapGet("/", GetAll);
        group.MapPost("/{id:int}/approve", Approve);
        group.MapDelete("/{id:int}", Reject);
    }

    // En çok önerilen en üstte
    private static async Task<IResult> GetAll(PantryDbContext db, CancellationToken ct)
    {
        var items = await db.Set<AliasSuggestion>().AsNoTracking()
            .OrderByDescending(s => s.Count)
            .ThenByDescending(s => s.LastSeenAt)
            .Take(100)
            .Select(s => new SuggestionItem(
                s.Id, s.Text, s.SampleLine, s.Count, s.LastSeenAt,
                s.IngredientId, s.Ingredient.Name, s.Ingredient.Emoji,
                s.Ingredient.ImageUrl ?? "/images/ingredients/" + s.IngredientId + ".jpg"))
            .ToListAsync(ct);

        return Results.Ok(items);
    }

    // Admin metni sadeleştirip onaylayabilir: "siyahcay fskbrlk" -> "siyahcay"
    private static async Task<IResult> Approve(
        int id, ApproveSuggestionRequest request, PantryDbContext db, IngredientCatalog catalog, CancellationToken ct)
    {
        var suggestion = await db.Set<AliasSuggestion>().SingleOrDefaultAsync(s => s.Id == id, ct);
        if (suggestion is null) return Results.NotFound();

        var key = AliasRules.Normalize(string.IsNullOrWhiteSpace(request.Alias) ? suggestion.Text : request.Alias);
        if (key.Length < AliasRules.MinLength)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["alias"] = [$"Eşanlamlı en az {AliasRules.MinLength} karakter olmalı."]
            });

        var owner = await db.Set<IngredientAlias>()
            .Where(a => a.Alias == key)
            .Select(a => a.Ingredient.Name)
            .FirstOrDefaultAsync(ct);
        if (owner is not null)
            return Results.Problem($"Bu eşanlamlı zaten \"{owner}\" için kullanılıyor.", statusCode: StatusCodes.Status409Conflict);

        // Eşanlamlıyı ekle ve öneriyi sil: tek SaveChanges, tek transaction
        db.Add(new IngredientAlias { IngredientId = suggestion.IngredientId, Alias = key });
        db.Remove(suggestion);

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            return Results.Problem("Bu eşanlamlı az önce eklendi.", statusCode: StatusCodes.Status409Conflict);
        }

        catalog.Invalidate();
        return Results.Ok(new { alias = key });
    }

    private static async Task<IResult> Reject(int id, PantryDbContext db, CancellationToken ct)
    {
        var deleted = await db.Set<AliasSuggestion>().Where(s => s.Id == id).ExecuteDeleteAsync(ct);
        return deleted == 0 ? Results.NotFound() : Results.NoContent();
    }
}