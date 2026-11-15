param(
    [Parameter(Mandatory = $true)][string]$ApiKey,
    [Parameter(Mandatory = $true)][string]$Password,
    [string]$Email = "gulendam@gmail.com"
)

$Base = "http://localhost:5000"
$OutRoot = Join-Path $env:USERPROFILE "Downloads\tarif-fotolari"
New-Item -ItemType Directory -Force $OutRoot | Out-Null

# Tarif slug'ı -> Pixabay'de aranacak İngilizce kelimeler
$Queries = @{
    "sucuklu-yumurta" = "eggs sausage pan"; "karniyarik" = "stuffed eggplant"; "kuru-fasulye" = "white bean stew"
    "mantarli-tavuk" = "creamy mushroom chicken"; "firinda-somon" = "baked salmon lemon"; "ezogelin-corbasi" = "red lentil soup"
    "zeytinyagli-taze-fasulye" = "green beans tomato"; "tavuklu-pilav" = "chicken rice pilaf"; "mucver" = "zucchini fritters"
    "kuru-kofte" = "meatballs plate"; "kremali-mantarli-makarna" = "creamy mushroom pasta"
    "hunkar-begendi" = "beef stew eggplant"; "izmir-kofte" = "meatballs potatoes tomato sauce"; "musakka" = "moussaka eggplant"
    "etli-nohut" = "chickpea stew"; "tas-kebabi" = "beef stew"; "orman-kebabi" = "beef vegetable stew"
    "etli-bezelye" = "peas carrot stew"; "kiymali-ispanak" = "spinach stew"; "kiymali-pirasa" = "leek dish"
    "firinda-sebzeli-tavuk" = "roasted chicken vegetables"
    "sutlac" = "rice pudding"; "revani" = "semolina cake"; "irmik-helvasi" = "semolina halva"
    "kakaolu-puding" = "chocolate pudding"; "muhallebi" = "milk pudding"; "firin-elma-tatlisi" = "baked apples"
    "kazandibi" = "caramel pudding"; "islak-kek" = "chocolate cake slice"; "tavuk-gogsu-tatlisi" = "milk pudding cinnamon"
    "lokma" = "fried dough balls honey"
    "yayla-corbasi" = "yogurt soup"; "tarhana-corbasi" = "tomato soup bowl"; "terbiyeli-tavuk-corbasi" = "chicken noodle soup"
    "domates-corbasi" = "tomato soup"; "mantar-corbasi" = "mushroom soup"; "sehriye-corbasi" = "noodle soup"
    "brokoli-corbasi" = "broccoli soup"; "yesil-mercimek-corbasi" = "lentil soup"; "sebze-corbasi" = "vegetable soup"
    "dugun-corbasi" = "meat soup bowl"
    "cilbir" = "poached eggs yogurt"; "peynirli-omlet" = "cheese omelette"; "mantarli-omlet" = "mushroom omelette"
    "pankek" = "pancakes"; "yumurtali-ekmek" = "french toast"; "pastirmali-yumurta" = "fried eggs pan"
    "patatesli-yumurta" = "potatoes eggs skillet"; "acuka" = "red pepper walnut dip"; "mihlama" = "melted cheese pan"
    "avokadolu-ekmek" = "avocado toast egg"
    "su-boregi" = "borek pastry"; "ispanakli-kol-boregi" = "spinach pastry"; "patatesli-rulo-borek" = "pastry rolls"
    "kiymali-borek" = "meat pie"; "peynirli-pogaca" = "cheese buns"; "pisi" = "fried dough bread"
    "sigara-boregi" = "cheese rolls"; "lahmacun" = "lahmacun"; "kiymali-pide" = "turkish pide"; "peynirli-gozleme" = "gozleme"
    "gavurdagi-salatasi" = "tomato walnut salad"; "roka-salatasi" = "arugula salad"; "mevsim-salatasi" = "green salad"
    "piyaz" = "bean salad"; "ton-balikli-salata" = "tuna salad"; "kisir" = "bulgur salad"; "patates-salatasi" = "potato salad"
    "mor-lahana-salatasi" = "red cabbage salad"; "tavuklu-salata" = "grilled chicken salad"; "patlican-salatasi" = "roasted eggplant salad"
}

function Get-Token {
    $body = @{ email = $Email; password = $Password } | ConvertTo-Json
    (Invoke-RestMethod -Method Post "$Base/api/auth/login" -ContentType "application/json" -Body $body).accessToken
}

# 1. Bütün tarifleri sayfa sayfa çek
$token = Get-Token
$recipes = @()
$page = 1
do {
    $r = Invoke-RestMethod "$Base/api/admin/recipes?page=$page&pageSize=100" -Headers @{ Authorization = "Bearer $token" }
    $recipes += $r.items
    $page++
} while ($recipes.Count -lt $r.totalCount)
Write-Host "Toplam tarif: $($recipes.Count)" -ForegroundColor Cyan

$done = 0
foreach ($rec in $recipes) {
    # 2. Fotoğrafı zaten varsa atla
    try { Invoke-WebRequest -Method Head "$Base$($rec.imageUrl)" -UseBasicParsing | Out-Null; continue } catch {}

    $query = $Queries[$rec.slug]
    if (-not $query) { $query = $rec.title }

    # 3. Pixabay'in yemek kategorisinden 4 aday indir
    $q = [uri]::EscapeDataString($query)
    $url = "https://pixabay.com/api/?key=$ApiKey&q=$q&image_type=photo&category=food&orientation=horizontal&safesearch=true&order=popular&per_page=10"
    $hits = @((Invoke-RestMethod -Uri $url).hits | Select-Object -First 4)
    if ($hits.Count -eq 0) { Write-Host "BULUNAMADI  $($rec.title)  ('$query')" -ForegroundColor Yellow; continue }

    $dir = Join-Path $OutRoot $rec.slug
    New-Item -ItemType Directory -Force $dir | Out-Null
    for ($i = 0; $i -lt $hits.Count; $i++) {
        Invoke-WebRequest $hits[$i].largeImageURL -OutFile (Join-Path $dir "$($i + 1).jpg") -UseBasicParsing
    }

    # 4. İlk adayı panele yükle (token süresi dolmasın diye 15 tarifte bir yenile)
    if ($done -gt 0 -and $done % 15 -eq 0) { $token = Get-Token }
    $code = curl.exe -s -o NUL -w "%{http_code}" -X POST "$Base/api/admin/recipes/$($rec.id)/image" `
        -H "Authorization: Bearer $token" -F "file=@$(Join-Path $dir '1.jpg')"

    if ($code -eq "200") { Write-Host "OK    $($rec.title)" -ForegroundColor Green }
    else { Write-Host "HATA  $($rec.title)  (kod $code)" -ForegroundColor Red }
    $done++
}

Write-Host "`nBitti: $done tarife fotograf yuklendi. Adaylar: $OutRoot" -ForegroundColor Cyan
Start-Process $OutRoot