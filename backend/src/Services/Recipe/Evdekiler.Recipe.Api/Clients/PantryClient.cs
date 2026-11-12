namespace Evdekiler.Recipe.Api.Clients;

// Pantry cevabından sadece ihtiyacımız olan alanlar
public record PantryItemDto(int IngredientId, DateOnly? ExpiresAt);

public class PantryClient(HttpClient http)
{
    public async Task<HashSet<int>> GetIngredientIdsAsync(
        string authorizationHeader, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/pantry/items");
        request.Headers.TryAddWithoutValidation("Authorization", authorizationHeader);

        using var response = await http.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();

        var items = await response.Content
            .ReadFromJsonAsync<List<PantryItemDto>>(cancellationToken: ct) ?? [];

        // Kullanıcının bugünü (sunucu UTC'de çalışıyor, kullanıcı Türkiye'de)
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeBySystemTimeZoneId(DateTime.UtcNow, "Europe/Istanbul"));

        // Süresi geçmiş ürünler "elimde var" sayılmaz
        return items
            .Where(i => i.ExpiresAt is null || i.ExpiresAt >= today)
            .Select(i => i.IngredientId)
            .ToHashSet();
    }
}