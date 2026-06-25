---
name: agent-file-update
display_name: "代理文件更新"
version: 2.0.0
description: |
  在 Multica 环境中更新 Agent 核心配置的技能。
  涵盖：Agent 指令注入（instructions）、角色描述、运行时、技能分配等。
  每次更新需经过"备份→波及评估→执行→验证→回滚"五步流程。
  不做：工作流层技能修改、gateway/cron 操作、创建新 Agent。
triggers:
  - "更新 agent"
  - "修改指令"
  - "更新 instructions"
  - "注入指令"
  - "修改 description"
  - "重配技能"
  - "改运行时"
  - "agent 配置变更"
  - "切 runtime"
  - "改 model"
  - "改描述"
  - "重命名 agent"
  - "改 max_concurrent_tasks"
  - "agent 维护"
tools:
  - read
  - write
  - edit
  - exec
mutating: true
metadata:
  codex:
    emoji: "📝"
    layer: 1
    layer_label: "Atomic Skills"
    priority: high
    requires:
      bins: ["multica"]
    deniedTools: []
    blast_radius:
      files: ["Multica Agent Config (DB)"]
      depends_on: []
      depended_by: ["所有 Agent 任务执行"]
type: workflow
tags: [agent-config, multica, backup, update]
related: [[[audit-skill]], [[gbrain-skill]]]
source: "main agent - Multica agent config workflow"
---

# 📝 Agent File Update (Multica) — Agent 配置更新流程

## 核心变化（相对 OpenClaw 版）

| 旧环境（OpenClaw） | 新环境（Multica + Codex） |
|-------------------|-------------------------|
| 直接编辑 `workspace/*.md` 文件 | 通过 `multica agent update` CLI |
| 备份到桌面 | **备份到文件**（当前 instructions 存为 `.backup/`） |
| 用 `edit` 工具改文件 | 用 `multica agent update --instructions` |
| 技能在本地 `~/.openclaw/skills/` | 技能在 Multica 工作区，用 `multica skill update` |
| `gateway restart` 生效 | 无需重启，下次任务立即生效 |

---

## 可更新字段一览

| 字段 | CLI 参数 | 更新命令 | 生效时机 |
|------|---------|----------|----------|
| Agent 指令（instructions） | `--instructions` | `multica agent update <id> --instructions "…"` | 下次任务 |
| 名称（name） | `--name` | `multica agent update <id> --name "新名称"` | 立即 |
| 描述（description） | `--description` | `multica agent update <id> --description "…"` | 立即 |
| 运行时（runtime） | `--runtime-id` | `multica agent update <id> --runtime-id <uuid>` | 下次任务 |
| 模型（model） | `--model` | `multica agent update <id> --model "模型ID"` | 下次任务 |
| 可见性（visibility） | `--visibility` | `multica agent update <id> --visibility "private/workspace"` | 立即 |
| 最大并行（max_concurrent_tasks） | `--max-concurrent-tasks` | `multica agent update <id> --max-concurrent-tasks 10` | 立即 |
| 自定义参数（custom_args） | `--custom-args` | `multica agent update <id> --custom-args '<json>'` | 下次任务 |
| 运行时配置（runtime_config） | `--runtime-config` | `multica agent update <id> --runtime-config '<json>'` | 下次任务 |
| 头像（avatar） | 无 CLI 参数 | `multica agent avatar <id> --file <path>` | 立即 |
| 技能分配（skills） | `--skill-ids` | `multica agent skills set <id> --skill-ids "id1,id2"` | 下次任务 |
| 添加技能（add skills） | `--skill-ids` | `multica agent skills add <id> --skill-ids "id1"` | 下次任务 |

指令注入时，**对大段中文内容**建议用 `--content-file` 替代 `--instructions` 传字符串，避免 shell 转义问题：

