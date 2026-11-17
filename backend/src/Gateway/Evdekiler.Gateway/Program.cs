var builder = WebApplication.CreateBuilder(args);

var allowedOrigins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? [];

builder.Services.AddCors(options =>
    options.AddPolicy("web", policy => policy
        .WithOrigins(allowedOrigins)
        .AllowAnyHeader()
        .AllowAnyMethod()
        // Tarayıcı preflight (OPTIONS) cevabını 10 dk hatırlasın;
        // aynı adres ve başlıklar için her istekte tekrar sormasın
        .SetPreflightMaxAge(TimeSpan.FromMinutes(10))));

builder.Services
    .AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

var app = builder.Build();

app.UseCors("web");

app.MapReverseProxy();

app.Run();