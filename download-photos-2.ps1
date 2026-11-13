param([Parameter(Mandatory = $true)][string]$ApiKey)

$dir = "C:\Projects\evdekiler\backend\src\Services\Pantry\Evdekiler.Pantry.Api\wwwroot\images\ingredients"

$ingredients = [ordered]@{
    "31" = "parsley";       "32" = "dill";            "33" = "mint leaves";     "34" = "mushrooms"
    "35" = "broccoli";      "36" = "cauliflower";     "37" = "green beans";     "38" = "white beans"
    "39" = "leek";          "40" = "green peas";      "41" = "sweet corn";      "42" = "cabbage"
    "43" = "red bell pepper"; "44" = "sausage";       "45" = "beef cubes";      "46" = "salmon fillet"
    "47" = "canned tuna";   "48" = "cream";           "49" = "bread loaf";      "50" = "flatbread"
    "51" = "vermicelli";    "52" = "black pepper";    "53" = "cumin";           "54" = "thyme"
    "55" = "sugar";         "56" = "honey";           "57" = "walnuts";         "58" = "banana"
    "59" = "orange fruit";  "60" = "sunflower oil"
}

foreach ($entry in $ingredients.GetEnumerator()) {
    $q = [uri]::EscapeDataString("$($entry.Value) isolated")
    $url = "https://pixabay.com/api/?key=$ApiKey&q=$q&image_type=photo&safesearch=true&order=popular&per_page=3"
    try {
        $photo = (Invoke-RestMethod -Uri $url).hits[0]
        if ($null -eq $photo) { Write-Host "BULUNAMADI  $($entry.Value)" -ForegroundColor Yellow; continue }
        Invoke-WebRequest $photo.webformatURL -OutFile "$dir\$($entry.Key).jpg" -UseBasicParsing
        Write-Host "OK  $($entry.Key) $($entry.Value)" -ForegroundColor Green
    } catch {
        Write-Host "HATA  $($entry.Key) $($entry.Value)" -ForegroundColor Red
    }
}