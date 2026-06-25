---
name: skill-evolver
version: 2.0.0
description: |
  Multica 环境技能库质量维护。定期扫描工作区所有技能，检查：重复/描述质量/原则违反/
  长期未使用/设计违规。可自动修正或标记待人工处理。
  适合安排为定时任务（如每周日）运行。
  不做：修改工作流层技能（infraloop-workflow/audit-skill）、删除有使用记录的技能、
  修改系统级配置。
triggers:
  - "技能检查"
  - "技能维护"
  - "技能自检"
  - "技能审计"
  - "技能仓库检查"
  - "定期检查技能"
  - "evolve skills"
  - "maintain skills"
  - "技能进化"
  - "evolver"
  - "技能质量"
  - "技能扫描"
  - "检查技能仓库"
tools:
  - read
  - write
  - edit
  - exec
mutating: true
metadata:
  codex:
    emoji: "🧬"
    layer: 1
    layer_label: "Atomic Skills"
    priority: normal
    requires:
      bins: ["multica"]
---

# 🧬 Skill Evolver (Multica) — 技能库质量维护

> 版本: 2.0.0 | 适用: Multica 工作区技能

---

## 核心变化（相对 v1）

| 旧版（OpenClaw） | 新版（Multica + Codex） |
|-----------------|------------------------|
| 扫描本地 `~/.openclaw/skills/` 目录 | 通过 `multica skill list` API 扫描工作区 |
| 本地 `edit` 工具修改 SKILL.md | 通过 `multica skill update --content-file` 更新 |
| `trash` 删除文件 | `multica skill update` + 标记废弃（无直接删除） |
| 检查本地文件 mtime/atime | 读取 `multica skill list` 的 `updated_at` + `created_at` |
| 本地 `changelog.md` 记录 | 写入 `multica/skill-evolver-reports/` 目录 |

---

## 检查范围

```powershell
# 获取工作区所有技能
& multica skill list --workspace-id <wsId> --output json
```

当前工作区：`5395cb85-8dbe-4787-ba3b-787895cd1907`（CF.Game）

### 技能分层（技能进化尊重层级）

| 层级 | 范围 | 可操作 |
|------|------|--------|
| 🔒 **L1 工作流层** | infraloop-workflow, audit-skill | **只读不写** |
| 📋 **L2 管理层** | task-planner, quality-gate 等 | 可建议优化，需审批 |
| ✏️ **L3 专业层** | 各角色工作技能 | **可优化/合并/修正** |
| 🆕 **L4 实验层** | 新建未评级技能 | **可优化/合并/删除** |

---

## 技能质量检查清单

对每个技能执行以下检查，逐项打分：

### A. 存在性与完整性
- [ ] `name` 存在且为合法 slug（小写+连字符）
- [ ] `description` 非空，≤200 字
- [ ] `triggers` 有至少 1 个触发词
- [ ] `tools` 中只含 `read/write/edit/exec`（Codex 兼容）
- [ ] 正文非空，有实际内容

### B. 七原则检查
| # | 原则 | 检查方法 |
|---|------|----------|
| 1 | 单一职责 | description + 步骤是否聚焦一件事？ |
| 2 | SOP 式 | 步骤是否可重复执行、无歧义？ |
| 3 | 工具边界 | tools 只声明 read/write/edit/exec 四种？ |
| 4 | 声明依赖 | metadata.requires.bins 是否填了外部依赖？ |
| 5 | 渐进披露 | 用标题分层，信息从粗到细？ |
| 6 | 幂等性 | 用"确保目录存在"而非"创建目录"？ |
| 7 | 可验证 | 有验证/自查方式？ |

### C. 描述质量
- 是否以具体动词开头（"管理""生成""检查"而非"这是一个"）
- 是否明确能力边界（含"不做"）
- 是否有冗余词

### D. 重复检测
两两对比技能描述，检查：共用触发词、核心功能表述、功能域交叉

**判定：**
- `exact-dup` — 描述几乎相同 → **合并**
- `near-dup` — 核心功能一致但场景不同 → **建议合并**
- `overlap` — 功能域交叉 → **记录待议**

### E. 健康度评分

