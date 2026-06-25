<#
.SYNOPSIS
  skill-evolver verification test (PURE ASCII only)
#>

param()
$ErrorActionPreference = "Stop"
$cd = "$env:USERPROFILE\.openclaw\skills\skill-evolver"
$sf = Join-Path $cd "SKILL.md"
$pc = 0; $fc = 0; $tc = 0

function A {
  param([string]$N, [scriptblock]$C)
  $script:tc++; $r = & $C
  if ($r) { Write-Host "  PASS: $N"; $script:pc++ }
  else { Write-Host "  FAIL: $N"; $script:fc++ }
}

Write-Host "=== skill-evolver Tests ===" -ForegroundColor Cyan

A "SKILL.md exists" { Test-Path $sf }
$raw = Get-Content $sf -Raw

# frontmatter
A "name: skill-evolver" { $raw -match "name: skill-evolver" }
A "has description:" { $raw -match "description:" }
A "has triggers:" { $raw -match "triggers:" }
A "has tools:" { $raw -match "tools:" }
A "has mutating:" { $raw -match "mutating:" }
A "has metadata:" { $raw -match "metadata:" }
A "has requires:" { $raw -match "requires:" }
A "has deniedTools" { $raw -match "deniedTools" }

# content sections
A "has Contract" { $raw -match "## Contract" }
A "has phases/steps" { $raw -match "Phase" -or $raw -match "Step" }

# section count check
$h2Count = [regex]::Matches($raw, "(?m)^## ").Count
A "section count >= 4" { $h2Count -ge 4 }

# quality
A "no vague try" { $raw -notmatch "\btry to\b" }
A "no bare mkdir" { $raw -notmatch "mkdir " }
A "file < 51200" { (Get-Item $sf).Length -lt 51200 }
A "has changelog" { $raw -match "changelog" }

Write-Host ""
Write-Host "=== Results: $pc/$tc passed, $fc failed ===" -ForegroundColor Cyan
if ($fc -gt 0) { exit 1 } else { exit 0 }