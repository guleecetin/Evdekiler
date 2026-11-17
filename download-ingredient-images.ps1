# Microsoft Fluent 3D emoji (MIT lisansı) - malzeme ikonlarını indirir
$dest = "C:\Projects\evdekiler\backend\src\Services\Pantry\Evdekiler.Pantry.Api\wwwroot\images\ingredients"
New-Item -ItemType Directory -Force $dest | Out-Null

$base = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets"

# Katalogdaki malzeme Id'si -> Fluent ikon adı
$map = [ordered]@{
    1 = "Tomato";        2 = "Cucumber";       3 = "Bell pepper";    4 = "Onion"
    5 = "Garlic";        6 = "Potato";         7 = "Carrot";         8 = "Cucumber"
    9 = "Eggplant";      10 = "Leafy green";   11 = "Lemon";         12 = "Red apple"
    13 = "Glass of milk"; 14 = "Bowl with spoon"; 15 = "Cheese wedge"; 16 = "Cheese wedge"
    17 = "Butter";       18 = "Egg";           19 = "Poultry leg";   20 = "Cut of meat"
    21 = "Cooked rice";  22 = "Spaghetti";     23 = "Sheaf of rice"; 24 = "Sheaf of rice"
    25 = "Beans";        26 = "Beans";         27 = "Canned food";   28 = "Olive"
    29 = "Salt";         30 = "Hot pepper"
}

foreach ($entry in $map.GetEnumerator()) {
    $id = $entry.Key
    $name = $entry.Value
    $file = ($name.ToLower() -replace ' ', '_') + "_3d.png"
    $url = "$base/$([uri]::EscapeDataString($name))/3D/$file"
    try {
        Invoke-WebRequest $url -OutFile "$dest\$id.png" -UseBasicParsing
        Write-Host "OK    $id $name" -ForegroundColor Green
    } catch {
        Write-Host "HATA  $id $name" -ForegroundColor Red
    }
}