---
name: task-planner
version: 1.0.0
description: "将用户的宏大目标分解为结构化任务地图。展示全局结构、阶段划分、依赖关系和关键里程碑。适用于项目启动、复杂目标拆解和长期规划。不执行具体任务，仅做规划。"
triggers:
  - "规划"
  - "任务分解"
  - "战略规划"
  - "task plan"
  - "项目规划"
tools:
  - exec
  - write
  - read
  - sessions_spawn
mutating: true
metadata:
  openclaw:
    emoji: "👑"
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
    configPaths: ["~/.openclaw/skills/task-planner/"]
---

# Task Planner — 战略规划技能

## Contract
1. **只规划不执行** — 本技能只生成任务地图和规划文档，不执行具体任务。
2. **结构化输出** — 输出为 Markdown 任务地图文件，包含阶段/里程碑/依赖/负责人。
3. **可追溯** — 每条任务项关联用户的原始目标，确保不偏离方向。
4. **输入：** 用户自然语言描述的宏大目标（任意长度）。
5. **验收标准：** 输出文件可被 openclaw-superpowers 技能作为输入直接消费。

## 执行步骤

### Step 1: 需求澄清
**输入：** 用户输入的目标描述
**操作：**
1. 提取核心目标、约束条件、期望时间线
2. 如果目标描述模糊（< 20 字），用 sessions_send 向用户确认关键细节
3. 输出清晰的需求陈述
**输出：** GoalStatement { title, description, constraints, timeline }

### Step 2: 阶段划分
**输入：** GoalStatement
**操作：**
1. 将目标拆解为 3-7 个逻辑阶段
2. 每个阶段标注：名称、目标、预期产出、估算时长
3. 识别阶段间的依赖关系
**输出：** Phase[] { name, goal, deliverable, estimatedDuration, dependsOn[] }

### Step 3: 里程碑设定
**输入：** Phase[]
**操作：**
1. 为每个阶段设定 1-3 个关键里程碑
2. 里程碑需有明确的验证标准（什么算完成）
**输出：** Milestone[] { phase, name, verificationCriteria, targetDate }

### Step 4: 任务分解
**输入：** Phase[] + Milestone[]
**操作：**
1. 将每个阶段分解为可执行的任务项
2. 每项任务标注：描述、负责人（Agent ID）、预估工时、依赖、优先级
3. 识别跨阶段的任务依赖链
**输出：** Task[] { id, phase, description, assignee, estimatedHours, dependsOn[], priority }

### Step 5: 生成任务地图文件
**输入：** GoalStatement + Phase[] + Milestone[] + Task[]
**操作：**
1. 写入 `~/.openclaw/skills/task-planner/plans/{project-name}-plan.md`
2. 格式：清晰的 Markdown 文档，含阶段进度条、里程碑时间线、依赖 DAG 图（Mermaid）
3. 确保文件幂等（同名项目覆盖而非追加）
**输出：** 确认文件路径 + 任务统计摘要

## 输出格式
```
👑 任务地图已生成
项目：{project-name}
阶段数：{n} | 里程碑：{m} | 任务数：{t}
预计总工时：{hours}h
关键路径：{critical-path}
文件：{path}
```

Markdown 地图包含：
- 项目概览（目标、约束、时间线）
- 阶段一览（Mermaid Gantt 图）
- 里程碑时间线
- 任务分解表（ID/描述/工时/依赖/优先级）
- 依赖关系图（Mermaid DAG）
- 关键路径高亮

## 验证方式
```powershell
# 1. 目录结构完整
Test-Path "$env:USERPROFILE\.openclaw\skills\task-planner\SKILL.md"
# 2. 输出目录可写
$planDir = "$env:USERPROFILE\.openclaw\skills\task-planner\plans"
if (-not (Test-Path $planDir)) { New-Item -ItemType Directory -Path $planDir -Force | Out-Null }
Write-Host "PASS: plan dir ready"
# 3. 生成测试规划文件
$testPlan = "# Test Plan`n## Phase 1: Setup`n- [ ] Task 1`n" 
$testPlan | Out-File -Path "$planDir\_test.md" -Encoding utf8
Remove-Item "$planDir\_test.md" -Force
Write-Host "PASS: plan file write/delete OK"
```

## 反模式
- ❌ 规划阶段就开始执行任务 — 只规划不执行
- ❌ 过度拆解（超过 50 个任务项） — 控制在可管理范围
- ❌ 忽略依赖关系 — 必须标注跨阶段依赖
- ❌ 规划不写文件 — 每次规划必须生成持久化文件
- ❌ 模糊的里程碑标准 — 必须有可验证的完成标准
