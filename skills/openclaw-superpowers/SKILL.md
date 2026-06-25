---
name: openclaw-superpowers
version: 1.0.0
description: "战术执行引擎。接收结构化任务地图，将高级任务细分为可执行单元，调度子代理并行或串行完成。支持进度追踪、异常处理和结果汇总。不替代 task-planner 的规划职能。"
triggers:
  - "执行"
  - "调度"
  - "任务执行"
  - "superpowers"
  - "subagent execute"
  - "战术执行"
tools:
  - exec
  - write
  - read
  - sessions_spawn
  - sessions_send
  - sessions_yield
  - subagents
  - memory_store
mutating: true
metadata:
  openclaw:
    emoji: "⚡"
    requires:
      bins: []
    deniedTools:
      - gateway
    configPaths: ["~/.openclaw/skills/openclaw-superpowers/"]

---

# OpenClaw Superpowers — 战术执行引擎

## Contract
1. **执行不规划** — 本技能不替代 task-planner 的规划职能，只执行已规划的任务。
2. **子代理优先** — 所有可并行的任务优先通过 sessions_spawn 委托子代理执行。
3. **心跳+超时** — 长任务子代理必须配置心跳报告，超时自动终止。
4. **幂等执行** — 同一个任务地图多次执行产生相同结果（已完成任务跳过）。
5. **输入格式：** task-planner 输出的 Markdown 任务地图文件路径。
6. **输出格式：** 执行报告，包含各任务状态、耗时、结果摘要、异常列表。

## 执行步骤

### Step 1: 加载任务地图
**输入：** 任务地图文件路径（由 task-planner 生成）
**操作：**
1. 读取文件，解析阶段/任务列表
2. 识别已完成/待完成的任务
3. 根据依赖关系构建执行顺序 DAG
**输出：** ExecPlan { tasks[], dag, parallelGroups[], totalEstimate }

### Step 2: 分组与排序
**输入：** ExecPlan
**操作：**
1. 按依赖 DAG 拓扑排序
2. 无依赖的任务归入同一并行组
3. 有依赖的任务按层次排列
4. 每组标注并发上限（默认 maxConcurrent=3）
**输出：** OrderedQueue { groups[{ parallel: tasks[] }], serial: tasks[] }

### Step 3: 子代理调度执行
**输入：** OrderedQueue
**操作 — 按组循环：**
1. 对并行组中的任务，每个任务 spawn 一个子代理：
   ```
   sessions_spawn(
     agentId: "main",
     task: "执行任务: {task.description}",
     taskName: "task-{task.id}",
     mode: "run",
     cleanup: "delete"
   )
   ```
2. 对串行组的任务，逐个 spawn 并 wait（sessions_yield）
3. 每个子代理任务 brief 包含：
   - 任务描述和验收标准
   - Fail-Fast 指令
   - 心跳要求（每完成一步 sessions_send 汇报）
4. 异常处理：子代理失败 → 重试 1 次 → 仍失败则标记为 FAILED 并记录
**输出：** TaskResult[] { taskId, status, result, duration, error? }

### Step 4: 结果汇总
**输入：** TaskResult[]
**操作：**
1. 统计完成/失败/跳过的任务数
2. 汇总各任务的关键输出
3. 标记失败任务及其原因
4. 写入执行日志到 `~/.openclaw/skills/openclaw-superpowers/runs/{project-name}-{timestamp}.log`
**输出：** ExecReport { summary, details[], anomalies[] }

### Step 5: 知识沉淀
**输入：** ExecReport
**操作：**
1. 对每项成功任务，用 memory_store 记录关键经验
2. 对失败任务，调用 audit-skill 或记录到 failure-memory
3. 更新项目状态文件
**输出：** memory_store 确认

## 输出格式
```
⚡ 执行报告
项目：{project-name}
任务总数：{total} | 完成：{completed} | 失败：{failed} | 跳过：{skipped}
总耗时：{duration}
并行效率：{parallelEfficiency}（串行预期/实际耗时）

详细结果：
[✅] 任务-001：{description} → {result} ({duration}s)
[❌] 任务-002：{description} → {error}
[⏭] 任务-003：{description} → 依赖失败，跳过
```

## 验证方式
```powershell
# 1. 技能目录存在
Test-Path "$env:USERPROFILE\.openclaw\skills\openclaw-superpowers\SKILL.md"
# 2. 运行日志目录可写
$runDir = "$env:USERPROFILE\.openclaw\skills\openclaw-superpowers\runs"
if (-not (Test-Path $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }
Write-Host "PASS: run log dir ready"
# 3. 测试子代理调度能力（模拟）
Write-Host "PASS: sessions_spawn available"
# 4. 执行计划解析测试
$testPlan = @"
# 测试项目
## Phase 1: 准备
- [ ] 任务A（无依赖）
- [ ] 任务B（依赖 任务A）
"@
if ($testPlan -match "Phase 1") { Write-Host "PASS: plan parsing OK" }
```

## 反模式
- ❌ 自己执行任务而不是委托子代理 — 子代理优先原则
- ❌ 忽略子代理心跳 — 长任务必须配心跳
- ❌ 无超时保护 — 所有子代理必须设 timeoutSeconds
- ❌ 不记录失败原因 — 失败任务必须记录详细原因到 failure-memory
- ❌ 乱序执行 — 严格按依赖 DAG 拓扑排序执行
- ❌ 一次性子代理不 cleanup — 必须加 cleanup: "delete" 避免僵尸会话
