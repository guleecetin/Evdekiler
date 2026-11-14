using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Recipe.Api.Data;
using Evdekiler.Recipe.Api.Storage;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Recipe.Api.Endpoints;

public static class AdminRecipeImageEndpoints
{
    private const long MaxBytes = 5 * 1024 * 1024; // 5 MB

    public static void MapAdminRecipeImageEndpoints(this IEndpointRouteBuilder app)
    {
        // POST /api/admin/recipes/{id}/image   (multipart/form-data, alan adı: file)
        app.MapPost("/api/admin/recipes/{id:int}/image", Upload)
            .RequireAuthorization(AuthPolicies.Admin)
            .DisableAntiforgery();
    }

    private static async Task<IResult> Upload(
        int id, IFormFile file, RecipeDbContext db, ImageStorage storage, CancellationToken ct)
    {
        // 1. Boyut kontrolü
        if (file.Length is 0 or > MaxBytes)
            return Error("Dosya boş olamaz ve 5 MB'ı geçemez.");

        // 2. Gerçekten resim mi? Dosyanın ilk baytlarına bakıyoruz
        await using var stream = file.OpenReadStream();
        var header = new byte[12];
        var read = await stream.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false, ct);
        stream.Position = 0;

        var format = read == header.Length ? DetectFormat(header) : null;
        if (format is null)
            return Error("Sadece JPEG, PNG veya WebP yüklenebilir.");

        var recipe = await db.Recipes.SingleOrDefaultAsync(r => r.Id == id, ct);
        if (recipe is null) return Results.NotFound();

        // 3. Dosya adını BİZ üretiyoruz; kullanıcının gönderdiği adı asla kullanmıyoruz
        var blobName = $"recipes/{recipe.Slug}-{Guid.NewGuid():N}.{format.Value.Extension}";

        // 4. Yükle ve adresi tarife yaz
        recipe.ImageUrl = await storage.UploadAsync(stream, blobName, format.Value.ContentType, ct);
        await db.SaveChangesAsync(ct);

        return Results.Ok(new { recipe.Id, recipe.ImageUrl });
    }

    // Dosya imzaları ("magic bytes")
    private static (string Extension, string ContentType)? DetectFormat(byte[] h)
    {
        if (h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF)
            return ("jpg", "image/jpeg");

        if (h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47)
            return ("png", "image/png");

        // "RIFF....WEBP"
        if (h[0] == 0x52 && h[1] == 0x49 && h[2] == 0x46 && h[3] == 0x46 &&
            h[8] == 0x57 && h[9] == 0x45 && h[10] == 0x42 && h[11] == 0x50)
            return ("webp", "image/webp");

        return null;
    }

    private static IResult Error(string message) =>
        Results.ValidationProblem(new Dictionary<string, string[]> { ["file"] = [message] });
}