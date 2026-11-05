using System.Security.Claims;
using Evdekiler.Identity.Api.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;

namespace Evdekiler.Identity.Api.Endpoints;

public static class UserEndpoints
{
    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/users/me", GetMe).RequireAuthorization();
    }

    private static async Task<IResult> GetMe(
        ClaimsPrincipal principal,
        AppDbContext db,
        CancellationToken ct)
    {
        var sub = principal.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (!Guid.TryParse(sub, out var userId))
            return Results.Unauthorized();

        var user = await db.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => new UserResponse(u.Id, u.Email, u.DisplayName))
            .SingleOrDefaultAsync(ct);

        return user is null ? Results.NotFound() : Results.Ok(user);
    }
}