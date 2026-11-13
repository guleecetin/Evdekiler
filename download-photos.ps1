param([Parameter(Mandatory = $true)][string]$ApiKey)

$root = "C:\Projects\evdekiler\backend\src\Services"

function Get-Photo($query, $orientation, $outFile) {
    $q = [uri]::EscapeDataString($query)
    $url = "https://pixabay.com/api/?key=$ApiKey&q=$q&image_type=photo&orientation=$orientation&safesearch=true&order=popular&per_page=3"
    try {
        $result = Invoke-RestMethod -Uri $url
        $photo = $result.hits[0]
        if ($null -eq $photo) { Write-Host "BULUNAMADI  $query" -ForegroundColor Yellow; return }
        Invoke-WebRequest $photo.webformatURL -OutFile $outFile -UseBasicParsing
        Write-Host "OK  $query" -ForegroundColor Green
    } catch {
        Write-Host "HATA  $query  $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- Malzemeler ---
$ingDir = "$root\Pantry\Evdekiler.Pantry.Api\wwwroot\images\ingredients"
New-Item -ItemType Directory -Force $ingDir | Out-Null
Remove-Item "$ingDir\*.png" -ErrorAction SilentlyContinue

$ingredients = [ordered]@{
    "1" = "tomato";            "2" = "cucumber";          "3" = "green pepper";      "4" = "onion"
    "5" = "garlic";            "6" = "potatoes";          "7" = "carrot";            "8" = "zucchini"
    "9" = "eggplant";          "10" = "spinach";          "11" = "lemon";            "12" = "red apple"
    "13" = "glass of milk";    "14" = "yogurt";           "15" = "feta cheese";      "16" = "cheddar cheese"
    "17" = "butter";           "18" = "eggs";             "19" = "chicken breast";   "20" = "minced meat"
    "21" = "rice";             "22" = "pasta";            "23" = "bulgur";           "24" = "flour"
    "25" = "red lentils";      "26" = "chickpeas";        "27" = "tomato paste";     "28" = "olive oil"
    "29" = "salt";             "30" = "chili flakes"
}

foreach ($entry in $ingredients.GetEnumerator()) {
    Get-Photo "$($entry.Value) isolated" "all" "$ingDir\$($entry.Key).jpg"
}

# --- Tarifler ---
$recDir = "$root\Recipe\Evdekiler.Recipe.Api\wwwroot\images\recipes"
New-Item -ItemType Directory -Force $recDir | Out-Null

$recipes = [ordered]@{
    "1" = "menemen";                 "2" = "lentil soup"
    "3" = "potato stew";             "4" = "spaghetti bolognese"
    "5" = "chicken stir fry";        "6" = "bulgur pilaf"
    "7" = "tomato cucumber salad";   "8" = "spinach eggs"
    "9" = "rice pilaf";              "10" = "stuffed eggplant"
}

foreach ($entry in $recipes.GetEnumerator()) {
    Get-Photo "$($entry.Value)" "horizontal" "$recDir\$($entry.Key).jpg"
}

Write-Host "`nBitti. Klasorleri acip fotograflara bak." -ForegroundColor Cyan