namespace Evdekiler.Pantry.Api.Receipts;

public static class AliasRules
{
    public const int MinLength = 3;
    public const int MaxLength = 60;

    // "SIYAHÇAY  FSKBRLK" -> "siyahcay fskbrlk"
    public static string Normalize(string? text)
    {
        var key = string.Join(' ',
            IngredientMatcher.Key(text ?? "").Split(' ', StringSplitOptions.RemoveEmptyEntries));
        return key.Length > MaxLength ? key[..MaxLength].TrimEnd() : key;
    }
}