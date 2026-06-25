---
name: audit-skill
display_name: "任务审计与自愈 (v3)"
type: workflow
tags: [audit, reflection, error-scanning, memory, self-heal]
related: [[gbrain-skill]], [[skill-judge]], [[task-planner]]
source: "main agent 2026-06-26 merge: agent-reflection + error-scanner + failure-memory → audit-skill"
version: 3.0.0
description: "任务后审计与自愈。覆盖审计触发、失败模式提取、修正方案生成、补丁应用、审计日志记录。统一替代 agent-reflection（复盘）、error-scanner（日志扫描）和 failure-memory（失败记录）。当任务失败、用户不满、重复出错、或门禁 4 交付完成时调用。不做系统级配置修改。"
triggers:
  - "audit"
  - "/audit"
  - "审计"
  - "任务审计"
  - "错误模式分析"
  - "scan errors"
  - "错误扫描"
  - "记错"
  - "record error"
  - "失败模式"
  - "反思"
  - "回顾"
  - "复盘"
  - "自我提升"
  - "做得怎么样"
  - "经验教训"
tools:
  - read
  - write
  - edit
  - exec
  - memory_search
  - memory_write
  - wiki_search
  - lcm_grep
  - lcm_describe
  - lcm_expand_query
mutating: true
metadata:
  openclaw:
    emoji: "??"
    layer: 2
    layer_label: "Workflow Library"
    requires:
      bins: []
    deniedTools:
      - gateway
      - sessions_spawn
      - cron
    configPaths: ["~/.openclaw/.audit/"]
---

# ?? Audit Skill v3 — 任务审计·反思·错误扫描·模式记录

## 职责

一体化任务后审查：扫描错误、反思复盘、记录失败模式、生成补丁、审计归档。
本 skill 统一了原 agent-reflection、error-scanner、failure-memory 三个独立技能的全部职能。

## Contract

1. **只读审计** — 审计阶段不做任何写操作。所有修改发生在"补丁生成"阶段，且必须记录 diff。
2. **输出格式** — JSONL 格式审计日志，每条含 taskId/trigger/reason/fix/needsReview。
3. **去重** — 同一错误模式在同一会话中只记录一次审计。
4. **补丁安全** — 低风险补丁（知识追加、措辞优化）自动应用；高风险补丁（修改核心逻辑、工具权限）需标记 needsReview=true。
5. **验收** — 审计日志可被 `memory_search` 或文件搜索独立验证。

---

## 执行步骤

### Step 1: 捕获触发

**输入：** 任务上下文（对话历史、工具调用序列、用户反馈）

**从以下途径捕获：**
- 用户表达了不满意（"不对""又错了""你忘了"）
- 工具调用失败或重试 > 1 次
- 执行时间显著超过同类任务均值
- 门禁 4 交付完成（触发 5 问反思）

**输出：** TriggerEvent { reason, severity, context }

---

### Step 2: 错误扫描（可选子模块）

仅在手动要求 "scan errors" 或自动检测到异常时执行。

**输入：** 日志路径 / 对话范围 / 自动（默认自动）

**行为：**
1. **确定扫描范围**
   - 有日志路径 → exec + Select-String 搜索 error/exception/fail/crash 模式
   - 无日志路径 → `lcm_grep(pattern="error|exception|fail|crash", mode="full_text", scope="both", sort="recency", limit=30)`
   - 自动模式：先搜对话，结果 <5 条再补扫日志

2. **归类与去重**
   - 提取规范化错误签名（去时间戳/进程 ID）
   - 与已知失败模式对比 → 标记已知/新发现
   - 推断严重度：`fatal`/`panic` → `critical` | `exception`/`crash` → `high` | `fail`/`timeout` → `medium`

**输出：** 错误扫描报告（模式列表含签名、严重度、首次/最新发现时间、出现次数）

**Windows 兼容命令：**
```powershell
Select-String -Pattern '(error|exception|fail|crash|fatal|abort|panic|unhandled)' -Path "<path>" -CaseSensitive:$false | Select-Object -Last 200
```

---

### Step 3: 结构化反思

**输入：** TriggerEvent（如果来自门禁 4 交付）

**回答五个反思问题：**