| 指标 | 满分 | 扣分项 |
|------|------|--------|
| description 清晰度 | 10 | 冗余/模糊/缺边界 -2 每项 |
| triggers 精准度 | 10 | 少于 2 个 -3，太泛 -2 |
| 步骤完整度 | 10 | 无步骤 -5，步骤模糊 -2 |
| 工具声明准确性 | 10 | 含 Codex 不认工具 -10 |
| 验证方式 | 10 | 无验证节 -3 |
| 单一职责 | 10 | 交叉功能 -5 |
| **总分** | **60** | |

健康等级：≥50=优秀, 40-49=良好, 30-39=需改进, <30=待废弃

---

## 执行流程

### Phase 1: 拉取技能清单

```powershell
& multica skill list --workspace-id <wsId> --output json > skills-raw.json
```

解析出所有技能 name/description/id/created_at/updated_at。

### Phase 2: 逐技能检查

对每个技能（按分层跳过 L1）：
1. 用 `multica skill get <id>` 获取完整内容
2. 执行 A→E 全部检查项
3. 记录 finding

### Phase 3: 执行修正

根据 finding 类型自动执行：

```powershell
# 修正 description
$fixedContent = <修正后的完整 SKILL.md 内容>
$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $fixedContent, [System.Text.Encoding]::UTF8)

& multica skill update <skillId> --workspace-id <wsId> --content-file $tmpFile --output json
Remove-Item $tmpFile -EA SilentlyContinue
```

### Phase 4: 生成报告

```markdown
## 🧬 技能进化报告 — <日期>

### 总览
| 指标 | 数值 |
|------|------|
| 工作区总技能数 | <N> |
| 本次扫描 | <N> |
| 跳过(L1锁定) | <N> |
| 优秀(≥50) | <N> |
| 良好(40-49) | <N> |
| 需改进(<40) | <N> |

### 自动修正
| 技能 | 操作 | 详情 |
|------|------|------|
| <name> | 优化描述 | 原: xxx → 新: xxx |
| <name> | 修正 tools | 移除了不兼容工具声明 |

### 待人工处理
| 技能 | 问题 | 建议 |
|------|------|------|
| <name> | 重复 | 与 <name2> 描述重叠 80% |
| <name> | 健康度低(25/60) | 无步骤/无验证/描述空泛 |

### 长期未关注
| 技能 | 创建时间 | 最后更新 | 天数 |
|------|----------|----------|------|
| <name> | <date> | <date> | <N>天 |
```

---

## 定时检查配置

建议用 Multica cron 或系统任务计划安排定期自检：

### 方式 1：通过 OpenClaw cron（推荐）

```yaml
# 每周日 9:00 执行 skill 仓库自检
schedule: "0 9 * * 0"
payload:
  kind: "systemEvent"
  text: "【定时自检】执行 skill-evolver 技能仓库质量扫描。扫描范围：工作区全部 L2-L4 技能。报告写入 multica/skill-evolver-reports/。"
```

### 方式 2：任务触发词
在分配给管理 Agent 的日常任务中附带触发词：
- "技能检查" → 自动触发 skill-evolver
- "技能自检" → 自动触发 skill-evolver
- "检查技能仓库" → 自动触发 skill-evolver

### 方式 3：反思后触发
当 `agent-reflection` 反思中发现技能相关问题时 → 调用 `skill-evolver` 做针对性检查。

---

## 报告归档

每次执行报告写入：

```powershell
$reportDir = "C:\Users\lixin\multica\skill-evolver-reports"
mkdir $reportDir -Force | Out-Null
$report | Out-File "$reportDir\evolver-<YYYY-MM-DD>.md" -Encoding utf8
```

保留最近 12 周报告，超期的自动归档：
```powershell
Get-ChildItem $reportDir -Filter "*.md" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-84) } | Remove-Item
```

---

## 防守原则

### 禁止操作
- ❌ 修改 L1 工作流技能（infraloop-workflow, audit-skill）
- ❌ 修改 instructions（这是 agent-file-update 的职责）
- ❌ 删除有使用记录的技能（created_at < 30 天且 updated_at 在 7 天内的视为活跃）
- ❌ 直接通过 API 删除技能（Multica 不支持 skill delete，只能更新内容）
- ❌ 修改其他 Agent 的角色指令

