---
name: longtask-orchestrator
version: 1.0.0
layer: 2
layer_label: "Workflow Library"
priority: normal
description: "目标导向长任务编排。Planner 模式 + 三角色闭环(Generator/Evaluator/Aggregator)。适合 >1h 多步任务或跨 session 工作。触发词:长任务、目标导向、planner模式、多步任务、跨session。"
triggers:
  - "长任务"
  - "目标导向"
  - "planner模式"
  - "多步任务"
  - "跨session"
  - "long task"
  - "planner"
tools:
  - exec
  - write
  - read
  - sessions_spawn
  - sessions_yield
  - sessions_send
  - subagents
mutating: true
needsCleanup: false
depends_on:
  - "skill:task-planner"
cross_agent: false
metadata:
  openclaw:
    emoji: "🎯"
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
---
# Longtask Orchestrator — 目标导向长任务工作流

> 版本: 1.0.0 | 所属: P7 Goal Harness
> 触发词: 长任务、开始跑、执行、帮我做、自动搞定

---

## 一、Overview

目标导向的长任务编排技能。不同于「按步走」的流程模式，这个技能的核心是：

1. **定目标 + 定边界** — 说清楚要什么、不能做什么
2. **自由执行** — Planner 自己拆解并调度子代理，不预先定步奏
3. **触碰边界上报** — 遇到不确定的/需要决策的点暂停通知主人
4. **越过红线回退** — 检测到方向性错误自动 rollback + 重规划
5. **最小人工参与** — 正常执行不需要主人关心

### 适用场景

| 场景 | 例子 |
|------|------|
| 多步代码/文件变更 | 改一个功能模块 |
| 调研 + 输出 | 研究某个技术方案并写报告 |
| 跨 session 任务 | 需要多轮对话才能做完的事 |
| 多 Agent 协作 | 需要拆成多个子任务并行/串行 |

### 不适用场景

- 纯聊天、问答（太轻量，门禁就够了）
- 只读查询（不需要编排）

---

## 二、架构：三 Agent 闭环

受 Anthropic Harness 设计（GAN 启发）影响，P7 采用三角色循环：

```
┌────────────────────────────────────────────────────────────┐
│                        PLANNER (我)                         │
│  职责: 定目标 → 拆 subtask → 调度 → 聚合结果 → 交付        │
│  位置: 主会话                                              │
│  模型: 当前主模型 (custom-3/hy3-preview)                    │
└─────┬───────────────────────────────────────┬──────────────┘
      │ sessions_spawn(context="fork")         │ sessions_spawn(isolated)
      ▼                                        ▼
┌──────────────┐                       ┌──────────────┐
│  GENERATOR   │  产生交付物           │  EVALUATOR   │
│  干活子代理   │─────────────────────→│  检查子代理   │
│              │                       │              │
│  model: flash│  ←── 反馈/迭代 ──────│  model: pro  │
│  timeout: 300│                       │  or direct   │
└──────────────┘                       └──────────────┘
     │ 完成后                                    │ 完成后
     ▼                                           ▼
┌────────────────────────────────────────────────────────────┐
│                       AGGREGATOR (我)                        │
│  收集结果 → 对照 evaluationCriteria 验证 → 交付             │
└────────────────────────────────────────────────────────────┘
```

### 角色决策表

| 角色 | 谁执行 | 模型建议 | 工具范围 |
|------|--------|---------|---------|
| Planner | 主会话（我） | 主模型 | 全部工具 |
| Generator | sessions_spawn(fork) | Flash 省钱 | 只给完成任务所需的工具 |
| Evaluator | sessions_spawn(isolated) 或直接 | Pro 保证判断力 | read / exec 等检查工具 |

### 为什么不直接用主会话干活？

- Generator 在独立 session 跑，即使卡死也不污染主会话上下文
- Evaluator 用 isolated 隔离，保证客观性（无自评偏差）
- 可并行多个 Generator 互不干扰

---

## 三、工作流

### Step 1: 目标捕获

主人说「做XX」后，Planner（我）立即产出：

```json
{
  "goal": "做XX",
  "boundaries": ["不能碰A", "超过B时通知"],
  "redLines": ["删非自创文件 → revert"],
  "deliverables": ["交付标准"],
  "evaluationCriteria": [
    {"criterion": "标准1", "weight": 0.4},
    {"criterion": "标准2", "weight": 0.3},
    {"criterion": "标准3", "weight": 0.3}
  ]
}
```

**产出物**：创建 Task Manifest `workspace/tasks/<taskId>.task.json`

### Step 2: 任务分解

根据 goal 拆成 subtask，标注依赖关系：

