using Evdekiler.Identity.Api.Auth;
using Evdekiler.Identity.Api.Data;
using Evdekiler.Identity.Api.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Evdekiler.Identity.Api.Endpoints;

public record RegisterRequest(string Email, string Password, string DisplayName);
public record LoginRequest(string Email, string Password);
public record RefreshRequest(string RefreshToken);
public record UserResponse(Guid Id, string Email, string DisplayName);
public record TokenResponse(
    string AccessToken,
    DateTime AccessTokenExpiresAt,
    string RefreshToken,
    DateTime RefreshTokenExpiresAt);

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth");
        group.MapPost("/register", Register);
        group.MapPost("/login", Login);
        group.MapPost("/refresh", Refresh);
        group.MapPost("/logout", Logout);
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

        if (result == PasswordVerificationResult.SuccessRehashNeeded)
            user.PasswordHash = hasher.HashPassword(user, request.Password);

        return Results.Ok(await IssueTokensAsync(user, db, tokens, ct));
    }

    private static async Task<IResult> Refresh(
        RefreshRequest request,
        AppDbContext db,
        TokenService tokens,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            return InvalidRefreshToken();

        var hash = TokenService.HashToken(request.RefreshToken);
        var stored = await db.RefreshTokens
            .Include(t => t.User)
            .SingleOrDefaultAsync(t => t.TokenHash == hash, ct);

        if (stored is null)
            return InvalidRefreshToken();

        var now = DateTime.UtcNow;

        // Daha önce kullanılmış (iptal edilmiş) bir token tekrar geldi:
        // token çalınmış olabilir, kullanıcının bütün oturumlarını kapat.
        if (stored.RevokedAt is not null)
        {
            await db.RefreshTokens
                .Where(t => t.UserId == stored.UserId && t.RevokedAt == null)
                .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAt, now), ct);
            return InvalidRefreshToken();
        }

        if (stored.ExpiresAt <= now)
            return InvalidRefreshToken();

        // Eski token'ı iptal et. "RevokedAt == null" şartı sayesinde aynı token
        // ile aynı anda iki istek gelirse sadece biri başarılı olur.
        var revoked = await db.RefreshTokens
            .Where(t => t.Id == stored.Id && t.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAt, now), ct);

        if (revoked == 0)
            return InvalidRefreshToken();

        return Results.Ok(await IssueTokensAsync(stored.User, db, tokens, ct));
    }

    private static async Task<IResult> Logout(
        RefreshRequest request,
        AppDbContext db,
        CancellationToken ct)
    {
        if (!string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            var hash = TokenService.HashToken(request.RefreshToken);
            var now = DateTime.UtcNow;

            await db.RefreshTokens
                .Where(t => t.TokenHash == hash && t.RevokedAt == null)
                .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAt, now), ct);
        }

        return Results.NoContent();
    }

    private static async Task<TokenResponse> IssueTokensAsync(
        User user, AppDbContext db, TokenService tokens, CancellationToken ct)
    {
        var (accessToken, accessExpiresAt) = tokens.CreateAccessToken(user);
        var (refreshToken, refreshEntity) = tokens.CreateRefreshToken(user.Id);

        db.RefreshTokens.Add(refreshEntity);
        await db.SaveChangesAsync(ct);

        return new TokenResponse(accessToken, accessExpiresAt,
            refreshToken, refreshEntity.ExpiresAt);
    }

    private static IResult InvalidCredentials() =>
        Results.Problem("E-posta veya şifre hatalı.",
            statusCode: StatusCodes.Status401Unauthorized);

    private static IResult InvalidRefreshToken() =>
        Results.Problem("Oturumun sona erdi, lütfen tekrar giriş yap.",
            statusCode: StatusCodes.Status401Unauthorized);
}