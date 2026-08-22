$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$profilesPath = Join-Path $root 'keys\profiles.json'
$sharedPath = Join-Path $root 'keys\shared.json'

$profiles = Get-Content -LiteralPath $profilesPath -Raw | ConvertFrom-Json
$shared = Get-Content -LiteralPath $sharedPath -Raw | ConvertFrom-Json

foreach ($prop in $shared.PSObject.Properties) {
    Set-Item -Path ("Env:" + $prop.Name) -Value $prop.Value
}

Write-Host ""
Write-Host "Selecione o perfil:" -ForegroundColor Cyan
for ($i = 0; $i -lt $profiles.profiles.Count; $i++) {
    $p = $profiles.profiles[$i]
    Write-Host ("[{0}] {1}" -f $p.id, $p.label)
}

$choice = Read-Host "Opcao"

$profile = $profiles.profiles | Where-Object { $_.id -eq $choice }
if (-not $profile) {
    Write-Host "Opcao invalida." -ForegroundColor Red
    exit 1
}

$env:GITHUB_TOKEN = $profile.github_token
foreach ($prop in $profile.env.PSObject.Properties) {
    Set-Item -Path ("Env:" + $prop.Name) -Value $prop.Value
}

Write-Host ("Perfil ativo: {0}" -f $profile.label) -ForegroundColor Green
Write-Host ""

opencode
