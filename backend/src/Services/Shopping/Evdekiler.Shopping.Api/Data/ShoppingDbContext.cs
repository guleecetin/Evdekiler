using Evdekiler.Shopping.Api.Entities;
using MassTransit;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Shopping.Api.Data;

public class ShoppingDbContext(DbContextOptions<ShoppingDbContext> options) : DbContext(options)
{
    public DbSet<ShoppingItem> ShoppingItems => Set<ShoppingItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ShoppingItem>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.Property(i => i.IngredientName).HasMaxLength(100).IsRequired();
            entity.Property(i => i.Quantity).HasPrecision(10, 2);
            entity.Property(i => i.Unit).HasMaxLength(20);

            // Aynı malzeme listede (alınmamışken) iki kez olmasın
            entity.HasIndex(i => new { i.UserId, i.IngredientId })
                .IsUnique()
                .HasFilter("\"IsPurchased\" = false");
        });

        // MassTransit'in Outbox tabloları
        modelBuilder.AddInboxStateEntity();
        modelBuilder.AddOutboxMessageEntity();
        modelBuilder.AddOutboxStateEntity();
    }
}