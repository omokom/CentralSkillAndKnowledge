---
name: audit-skill
display_name: "技能审计"
version: 2.0.0
description: "任务后审计与自愈。分析任务执行中的疏漏、错误和低效模式，自动生成补丁技能或修改现有技能。覆盖 AGENTS.md 域十一（任务后审计强制）的全部职责：审计触发、失败模式提取、修正方案生成、补丁应用、审计日志记录。当任务失败、用户不满、重复出错、或门禁 4 交付完成时由 Agent 调用。不做系统级配置修改。"
triggers:
  - "audit"
  - "/audit"
  - "审计"
  - "任务审计"
  - "域十一"
  - "任务后审计"
  - "审计触发"
  - "错误模式分析"
tools:
  - exec
  - write
  - edit
  - read
  - lcm_grep
  - lcm_describe
  - memory_recall
  - memory_store
mutating: true
metadata:
  openclaw:
    emoji: "🔎"
    layer: 2
    layer_label: "Workflow Library"
    requires:
      bins: []
    deniedTools:
      - gateway
      - sessions_spawn
    configPaths: ["~/.openclaw/skills/audit-skill/", "~/.openclaw/.audit/"]
    replaces: "AGENTS.md 域十一"

---

# Audit Skill — 任务审计与自愈

## Contract
1. **只读审计** — 审计阶段不做任何写操作。所有修改发生在"补丁生成"阶段，且必须记录 diff。
2. **输出格式** — JSONL 格式审计日志，每条含 taskId/trigger/reason/fix/needsReview。
3. **去重** — 同一错误模式在同一会话中只记录一次审计。
4. **补丁安全** — 低风险补丁（知识追加、措辞优化）自动应用；高风险补丁（修改核心逻辑、工具权限）需标记 needsReview=true。
5. **验收** — 审计日志可被 `memory_recall` 或文件搜索独立验证。

## 执行步骤

### Step 1: 捕获审计触发
**输入：** 任务上下文（对话历史、工具调用序列、用户反馈）
**检查条件：**
- 用户表达了不满意（"不对""又错了""你忘了"）
- 工具调用失败或重试 > 1 次
- 执行时间显著超过同类任务均值
- 技能调用结果不理想
**输出：** TriggerEvent { reason, severity, context }

### Step 2: 提取失败模式
**输入：** TriggerEvent
**操作：**
1. 如果来自对话，用 lcm_grep 搜索关键错误行
2. 从工具调用链中定位失败步骤
3. 对比预期结果标记不一致
**输出：** FailurePattern { pattern, rootCause, frequency, evidence }

### Step 3: 生成修正方案
**输入：** FailurePattern
**分支判断：**
- 知识缺失 → 生成 MEMORY.md 更新片段（自动应用）
- 工具调用冗余 → 生成优化技能放入 staging/（自动）
- 技能步骤错误 → 生成 diff 补丁（标记 needsReview=true）
- 新模式 → 调用 skill-creator 生成新技能（自动，七原则检查）
**输出：** FixPlan { type, target, content, needsReview }

### Step 4: 应用补丁
**输入：** FixPlan
**操作：**
1. 如果 needsReview=false → 自动应用（write/edit/memory_store）
2. 如果 needsReview=true → 写入 staging/ 并生成 quality_report
3. 无论哪种情况都执行验证（重跑或回读确认）
**输出：** PatchResult { applied, file, success, validation }

### Step 5: 记录审计日志
**输入：** TriggerEvent + FailurePattern + FixPlan + PatchResult
**操作：** 写入 `~/.openclaw/.audit/YYYY-MM-DD.jsonl`
**日志格式：** JSON 单行，包含 timestamp/trigger/reason/severity/action/target/needsReview/success
**输出：** 确认写入 + 日志行预览

## 输出格式
审计摘要文本：
```
🔎 审计结果
触发原因：{reason}
发现模式：{pattern}
修正动作：{action} → {target}
是否需要复核：{needsReview}
审计日志：{path}
```

## 验证方式
```powershell
# 1. 审计目录存在
Test-Path "$env:USERPROFILE\.openclaw\.audit"
# 2. SKILL.md 存在
Test-Path "$env:USERPROFILE\.openclaw\skills\audit-skill\SKILL.md"
# 3. 审计日志可写
$testEntry = '{"test":true,"timestamp":"'+(Get-Date -Format "o")+'"}'
$testEntry | Out-File -FilePath "$env:USERPROFILE\.openclaw\.audit\test.jsonl" -Append -Encoding utf8
Remove-Item "$env:USERPROFILE\.openclaw\.audit\test.jsonl" -Force
Write-Host "PASS: audit log writable"
```

## 反模式
- ❌ 审计阶段修改源文件 — 审计是只读的，patch 阶段才能写
- ❌ 记录全量对话 — 只提取摘要和关键行
- ❌ 自动应用高风险补丁 — 必须标记 needsReview
- ❌ 多次告警同一模式 — 同一会话中去重
- ❌ 审计自己 — 审计技能不审计自身的执行
