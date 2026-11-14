using System.Security.Claims;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Identity.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Evdekiler.Identity.Api.Endpoints;

public record MeResponse(Guid Id, string Email, string DisplayName, string Role);
public record UserListItem(Guid Id, string Email, string DisplayName, string Role, DateTime CreatedAt);

public static class UserEndpoints
{
    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        // Giriş yapmış herkes
        app.MapGet("/api/users/me", GetMe).RequireAuthorization();

        // Sadece Admin rolü
        app.MapGet("/api/users", GetAll).RequireAuthorization(AuthPolicies.Admin);
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

    private static async Task<IResult> GetAll(AppDbContext db, CancellationToken ct)
    {
        var users = await db.Users
            .AsNoTracking()
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new UserListItem(u.Id, u.Email, u.DisplayName, u.Role, u.CreatedAt))
            .Take(100)
            .ToListAsync(ct);

        return Results.Ok(users);
    }
}