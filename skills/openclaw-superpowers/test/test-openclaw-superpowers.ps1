<#
.SYNOPSIS
  openclaw-superpowers verification test
#>
$cd = "$env:USERPROFILE\.openclaw\skills\openclaw-superpowers"
$sf = Join-Path $cd "SKILL.md"
$pc = 0; $fc = 0; $tc = 0
function A { param([string]$N,[scriptblock]$C) $script:tc++; if (&$C) { Write-Host "  PASS: $N"; $script:pc++ } else { Write-Host "  FAIL: $N"; $script:fc++ } }
Write-Host "=== openclaw-superpowers Tests ===" -ForegroundColor Cyan
A "SKILL.md exists" { Test-Path $sf }
$raw = Get-Content $sf -Raw
A "name: openclaw-superpowers" { $raw -match "name: openclaw-superpowers" }
A "has triggers" { $raw -match "triggers:" }
A "has tools" { $raw -match "tools:" }
A "has deniedTools" { $raw -match "deniedTools" }
A "has metadata" { $raw -match "metadata:" }
A "has Contract" { $raw -match "## Contract" }
A "has steps" { $raw -match "Step \d" }
A "has output format" { $raw -match "输出格式" }
A "has verification" { $raw -match "验证方式" }
A "has anti-patterns" { $raw -match "反模式" }
$runDir = Join-Path $cd "runs"
A "runs dir exists" { Test-Path $runDir }
Write-Host "=== Results: $pc/$tc passed, $fc failed ===" -ForegroundColor Cyan
if ($fc -gt 0) { exit 1 }