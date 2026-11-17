param([Parameter(Mandatory = $true)][string]$Password, [string]$Email = "gulendam@gmail.com")

$Base = "http://localhost:5000"

function Login($email, $password) {
    $body = @{ email = $email; password = $password } | ConvertTo-Json
    $r = Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body
    return @{ Authorization = "Bearer $($r.accessToken)" }
}

function Call($method, $path, $headers, $body) {
    $p = @{ Method = $method; Uri = "$Base$path"; Headers = $headers; UseBasicParsing = $true }
    if ($body) { $p.ContentType = "application/json"; $p.Body = ($body | ConvertTo-Json -Depth 5) }
    try {
        $r = Invoke-WebRequest @p
        $data = $null
        if ($r.Content) { $data = $r.Content | ConvertFrom-Json }
        return @{ Code = [int]$r.StatusCode; Data = $data }
    } catch {
        return @{ Code = $_.Exception.Response.StatusCode.value__; Data = $null }
    }
}

function Check($name, $expected, $actual) {
    if ($expected -eq $actual) { Write-Host "OK    $name -> $actual" -ForegroundColor Green }
    else { Write-Host "HATA  $name -> $actual (beklenen $expected)" -ForegroundColor Red }
}

$admin = Login $Email $Password
$normal = Login "test@evdekiler.com" "test12345"

$recipe = @{
    title = "Sucuklu Yumurta"; description = "Pratik kahvalti klasigi."; emoji = ""
    prepMinutes = 10; servings = 2
    ingredients = @(
        @{ ingredientId = 44; name = "Sucuk"; quantity = 100; unit = "Gram"; isOptional = $false },
        @{ ingredientId = 18; name = "Yumurta"; quantity = 3; unit = "Piece"; isOptional = $false }
    )
    steps = @("Sucuklari dilimleyip tavada kizart.", "Yumurtalari kir, pisince servis et.")
}

$created = Call "POST" "/api/admin/recipes" $admin $recipe
Check "Admin tarif ekler" 201 $created.Code
$id = $created.Data.id
Write-Host "      id=$id  slug=$($created.Data.slug)"

Check "Ayni tarif tekrar eklenemez" 409 (Call "POST" "/api/admin/recipes" $admin $recipe).Code

$bad = $recipe.Clone(); $bad.title = ""; $bad.prepMinutes = 0
Check "Hatali veri reddedilir" 400 (Call "POST" "/api/admin/recipes" $admin $bad).Code

Check "Normal kullanici ekleyemez" 403 (Call "POST" "/api/admin/recipes" $normal $recipe).Code

$list = Call "GET" "/api/admin/recipes?search=sucuk" $admin $null
Check "Arama ve sayfalama" 200 $list.Code
Write-Host "      bulunan=$($list.Data.totalCount)  sayfa=$($list.Data.page)"

$recipe.title = "Sucuklu Yumurta Tava"
Check "Admin tarifi gunceller" 204 (Call "PUT" "/api/admin/recipes/$id" $admin $recipe).Code

$detail = Call "GET" "/api/recipes/$id" $admin $null
Write-Host "      yeni baslik=$($detail.Data.title)  malzeme=$($detail.Data.ingredients.Count)"

Check "Admin tarifi siler" 204 (Call "DELETE" "/api/admin/recipes/$id" $admin $null).Code
Check "Silinen tarif bulunamaz" 404 (Call "DELETE" "/api/admin/recipes/$id" $admin $null).Code