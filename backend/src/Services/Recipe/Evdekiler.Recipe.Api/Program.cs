using System.Text.Json.Serialization;
using Azure.Storage.Blobs;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Recipe.Api.Clients;
using Evdekiler.Recipe.Api.Data;
using Evdekiler.Recipe.Api.Endpoints;
using Evdekiler.Recipe.Api.Storage;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<RecipeDbContext>(options =>
    options
        .UseNpgsql(builder.Configuration.GetConnectionString("RecipeDb"))
        .UseSeeding((context, _) => RecipeSeed.Seed(context))
        .UseAsyncSeeding((context, _, ct) => RecipeSeed.SeedAsync(context, ct)));

builder.Services
    .AddHttpClient<PantryClient>(client =>
        client.BaseAddress = new Uri(builder.Configuration["Services:PantryUrl"]!))
    .AddStandardResilienceHandler();

builder.Services.Configure<StorageOptions>(builder.Configuration.GetSection("Storage"));
builder.Services.AddSingleton(new BlobServiceClient(builder.Configuration["Storage:ConnectionString"]));
builder.Services.AddSingleton<ImageStorage>();

builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddEvdekilerJwtAuth(builder.Configuration);
builder.Services.AddOpenApi();

var app = builder.Build();

app.UseStaticFiles();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapRecipeEndpoints();
app.MapAdminRecipeEndpoints();
app.MapAdminRecipeImageEndpoints();

app.Run();