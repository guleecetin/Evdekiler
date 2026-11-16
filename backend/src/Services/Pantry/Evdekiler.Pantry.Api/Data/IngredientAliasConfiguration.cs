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

        // Eşanlamlılar sadeleştirilmiş, küçük harf yazılır (fişler Türkçe karaktersiz gelir)
        entity.HasData(
            A(1, 27, "domates salcasi"),
            A(2, 27, "biber salcasi"),
            A(3, 49, "unlu mam"),
            A(4, 49, "francala"),
            A(5, 16, "kasar"),
            A(6, 15, "beyaz peyn"),
            A(7, 19, "tavuk gogus"),
            A(8, 19, "pilic gogus"),
            A(9, 108, "pilic but"),
            A(10, 60, "aycicek"),
            A(11, 28, "zeytin yagi"),
            A(12, 21, "baldo"),
            A(13, 21, "osmancik"),
            A(14, 22, "spagetti"),
            A(15, 22, "penne"),
            A(16, 25, "kirmizi mercimek"),
            A(17, 55, "toz seker"),
            A(18, 55, "kup seker"),
            A(19, 31, "maydonoz"),
            A(20, 20, "dana kiyma"));
    }

    private static IngredientAlias A(int id, int ingredientId, string alias) =>
        new() { Id = id, IngredientId = ingredientId, Alias = alias };
}