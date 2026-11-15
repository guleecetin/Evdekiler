using System.Text.Json;
using Evdekiler.Recipe.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Recipe.Api.Data;

internal record SeedIngredient(int Id, string Name, decimal Quantity, string Unit, bool Optional);

internal record SeedRecipe(
    string Slug, string Title, string Emoji, string Description,
    int PrepMinutes, int Servings, List<SeedIngredient> Ingredients, List<string> Steps,
    string? Category = null);

public static class RecipeSeed
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private static List<SeedRecipe> Load()
    {
        var dir = Path.Combine(AppContext.BaseDirectory, "Data");
        return Directory.GetFiles(dir, "recipes*.json")
            .OrderBy(f => f)
            .SelectMany(f => JsonSerializer.Deserialize<List<SeedRecipe>>(File.ReadAllText(f), JsonOptions) ?? [])
            .ToList();
    }

    public static void Seed(DbContext context)
    {
        var db = (RecipeDbContext)context;
        var existing = db.Recipes.Select(r => r.Slug).ToHashSet();
        var toAdd = Load().Where(r => !existing.Contains(r.Slug)).Select(ToEntity).ToList();
        if (toAdd.Count == 0) return;

        db.Recipes.AddRange(toAdd);
        db.SaveChanges();
    }

    public static async Task SeedAsync(DbContext context, CancellationToken ct)
    {
        var db = (RecipeDbContext)context;
        var existing = (await db.Recipes.Select(r => r.Slug).ToListAsync(ct)).ToHashSet();
        var toAdd = Load().Where(r => !existing.Contains(r.Slug)).Select(ToEntity).ToList();
        if (toAdd.Count == 0) return;

        db.Recipes.AddRange(toAdd);
        await db.SaveChangesAsync(ct);
    }

    private static Entities.Recipe ToEntity(SeedRecipe s) => new()
    {
        Slug = s.Slug,
        Title = s.Title,
        Emoji = s.Emoji,
        Description = s.Description,
        Category = Enum.TryParse<RecipeCategory>(s.Category, ignoreCase: true, out var c)
            ? c
            : RecipeCategory.MainCourse,
        PrepMinutes = s.PrepMinutes,
        Servings = s.Servings,
        ImageUrl = $"/images/recipes/{s.Slug}.jpg",
        Ingredients = s.Ingredients.Select(i => new RecipeIngredient
        {
            IngredientId = i.Id,
            IngredientName = i.Name,
            Quantity = i.Quantity,
            Unit = i.Unit,
            IsOptional = i.Optional
        }).ToList(),
        Steps = s.Steps.Select((text, i) => new RecipeStep { Order = i + 1, Text = text }).ToList()
    };
}