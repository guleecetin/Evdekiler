@echo off
call "%~dp0stop-backend.cmd"

cd /d "%~dp0backend"
echo Derleniyor...
dotnet build || (echo DERLEME HATASI & pause & exit /b 1)

start "Gateway"  cmd /k dotnet run --no-build --project src/Gateway/Evdekiler.Gateway
start "Identity" cmd /k dotnet run --no-build --project src/Services/Identity/Evdekiler.Identity.Api --launch-profile http
start "Pantry"   cmd /k dotnet run --no-build --project src/Services/Pantry/Evdekiler.Pantry.Api
start "Recipe"   cmd /k dotnet run --no-build --project src/Services/Recipe/Evdekiler.Recipe.Api

echo Dort servis baslatildi.