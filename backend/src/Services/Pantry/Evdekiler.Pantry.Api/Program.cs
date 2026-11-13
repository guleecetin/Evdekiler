using System.Text.Json.Serialization;
using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Pantry.Api.Consumers;
using Evdekiler.Pantry.Api.Data;
using Evdekiler.Pantry.Api.Endpoints;
using MassTransit;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<PantryDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("PantryDb")));

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

builder.Services.AddEvdekilerJwtAuth(builder.Configuration);

builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));

builder.Services.AddOpenApi();

var app = builder.Build();

// wwwroot klasöründeki dosyaları (ikonlar) herkese açık sun
app.UseStaticFiles();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthentication();
app.UseAuthorization();

app.MapPantryEndpoints();

app.Run();