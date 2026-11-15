param([Parameter(Mandatory = $true)][string]$Password, [string]$Email = "gulendam@gmail.com")

$Base = "http://localhost:5000"

# Fotoğrafı açıkça yanlış olan tarifler
$Wrong = @(
    "orman-kebabi", "zeytinyagli-taze-fasulye", "mantarli-tavuk", "kuru-fasulye", "kuru-kofte",
    "karniyarik", "kiymali-ispanak", "kiymali-pirasa", "etli-nohut",
    "brokoli-corbasi", "dugun-corbasi", "ezogelin-corbasi", "domates-corbasi", "sebze-corbasi",
    "terbiyeli-tavuk-corbasi", "yayla-corbasi", "yesil-mercimek-corbasi",
    "piyaz", "gavurdagi-salatasi", "patates-salatasi", "ton-balikli-salata",
    "lahmacun", "ispanakli-kol-boregi", "peynirli-pogaca", "sigara-boregi", "pisi",
    "irmik-helvasi", "revani", "lokma", "kazandibi"
)

$body = @{ email = $Email; password = $Password } | ConvertTo-Json
$token = (Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body).accessToken
$headers = @{ Authorization = "Bearer $token" }

$all = (Invoke-RestMethod "$Base/api/admin/recipes?pageSize=100" -Headers $headers).items

foreach ($slug in $Wrong) {
    $rec = $all | Where-Object { $_.slug -eq $slug }
    if (-not $rec) { Write-Host "YOK   $slug" -ForegroundColor Yellow; continue }
    Invoke-RestMethod -Method Delete "$Base/api/admin/recipes/$($rec.id)/image" -Headers $headers | Out-Null
    Write-Host "KALDIRILDI  $($rec.title)" -ForegroundColor Green
}