| # | 问题 | 说明 |
|---|------|------|
| Q1 | 这次做对了什么？ | 哪个决策最有效？哪个步骤特别顺畅？ |
| Q2 | 这次做错了什么？ | 哪里走了弯路？哪个判断是错的？ |
| Q3 | 如果重来会怎么做？ | 第一步做什么改变？什么可以跳过/简化？ |
| Q4 | 学到了什么？ | 新工具/新API/新方法/新排查思路？ |
| Q5 | 谁需要知道？ | 沉淀到 gbrain？更新 MEMORY.md？ |

**输出：** 反思笔记（Markdown 格式，含好/改进/学到/后续行动）

---

### Step 4: 记录失败/成功模式

**输入：** 错误扫描报告 + 反思笔记

**行为：**
1. 检查去重：`memory_search(query="<模式关键词>", corpus="memory")` 查看是否已有类似记录
2. 新发现 → 结构化记录到 MEMORY.md 域三（教训库）：
   - `memory_write(key="域三：教训库.<主题>", value="<场景/根因/修复>")`
3. 成功经验 → 记录到 MEMORY.md 域五（习惯备忘）

**记录原则：**
- 不记录纯噪声（临时网络波动、已知平台限制）
- 只记录有根因分析价值的模式
- 根因分析用五问法追到真因

**输出：** 模式记录确认

---

### Step 5: 生成修正方案

**输入：** FailurePattern

**分支判断：**
- 知识缺失 → 生成 MEMORY.md 更新片段（自动应用）
- 工具调用冗余 → 优化步骤描述（自动）
- 技能步骤错误 → 生成 diff 补丁（标记 needsReview=true）
- 新模式需沉淀 → 调用 gbrain-skill 入库（自动）

**输出：** FixPlan { type, target, content, needsReview }

---

### Step 6: 应用补丁

**输入：** FixPlan

**操作：**
1. needsReview=false → 自动应用（write/edit/memory_write）
2. needsReview=true → 输出建议，等主人决策
3. 无论哪种都执行验证（回读确认）

**输出：** PatchResult { applied, file, success, validation }

---

### Step 7: 记录审计日志

**输入：** 完整的触发→分析→修正确认链

**操作：** 追加写入 `~/.openclaw/.audit/YYYY-MM-DD.jsonl`

**格式：**
```json
{"timestamp":"ISO8601","trigger":"reason","severity":"high","action":"patch/fix/log","target":"path","needsReview":false,"success":true}
```

**输出：** 确认写入 + 日志行预览

---

## 输出格式

```
?? 审计结果
触发原因：{reason}
发现模式：{pattern}
修正动作：{action} → {target}
是否需要复核：{needsReview}
审计日志：{path}
```

---

## 验证方式

```powershell
# 验证审计目录存在
Test-Path "$env:USERPROFILE\.openclaw\.audit"
# 验证 SKILL.md 存在
Test-Path "$env:USERPROFILE\.openclaw\skills\audit-skill\SKILL.md"
# 验证日志可写
$testEntry = '{"test":true,"timestamp":"'+(Get-Date -Format "o")+'"}'
$testEntry | Out-File -FilePath "$env:USERPROFILE\.openclaw\.audit\test.jsonl" -Append -Encoding utf8
Remove-Item "$env:USERPROFILE\.openclaw\.audit\test.jsonl" -Force
Write-Host "PASS: audit log writable"
```

---

## 何时用 / 何时不用

| 场景 | 用 / 不用 |
|------|-----------|
| 用户说"又错了""不对" | ✅ 用 |
| 工具调用连续失败 | ✅ 用 |
| 门禁 4 交付完成 | ✅ 用（触发反思环节） |
| 需要扫描日志找错误 | ✅ 用（Step 2 子模块） |
| 需要记录踩坑教训 | ✅ 用（Step 4 → MEMORY.md 域三） |
| 纯闲聊 | ❌ 不用 |
| 系统级配置修改 | ❌ 不用（gateway/cron 被 deny） |
| 审计自身执行 | ❌ 不用 |

## 反模式

- ? 审计阶段修改源文件 — 审计是只读的，patch 阶段才能写
- ? 记录全量对话 — 只提取摘要和关键行
- ? 自动应用高风险补丁 — 必须标记 needsReview
- ? 多次告警同一模式 — 同一会话中去重
- ? 审计自己 — 本 skill 不审计自身的执行
- ? 记录纯噪声 — 临时网络波动、已知平台限制不记录
- ? 不记录失败原因 — 失败任务必须记录详细原因
