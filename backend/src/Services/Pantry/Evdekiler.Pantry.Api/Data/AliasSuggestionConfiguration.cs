using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Evdekiler.Pantry.Api.Data;

public class AliasSuggestionConfiguration : IEntityTypeConfiguration<AliasSuggestion>
{
    public void Configure(EntityTypeBuilder<AliasSuggestion> entity)
    {
        entity.HasKey(s => s.Id);
        entity.Property(s => s.Text).HasMaxLength(60).IsRequired();
        entity.Property(s => s.SampleLine).HasMaxLength(200).IsRequired();

        // Aynı metin + aynı malzeme tek satır: tekrar önerilince sayaç artar
        entity.HasIndex(s => new { s.Text, s.IngredientId }).IsUnique();
        entity.HasIndex(s => s.Count);

        entity.HasOne(s => s.Ingredient)
            .WithMany()
            .HasForeignKey(s => s.IngredientId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}