using System.Security.Claims;
using System.Text.RegularExpressions;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Identity.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Identity.Api.Endpoints;

public record MeResponse(Guid Id, string Email, string DisplayName, string Role);
public record UserListItem(Guid Id, string Email, string DisplayName, string Role, DateTime CreatedAt);
public record UserPage(List<UserListItem> Items, int Page, int PageSize, int TotalCount, int AdminCount);
public record ChangeRoleRequest(string Role);

public static class UserEndpoints
{
    private const string AdminRole = "Admin";
    private static readonly string[] Roles = ["User", AdminRole];

    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        // Giriş yapmış herkes
        app.MapGet("/api/users/me", GetMe).RequireAuthorization();

        // Sadece Admin rolü
        var admin = app.MapGroup("/api/users").RequireAuthorization(AuthPolicies.Admin);
        admin.MapGet("", GetAll);
        admin.MapPut("/{id:guid}/role", ChangeRole);
    }

    private static async Task<IResult> GetMe(
        ClaimsPrincipal principal, AppDbContext db, CancellationToken ct)
    {
        var userId = principal.GetUserId();

        var user = await db.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new MeResponse(u.Id, u.Email, u.DisplayName, u.Role))
            .SingleOrDefaultAsync(ct);

        return user is null ? Results.NotFound() : Results.Ok(user);
    }

    // GET /api/users?page=1&pageSize=20&search=gul&role=Admin
    private static async Task<IResult> GetAll(
        int? page, int? pageSize, string? search, string? role,
        AppDbContext db, CancellationToken ct)
    {
        var currentPage = Math.Max(1, page ?? 1);
        var size = Math.Clamp(pageSize ?? 20, 1, 100);

        var query = db.Users.AsNoTracking();

        // LIKE joker karakterlerini temizle, sonra büyük/küçük harf duyarsız ara
        var q = Regex.Replace(search?.Trim() ?? "", @"[%_\\]", "");
        if (q.Length > 0)
        {
            var pattern = $"%{q}%";
            query = query.Where(u =>
                EF.Functions.ILike(u.Email, pattern) || EF.Functions.ILike(u.DisplayName, pattern));
        }

        if (role is not null && Roles.Contains(role))
            query = query.Where(u => u.Role == role);

        var total = await query.CountAsync(ct);
        var adminCount = await db.Users.CountAsync(u => u.Role == AdminRole, ct);

        var items = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((currentPage - 1) * size)
            .Take(size)
            .Select(u => new UserListItem(u.Id, u.Email, u.DisplayName, u.Role, u.CreatedAt))
            .ToListAsync(ct);

        return Results.Ok(new UserPage(items, currentPage, size, total, adminCount));
    }

    // PUT /api/users/{id}/role  { "role": "Admin" }
    private static async Task<IResult> ChangeRole(
        Guid id, ChangeRoleRequest request, ClaimsPrincipal principal,
        AppDbContext db, CancellationToken ct)
    {
        if (!Roles.Contains(request.Role))
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["role"] = ["Rol 'User' ya da 'Admin' olmalı."]
            });

        // Kural 1: Kimse kendi rolünü değiştiremez (kendini dışarıda bırakmasın)
        if (id == principal.GetUserId())
            return Conflict("Kendi rolünü değiştiremezsin.");

        await using var tx = await db.Database.BeginTransactionAsync(ct);

        // Admin satırlarını kilitle: aynı anda gelen rol değişiklikleri SIRAYA girsin.
        // İkinci istek, birincisi bitene kadar burada bekler ve güncel sayıyı görür.
        var adminIds = await db.Database.SqlQuery<Guid>($"""
            SELECT "Id" AS "Value" FROM "Users" WHERE "Role" = 'Admin' FOR UPDATE
            """).ToListAsync(ct);

        var user = await db.Users.SingleOrDefaultAsync(u => u.Id == id, ct);
        if (user is null) return Results.NotFound();

        if (user.Role == request.Role)
            return Results.Ok(ToItem(user));

        // Kural 2: Son admin'in yetkisi alınamaz
        if (user.Role == AdminRole && adminIds.Count <= 1)
            return Conflict("Sistemde en az bir admin kalmalı.");

        user.Role = request.Role;
        await db.SaveChangesAsync(ct);

        // Kural 3: Oturumlarını kapat. Elindeki access token en geç 15 dk sonra biter,
        // token yenileyemez ve yeni rolüyle tekrar giriş yapmak zorunda kalır.
        var now = DateTime.UtcNow;
        await db.RefreshTokens
            .Where(t => t.UserId == id && t.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAt, now), ct);

        await tx.CommitAsync(ct);
        return Results.Ok(ToItem(user));
    }

    private static UserListItem ToItem(Entities.User u) =>
        new(u.Id, u.Email, u.DisplayName, u.Role, u.CreatedAt);

    private static IResult Conflict(string message) =>
        Results.Problem(message, statusCode: StatusCodes.Status409Conflict);
}