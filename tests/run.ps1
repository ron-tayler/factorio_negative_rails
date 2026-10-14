param([string]$Factorio = 'F:\SteamLibrary\steamapps\common\Factorio\bin\x64\Factorio.exe', [string]$PlayerSave, [string]$NegativeSpaceZip)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $projectRoot 'test-runtime'
New-Item -ItemType Directory -Path (Join-Path $runtimeRoot 'mods') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'mods\negative_rails_1.0.2') -Destination (Join-Path $runtimeRoot 'mods') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'mods\negative_rails_test_0.1.0') -Destination (Join-Path $runtimeRoot 'mods') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'mods\negative_rails_instant_test_0.1.0') -Destination (Join-Path $runtimeRoot 'mods') -Recurse -Force
$gameRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Factorio))
@"
[path]
read-data=$($gameRoot.Replace('\','/'))/data
write-data=$($runtimeRoot.Replace('\','/'))
"@ | Set-Content -LiteralPath (Join-Path $runtimeRoot 'config.ini') -Encoding utf8
'{"mods":[{"name":"base","enabled":true},{"name":"negative_rails","enabled":true},{"name":"negative_rails_test","enabled":true},{"name":"negative_rails_instant_test","enabled":true},{"name":"space-age","enabled":false},{"name":"quality","enabled":false},{"name":"elevated-rails","enabled":false}]}' | Set-Content -LiteralPath (Join-Path $runtimeRoot 'mods\mod-list.json') -Encoding utf8
$modListPath = Join-Path $runtimeRoot 'mods\mod-list.json'
$modList = Get-Content -LiteralPath $modListPath -Raw | ConvertFrom-Json
$modList.mods += @{name='negative_space';enabled=[bool]$NegativeSpaceZip}
$modList | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $modListPath -Encoding utf8
if ($NegativeSpaceZip) { Copy-Item -LiteralPath $NegativeSpaceZip -Destination (Join-Path $runtimeRoot 'mods') -Force }
$stdoutPath = Join-Path $runtimeRoot 'stdout.txt'
$stderrPath = Join-Path $runtimeRoot 'stderr.txt'
$arguments = @('--config', ('"' + (Join-Path $runtimeRoot 'config.ini') + '"'), '--mod-directory', ('"' + (Join-Path $runtimeRoot 'mods') + '"'), '--create', ('"' + (Join-Path $runtimeRoot 'test.zip') + '"'))
if ($PlayerSave) {
  $copiedSave = Join-Path $runtimeRoot 'player-fixture.zip'
  Copy-Item -LiteralPath $PlayerSave -Destination $copiedSave -Force
  $arguments = @('--config', ('"' + (Join-Path $runtimeRoot 'config.ini') + '"'), '--mod-directory', ('"' + (Join-Path $runtimeRoot 'mods') + '"'), '--benchmark', ('"' + $copiedSave + '"'), '--benchmark-ticks', '1801')
}
$process = Start-Process -FilePath $Factorio -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -Wait
Get-Content -LiteralPath $stdoutPath -Tail 30
Get-Content -LiteralPath $stderrPath
if ($process.ExitCode -ne 0) { throw "Factorio tests failed: exit $($process.ExitCode)" }
if (-not (Select-String -LiteralPath (Join-Path $runtimeRoot 'factorio-current.log') -Pattern 'NEGATIVE_TEST ALL PASS' -Quiet)) { throw 'Test completion marker missing' }
if ($PlayerSave -and -not (Select-String -LiteralPath (Join-Path $runtimeRoot 'factorio-current.log') -Pattern 'robot isolation, alerts and paired cleanup PASS' -Quiet)) { throw 'Delayed robot/alert checks missing' }