```powershell
# 推荐（避免转义问题）：
$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $instructions, [System.Text.Encoding]::UTF8)
& multica agent update <id> --workspace-id <wsId> --content-file $tmpFile --output json

# 或通过 API 直接 Patch：
& curl.exe -s -m 15 -X PATCH "http://localhost:8080/api/agents/<id>?workspace_id=<wsId>" `
  -H "Authorization: Bearer $pat" -H "Content-Type: application/json" `
  -d "{`"instructions`":`"...大段内容..."`}"
```

---

## 五步执行流程

### Step 1: 备份（强制）

**输入：** 待修改 Agent 的当前状态
**操作：**
```powershell
# 备份当前 Agent 的完整配置到 .backup/ 目录
$backupDir = "C:\Users\lixin\multica\.backup"
mkdir $backupDir -Force | Out-Null

# 备份完整 Agent JSON
& multica agent get <agentId> --workspace-id <wsId> --output json `
  | Out-File "$backupDir/<agentName>.<YYYY-MM-DD>.json" -Encoding utf8

# 如果只改 instructions，备份当前 instructions 到单独文件
& multica agent get <agentId> --workspace-id <wsId> --output json `
  | ConvertFrom-Json | Select-Object -ExpandProperty instructions `
  | Out-File "$backupDir/<agentName>.instructions.<YYYY-MM-DD>.txt" -Encoding utf8
```
**验收：** 备份文件存在且大小 >0
**禁止：** 不备份直接修改

### Step 2: 波及评估（强制）

**输入：** 修改内容描述
**检查项：**
- [ ] 改 instructions → 是否影响该 Agent 的职责边界？上下游依赖是否需要同步？
- [ ] 改 runtime → 新 runtime 是否支持该 Agent 当前挂载的技能？
- [ ] 改 model → 模型切换后该 Agent 的能力是否匹配职责？
- [ ] 改技能分配 → 增减技能后 Agent 的行为流是否仍然完整？
- [ ] 改名称/描述 → 工作区其他成员是否依赖于旧名称（如 issue mention）？
- [ ] 改 max_concurrent_tasks → 并发增加是否会导致资源争用？
- [ ] 涉及批量修改 → 是否需要在同一批次内原子完成？

**输出：** 波及清单 + 是否需要分批执行

### Step 3: 执行

**输入：** Step 1 + Step 2 结果
**原则：**
- 单 Agent 单字段修改 → 一次命令搞定
- 批量多 Agent 同字段修改 → 用循环脚本批量执行
- **指令内容大的（>500 字）** → 用 `--content-file` 写临时文件传，不用命令行字符串
- 涉及 instructions 的修改，注意保留原有格式（Markdown、YAML frontmatter）

```powershell
# 单 Agent 单字段更新示例
& multica agent update <agentId> --workspace-id <wsId> --model "gpt-4o" --output json

# 批量更新示例
$agentIds = @("id1","id2","id3")
foreach ($id in $agentIds) {
  & multica agent update $id --workspace-id $wsId --description "新描述"
}
```

### Step 4: 验证

**检查项：**
- [ ] `multica agent get <id>` 确认字段已更新
- [ ] 备份文件存在且时间戳正确
- [ ] UI 刷新后内容一致（http://localhost:3000）
- [ ] 如果是 instructions 修改 → 确认内容完整无截断（对比备份）
- [ ] 如果是 runtime/model 切换 → 确认 Agent 状态为 idle（非 error）
- [ ] 如果是技能修改 → `multica agent skills list <id>` 确认挂载正确
- [ ] 如果是批量操作 → 抽查 2-3 个 Agent 确认

### Step 5: 回滚预案

**如果修改导致问题：**
```powershell
# 从 .backup 恢复 instructions
$oldInstructions = Get-Content "$backupDir/<agentName>.instructions.<YYYY-MM-DD>.txt" -Raw
& multica agent update <agentId> --workspace-id <wsId> --instructions $oldInstructions --output json

# 或恢复完整配置（需要手动重建指令）
& multica agent update <agentId> --workspace-id <wsId> `
  --name "原名" --description "原描述" --runtime-id "<原runtime>"
