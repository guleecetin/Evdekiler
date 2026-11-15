param(
    [Parameter(Mandatory = $true)][string]$ApiKey,
    [Parameter(Mandatory = $true)][string]$Arama,
    [int]$Sira = 1
)

$q = [uri]::EscapeDataString($Arama)
$url = "https://pixabay.com/api/?key=$ApiKey&q=$q&image_type=photo&orientation=horizontal&safesearch=true&order=popular&per_page=20"
$hits = (Invoke-RestMethod -Uri $url).hits

if ($hits.Count -lt $Sira) {
    Write-Host "Sonuc yok ($($hits.Count) sonuc var)" -ForegroundColor Yellow
    exit
}

$name = ($Arama -replace '[^a-zA-Z0-9]', '-') + "-$Sira.jpg"
$out = Join-Path $env:USERPROFILE "Downloads\$name"

Invoke-WebRequest $hits[$Sira - 1].largeImageURL -OutFile $out -UseBasicParsing
Write-Host "Indirildi: $out" -ForegroundColor Green

# Fotoğrafı aç ki bakabilesin
Start-Process $out