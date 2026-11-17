param([Parameter(Mandatory = $true)][string]$ApiKey)

$dir = "C:\Projects\evdekiler\backend\src\Services\Pantry\Evdekiler.Pantry.Api\wwwroot\images\ingredients"

$items = [ordered]@{
    "61" = "semolina";          "62" = "corn starch";       "63" = "cocoa powder";      "64" = "dark chocolate"
    "65" = "vanilla";           "66" = "baking powder";     "67" = "dry yeast";         "68" = "phyllo dough"
    "69" = "hazelnuts";         "70" = "pistachios";        "71" = "almonds";           "72" = "raisins"
    "73" = "cinnamon";          "74" = "powdered sugar";    "75" = "coconut flakes";    "76" = "strawberries"
    "77" = "cream cheese";      "78" = "cottage cheese";    "79" = "black olives";      "80" = "jam jar"
    "81" = "tahini";            "82" = "molasses";          "83" = "clotted cream";     "84" = "sausages"
    "85" = "pastrami";          "86" = "lettuce";           "87" = "arugula";           "88" = "pomegranate molasses"
    "89" = "pomegranate";       "90" = "red cabbage";       "91" = "radish";            "92" = "green onions"
    "93" = "avocado";           "94" = "green lentils";     "95" = "soup powder";       "96" = "orzo pasta"
    "97" = "vinegar";           "98" = "mustard";           "99" = "mayonnaise";        "100" = "ketchup"
    "101" = "breadcrumbs";      "102" = "cornmeal";         "103" = "sesame seeds";     "104" = "nigella seeds"
    "105" = "paprika powder";   "106" = "turmeric";         "107" = "lamb meat";        "108" = "chicken thighs"
    "109" = "anchovies fish";   "110" = "sea bass"
}

foreach ($entry in $items.GetEnumerator()) {
    $q = [uri]::EscapeDataString("$($entry.Value) isolated")
    $url = "https://pixabay.com/api/?key=$ApiKey&q=$q&image_type=photo&safesearch=true&order=popular&per_page=3"
    try {
        $photo = (Invoke-RestMethod -Uri $url).hits[0]
        if ($null -eq $photo) { Write-Host "BULUNAMADI  $($entry.Key) $($entry.Value)" -ForegroundColor Yellow; continue }
        Invoke-WebRequest $photo.webformatURL -OutFile "$dir\$($entry.Key).jpg" -UseBasicParsing
        Write-Host "OK  $($entry.Key) $($entry.Value)" -ForegroundColor Green
    } catch {
        Write-Host "HATA  $($entry.Key) $($entry.Value)" -ForegroundColor Red
    }
}