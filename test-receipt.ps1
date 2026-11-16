param([Parameter(Mandatory = $true)][string]$Password, [string]$Email = "gulendam@gmail.com")

$Base = "http://localhost:5000"

$body = @{ email = $Email; password = $Password } | ConvertTo-Json
$token = (Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body).accessToken

# Gima fişi + birkaç modern market satırı
$lines = @(
    "GIMA T.A.S.", "ADAPAZARI MAGAZALARI", "ADNAN MENDERES CAD. NO:180",
    "TARIH : 15/12/1999 SAAT: 18:09",
    "2 X 1.0 AD TL395,000 SF", "PINAR SUT 1/1 %8 *790,000",
    "PINAR SUT 1/1 %8 *395,000", "*** HATA DUZELT. ***", "PINAR SUT 1/1 %8 -395,000C",
    "BIRTAT YOGURT 1500GR%8 *825,000",
    "IYI DUSUN DOGRU KARA%8 *3.000.000",
    "3 X 1.0 KG TL200.000 SF", "K.BAKI UNLU MAM.%1 %1 *600,000",
    "GIMA SU 5 LT %17 *329,000", "COCA COLA 2.5 LT %17 *695,000",
    "DOMATES KG 1,250 X 24,90 *31,13", "KASAR PEYN 400G %1 *189,90",
    "YUMURTA 30LU %1 *149,00", "DOMATES SALCASI 700G *89,90", "TEL SEHRIYE 500G *19,90",
    "TOPLAM *6.550.500", "NAKIT *10.000.000"
)

$req = @{ lines = $lines } | ConvertTo-Json
$res = Invoke-RestMethod -Method Post "$Base/api/pantry/receipts/parse" `
    -Headers @{ Authorization = "Bearer $token" } -ContentType "application/json; charset=utf-8" `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($req))

Write-Host "`nBULUNANLAR" -ForegroundColor Green
foreach ($i in $res.items) {
    Write-Host ("  {0,-16} {1,8} {2,-11} ({3})" -f $i.ingredient.name, $i.quantity, $i.unit, $i.confidence)
}

Write-Host "`nESLESMEYENLER" -ForegroundColor Yellow
foreach ($u in $res.unmatched) { Write-Host "  $u" }