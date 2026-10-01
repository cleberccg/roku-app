# Interromper em qualquer falha evita anunciar sucesso com um ZIP incompleto.
$ErrorActionPreference = 'Stop'
# PSScriptRoot é a pasta deste script, mesmo quando ele é chamado de outro lugar.
# O projeto fica um nível acima, e dist concentra os artefatos não versionados.
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$packagePath = Join-Path $outputDirectory 'roku-showcase.zip'
# Usamos as classes .NET para controlar os nomes dentro do ZIP. O separador '/'
# precisa ser mantido mesmo no Windows, e o manifest precisa ficar na raiz.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
# Create substitui o pacote anterior. A lista abaixo inclui apenas runtime:
# README, comentários externos, .git e scripts não são necessários no Roku.
$stream = [System.IO.File]::Open($packagePath, [System.IO.FileMode]::Create)
$archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in @('manifest', 'source', 'components', 'data', 'images')) {
        $files = Get-ChildItem -LiteralPath (Join-Path $projectRoot $entry) -File -Recurse
        foreach ($file in $files) {
            # Remover o prefixo absoluto impede caminhos do PC dentro do pacote.
            $relativePath = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relativePath) | Out-Null
        }
    }
} finally {
    # Dispose finaliza o índice do ZIP e libera os arquivos mesmo se houver erro.
    $archive.Dispose()
    $stream.Dispose()
}
Write-Output "Pacote criado: $packagePath"
