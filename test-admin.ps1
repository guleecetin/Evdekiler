param(
    [Parameter(Mandatory = $true)][string]$Password,
    [string]$Email = "gulendam@gmail.com"
)

$Base = "http://localhost:5000"

function Login($email, $password) {
    $body = @{ email = $email; password = $password } | ConvertTo-Json
    $r = Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body
    return @{ Authorization = "Bearer $($r.accessToken)" }
}

function Status($url, $headers) {
    try { Invoke-RestMethod $url -Headers $headers | Out-Null; return 200 }
    catch { return $_.Exception.Response.StatusCode.value__ }
}

function Check($name, $expected, $actual) {
    if ($expected -eq $actual) { Write-Host "OK    $name -> $actual" -ForegroundColor Green }
    else { Write-Host "HATA  $name -> $actual (beklenen $expected)" -ForegroundColor Red }
}

# 1. Admin girisi ve rol
$admin = Login $Email $Password
$me = Invoke-RestMethod "$Base/api/users/me" -Headers $admin
Write-Host "Giris yapan: $($me.email)  Rol: $($me.role)"

# 2. Admin token ile kullanici listesi
Check "Admin token ile /api/users" 200 (Status "$Base/api/users" $admin)

# 3. Token'siz
Check "Token'siz /api/users" 401 (Status "$Base/api/users" @{})

# 4. Normal kullanici olustur (zaten varsa sorun degil) ve giris yap
$reg = @{ email = "test@evdekiler.com"; password = "test12345"; displayName = "Test Kullanici" } | ConvertTo-Json
try { Invoke-RestMethod -Method Post "$Base/api/auth/register" -ContentType "application/json" -Body $reg | Out-Null } catch {}
$normal = Login "test@evdekiler.com" "test12345"

# 5. Normal kullanici token'i ile
Check "Normal kullanici ile /api/users" 403 (Status "$Base/api/users" $normal)
Check "Normal kullanici ile /api/users/me" 200 (Status "$Base/api/users/me" $normal)
