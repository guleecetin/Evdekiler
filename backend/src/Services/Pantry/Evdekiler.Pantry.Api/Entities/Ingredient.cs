namespace Evdekiler.Pantry.Api.Entities;

public class Ingredient
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Emoji { get; set; } = string.Empty;
    public IngredientCategory Category { get; set; }
    public MeasureUnit DefaultUnit { get; set; }

    // Panelden yüklenen fotoğraf (Blob Storage). Boşsa eski kural: /images/ingredients/{Id}.jpg
    public string? ImageUrl { get; set; }
}