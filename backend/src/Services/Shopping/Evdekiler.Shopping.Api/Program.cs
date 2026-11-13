using Evdekiler.BuildingBlocks.Auth;
using Evdekiler.Shopping.Api.Data;
using MassTransit;
using Microsoft.EntityFrameworkCore;
using Evdekiler.Shopping.Api.Endpoints;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<ShoppingDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("ShoppingDb")));

builder.Services.AddMassTransit(x =>
{
    // Outbox: olaylar önce aynı transaction'la veritabanına yazılır,
    // arka planda RabbitMQ'ya gönderilir
    x.AddEntityFrameworkOutbox<ShoppingDbContext>(o =>
    {
        o.UsePostgres();
        o.UseBusOutbox();
    });

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
builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapShoppingEndpoints();

app.Run();