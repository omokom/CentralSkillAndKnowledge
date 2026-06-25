---
name: backup-discipline
display_name: "备份纪律"
version: 1.0.0
description: |
  统一备份规范。定义所有备份操作的统一路径、命名规则、清理策略、回滚流程。
  确保任何写操作前的备份都放在同一个地方，不再到处乱放。
  覆盖 skillification-criteria.md 的 E1/E2/E3/F3 条件。
  不做：全量系统备份（由 openclaw-backup 负责）、cron 自动备份调度。
triggers:
  - "备份"
  - "备份文件"
  - "备份到哪里"
  - "备份规范"
  - "备份路径"
  - "备份命名"
  - "回滚备份"
  - "统一备份"
  - "备份纪律"
  - "备份清理"
tools:
  - exec
  - write
mutating: true
metadata:
  openclaw:
    emoji: "💾"
    layer: 1
    layer_label: "Atomic Skills"
    priority: high
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
    configPaths: ["C:\Users\lixin\Desktop"]
---

# 💾 Backup Discipline — 统一备份规范

## Contract

1. **统一锚点** — 所有备份必须放在桌面（`C:\Users\lixin\Desktop\`），禁止其他路径
2. **统一命名** — `<原始文件名>.bak.<YYYY-MM-DD>`
3. **覆盖前检查** — 同名备份已存在时自动覆盖（幂等）
4. **清理策略** — 备份超过 30 天可清理，但至少保留最近 1 个
5. **回滚保障** — 每个备份必须有对应的回滚命令

## 执行步骤

### Step 1: 创建备份

**输入：** 待备份文件路径
**命令：**
```powershell
Copy-Item "<文件路径>" "C:\Users\lixin\Desktop\<文件名>.bak.<YYYY-MM-DD>" -Force
```
**验收：** `Test-Path "C:\Users\lixin\Desktop\<文件名>.bak.<YYYY-MM-DD>"` → $true

### Step 2: 回滚

**输入：** 备份文件路径 + 原文件路径
**命令：**
```powershell
Copy-Item "C:\Users\lixin\Desktop\<文件名>.bak.<YYYY-MM-DD>" "<原文件路径>" -Force
```
**注意：** 回滚后立即验证原文件内容正确

### Step 3: 清理旧备份

**触发：** 备份操作完成时顺便检查
**命令：**
```powershell
$cutoff = (Get-Date).AddDays(-30)
Get-ChildItem "C:\Users\lixin\Desktop\*.bak.*" | Where-Object { $_.LastWriteTime -lt $cutoff } | ForEach-Object {
    # 至少保留最近 1 个
    Remove-Item $_.FullName
}
```
**禁止：** 如果某文件只有 1 个备份且已过期 → 保留不删

## 特殊场景

### 场景 A：编辑前备份（与 agent-file-update 协作）
- 由 `agent-file-update` Step 1 调用本规范的备份命令
- 路径：桌面，命名：`<文件名>.bak.<YYYY-MM-DD>`

### 场景 B：配置变更前备份（与工具技能协作）
- 修改 openclaw.json 等核心配置前必须先执行本规范
- 额外要求：备份后验证 JSON 语法

### 场景 C：批量操作前备份
- 涉及多个文件时，逐个备份，不要用通配符覆盖
- 或者创建一个带时间戳的目录：`C:\Users\lixin\Desktop\pre-<操作名>-<YYYY-MM-DD>\`

## 输出格式

```
[Backup] 操作: <创建/回滚/清理> | 文件: <路径> | 目标: <备份路径> | 状态: OK/FAIL
```

## 反模式（Anti-Patterns）

- 备份到桌面以外的路径 ❌
- 不按命名规范（导致找不到备份）❌
- 多个备份文件没有日期区分 ❌
- 清理时删掉唯一的备份 ❌
- 备份后不验证 ❌
- 用 `cp` 而非 `Copy-Item`（PowerShell）❌

## 验证方式

```powershell
# 检查备份存在
Get-ChildItem "C:\Users\lixin\Desktop\*.bak.$(Get-Date -Format 'yyyy-MM-dd')"
# 检查备份大小
Get-Item "C:\Users\lixin\Desktop\<文件名>.bak.$(Get-Date -Format 'yyyy-MM-dd')" | Select-Object Length
```
