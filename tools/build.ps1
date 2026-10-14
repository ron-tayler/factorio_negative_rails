$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$stagingRoot = Join-Path $projectRoot ('test-runtime\packages\' + [guid]::NewGuid().ToString())
$releases = @(
  @{Version='1.0.2';GameVersion='2.0';Output='dist'},
  @{Version='1.0.3';GameVersion='2.1';Output='dist\factorio-2.1'}
)
New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
foreach ($release in $releases) {
  $folderName = 'negative_rails_' + $release.Version
  $sourceRoot = Join-Path $projectRoot ('mods\' + $folderName)
  $manifest = Get-Content -LiteralPath (Join-Path $sourceRoot 'info.json') -Raw | ConvertFrom-Json
  if ($manifest.version -ne $release.Version -or $manifest.factorio_version -ne $release.GameVersion) {
    throw "Unexpected manifest in $folderName"
  }
  Copy-Item -LiteralPath $sourceRoot -Destination $stagingRoot -Recurse
  $packageRoot = Join-Path $stagingRoot $folderName
  Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination $packageRoot
  Copy-Item -LiteralPath (Join-Path $projectRoot 'DESCRIPTION.md') -Destination $packageRoot -Force
  $outputRoot = Join-Path $projectRoot $release.Output
  New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
  $archivePath = Join-Path $outputRoot ($folderName + '.zip')
  Compress-Archive -LiteralPath $packageRoot -DestinationPath $archivePath -Force
  Write-Output $archivePath
}
