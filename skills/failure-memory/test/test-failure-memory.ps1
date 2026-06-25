<#
.SYNOPSIS
  failure-memory verification test (PURE ASCII only)
#>

param()
$ErrorActionPreference = "Stop"
$cd = "$env:USERPROFILE\.openclaw\skills\failure-memory"
$sf = Join-Path $cd "SKILL.md"
$pc = 0; $fc = 0; $tc = 0

function A {
  param([string]$N, [scriptblock]$C)
  $script:tc++; $r = & $C
  if ($r) { Write-Host "  PASS: $N"; $script:pc++ }
  else { Write-Host "  FAIL: $N"; $script:fc++ }
}

Write-Host "=== failure-memory Tests ===" -ForegroundColor Cyan

A "SKILL.md exists" { Test-Path $sf }
$raw = Get-Content $sf -Raw

A "has name:" { $raw -match "name: failure-memory" }
A "has description:" { $raw -match "description:" }
A "has triggers:" { $raw -match "triggers:" }
A "has tools:" { $raw -match "tools:" }
A "has mutating:" { $raw -match "mutating:" }
A "has metadata:" { $raw -match "metadata:" }
A "has requires:" { $raw -match "requires:" }
A "has deniedTools" { $raw -match "deniedTools" }
A "has Contract" { $raw -match "## Contract" }
A "has numbered steps" { $raw -match "Step" -or $raw -match "\d+\." }

# section count check (4+ h2 headings = well-structured)
$h2Count = [regex]::Matches($raw, "(?m)^## ").Count
A "section count >= 4" { $h2Count -ge 4 }
A "file < 51200 bytes" { (Get-Item $sf).Length -lt 51200 }
A "no bare mkdir" { $raw -notmatch "mkdir " }

Write-Host ""
Write-Host "=== Results: $pc/$tc passed, $fc failed ===" -ForegroundColor Cyan
if ($fc -gt 0) { exit 1 } else { exit 0 }