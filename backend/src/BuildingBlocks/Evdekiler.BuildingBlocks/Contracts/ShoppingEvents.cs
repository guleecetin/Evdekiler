namespace Evdekiler.BuildingBlocks.Contracts;

public record ShoppingItemPurchased(
    Guid ShoppingItemId,
    Guid UserId,
    int IngredientId,
    decimal Quantity,
    string Unit,
    DateTime PurchasedAt);