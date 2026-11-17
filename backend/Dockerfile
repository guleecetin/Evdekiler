# Bütün .NET servisleri için TEK Dockerfile. Hangi servis olduğu ARG ile gelir.

# ─── 1. aşama: derleme (büyük SDK imajı) ───────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG PROJECT
ARG BUNDLE=false
WORKDIR /src

COPY . .
RUN dotnet publish "$PROJECT" -c Release -o /app

# Migration'ları tek başına çalışan bir programa (efbundle) derle
RUN if [ "$BUNDLE" = "true" ]; then \
      dotnet tool install --global dotnet-ef --version "10.*" && \
      /root/.dotnet/tools/dotnet-ef migrations bundle \
        --project "$PROJECT" --configuration Release \
        --self-contained -r linux-x64 -o /app/efbundle ; \
    fi

# ─── 2. aşama: çalıştırma (küçük runtime imajı) ────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0
ARG APP_DLL
ENV APP_DLL=${APP_DLL}
WORKDIR /app
COPY --from=build /app .
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec dotnet \"$APP_DLL\""]