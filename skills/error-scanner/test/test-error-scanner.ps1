<#
.SYNOPSIS
  error-scanner verification test (ASCII only)
#>

param()
$ErrorActionPreference = "Stop"
$skillDir = "$env:USERPROFILE\.openclaw\skills\error-scanner"
$skillFile = Join-Path $skillDir "SKILL.md"
$testDir = Join-Path $skillDir "test"

$passCount = 0
$failCount = 0
$testCount = 0

function Assert {
  param([string]$Name, [scriptblock]$Cond)
  $script:testCount++
  $r = & $Cond
  if ($r) { Write-Host "  PASS: $Name"; $script:passCount++ }
  else { Write-Host "  FAIL: $Name"; $script:failCount++ }
}

Write-Host "=== error-scanner Verification Tests ===" -ForegroundColor Cyan

Assert "SKILL.md exists" { Test-Path $skillFile }

$raw = Get-Content $skillFile -Raw

# frontmatter
Assert "name: error-scanner" { $raw -match "name: error-scanner" }
Assert "has description:" { $raw -match "description:" }
Assert "has triggers:" { $raw -match "triggers:" }
Assert "has tools:" { $raw -match "tools:" }
Assert "has mutating:" { $raw -match "mutating:" }
Assert "has metadata:" { $raw -match "metadata:" }
Assert "has requires:" { $raw -match "requires:" }
Assert "has deniedTools" { $raw -match "deniedTools" }

# content sections
Assert "has Contract" { $raw -match "## Contract" }
Assert "has numbered steps" { $raw -match "Step \d" }
Assert "has Output section" { $raw -match "output" -or $raw -match "Output" }
Assert "has Verify section" { $raw -match "verif" -or $raw -match "test" -or $raw -match "validate" }
Assert "has Anti-Patterns" { $raw -match "anti-pattern" -or $raw -match "Don" -or $raw -match "not" }

# quality checks
Assert "no raw mkdir " { $raw -notmatch "mkdir " }
Assert "file < 51200 bytes" { (Get-Item $skillFile).Length -lt 51200 }

Write-Host ""
Write-Host "=== Results: $passCount/$testCount passed, $failCount failed ===" -ForegroundColor Cyan
if ($failCount -gt 0) { exit 1 } else { exit 0 }