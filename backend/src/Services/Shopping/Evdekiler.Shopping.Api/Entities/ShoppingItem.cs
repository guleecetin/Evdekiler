namespace Evdekiler.Shopping.Api.Entities;

public class ShoppingItem
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }

    public int IngredientId { get; set; }
    public string IngredientName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;

    public bool IsPurchased { get; set; }
    public DateTime? PurchasedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}