### 必须记录
- ✅ 每次自动修正必须写入 `edits-log.md`
- ✅ 每次人工建议必须写入 `pending-reviews.md`
- ✅ 每周报告必须归档，保留至少 12 周

### 升级条件
- 发现 L1 技能有原则违反 → 记录但不修改，在报告中特别标注
- 发现技能安全隐患（如 tools 声明中有 banned 工具）→ 标记 CRITICAL，立即上报
- 连续 3 次检查同一技能 health < 30 → 标记为废弃候选

---

## 验证方式

```powershell
# 检查报告是否存在
Get-ChildItem "C:\Users\lixin\multica\skill-evolver-reports\" | Select-Object Name, Length, LastWriteTime

# 检查最近一次自检是否修正了问题
& multica skill get <modifiedSkillId> --workspace-id <wsId> --output json 2>&1

# 检查 edits-log 确认修改记录
Get-Content "C:\Users\lixin\multica\skill-evolver-reports\edits-log.md" -Tail 10
```

---

## 附录：实战操作模式（2026-06-03 验证通过）

### A. 获取技能 ID 映射（关键操作）

由于 Multica CLI 输出的 JSON 含中文字段，PowerShell `ConvertFrom-Json` 会解析失败。以下模式已验证可用：

```powershell
# 方法一：curl 取原始 JSON + UTF8.GetString 解析
$raw = & curl.exe -s -m 10 "http://localhost:8080/api/skills?workspace_id=$wsId" -H "Authorization: Bearer $pat"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($raw)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)

$idMatches = [regex]::Matches($text, '"id":"([^"]+)"')
$nameMatches = [regex]::Matches($text, '"name":"([^"]+)"')

$skillMap = @{}
for ($i = 0; $i -lt $idMatches.Count; $i++) {
    $skillMap[$nameMatches[$i].Groups[1].Value] = $idMatches[$i].Groups[1].Value
}
```

```powershell
# 方法二：table 输出查看（简单确认）
& multica skill list --workspace-id $wsId --output table | Select-String "技能名"
```

```powershell
# 方法三：Python 解析（复杂时）
python -c "import json, subprocess\nout, _ = subprocess.run(['multica','skill','list','--workspace-id','$wsId','--output','json'], capture_output=True, text=True, encoding='utf-8', errors='replace')\nskills = json.loads(out)\nfor s in skills: print(s['id'], s['name'])"
```

### B. 读取单技能完整内容

```powershell
$raw = & curl.exe -s -m 5 "http://localhost:8080/api/skills/$skillId?workspace_id=$wsId" -H "Authorization: Bearer $pat"
# 或
& multica skill get $skillId --workspace-id $wsId --output json
```

### C. 更新技能内容

```powershell
$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $newContent, [System.Text.Encoding]::UTF8)
& multica skill update $skillId --workspace-id $wsId --content-file $tmpFile --output json
Remove-Item $tmpFile -EA SilentlyContinue
```

### D. 健康度评分参考

基于本次 92 个技能的实际扫描经验，常见扣分项：

| 问题 | 扣分 | 出现频率 |
|------|------|----------|
| `tools` 含 Codex 不认的工具（lcm_*, memory_*, sessions_*） | -10 | 高（需适配） |
| `depends_on` 引用了 OpenClaw 特有技能 | -5 | 中 |
| `deniedTools` 含 gateway/cron 但已在 frontmatter 声明 | -3 | 中 |
| 无 `mutating` 字段 | -2 | 低 |
| 无 `metadata` 段 | -1 | 低 |
| description 超 200 字截断 | -1 | 低 |
| triggers 少于 2 个 | -3 | 中 |
| 无 steps 或步骤模糊 | -5 | 低（92 个新技能含详细 YAML） |

### E. 批量技能操作的最佳顺序

```
1. multica skill create（批量创建所有技能）
2. curl API 获取全部技能 ID 映射
3. multica agent skills set/add（批量分配到 Agent）
```

注意：`set` 是全量替换，`add` 是追加。如果 Agent 已有基础技能用 `add`，初次分配用 `set` 更方便。
