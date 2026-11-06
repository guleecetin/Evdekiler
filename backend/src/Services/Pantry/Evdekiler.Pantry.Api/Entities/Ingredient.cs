namespace Evdekiler.Pantry.Api.Entities;

public class Ingredient
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public IngredientCategory Category { get; set; }
    public MeasureUnit DefaultUnit { get; set; }
}