namespace Evdekiler.Pantry.Api.Entities;

public class PantryItem
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public int IngredientId { get; set; }
    public Ingredient Ingredient { get; set; } = null!;

    public decimal Quantity { get; set; }
    public MeasureUnit Unit { get; set; }
    public DateOnly? ExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    // Alışveriş listesinden geldiyse, hangi üründen geldiği (tekrar eklemeyi önlemek için)
    public Guid? SourceShoppingItemId { get; set; }

    public uint Version { get; set; }
}