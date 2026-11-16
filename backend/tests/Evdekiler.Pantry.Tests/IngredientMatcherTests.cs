using Evdekiler.Pantry.Api.Entities;
using Evdekiler.Pantry.Api.Receipts;

namespace Evdekiler.Pantry.Tests;

public class IngredientMatcherTests
{
    private static CatalogIngredient I(int id, string name) =>
        new(id, name, "", IngredientCategory.Other, MeasureUnit.Piece);

    // Gerçek kataloğun temsili bir parçası: kısa adlar, çok kelimeliler, birbirinin başı olan adlar
    private static readonly CatalogIngredient[] Catalog =
    [
        I(1, "Domates"), I(13, "Süt"), I(15, "Beyaz peynir"), I(16, "Kaşar peyniri"), I(24, "Un"),
        I(27, "Salça"), I(28, "Zeytinyağı"), I(41, "Mısır"), I(49, "Ekmek"), I(51, "Tel şehriye"),
        I(52, "Karabiber"), I(79, "Zeytin"), I(96, "Arpa şehriye"), I(102, "Mısır unu")
    ];

    private static readonly IngredientMatcher Matcher = new(Catalog,
    [
        new CatalogAlias("domates salcasi", 27),
        new CatalogAlias("unlu mam", 49),
        new CatalogAlias("kasar", 16)
    ]);

    // Eşanlamlısız: kısaltma kuralını tek başına denemek için
    private static readonly IngredientMatcher MatcherWithoutAliases = new(Catalog, []);

    [Theory]
    [InlineData("PINAR SUT", 13)]
    [InlineData("SUT TAM YAG", 13)]
    [InlineData("KASAR PEYN", 16)]
    [InlineData("DOMATES", 1)]
    [InlineData("DOMATES SALCASI", 27)]
    [InlineData("K BAKI UNLU MAM", 49)]
    [InlineData("ZEYTINYAGI", 28)]
    [InlineData("MISIR UNU", 102)]
    [InlineData("MISIR", 41)]
    [InlineData("TEL SEHRIYE", 51)]
    [InlineData("UN", 24)]
    [InlineData("KARABIBER 50G", 52)]
    public void Matches_receipt_text_to_catalog(string text, int expectedId)
    {
        var match = Matcher.Match(text);

        Assert.NotNull(match);
        Assert.Equal(expectedId, match.Ingredient.Id);
    }

    [Fact]
    public void Abbreviation_is_accepted_when_another_word_matches_fully()
    {
        // "kasar" tam, "peyn" -> "peyniri" kısaltma
        var match = MatcherWithoutAliases.Match("KASAR PEYN");

        Assert.NotNull(match);
        Assert.Equal(16, match.Ingredient.Id);
        Assert.Equal(MatchConfidence.Medium, match.Confidence);
    }

    [Theory]
    [InlineData("COCA COLA")]
    [InlineData("EMRE AYDIN")]
    [InlineData("IYI DUSUN DOGRU KARA")]   // "kara" tek başına "karabiber" sayılmamalı
    [InlineData("BEYAZ")]                  // "beyaz peynir"in sadece bir kelimesi
    public void Does_not_match_unrelated_lines(string text)
    {
        Assert.Null(Matcher.Match(text));
    }
}