using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Evdekiler.Pantry.Api.Data;

public class IngredientAliasConfiguration : IEntityTypeConfiguration<IngredientAlias>
{
    public void Configure(EntityTypeBuilder<IngredientAlias> entity)
    {
        entity.HasKey(a => a.Id);
        entity.Property(a => a.Alias).HasMaxLength(60).IsRequired();
        entity.HasIndex(a => a.Alias).IsUnique();

        entity.HasOne(a => a.Ingredient)
            .WithMany()
            .HasForeignKey(a => a.IngredientId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}