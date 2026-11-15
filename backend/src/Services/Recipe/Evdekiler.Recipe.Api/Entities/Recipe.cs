namespace Evdekiler.Recipe.Api.Entities;

// Sıra önemli: varsayılan değer (0) MainCourse
public enum RecipeCategory
{
    MainCourse,   // Ana yemek
    Dessert,      // Tatlı
    Breakfast,    // Kahvaltılık
    Soup,         // Çorba
    Salad,        // Salata
    Pastry,       // Hamur işi
    Snack         // Atıştırmalık
}

public class Recipe
{
    public int Id { get; set; }
    public string Slug { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public RecipeCategory Category { get; set; }
    public int PrepMinutes { get; set; }
    public int Servings { get; set; }

    public List<RecipeIngredient> Ingredients { get; set; } = [];
    public List<RecipeStep> Steps { get; set; } = [];
}

public class RecipeIngredient
{
    public int RecipeId { get; set; }
    public int IngredientId { get; set; }
    public string IngredientName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public bool IsOptional { get; set; }
}

public class RecipeStep
{
    public int RecipeId { get; set; }
    public int Order { get; set; }
    public string Text { get; set; } = string.Empty;
}