```json
"subtasks": [
  {"id": "s1", "dependsOn": [], "description": "调研", "model": "flash"},
  {"id": "s2", "dependsOn": ["s1"], "description": "设计", "model": "pro"},
  {"id": "s3", "dependsOn": ["s2"], "description": "实现", "model": "flash"},
  {"id": "s4", "dependsOn": ["s2"], "description": "测试", "model": "flash"}
]
```

**分解规则**：
- 一个 subtask 预计 ≤15 分钟工作量，超过再拆
- 无依赖可并行，有依赖必须串行
- 每个 subtask 只做一件事

### Step 3: 执行调度

对于每个 subtask：

```
1. 写 Subagent Brief（见第四章）
2. sessions_spawn(task=brief, context="fork", model=指定, timeoutSeconds=设定)
3. sessions_yield → 等待完成事件
4. 收到完成事件后检查结果
```

**并行策略**：
- 无依赖的 subtask 一次性 spawn 多个
- 但不超过 3 个并行（超过需主人确认，避免 API 限流）

### Step 4: Evaluator 检查

Generator 完成后，Planner 自己或另起 Evaluator 检查：

```
对照 evaluationCriteria 逐项打分
├─ 全部通过 → 标记 done，聚合结果
├─ 部分通过 → 标记 partial，反馈给 Generator 修正
└─ 全部不通过 → 标记 failed，记录失败原因
```

**何时需要拉主人**：
- Evaluator 反馈后 Generator 连续修正 2 次仍不通过
- 碰到边界（boundary hit）

### Step 5: 聚合交付

所有 subtask done 后：

```
1. 汇总所有 subtask 的结果
2. 对照 deliverables 检查完整性
3. 更新 manifest status=completed
4. 向主人写交付总结
5. 自动触发门禁 5（知识沉淀）
```

### Step 6: 知识沉淀

完成交付后自动执行（不阻塞）：

```
1. 任务摘要写入会话笔记
2. 如果有新教训 → 写入 learnings/
3. 如果有值得升级的经验 → 标记等待主人确认
```

---

## 四、Subagent Brief 模板

## 核心原则：Fail-Fast

子代理必须遵循 **快失败（Fail-Fast）** 原则：
1. **主命令失败 → 立即报告**。exec 超时/报错后不继续做诊断，直接返回「主命令失败：XXX」
2. **不要浪费 tokens 调查你不懂的事情**。如果 exec 超时，它的输出就是最有用的信息，不需要额外查文件/查进程
3. **报告即可，不需修复**。子代理只负责执行和报告，不需要解决环境问题

---

## Subagent Warm-Start 策略

子代理慢的核心原因是 **cold start**（零上下文启动）：它不知道我当前已经知道的文件结构、目录内容、已尝试的方案。

### 规则

1. **不要只写「目录 X」** — 要写「目录 X 下有 a.js, b.js，其中 a.js 做了 XXX」
2. **用 spawn brief 传输思考结果** — 把我在主会话中已经查到的、验证过的信息直接写入 brief，不丢给子代理重新发现
3. **大文件 context 写临时文件** — 如果上下文太大放不进 brief，先写一个 `.context.md` 到工作区，brief 里引用路径让子代理 `read`
4. **fork 只用一种情况** — 子任务需要精确复现多步操作过程（如调试完整流程），且上下文 < 80KB

### 操作流程

```
我（主会话）确认需要 spawn 子代理
    │
    ├─ 检查当前已知道什么（文件内容、目录结构、失败原因）
    ├─ 把这些直接写入 subagent brief（不要扔给子代理去发现）
    ├─ 如果写入内容超过 2KB → 改写到 .context.md 临时文件
    └─ spawn(brief + context.md 路径)
```

---

## Brief 模板

每次 sessions_spawn 时使用的标准化 prompt 结构：

```
## 任务
{一句话描述}

## 上下文（Warm-Start：主会话已确认的信息，子代理不需要重新发现）
- 相关文件结构: {已知的目录/文件清单}
- 已尝试方案: {已知失败/成功的信息}
- 关键路径: {文件 A 在哪行做什么}

附加上下文: read workspace/tasks/<taskId>.context.md（如需要）

## 边界
- {边界1}
- {边界2}

## Fail-Fast
- 主命令超时或报错 → **立即返回错误信息，不做诊断**
- 子代理只负责执行和报告，不负责修复环境问题

## 红线
- {红线1}

## 交付物
- {具体产出}

## 验证方式
- {怎么检查你做完了、做对了}

## 模型
{模型指定，通常不限制}

## 超时
{秒数}
```

### Warm-Start 示例

❌ 冷启动（子代理要 3-5 轮发现）：
```
## 上下文
检查 skills/cloakbrowser-web/ 目录的环境
```

