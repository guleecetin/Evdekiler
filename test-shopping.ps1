param([string]$Email = "gulendam@gmail.com", [Parameter(Mandatory = $true)][string]$Password)

$Base = "http://localhost:5000"
$ErrorActionPreference = "Stop"
function Title($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Green }

Title "1. Giris"
$login = Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" `
    -Body (@{ email = $Email; password = $Password } | ConvertTo-Json)
$h = @{ Authorization = "Bearer $($login.accessToken)" }
Write-Host "OK"

Title "2. Alisveris listesine Biber ekle"
$body = @{ items = @(@{ ingredientId = 3; ingredientName = "Biber"; quantity = 2; unit = "Piece" }) } | ConvertTo-Json -Depth 3
$added = Invoke-RestMethod -Method Post "$Base/api/shopping/items" -Headers $h -ContentType "application/json" -Body $body
$itemId = ($added | Where-Object { $_.ingredientId -eq 3 }).id
$added | Format-Table ingredientName, quantity, unit, isPurchased -AutoSize

Title "3. Buzdolabinda Biber var mi? (ONCE)"
$before = (Invoke-RestMethod "$Base/api/pantry/items" -Headers $h | Where-Object { $_.ingredientId -eq 3 }).Count
Write-Host "Biber sayisi: $before"

Title "4. 'Alindi' isaretle"
Invoke-RestMethod -Method Post "$Base/api/shopping/items/$itemId/purchase" -Headers $h |
    Format-Table ingredientName, isPurchased, purchasedAt -AutoSize

Write-Host "Olayin islenmesi icin 3 saniye bekleniyor..."
Start-Sleep -Seconds 3

Title "5. Buzdolabinda Biber var mi? (SONRA)"
$after = (Invoke-RestMethod "$Base/api/pantry/items" -Headers $h | Where-Object { $_.ingredientId -eq 3 }).Count
Write-Host "Biber sayisi: $after"
if ($after -eq $before + 1) { Write-Host "BASARILI: Olay Pantry'ye ulasti!" -ForegroundColor Green }
else { Write-Host "Biber eklenmedi, Pantry penceresindeki loglara bak" -ForegroundColor Red }

Title "6. Ayni urunu tekrar 'alindi' isaretle (idempotency)"
Invoke-RestMethod -Method Post "$Base/api/shopping/items/$itemId/purchase" -Headers $h | Out-Null
Start-Sleep -Seconds 3
$again = (Invoke-RestMethod "$Base/api/pantry/items" -Headers $h | Where-Object { $_.ingredientId -eq 3 }).Count
Write-Host "Biber sayisi: $again"
if ($again -eq $after) { Write-Host "BASARILI: Iki kez eklenmedi" -ForegroundColor Green }