# Verifica acesso real ao arquivo, sem baixar o vídeo inteiro.
# HEAD sozinho não garante que o servidor permita obter o conteúdo via GET.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$catalog = Get-Content -LiteralPath (Join-Path $projectRoot 'data/catalog.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$failures = 0
foreach ($item in $catalog) {
    $response = $null
    $stream = $null
    try {
        $request = [System.Net.HttpWebRequest]::Create($item.videoUrl)
        $request.Timeout = 15000
        $request.ReadWriteTimeout = 15000
        # Solicita só os primeiros 64 bytes. Se o servidor ignorar Range e
        # responder 200, lemos apenas o cabeçalho e fechamos a conexão.
        $request.AddRange(0, 63)
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $bytes = New-Object byte[] 64
        $read = 0
        while ($read -lt $bytes.Length) {
            $count = $stream.Read($bytes, $read, $bytes.Length - $read)
            if ($count -eq 0) { break }
            $read += $count
        }
        # MP4 começa normalmente com a box ftyp: este teste também detecta
        # páginas HTML de erro retornadas incorretamente com status HTTP 200.
        if ($read -lt 12 -or [System.Text.Encoding]::ASCII.GetString($bytes, 4, 4) -ne 'ftyp') {
            throw 'A resposta não contém um cabeçalho MP4 reconhecido.'
        }
        Write-Output "OK: $($item.title) — HTTP $([int]$response.StatusCode), MP4 confirmado"
    } catch {
        $failures++
        Write-Output "FALHA: $($item.title) — $($_.Exception.Message)"
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
        if ($null -ne $response) { $response.Close() }
    }
}
if ($failures -gt 0) { throw "$failures URL(s) de vídeo falharam." }
Write-Output "Todos os $($catalog.Count) vídeos estão acessíveis. A reprodução e os codecs ainda devem ser verificados no Roku."
