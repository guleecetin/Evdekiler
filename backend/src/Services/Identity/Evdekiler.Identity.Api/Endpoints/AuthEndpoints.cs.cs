using Evdekiler.Identity.Api.Auth;
using Evdekiler.Identity.Api.Data;
using Evdekiler.Identity.Api.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Identity.Api.Endpoints;

public record RegisterRequest(string Email, string Password, string DisplayName);
public record LoginRequest(string Email, string Password);
public record UserResponse(Guid Id, string Email, string DisplayName);
public record TokenResponse(string AccessToken, DateTime ExpiresAt);

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth");
        group.MapPost("/register", Register);
        group.MapPost("/login", Login);
    }

    private static async Task<IResult> Register(
        RegisterRequest request,
        AppDbContext db,
        IPasswordHasher<User> hasher,
        CancellationToken ct)
    {
        var email = request.Email?.Trim().ToLowerInvariant() ?? "";
        var displayName = request.DisplayName?.Trim() ?? "";

        var errors = new Dictionary<string, string[]>();
        if (!email.Contains('@') || email.Length > 256)
            errors["email"] = ["Geçerli bir e-posta adresi girin."];
        if (request.Password is null || request.Password.Length < 8)
            errors["password"] = ["Şifre en az 8 karakter olmalı."];
        if (displayName.Length is 0 or > 100)
            errors["displayName"] = ["İsim 1-100 karakter olmalı."];
        if (errors.Count > 0)
            return Results.ValidationProblem(errors);

        if (await db.Users.AnyAsync(u => u.Email == email, ct))
            return Results.Problem("Bu e-posta adresi zaten kullanılıyor.",
                statusCode: StatusCodes.Status409Conflict);

        var user = new User
        {
            Id = Guid.CreateVersion7(),
            Email = email,
            DisplayName = displayName,
            CreatedAt = DateTime.UtcNow
        };
        user.PasswordHash = hasher.HashPassword(user, request.Password!);

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

        return Results.Created($"/api/users/{user.Id}",
            new UserResponse(user.Id, user.Email, user.DisplayName));
    }

    private static async Task<IResult> Login(
        LoginRequest request,
        AppDbContext db,
        IPasswordHasher<User> hasher,
        TokenService tokens,
        CancellationToken ct)
    {
        var email = request.Email?.Trim().ToLowerInvariant() ?? "";

        var user = await db.Users.SingleOrDefaultAsync(u => u.Email == email, ct);
        if (user is null || request.Password is null)
            return InvalidCredentials();

        var result = hasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);
        if (result == PasswordVerificationResult.Failed)
            return InvalidCredentials();

        // Hash algoritması güncellendiyse şifreyi yeni ayarlarla tekrar hash'le
        if (result == PasswordVerificationResult.SuccessRehashNeeded)
        {
            user.PasswordHash = hasher.HashPassword(user, request.Password);
            await db.SaveChangesAsync(ct);
        }

        var (token, expiresAt) = tokens.CreateAccessToken(user);
        return Results.Ok(new TokenResponse(token, expiresAt));
    }

    private static IResult InvalidCredentials() =>
        Results.Problem("E-posta veya şifre hatalı.",
            statusCode: StatusCodes.Status401Unauthorized);
}