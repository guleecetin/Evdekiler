using Evdekiler.Recipe.Api.Clients;
using Evdekiler.Recipe.Api.Data;
using Microsoft.EntityFrameworkCore;
using Polly.CircuitBreaker;
using Polly.Timeout;

namespace Evdekiler.Recipe.Api.Endpoints;

public record RecipeSuggestion(
    int Id, string Title, string Emoji, string ImageUrl, int PrepMinutes, int Servings,
    int HaveCount, int RequiredCount, int MatchPercent, List<string> Missing);

public record RecipeIngredientResponse(
    int IngredientId, string Name, decimal Quantity, string Unit, bool IsOptional);

public record RecipeDetailResponse(
    int Id, string Title, string Description, string Emoji, string ImageUrl,
    int PrepMinutes, int Servings,
    List<RecipeIngredientResponse> Ingredients, List<string> Steps);

public static class RecipeEndpoints
{
    public static void MapRecipeEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/recipes").RequireAuthorization();

        group.MapGet("/suggestions", GetSuggestions);
        group.MapGet("/{id:int}", GetById);
    }

    private static async Task<IResult> GetSuggestions(
        HttpContext http, PantryClient pantry, RecipeDbContext db, CancellationToken ct)
    {
        HashSet<int> have;
        try
        {
            have = await pantry.GetIngredientIdsAsync(
                http.Request.Headers.Authorization.ToString(), ct);
        }
        catch (Exception ex) when (ex is HttpRequestException
                                       or TimeoutRejectedException
                                       or BrokenCircuitException)
        {
            return Results.Problem(
                "Buzdolabı bilgine şu an ulaşılamıyor, birazdan tekrar dene.",
                statusCode: StatusCodes.Status503ServiceUnavailable);
        }

        var recipes = await db.Recipes
            .AsNoTracking()
            .Select(r => new
            {
                r.Id,
                r.Title,
                r.Emoji,
                r.ImageUrl,
                r.PrepMinutes,
                r.Servings,
                Required = r.Ingredients
                    .Where(i => !i.IsOptional)
                    .Select(i => new { i.IngredientId, i.IngredientName })
                    .ToList()
            })
            .ToListAsync(ct);

        var suggestions = recipes
            .Select(r =>
            {
                var haveCount = r.Required.Count(i => have.Contains(i.IngredientId));
                var missing = r.Required
                    .Where(i => !have.Contains(i.IngredientId))
                    .Select(i => i.IngredientName)
                    .ToList();
                var percent = r.Required.Count == 0 ? 100 : haveCount * 100 / r.Required.Count;

                return new RecipeSuggestion(r.Id, r.Title, r.Emoji, r.ImageUrl,
                    r.PrepMinutes, r.Servings, haveCount, r.Required.Count, percent, missing);
            })
            .Where(s => s.HaveCount > 0)
            .OrderBy(s => s.Missing.Count)
            .ThenByDescending(s => s.MatchPercent)
            .ThenBy(s => s.PrepMinutes)
            .ToList();

        return Results.Ok(suggestions);
    }

    private static async Task<IResult> GetById(int id, RecipeDbContext db, CancellationToken ct)
    {
        var recipe = await db.Recipes
            .AsNoTracking()
            .AsSplitQuery()
            .Where(r => r.Id == id)
            .Select(r => new RecipeDetailResponse(
                r.Id, r.Title, r.Description, r.Emoji, r.ImageUrl,
                r.PrepMinutes, r.Servings,
                r.Ingredients
                    .OrderBy(i => i.IsOptional)
                    .Select(i => new RecipeIngredientResponse(
                        i.IngredientId, i.IngredientName, i.Quantity, i.Unit, i.IsOptional))
                    .ToList(),
                r.Steps.OrderBy(s => s.Order).Select(s => s.Text).ToList()))
            .SingleOrDefaultAsync(ct);

        return recipe is null ? Results.NotFound() : Results.Ok(recipe);
    }
}