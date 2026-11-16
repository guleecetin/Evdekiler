using Evdekiler.Pantry.Api.Endpoints;
using Evdekiler.Pantry.Api.Entities;

namespace Evdekiler.Pantry.Api.Receipts;

public record ParseReceiptRequest(List<string> Lines);

public record ReceiptItem(
    IngredientResponse Ingredient, decimal Quantity, MeasureUnit Unit, string Confidence, List<string> Lines);

public record ParseReceiptResponse(List<ReceiptItem> Items, List<string> Unmatched);

public static class ReceiptEndpoints
{
    public static void MapReceiptEndpoints(this IEndpointRouteBuilder app)
    {
        // POST /api/pantry/receipts/parse  { "lines": ["DOMATES KG 1,250 ...", ...] }
        app.MapPost("/api/pantry/receipts/parse", Parse).RequireAuthorization();
    }

    private static async Task<IResult> Parse(
        ParseReceiptRequest request, IngredientCatalog catalog, CancellationToken ct)
    {
        if (request.Lines is not { Count: > 0 and <= 300 } || request.Lines.Any(l => l is null || l.Length > 200))
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["lines"] = ["1-300 arası satır gönderilmeli, her satır en fazla 200 karakter olmalı."]
            });

        var parsed = ReceiptParser.Parse(request.Lines);
        var matcher = await catalog.GetMatcherAsync(ct);

        var unmatched = new List<string>();
        var matched = new List<(IngredientMatch Match, decimal Quantity, MeasureUnit Unit, string Raw)>();

        foreach (var line in parsed)
        {
            var match = matcher.Match(line.Text);
            if (match is null)
            {
                unmatched.Add(line.Raw);
                continue;
            }

            // Fişte birim yoksa malzemenin varsayılan birimi, miktar yoksa 1
            var unit = Enum.TryParse<MeasureUnit>(line.Unit, out var u) ? u : match.Ingredient.DefaultUnit;
            matched.Add((match, line.Quantity ?? 1, unit, line.Raw));
        }

        // Aynı malzeme aynı birimle birden çok satırdaysa topla
        var items = matched
            .GroupBy(m => (m.Match.Ingredient.Id, m.Unit))
            .Select(g =>
            {
                var ing = g.First().Match.Ingredient;
                var confidence = g.Any(m => m.Match.Confidence == MatchConfidence.Medium) ? "Medium" : "High";
                return new ReceiptItem(
                    new IngredientResponse(ing.Id, ing.Name, ing.Emoji, $"/images/ingredients/{ing.Id}.jpg",
                        ing.Category, ing.DefaultUnit),
                    g.Sum(m => m.Quantity),
                    g.Key.Unit,
                    confidence,
                    g.Select(m => m.Raw).ToList());
            })
            .ToList();

        return Results.Ok(new ParseReceiptResponse(items, unmatched));
    }
}