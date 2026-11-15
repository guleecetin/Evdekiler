using Evdekiler.Recipe.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Recipe.Api.Data;

public class RecipeDbContext(DbContextOptions<RecipeDbContext> options) : DbContext(options)
{
    public DbSet<Entities.Recipe> Recipes => Set<Entities.Recipe>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Entities.Recipe>(entity =>
        {
            entity.HasKey(r => r.Id);
            entity.Property(r => r.Slug).HasMaxLength(100).IsRequired();
            entity.HasIndex(r => r.Slug).IsUnique();
            entity.Property(r => r.ImageUrl).HasMaxLength(200);
            entity.Property(r => r.Title).HasMaxLength(150).IsRequired();
            entity.Property(r => r.Description).HasMaxLength(500);
            entity.Property(r => r.Emoji).HasMaxLength(16);

            // Enum veritabanında metin olarak: "MainCourse", "Dessert"...
            entity.Property(r => r.Category)
                .HasConversion<string>()
                .HasMaxLength(20)
                .HasDefaultValue(RecipeCategory.MainCourse);
            entity.HasIndex(r => r.Category);

            entity.HasMany(r => r.Ingredients).WithOne().HasForeignKey(i => i.RecipeId);
            entity.HasMany(r => r.Steps).WithOne().HasForeignKey(s => s.RecipeId);
        });

        modelBuilder.Entity<RecipeIngredient>(entity =>
        {
            entity.HasKey(i => new { i.RecipeId, i.IngredientId });
            entity.Property(i => i.IngredientName).HasMaxLength(100).IsRequired();
            entity.Property(i => i.Quantity).HasPrecision(10, 2);
            entity.Property(i => i.Unit).HasMaxLength(20);
            entity.HasIndex(i => i.IngredientId);
        });

        modelBuilder.Entity<RecipeStep>(entity =>
        {
            entity.HasKey(s => new { s.RecipeId, s.Order });
            entity.Property(s => s.Text).HasMaxLength(1000).IsRequired();
        });
    }
}