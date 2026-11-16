param([Parameter(Mandatory = $true)][string]$Password, [string]$Email = "gulendam@gmail.com")

$Base = "http://localhost:5000"
$body = @{ email = $Email; password = $Password } | ConvertTo-Json
$token = (Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body).accessToken
$headers = @{ Authorization = "Bearer $token" }

function Post($path, $data) {
    $json = $data | ConvertTo-Json -Depth 4
    try {
        $r = Invoke-WebRequest -Method Post "$Base$path" -Headers $headers -UseBasicParsing `
            -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
        return @{ Code = [int]$r.StatusCode; Data = ($r.Content | ConvertFrom-Json) }
    } catch {
        return @{ Code = $_.Exception.Response.StatusCode.value__; Data = $null }
    }
}

# 1. Fişte tanınmayan iki ürünü kataloğa ekle
$r1 = Post "/api/admin/ingredients" @{ name = "Noodle"; emoji = "🍜"; category = "Grain"; defaultUnit = "Piece" }
Write-Host "Noodle ekle        -> $($r1.Code)  (id=$($r1.Data.id))"

$r2 = Post "/api/admin/ingredients" @{ name = "Siyah çay"; emoji = "🍵"; category = "Other"; defaultUnit = "Gram" }
Write-Host "Siyah çay ekle     -> $($r2.Code)  (id=$($r2.Data.id))"

# 2. Aynı isim Türkçe karaktersiz ve büyük harfle: reddedilmeli
$r3 = Post "/api/admin/ingredients" @{ name = "SIYAH CAY"; emoji = ""; category = "Other"; defaultUnit = "Gram" }
Write-Host "SIYAH CAY tekrar   -> $($r3.Code)  (409 bekleniyor)"

# 3. Aynı fiş satırlarını tekrar okut: önbellek temizlendiği için hemen tanınmalı
$p = Post "/api/pantry/receipts/parse" @{ lines = @("NOODLE 5LI TAVUK350G X1 20.50", "SIYAHCAY 1KG FSKBRLK X1") }
Write-Host "`nBULUNANLAR" -ForegroundColor Green
foreach ($i in $p.Data.items) { Write-Host "  $($i.ingredient.name)  $($i.quantity) $($i.unit)" }
Write-Host "ESLESMEYENLER" -ForegroundColor Yellow
foreach ($u in $p.Data.unmatched) { Write-Host "  $u" }