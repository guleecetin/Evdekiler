using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Endpoints;
using Evdekiler.Pantry.Api.Entities;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Pantry.Api.Receipts;

public record ParseReceiptRequest(List<string> Lines);

public record ResolveLineRequest(string Line, int IngredientId);

public record ReceiptItem(
    IngredientResponse Ingredient, decimal Quantity, MeasureUnit Unit, string Confidence, List<string> Lines);

public record ParseReceiptResponse(List<ReceiptItem> Items, List<string> Unmatched);

public static class ReceiptEndpoints
{
    public static void MapReceiptEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/pantry/receipts/parse", Parse).RequireAuthorization();
        app.MapPost("/api/pantry/receipts/resolve", Resolve).RequireAuthorization();
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

            var unit = Enum.TryParse<MeasureUnit>(line.Unit, out var u) ? u : match.Ingredient.DefaultUnit;
            matched.Add((match, line.Quantity ?? 1, unit, line.Raw));
        }

        var items = matched
            .GroupBy(m => (m.Match.Ingredient.Id, m.Unit))
            .Select(g =>
            {
                var ing = g.First().Match.Ingredient;
                var confidence = g.Any(m => m.Match.Confidence == MatchConfidence.Medium) ? "Medium" : "High";
                return new ReceiptItem(
                    new IngredientResponse(ing.Id, ing.Name, ing.Emoji,
                        ing.ImageUrl ?? $"/images/ingredients/{ing.Id}.jpg", ing.Category, ing.DefaultUnit),
                    g.Sum(m => m.Quantity),
                    g.Key.Unit,
                    confidence,
                    g.Select(m => m.Raw).ToList());
            })
            .ToList();

        return Results.Ok(new ParseReceiptResponse(items, unmatched));
    }

    // Kullanıcı tanınmayan bir satır için malzemeyi kendisi seçti
    private static async Task<IResult> Resolve(
        ResolveLineRequest request, PantryDbContext db, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Line) || request.Line.Length > 200)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["line"] = ["Satır 1-200 karakter olmalı."]
            });

        var ingredient = await db.Ingredients.AsNoTracking()
            .FirstOrDefaultAsync(i => i.Id == request.IngredientId, ct);
        if (ingredient is null) return Results.NotFound();

        // Miktar ve birimi yine ayrıştırıcıdan al
        var parsed = ReceiptParser.Parse([request.Line]).FirstOrDefault();
        var quantity = parsed?.Quantity ?? 1;
        var unit = Enum.TryParse<MeasureUnit>(parsed?.Unit, out var u) ? u : ingredient.DefaultUnit;

        // Öğrenme: bu yazılış henüz eşanlamlı değilse öneri olarak kaydet
        var key = AliasRules.Normalize(parsed?.Text);
        if (key.Length >= AliasRules.MinLength &&
            !await db.Set<IngredientAlias>().AnyAsync(a => a.Alias == key, ct))
        {
            await RecordSuggestionAsync(db, key, ingredient.Id, request.Line, ct);
        }

        var item = new ReceiptItem(
            new IngredientResponse(ingredient.Id, ingredient.Name, ingredient.Emoji,
                ingredient.ImageUrl ?? $"/images/ingredients/{ingredient.Id}.jpg",
                ingredient.Category, ingredient.DefaultUnit),
            quantity, unit, "Manual", [request.Line]);

        return Results.Ok(item);
    }

    // "Varsa sayacı artır, yoksa ekle" (upsert), eşzamanlı isteklere dayanıklı
    private static async Task RecordSuggestionAsync(
        PantryDbContext db, string key, int ingredientId, string sampleLine, CancellationToken ct)
    {
        var now = DateTime.UtcNow;

        Task<int> Increment() => db.Set<AliasSuggestion>()
            .Where(s => s.Text == key && s.IngredientId == ingredientId)
            .ExecuteUpdateAsync(s => s
                .SetProperty(x => x.Count, x => x.Count + 1)
                .SetProperty(x => x.LastSeenAt, now), ct);

        // 1. Önce var olanı artırmayı dene (tek SQL: UPDATE ... SET "Count" = "Count" + 1)
        if (await Increment() > 0) return;

        // 2. Yoksa yeni öneri ekle
        db.Add(new AliasSuggestion
        {
            IngredientId = ingredientId,
            Text = key,
            SampleLine = sampleLine,
            Count = 1,
            CreatedAt = now,
            LastSeenAt = now
        });

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // 3. Bu arada başka bir kullanıcı aynı öneriyi eklemiş: o zaman onu artır
            await Increment();
        }
    }
}