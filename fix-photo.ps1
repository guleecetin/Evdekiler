param(
    [Parameter(Mandatory = $true)][string]$ApiKey,
    [Parameter(Mandatory = $true)][ValidateSet("malzeme", "tarif")][string]$Tur,
    [Parameter(Mandatory = $true)][string]$Id,
    [Parameter(Mandatory = $true)][string]$Arama,
    [int]$Sira = 1
)

$root = "C:\Projects\evdekiler\backend\src\Services"

if ($Tur -eq "malzeme") {
    $dir = "$root\Pantry\Evdekiler.Pantry.Api\wwwroot\images\ingredients"
    $orientation = "all"
} else {
    $dir = "$root\Recipe\Evdekiler.Recipe.Api\wwwroot\images\recipes"
    $orientation = "horizontal"
}

$q = [uri]::EscapeDataString($Arama)
$url = "https://pixabay.com/api/?key=$ApiKey&q=$q&image_type=photo&orientation=$orientation&safesearch=true&order=popular&per_page=20"
$hits = (Invoke-RestMethod -Uri $url).hits

if ($hits.Count -lt $Sira) {
    Write-Host "Yeterli sonuc yok ($($hits.Count) sonuc)" -ForegroundColor Yellow
    exit
}

Invoke-WebRequest $hits[$Sira - 1].webformatURL -OutFile "$dir\$Id.jpg" -UseBasicParsing
Write-Host "OK  $Tur $Id <- '$Arama' ($Sira. sonuc)" -ForegroundColor Green