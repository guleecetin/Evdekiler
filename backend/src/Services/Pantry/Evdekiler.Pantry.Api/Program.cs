using System.Text.Json.Serialization;
using Azure.Storage.Blobs;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Consumers;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Endpoints;
using Evdekiler.Pantry.Api.Receipts;
using Evdekiler.Pantry.Api.Storage;
using MassTransit;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<PantryDbContext>(options =>
    options
        .UseNpgsql(builder.Configuration.GetConnectionString("PantryDb"))
        .UseSeeding((context, _) => PantrySeed.Seed(context))
        .UseAsyncSeeding((context, _, ct) => PantrySeed.SeedAsync(context, ct)));

builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<ShoppingItemPurchasedConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        var rabbit = builder.Configuration.GetSection("RabbitMq");
        cfg.Host(rabbit["Host"], "/", h =>
        {
            h.Username(rabbit["Username"]!);
            h.Password(rabbit["Password"]!);
        });
        cfg.ConfigureEndpoints(context);
    });
});

builder.Services.AddMemoryCache();
builder.Services.AddScoped<IngredientCatalog>();

builder.Services.Configure<StorageOptions>(builder.Configuration.GetSection("Storage"));
builder.Services.AddSingleton(new BlobServiceClient(builder.Configuration["Storage:ConnectionString"]));
builder.Services.AddSingleton<ImageStorage>();

builder.Services.AddEvdekilerJwtAuth(builder.Configuration);

builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddOpenApi();

var app = builder.Build();

app.UseStaticFiles();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapPantryEndpoints();
app.MapPantryBulkEndpoints();
app.MapReceiptEndpoints();
app.MapAdminIngredientEndpoints();
app.MapAdminSuggestionEndpoints();

app.Run();