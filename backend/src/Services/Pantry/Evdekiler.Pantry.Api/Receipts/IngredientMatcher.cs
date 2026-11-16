using Evdekiler.Pantry.Api.Entities;

namespace Evdekiler.Pantry.Api.Receipts;

public sealed record CatalogIngredient(
    int Id, string Name, string Emoji, IngredientCategory Category, MeasureUnit DefaultUnit,
    string? ImageUrl = null);

public sealed record CatalogAlias(string Alias, int IngredientId);

public enum MatchConfidence { High, Medium }

public sealed record IngredientMatch(CatalogIngredient Ingredient, MatchConfidence Confidence);

public sealed class IngredientMatcher
{
    private enum WordMatch { None, Abbreviation, Full }

    private readonly List<(CatalogIngredient Ingredient, string[] Words, int Length)> _entries;
    private readonly List<(string Alias, CatalogIngredient Ingredient)> _aliases;

    public IngredientMatcher(IEnumerable<CatalogIngredient> ingredients, IEnumerable<CatalogAlias> aliases)
    {
        var byId = ingredients.ToDictionary(i => i.Id);

        _entries = byId.Values
            .Select(i =>
            {
                var key = Key(i.Name);
                return (i, key.Split(' ', StringSplitOptions.RemoveEmptyEntries), key.Length);
            })
            .ToList();

        _aliases = aliases
            .Where(a => byId.ContainsKey(a.IngredientId))
            .Select(a => (Key(a.Alias), byId[a.IngredientId]))
            .OrderByDescending(a => a.Item1.Length)
            .ToList();
    }

    public IngredientMatch? Match(string text)
    {
        var key = Key(text);
        var padded = $" {key} ";
        var lineWords = key.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        foreach (var (alias, ingredient) in _aliases)
        {
            if (padded.Contains($" {alias}"))
                return new IngredientMatch(ingredient, MatchConfidence.High);
        }

        IngredientMatch? best = null;
        var bestWords = 0;
        var bestLength = 0;

        foreach (var (ingredient, words, length) in _entries)
        {
            var results = words.Select(w => BestMatch(w, lineWords)).ToArray();

            if (results.Any(r => r == WordMatch.None)) continue;
            if (!results.Any(r => r == WordMatch.Full)) continue;

            if (words.Length > bestWords || (words.Length == bestWords && length > bestLength))
            {
                var confidence = results.All(r => r == WordMatch.Full) ? MatchConfidence.High : MatchConfidence.Medium;
                best = new IngredientMatch(ingredient, confidence);
                bestWords = words.Length;
                bestLength = length;
            }
        }

        return best;
    }

    private static WordMatch BestMatch(string nameWord, string[] lineWords)
    {
        var result = WordMatch.None;

        foreach (var lineWord in lineWords)
        {
            if (nameWord.Length <= 3)
            {
                if (lineWord == nameWord) return WordMatch.Full;
                continue;
            }

            if (lineWord.StartsWith(nameWord)) return WordMatch.Full;

            if (lineWord.Length >= 4 && lineWord.Length * 2 >= nameWord.Length && nameWord.StartsWith(lineWord))
                result = WordMatch.Abbreviation;
        }

        return result;
    }

    public static string Key(string text) => ReceiptParser.Fold(text).ToLowerInvariant();
}