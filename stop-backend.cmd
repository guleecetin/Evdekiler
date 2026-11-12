@echo off
taskkill /F /IM Evdekiler.Gateway.exe 2>nul
taskkill /F /IM Evdekiler.Identity.Api.exe 2>nul
taskkill /F /IM Evdekiler.Pantry.Api.exe 2>nul
taskkill /F /IM Evdekiler.Recipe.Api.exe 2>nul
echo Tum servisler durduruldu.