```

---

## Multica 环境独有注意事项

### 1. 工作区 ID 是个常量
```
$wsId = "5395cb85-8dbe-4787-ba3b-787895cd1907"
```
所有 multica agent 操作都需要带上它。

### 2. API 路径规则
- Multica CLI 自动处理 workspace 上下文，但 **某些 API 端点仍需传 `workspace_id` 参数**
- `PATCH /api/agents/<id>` 需要 `?workspace_id=` 或 slug 路径
- 直接用 CLI 比手搓 curl 更稳定

### 3. 中文编码
- PowerShell 的 `ConvertFrom-Json` 对含中文字段的 JSON 易出错
- **建议用** `[System.Text.Encoding]::UTF8.GetString()` 搭配正则提取
- 或用 `--output table` 查看，避免 JSON 解析报错

### 4. 指令长度约束
- Multica 后端 `instructions` 字段无硬性长度限制，但 CG 质量建议单条指令 ≤ 8000 字
- 超过的可考虑拆分为 instructions + skills 组合

### 5. 操作轨迹
- Multica 的 Agent 更新会记录 `updated_at` 时间戳
- 但无内置审计日志 → **操作者应自己记录修改日志**到 `multica/changelog/` 目录

### 6. 原子性
- Multica 无批量事务支持：`agent update` 是单条操作
- 批量更新时若中间失败，**已成功的不会回滚**
- → 关键批量操作前：先备份全家桶 `multica agent list --workspace-id <wsId> --output json > full-backup.json`

---

## 输出格式

每次更新完成后输出：
```
[Agent File Update] Agent: <名称> | 操作: <instructions/description/runtime/skills>
备份: <路径> | 验证: PASS/FAIL | 回滚: <预案简述>
```

## 反模式（Anti-Patterns）

- 不备份当前 instructions 就直接覆盖 ❌
- 长篇指令内容直接传 CLI 参数而不写文件 ❌
- 批量操作不记录顺序，失败后无法分批重试 ❌
- 改 instructions 后不确认内容完整性 ❌
- 直接用 API PATCH 但没传 workspace_id ❌

## 验证方式

```powershell
# 验证备份存在
Get-ChildItem "C:\Users\lixin\multica\.backup\*.json" | Select-Object Name, Length, LastWriteTime

# 验证 Agent 当前状态
& multica agent get <agentId> --workspace-id <wsId> --output json 2>&1

# 验证指令内容完整（对比备份文件与当前）
$current = & multica agent get <agentId> --workspace-id <wsId> --output json 2>&1
$current > "$env:TEMP\_current.json"
python3 -c "import json; print(len(json.load(open(r'$env:TEMP\_current.json'))['instructions']))" 2>&1
```

---

## 附录：实战操作模式（2026-06-03 验证通过）

以下操作模式均在本集群搭建过程中实际执行并验证通过，可直接复制使用。

### A. 批量注入 Agent 指令

```powershell
$wsId = "5395cb85-8dbe-4787-ba3b-787895cd1907"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$instructions = [System.IO.File]::ReadAllText($filePath)

# 写临时文件避免 shell 转义
$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $instructions, $utf8NoBom)
$content = [System.IO.File]::ReadAllText($tmpFile)

$r = & multica agent update $agentId --workspace-id $wsId --instructions $content --output json 2>&1
Remove-Item $tmpFile -EA SilentlyContinue
```

### B. 批量设置技能（set = 全量替换）

```powershell
# set = 替换全部已有技能
$ids = "id1,id2,id3"
& multica agent skills set $agentId --workspace-id $wsId --skill-ids $ids --output json

# add = 追加不覆盖
& multica agent skills add $agentId --workspace-id $wsId --skill-ids $ids --output json

# 用 table 输出查看（避免 JSON 编码问题）
& multica agent skills list $agentId --workspace-id $wsId --output table
```

### C. 批量创建技能（从 YAML 块解析）

从包含 ````yaml` 块的 .txt 文件中批量提取并创建技能：