✅ 预热启动（直接把我知道的写进去）：
```
## 上下文（Warm-Start）
- 技能目录: skills/cloakbrowser-web/
  - 文件: core.js(8KB), index.js(4KB), sites/deepseek.js(5KB), open-login.js(0.8KB)
  - profiles/deepseek/ — 浏览器持久化配置，有登录态
  - 已知: 无 package.json，无 node_modules，cloakbrowser@0.3.28 已全局安装
  - 已知: 内置 Stealth Chromium v177.4 的 chrome.exe 损坏（SxS 配置错误）
  - 已知: 系统 Chrome 可用（C:\Program Files\Google\Chrome\Application\chrome.exe）
  - 已知: CLOAKBROWSER_BINARY_PATH 环境变量可覆盖
```

子代理拿到这个 brief 后，**0 轮探索直接干活**。

```
## 任务
{一句话描述}

## 上下文
{背景信息、相关文件路径}

## 边界
- {边界1}
- {边界2}
- 如果遇到不确定的情况，先 pause 报告，不要猜测

## 红线
- {红线1}
- 威胁到现有系统稳定性时立即停止

## 交付物
- {具体产出}

## 验证方式
- {怎么检查你做完了、做对了}

## 模型
{模型指定，通常不限制}

## 超时
{秒数}
```

### 实操示例

```
## 任务
分析 workspace/agents/game-dev/AGENTS.md 的行数、大小，评估是否超过压缩阈值

## 上下文
AGENTS.md 是游戏开发集群的核心配置文件，当前约 12KB。
压缩阈值参考 knowledge/brain/system/context-monitor.md。

## 边界
- 只读分析，不改任何文件
- 不做内容质量评判，只做客观数据统计

## 红线
- 无（只读任务）

## 交付物
- 文件大小（KB）+ 行数
- 与阈值对比的结论（已超/未超/接近）

## 验证方式
用 read 和 Get-Content 双重确认数值

## 模型
custom-1/deepseek-v4-flash

## 超时
120
```

---

## 五、边界与红线处理

### Boundary Hit（触碰边界）

```
检测到边界条件触发
  │
  ├─ 暂停当前 affected subtask
  ├─ 记录 checkpoint：boundary_hit
  ├─ 通知主人：「碰到边界 XXX，需要你决策」
  ├─ 等待主人回复
  │
  ├─ 主人允许 → 继续
  ├─ 主人拒绝 → 标记 subtask 为 skipped，重新规划
  └─ 主人修改边界 → 更新 manifest boundaries
```

### Red Line Hit（越过红线）

```
检测到红线条件触发
  │
  ├─ 立即停止所有执行中的 subtask
  ├─ rollback（git revert / 恢复备份文件）
  ├─ 记录 checkpoint：red_line
  ├─ 通知主人：「触发了红线 XXX，已回退，请指示」
  └─ 等待主人确认后 → 重新规划
```

### 连续失败

```
同一 subtask 连续 FAIL × 2
  │
  ├─ 标记该 subtask 为 blocked
  ├─ 如果其他 subtask 无依赖 → 继续执行
  ├─ 如果阻塞了整个链 → 标记 manifest 为 blocked
  └─ 通知主人：「XXX 连续失败 2 次，原因：...，需要你介入」
```

---

## 六、Manifest 生命周期

```
创建
  │
  ├─ 写入 workspace/tasks/<taskId>.task.json
  │
  ├─ 执行中 → 更新 subtask 状态 + updatedAt
  ├─ 触碰边界 → 追加 checkpoint
  │
  ├─ 完成 → status=completed + completedAt
  │   └─ 移动到 tasks/archive/
  │
  └─ 失败 → status=failed
      └─ 移动到 tasks/archive/
```

---

## 七、Pro Tips

1. **目标要窄** — 一个 Manifest 只做一件事。「写小说和搭网站」是两个 Manifest
2. **边界要先说** — 宁可多列一条不必要的边界，不可漏一条关键的
3. **Evaluator 用 Pro 模型** — 检查工作比干活更需要判断力
4. **并行不超过 3** — 多了 API 限流 + 上下文混乱
5. **不要猜** — 碰到不确定的 pause 报告，猜错比不干活更糟糕
6. **manifest 是事实源** — 所有状态以文件为准，不依赖对话记忆

---

## 八、与现有系统的关系

| 系统 | 关系 |
|------|------|
| **门禁系统（AGENTS.md 域二）** | P7 是门禁的编排层。门禁管"我怎么执行"，P7 管"我怎么派活" |
| **sessions_spawn** | Generator 用 `context="fork"`（需要当前上下文），Evaluator 用 `context="isolated"`（保持客观） |
| **sessions_yield** | 等子代理完成的标准方式，不轮询 |
| **task-manifest.md** | 本 SKILL.md 的配套规范文件 |
| **知识沉淀（门禁 5）** | 任务交付后自动触发 |
