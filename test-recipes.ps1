param(
    [string]$Email = "gulendam@gmail.com",
    [Parameter(Mandatory = $true)][string]$Password,
    [string]$Base = "http://localhost:5000"
)

$ErrorActionPreference = "Stop"
function Show-Title($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Green }

Show-Title "1. Giris"
$body = @{ email = $Email; password = $Password } | ConvertTo-Json
$login = Invoke-RestMethod -Method Post -Uri "$Base/api/auth/login" -ContentType "application/json" -Body $body
$headers = @{ Authorization = "Bearer $($login.accessToken)" }
Write-Host "OK - token alindi"

Show-Title "2. Buzdolabindaki urunler"
$items = Invoke-RestMethod -Uri "$Base/api/pantry/items" -Headers $headers
if ($items.Count -eq 0) { Write-Host "Buzdolabi bos" }
else { $items | Format-Table ingredientId, ingredientName, quantity, unit, expiresAt -AutoSize }

Show-Title "3. Tarif onerileri"
$s = Invoke-RestMethod -Uri "$Base/api/recipes/suggestions" -Headers $headers
if ($s.Count -eq 0) { Write-Host "Oneri yok" }
else {
    $s | Format-Table id, title,
        @{ n = "eslesme"; e = { "$($_.haveCount)/$($_.requiredCount) (%$($_.matchPercent))" } },
        @{ n = "eksikler"; e = { if ($_.missing.Count -eq 0) { "-" } else { $_.missing -join ", " } } } -AutoSize
}

Show-Title "4. Tarif detayi (id=1)"
$r = Invoke-RestMethod -Uri "$Base/api/recipes/1" -Headers $headers
Write-Host "$($r.title) - $($r.prepMinutes) dk, $($r.servings) kisilik"
$r.ingredients | Format-Table name, quantity, unit, isOptional -AutoSize
$i = 1; foreach ($step in $r.steps) { Write-Host "$i. $step"; $i++ }

Show-Title "5. Token'siz istek (401 beklenir)"
try { Invoke-RestMethod -Uri "$Base/api/recipes/suggestions" | Out-Null; Write-Host "HATA: 401 bekleniyordu" -ForegroundColor Red }
catch { Write-Host "OK - HTTP $($_.Exception.Response.StatusCode.value__)" }