```powershell
# 提取 YAML 块 → 写 SKILL.md → 创建
$content = Get-Content $path -Raw
$blocks = [regex]::Matches($content, '(?ms)````yaml\s*\n(.+?)\n````')
foreach ($block in $blocks) {
    $yamlContent = $block.Groups[1].Value
    $name = [regex]::Match($yamlContent, '(?m)^name:\s*(\S+)').Groups[1].Value
    $desc = <从 yaml 提取 description>
    
    # 构建 SKILL.md 内容
    $skillMd = "---`nname: $name`n...`n---`n```yaml`n$yamlContent`n```"
    
    $tmpFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpFile, $skillMd, $utf8NoBom)
    
    & multica skill create --workspace-id $wsId --name $name `
      --description $desc --content-file $tmpFile --output json
    
    Remove-Item $tmpFile -EA SilentlyContinue
}
```

**注意：** `skill create` 用 `--content-file` 参数传文件，无 `--file` 参数。

### D. 批量切运行时

```powershell
$codexId = "c676f3af-b44a-49b1-9361-467fe6d2f34e"
$ids = @("agentId1", "agentId2", ...)
foreach ($id in $ids) {
    & multica agent update $id --workspace-id $wsId --runtime-id $codexId --output json
}
```

### E. 批量设头像

```powershell
foreach ($id in $ids) {
    & multica agent avatar $id --file "D:\path\to\avatar.gif" --output json
}
```

### F. 批量分配专业技能（从角色-技能映射）

```powershell
# 按角色文件解析 → 解析出技能名 → 查 ID → add 到 Agent
$agentSkills = @{
    "CP" = @("skill-a", "skill-b", "skill-c")
    "QD" = @("skill-d", "skill-e", "skill-f")
}

# 先创建所有技能，再通过 curl API 获取 ID 映射
$raw = & curl.exe -s -m 10 "http://localhost:8080/api/skills?workspace_id=$wsId" -H "Authorization: Bearer $pat"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$idMatches = [regex]::Matches($text, '"id":"([^"]+)"')
$nameMatches = [regex]::Matches($text, '"name":"([^"]+)"')

$skillIdMap = @{}
for ($i = 0; $i -lt $idMatches.Count; $i++) {
    $skillIdMap[$nameMatches[$i].Groups[1].Value] = $idMatches[$i].Groups[1].Value
}
```

### G. 创建小队并添加成员

```powershell
& multica squad create --workspace-id $wsId --name "策划部" `
  --description "策划案撰写与审批" --leader $plId --output json

& multica squad member add $squadId --workspace-id $wsId `
  --member-id $agentId --type agent --output json
```

### H. 更新已有技能内容

```powershell
& multica skill update $skillId --workspace-id $wsId --content-file $path --output json
```

### I. 已知坑点（已验证）

| 坑 | 现象 | 根因 | 正确做法 |
|----|------|------|----------|
| `multica agent update --instructions "@file"` | 指令内容存为 `@file` 字面量 | CLI 不支持 `@file` 语法 | 用 `--content-file` 或 ReadAllText 后传字符串 |
| `ConvertFrom-Json` 解析含中文的 JSON | 报 `invalid property identifier` | 中文被 PS 编码破坏 | 用 `[Text.Encoding]::UTF8.GetString()` 或 `--output table` |
| `Out-File -Encoding utf8` | 生成带 BOM 的 UTF-8 | PS 默认带 BOM | 用 `WriteAllText($path, $content, $utf8NoBom)` |
| Python `capture_output=True` 含中文 | `UnicodeDecodeError` | stdout 编码为 GBK | 设 `encoding='utf-8', errors='replace'` |
| `PATCH /api/agents/` | 404 / `workspace_id required` | workspace_id 只能通过 URL 参数传递 | 尽量用 CLI 而非 curl |
| `multica skill create` 无 `--file` 参数 | `unknown flag: --file` | 参数名是 `--content-file` | 用 `--content-file` |
| 批量操作中途失败 | 已成功的不会回滚 | Multica 无事务 | 操作前备份全家桶 `multica agent list --output json > backup.json` |
