using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Recipe.Api.Clients;
using Evdekiler.Recipe.Api.Data;
using Evdekiler.Recipe.Api.Endpoints;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<RecipeDbContext>(options =>
    options
        .UseNpgsql(builder.Configuration.GetConnectionString("RecipeDb"))
        .UseSeeding((context, _) => RecipeSeed.Seed(context))
        .UseAsyncSeeding((context, _, ct) => RecipeSeed.SeedAsync(context, ct)));

// Pantry'ye giden HTTP istemcisi: timeout + retry + circuit breaker
builder.Services
    .AddHttpClient<PantryClient>(client =>
        client.BaseAddress = new Uri(builder.Configuration["Services:PantryUrl"]!))
    .AddStandardResilienceHandler();

builder.Services.AddEvdekilerJwtAuth(builder.Configuration);
builder.Services.AddOpenApi();

var app = builder.Build();

// wwwroot/images/recipes altındaki fotoğrafları herkese açık sun
app.UseStaticFiles();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapRecipeEndpoints();

app.Run();