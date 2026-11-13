using Evdekiler.BuildingBlocks.Contracts;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Entities;
using MassTransit;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Pantry.Api.Consumers;

public class ShoppingItemPurchasedConsumer(
    PantryDbContext db,
    ILogger<ShoppingItemPurchasedConsumer> logger) : IConsumer<ShoppingItemPurchased>
{
    public async Task Consume(ConsumeContext<ShoppingItemPurchased> context)
    {
        var msg = context.Message;

        // Bu haber daha önce işlendiyse tekrar ekleme
        if (await db.PantryItems.AnyAsync(p => p.SourceShoppingItemId == msg.ShoppingItemId))
        {
            logger.LogInformation("Zaten işlenmiş, atlandı: {Id}", msg.ShoppingItemId);
            return;
        }

        var ingredient = await db.Ingredients.FindAsync(msg.IngredientId);
        if (ingredient is null) return;

        var unit = Enum.TryParse<MeasureUnit>(msg.Unit, out var u) ? u : ingredient.DefaultUnit;

        db.PantryItems.Add(new PantryItem
        {
            Id = Guid.CreateVersion7(),
            UserId = msg.UserId,
            IngredientId = ingredient.Id,
            Quantity = msg.Quantity,
            Unit = unit,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            SourceShoppingItemId = msg.ShoppingItemId
        });

        await db.SaveChangesAsync();
        logger.LogInformation("{Name} buzdolabına eklendi", ingredient.Name);
    }
}