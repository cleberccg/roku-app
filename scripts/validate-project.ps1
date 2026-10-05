param(
    [string]$CatalogPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'data/catalog.json')
)

# Verificação offline: não depende da disponibilidade dos servidores de vídeo.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$raw = Get-Content -LiteralPath $CatalogPath -Raw -Encoding UTF8
if (-not $raw.TrimStart().StartsWith('[')) { throw 'O catálogo deve ser um array JSON.' }
$parsed = ConvertFrom-Json -InputObject $raw
$catalog = @($parsed)
if ($catalog.Count -eq 0) { throw 'O catálogo está vazio.' }
$ids = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($item in $catalog) {
    foreach ($field in @('id', 'title', 'category', 'description', 'poster', 'videoUrl', 'streamFormat')) {
        if ($item.$field -isnot [string] -or [string]::IsNullOrWhiteSpace($item.$field)) {
            throw "Campo inválido ou vazio: $field"
        }
    }
    if (-not $ids.Add($item.id)) { throw "ID duplicado: $($item.id)" }
    if ($item.category -ceq 'Favoritos') { throw 'Favoritos é uma categoria reservada.' }
    if ($item.streamFormat -cne 'mp4') { throw "Formato não suportado: $($item.streamFormat)" }
    $videoUri = $null
    if (-not $item.videoUrl.StartsWith('https://', [System.StringComparison]::Ordinal) -or
        -not [Uri]::TryCreate($item.videoUrl, [UriKind]::Absolute, [ref]$videoUri) -or
        [string]::IsNullOrWhiteSpace($videoUri.Host)) { throw "URL HTTPS inválida: $($item.id)" }
    if (-not $item.poster.StartsWith('pkg:/images/', [System.StringComparison]::Ordinal)) {
        throw "A capa deve estar em pkg:/images/: $($item.id)"
    }
    $posterPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $item.poster.Substring(5)))
    $imagesRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'images')) + [IO.Path]::DirectorySeparatorChar
    if (-not $posterPath.StartsWith($imagesRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $posterPath -PathType Leaf)) { throw "Capa inválida ou ausente: $($item.id)" }
}

# XML malformado e referências ausentes impedem a criação de componentes.
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'components') -Filter '*.xml') {
    $xml = [xml](Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
    foreach ($script in $xml.component.script) {
        if (-not $script.uri.StartsWith('pkg:/') -or
            -not (Test-Path -LiteralPath (Join-Path $projectRoot $script.uri.Substring(5)) -PathType Leaf)) {
            throw "Script ausente em $($file.Name): $($script.uri)"
        }
    }
}
foreach ($required in @('manifest', 'source/main.brs')) {
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $required) -PathType Leaf)) {
        throw "Arquivo obrigatório ausente: $required"
    }
}
Write-Output "Projeto válido: $($catalog.Count) vídeos; capas e componentes verificados."
