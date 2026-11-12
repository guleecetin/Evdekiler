namespace Evdekiler.Recipe.Api.Entities;

public class Recipe
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public int PrepMinutes { get; set; }
    public int Servings { get; set; }

    public List<RecipeIngredient> Ingredients { get; set; } = [];
    public List<RecipeStep> Steps { get; set; } = [];
}

public class RecipeIngredient
{
    public int RecipeId { get; set; }
    public int IngredientId { get; set; }        // Pantry kataloğundaki Id
    public string IngredientName { get; set; } = string.Empty; // denormalize kopya
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public bool IsOptional { get; set; }         // tuz, pul biber gibi
}

public class RecipeStep
{
    public int RecipeId { get; set; }
    public int Order { get; set; }
    public string Text { get; set; } = string.Empty;
}