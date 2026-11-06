using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Pantry.Api.Data;

public class PantryDbContext(DbContextOptions<PantryDbContext> options) : DbContext(options)
{
    public DbSet<Ingredient> Ingredients => Set<Ingredient>();
    public DbSet<PantryItem> PantryItems => Set<PantryItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Ingredient>(entity =>
        {
            entity.HasKey(i => i.Id);
            entity.Property(i => i.Name).HasMaxLength(100).IsRequired();
            entity.HasIndex(i => i.Name).IsUnique();
            entity.Property(i => i.Emoji).HasMaxLength(16);
            entity.Property(i => i.Category).HasConversion<string>().HasMaxLength(20);
            entity.Property(i => i.DefaultUnit).HasConversion<string>().HasMaxLength(20);
            entity.HasData(IngredientSeed.All);
        });

        modelBuilder.Entity<PantryItem>(entity =>
        {
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Quantity).HasPrecision(10, 2);
            entity.Property(p => p.Unit).HasConversion<string>().HasMaxLength(20);

            entity.HasOne(p => p.Ingredient)
                .WithMany()
                .HasForeignKey(p => p.IngredientId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(p => new { p.UserId, p.ExpiresAt });

            entity.Property(p => p.Version).IsRowVersion();
        });
    }
}