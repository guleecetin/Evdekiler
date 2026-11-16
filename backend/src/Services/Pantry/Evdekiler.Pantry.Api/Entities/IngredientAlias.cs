namespace Evdekiler.Pantry.Api.Entities;

// Fişlerdeki kısaltma ve eşanlamlılar: "domates salcasi" -> Salça
public class IngredientAlias
{
    public int Id { get; set; }
    public int IngredientId { get; set; }
    public Ingredient Ingredient { get; set; } = null!;
    public string Alias { get; set; } = string.Empty;
}