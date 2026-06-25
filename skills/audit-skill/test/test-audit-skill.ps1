#!/usr/bin/env pwsh
<#
.SYNOPSIS
    验证 audit-skill SKILL.md 满足七条黄金法则
.DESCRIPTION
    检查文件存在性、yaml frontmatter 完整性、各节完整性、幂等性声明等。
#>

$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\.."
$skillFile = Join-Path $root "SKILL.md"
$auditDir = "$env:USERPROFILE\.openclaw\.audit"

$passed = 0
$failed = 0

function Test-Check {
    param([string]$Name, [scriptblock]$Block)
    try {
        & $Block | Out-Null
        Write-Host "  ✓ $Name" -ForegroundColor Green
        $script:passed++
    } catch {
        Write-Host "  ✗ $Name`n    $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n=== 七条黄金法则检查: audit-skill ===" -ForegroundColor Cyan

# ---- 法则 1: 单一职责 ----
Test-Check -Name "1. 单一职责 — 只做审计+补丁生成" -Block {
    $content = Get-Content $skillFile -Raw
    if ($content -notmatch "审计" -or $content -notmatch "补丁") {
        throw "SKILL.md 中必须包含'审计'和'补丁'关键词"
    }
    # 确认不包含不相关职责关键词
    $badPatterns = @("部署", "运维", "编译", "测试")
    foreach ($bp in $badPatterns) {
        if ($content -match $bp) {
            # 这些词出现在工具名或正常上下文里可以忽略；我们只检查大标题
            if ($content -match "(?m)^#.*$bp") {
                throw "包含不相关职责区域: $bp"
            }
        }
    }
}

# ---- 法则 2: SOP 式 ----
Test-Check -Name "2. SOP 式 — 步骤编号、输入输出明确" -Block {
    $content = Get-Content $skillFile -Raw
    if ($content -notmatch "Step \d") {
        throw "必须包含 Step 1/2/3/4/5 编号步骤"
    }
    if ($content -notmatch "\*\*输入：\*\*" -or $content -notmatch "\*\*输出：\*\*") {
        throw "每步必须有 **输入：** 和 **输出：** 标注"
    }
}

# ---- 法则 3: 边界声明 ----
Test-Check -Name "3. 边界声明 — tools+deniedTools" -Block {
    $yaml = (Get-Content $skillFile -Raw) -split '(?m)^---' | Select-Object -Index 1
    if (-not $yaml) { throw "无法解析 YAML frontmatter" }
    if ($yaml -notmatch "tools:") { throw "缺少 tools 字段" }
    if ($yaml -notmatch "deniedTools") { throw "缺少 deniedTools 字段" }
    if ($yaml -notmatch "gateway") { throw "deniedTools 应禁止 gateway" }
}

# ---- 法则 4: 依赖声明 ----
Test-Check -Name "4. 依赖声明 — requires.bins" -Block {
    $yaml = (Get-Content $skillFile -Raw) -split '(?m)^---' | Select-Object -Index 1
    if ($yaml -notmatch "bins: \[\]") { throw "requires.bins 必须为空数组" }
}

# ---- 法则 5: 渐进披露 ----
Test-Check -Name "5. 渐进披露 — description+正文分层" -Block {
    $yaml = (Get-Content $skillFile -Raw) -split '(?m)^---' | Select-Object -Index 1
    if ($yaml -notmatch "audit" -and $yaml -notmatch "审计") { throw "description 缺触发关键词" }
    $body = (Get-Content $skillFile -Raw) -split '(?m)^---' | Select-Object -Index 2
    if ($body -notmatch "## 执行步骤" -or $body -notmatch "## 输出格式" -or $body -notmatch "## 验证方式" -or $body -notmatch "## 反模式") {
        throw "正文缺少必要分层小节"
    }
}

# ---- 法则 6: 幂等性 ----
Test-Check -Name "6. 幂等性 — 确保目录存在，非创建" -Block {
    $content = Get-Content $skillFile -Raw
    # Step 5 写日志是追加模式（Append），验证用的 Test-Path 也是检查而非创建
    if ($content -match "(?m)^创建 ") {
        throw "包含'创建'动作词，应使用'确保存在'或'写入'"
    }
    # 验证部分使用 Add-Content -Append 或 Out-File -Append，可接受（幂等追加）
}

# ---- 法则 7: 测试先行 ----
Test-Check -Name "7. 测试先行 — 存在 test/test-audit-skill.ps1" -Block {
    $testScript = Join-Path $root "test\test-audit-skill.ps1"
    if (-not (Test-Path $testScript)) {
        throw "测试脚本不存在: $testScript"
    }
    $content = Get-Content $testScript -Raw
    if ($content -notmatch "Test-Path" -and $content -notmatch "Should") {
        throw "测试脚本缺少实际断言"
    }
}

# ---- 额外检查: YAML 合法性 ----
Test-Check -Name "YAML frontmatter 完整" -Block {
    $lines = Get-Content $skillFile
    if ($lines[0] -ne '---' -or ($lines -notcontains '---') -or ($lines -match '^---' | Measure-Object | Select-Object -ExpandProperty Count) -lt 2) {
        throw "YAML frontmatter 未正确闭合（需要 --- 开头和结尾）"
    }
}

Test-Check -Name "审计目录可创建" -Block {
    New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
    if (-not (Test-Path $auditDir)) {
        throw "无法创建 $auditDir"
    }
}

# ---- 汇总 ----
Write-Host "`n结果: $passed 通过, $failed 失败" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) {
    exit 1
}
