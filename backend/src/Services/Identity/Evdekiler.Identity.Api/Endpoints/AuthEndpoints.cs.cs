using Evdekiler.Identity.Api.Data;
using Evdekiler.Identity.Api.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Identity.Api.Endpoints;

public record RegisterRequest(string Email, string Password, string DisplayName);
public record UserResponse(Guid Id, string Email, string DisplayName);

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth");
        group.MapPost("/register", Register);
    }

    private static async Task<IResult> Register(
        RegisterRequest request,
        AppDbContext db,
        IPasswordHasher<User> hasher,
        CancellationToken ct)
    {
        // 1. Veriyi temizle
        var email = request.Email?.Trim().ToLowerInvariant() ?? "";
        var displayName = request.DisplayName?.Trim() ?? "";

        // 2. Doğrula
        var errors = new Dictionary<string, string[]>();
        if (!email.Contains('@') || email.Length > 256)
            errors["email"] = ["Geçerli bir e-posta adresi girin."];
        if (request.Password is null || request.Password.Length < 8)
            errors["password"] = ["Şifre en az 8 karakter olmalı."];
        if (displayName.Length is 0 or > 100)
            errors["displayName"] = ["İsim 1-100 karakter olmalı."];
        if (errors.Count > 0)
            return Results.ValidationProblem(errors);

        // 3. Mail kullanılıyor mu? (normal durum için kontrol)
        if (await db.Users.AnyAsync(u => u.Email == email, ct))
            return Results.Problem("Bu e-posta adresi zaten kullanılıyor.",
                statusCode: StatusCodes.Status409Conflict);

        // 4. Kullanıcıyı oluştur, şifreyi hash'le
        var user = new User
        {
            Id = Guid.CreateVersion7(),
            Email = email,
            DisplayName = displayName,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = hasher.HashPassword(user, request.Password!);

        // 5. Kaydet (race condition'a karşı unique index hatasını yakala)
        db.Users.Add(user);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            return Results.Problem("Bu e-posta adresi zaten kullanılıyor.",
                statusCode: StatusCodes.Status409Conflict);
        }

        // 6. Cevap dön (şifre hash'i asla dönmez!)
        return Results.Created($"/api/users/{user.Id}",
            new UserResponse(user.Id, user.Email, user.DisplayName));
    }
}