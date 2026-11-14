param([Parameter(Mandatory = $true)][string]$Password, [string]$Email = "gulendam@gmail.com")

$Base = "http://localhost:5000"
$Photo = "C:\Projects\evdekiler\backend\src\Services\Recipe\Evdekiler.Recipe.Api\wwwroot\images\recipes\menemen.jpg"

function Token($email, $password) {
    $body = @{ email = $email; password = $password } | ConvertTo-Json
    return (Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body).accessToken
}

function Upload($id, $token, $file) {
    $a = @("-s", "-w", "`n%{http_code}", "-X", "POST", "$Base/api/admin/recipes/$id/image", "-F", "file=@$file")
    if ($token) { $a += @("-H", "Authorization: Bearer $token") }
    $out = @(curl.exe @a)
    $body = ""
    if ($out.Count -gt 1) { $body = ($out[0..($out.Count - 2)] -join "") }
    return @{ Code = [int]$out[-1]; Body = $body }
}

function Check($name, $expected, $actual) {
    if ($expected -eq $actual) { Write-Host "OK    $name -> $actual" -ForegroundColor Green }
    else { Write-Host "HATA  $name -> $actual (beklenen $expected)" -ForegroundColor Red }
}

$admin = Token $Email $Password
$normal = Token "test@evdekiler.com" "test12345"

$list = Invoke-RestMethod "$Base/api/admin/recipes?search=menemen" -Headers @{ Authorization = "Bearer $admin" }
$id = $list.items[0].id
Write-Host "Tarif: $($list.items[0].title) (id=$id)"
Write-Host "Eski adres: $($list.items[0].imageUrl)"

$r = Upload $id $admin $Photo
Check "Admin fotograf yukler" 200 $r.Code
$url = ($r.Body | ConvertFrom-Json).imageUrl
Write-Host "Yeni adres: $url"

$img = Invoke-WebRequest "$Base$url" -UseBasicParsing
Check "Fotograf gateway uzerinden aciliyor" 200 ([int]$img.StatusCode)
Write-Host "      tur=$($img.Headers['Content-Type'])  boyut=$($img.RawContentLength) bayt"

Check "Resim olmayan dosya reddedilir" 400 (Upload $id $admin $PSCommandPath).Code
Check "Normal kullanici yukleyemez" 403 (Upload $id $normal $Photo).Code
Check "Token'siz yuklenemez" 401 (Upload $id $null $Photo).Code