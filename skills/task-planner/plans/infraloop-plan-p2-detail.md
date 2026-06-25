# InfraLoop — P2 核心上游实现详细规格

> 补充文档，附加到 `infraloop-plan.md` 的阶段二
> 每个任务均给出精确的写入内容、文件位置、改动范围
> 版本: 1.0.0 | 日期: 2026-05-26

---

## T11：AGENTS.md 新增域十 — 精确写入内容

### 操作

在现有域九之后追加一个完整域。以下为精确 Markdown，逐字写入，不可偏差：

```markdown
## 域十：基础设施工作流大循环（最高级别）

> 版本: 1.0.0 | 新增于 2026-05-26
> 本域为最高级别执行框架，是核心操作规范的下游实现。所有任务执行、知识沉淀、技能创建必须遵守本循环。
> 优先级：核心操作规范(0) → 本域(1A) → 门禁系统(2) → 其他

### 循环定义

```
Goal Harness（task-planner 规划 → openclaw-superpowers 执行 → longtask-orchestrator 长任务编排）
  → 门禁 5 知识沉淀（三要素完整性：向量库 + 内链 + MEMORY）
  → 技能化判定（skill-judge 四级评分矩阵）
  → 技能创建/追加/跳过
  → 技能触发执行（向量语义匹配 + 自生长）
```

### 强制规则

**R1 — 判定不可跳过**
每次门禁 5 完成后，必须执行技能化判定。执行步骤：
1. 调取本次门禁 5 产出的 3 问提取内容
2. 调用 skill-judge 技能执行四级评分
3. ≥80 分 → 创建技能（`skill_manage create`）；50-79 → 追加补丁（`skill_manage patch`）；<50 → 仅写入知识库
4. 判定过程埋点：`track-event.ps1 "skill.judge" <payload_json>`

**R2 — 沉淀必须完整（三要素验收）**
门禁 5 完成后必须自检：
```
□ memory_store 已写入 ≥1 条（向量库可检索）
□ 内链已建立：brain/ 文件新关联 或 会话笔记中追加关联知识章节
□ MEMORY.md 域二已追加回溯条目
```
任意一项缺失 → 门禁 5 未通过，需补全。

**R3 — 技能创建后标记 needsCleanup**
新技能 SKILL.md frontmatter 中必须含 `needsCleanup: true`。技能下次被触发执行时，由技能自身检查以下文件并提出清理建议：
- AGENTS.md 中已被该技能覆盖的特定规则
- HEARTBEAT.md 中已被技能覆盖的检查项
- MEMORY.md 域中已被技能替代的教训条目
清理以提议形式提交主人确认，禁止自动删除。

**R4 — Cron 纪律**
现有 cron 已合并为 5 个 + 1 HEARTBEAT。禁止绕过工作流新增 cron。如需新增，须先评估是否可合并到 daily-pipeline 或 weekly-housekeeping。

**R5 — 技能触发覆盖率检查**
weekly-housekeeping 每次运行时自动执行：
- `build-skill-index.ps1` 重建向量索引
- 模拟 20 个典型查询，验证 top3 命中率
- 命中率 <70% → 输出改进建议
- 埋点：`track-event.ps1 "skill.trigger.coverage" '{"hit_rate": ..., "total": 20}'`

### Cron 调度参考

| # | 名称 | 频率 | 内容 | 路由 |
|---|------|------|------|------|
| 1 | daily-pipeline | 每日 09:00 | 6合1 管道 | silent |
| 2 | gateway-health-daily | 每日 10:15 | 健康检查 | QQ异常 |
| 3 | weekly-housekeeping | 每周一 10:00 | 6合1 周维护 | QQ摘要 |
| 4 | memory-reindex-weekly | 每周一 03:00 | 向量索引 | silent |
| 5 | daily-health-silent | 每日 09:00 | 完整性检查 | silent |

### growth-patches 子组件说明

growth-patches 是本循环的支撑组件（非独立系统），负责：
- 技能版本追踪（manifests/skills.json）
- 补丁层管理（patches/）
- Fork 升级（≥3 次补丁自动触发）
- 过期技能检测（clawdbot 引用扫描）
所有 growth-patches 维护动作已整合到 weekly-housekeeping 中。

### 埋点要求

循环中每个关键动作均需埋点。调用格式：
```powershell
track-event.ps1 "<event_type>" '<json_payload>'
```
事件类型见 analytics/schema/ 中的 events 表枚举。
埋点失败不影响主流程，静默忽略。
```

### 域十插入位置

- 文件: `C:\Users\lixin\.openclaw\workspace\AGENTS.md`
- 插入点: 域九之后、文件末尾之前
- 使用 `edit` 工具精确插入，不修改已有内容

---

## T12：EVOLUTION.md 更新 — 精确内容

### 操作

在 EVOLUTION.md 末尾追加两个章节。

```markdown

---

## 工作流循环状态 (InfraLoop)

> 自 2026-05-26 起，本系统作为 InfraLoop 工作流的支撑子组件运行。
> 不再拥有独立 cron。所有维护动作由 weekly-housekeeping 统一触发。

### 循环状态表

| 循环轮次 | 日期 | 任务 | 判定分数 | 产出技能 | 状态 |
|----------|------|------|---------|---------|------|
| - | 2026-05-26 | 初始化 | - | - | 🟢 等待首次循环 |

### 子组件职责

| 职责 | 触发方式 | 说明 |
|------|---------|------|
| 技能版本追踪 | weekly-housekeeping → generate-manifest.ps1 | skills.json + audit.json 刷新 |
| 补丁层管理 | 技能自生长 | 新补丁写入 patches/ |
| Fork 升级 | skill-evolver（周检） | ≥3 补丁 → fork |
| 过期检测 | weekly-housekeeping | clawdbot 引用扫描 |

### 架构关系

```
InfraLoop 大循环
  ├── 节点 ③ 技能化判定 → 调用 generate-manifest.ps1 刷新索引
  ├── 节点 ④ 技能自生长 → 生成补丁到 patches/
  └── weekly-housekeeping → 包含 manifest-refresh + skill-evolver
```
```

---

## T13：skill-judge 技能 — 完整 SKILL.md

### 文件位置

`C:\Users\lixin\.openclaw\skills\skill-judge\SKILL.md`

### 完整内容（新建文件）

```markdown
---
name: skill-judge
version: 1.0.0
description: "技能化判定引擎。对门禁 5 产出的知识进行四级评分，决定是否创建技能。判断复用频率、独立性、可触发性、轻量换收益四个维度。触发词：技能判定、skill judge、该不该技能化、评为、是否创建技能。"
triggers:
  - "技能判定"
  - "技能化"
  - "skill judge"
  - "该不该创建技能"
  - "判定"
  - "评分矩阵"
  - "是否技能化"
tools:
  - read
  - write
  - memory_store
  - memory_recall
  - exec
  - wiki_search
mutating: true
needsCleanup: false
metadata:
  openclaw:
    emoji: "⚖️"
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
---

# ⚖️ Skill Judge — 技能化判定引擎

## Contract

1. **只判定不创建** — 本技能只输出判定结果和建议，不自行调用 `skill_manage`
2. **可解释** — 每个评分维度必须附理由（一行），不可只给数字
3. **可复现** — 相同输入 → 相同输出
4. **输入**：门禁 5 的 3 问提取（决策 + 新发现 + 下轮记住）+ 任务性质描述
5. **输出**：四级评分 + 判定结论 + 建议动作

## 四级评分矩阵

| 维度 | 权重 | 评分指南 |
|------|------|---------|
| **复用频率 (R)** | 40% | 未来 30 天内预测触发次数？0次=1分, 1-2次=3分, 3-5次=5分, >5次=8分, ≥10次=10分 |
| **独立性 (I)** | 25% | 能否切割为单一职责操作？与其他技能高度耦合=1分, 部分独立=3分, 可独立但需输入=5分, 完全独立无外部依赖=8分, 自包含可离线执行=10分 |
| **可触发性 (T)** | 20% | 用 ≤3 个关键词向量检索的 top3 命中率预期？<30%=1分, 30-50%=3分, 50-70%=5分, 70-90%=8分, >90%=10分 |
| **轻量换收益 (L)** | 15% | 创建技能的 token 成本 vs 不创建时的重复探索成本？成本 >> 收益=1分, 持平=3分, 省20%=5分, 省50%=8分, 每次触发省90%+=10分 |

**加权公式**：`总分 = R×0.4 + I×0.25 + T×0.2 + L×0.15`
**最终分数**：`总分 × 10`（映射到 0-100 区间）

## 判定阈值

| 分数 | 等级 | 动作 | 说明 |
|------|------|------|------|
| ≥80 | 🟢 高 | `skill_manage create` | 创建独立技能到 auto-generated/ |
| 50-79 | 🟡 中 | `skill_manage patch` | 追加到已有技能 |
| <50 | 🔴 低 | 仅知识库 | 门禁 5 沉淀足够，不技能化 |

## 执行步骤

### Step 1: 获取判定输入
从门禁 5 产出中提取：
- 3 问中的「最关键决策」
- 3 问中的「新发现」
- 3 问中的「下轮需记得」
- 本次任务的类型标签（编码/配置/调试/规划/知识整理/系统维护/...）

### Step 2: 逐维度评分
对四个维度逐一评分，每个维度附一行理由：

```
## 技能化判定

**任务**: {描述}
**门禁5产出**: {3问摘要}

### 评分

| 维度 | 评分 | 理由 |
|------|------|------|
| 复用频率 | X/10 | ... |
| 独立性 | X/10 | ... |
| 可触发性 | X/10 | ... |
| 轻量换收益 | X/10 | ... |

**加权总分**: {score}/100
```

### Step 3: 输出判定结论

如果 ≥80 分：
```
🟢 建议创建技能
技能名建议: {kebab-case}
目标位置: ~/.openclaw/skills/auto-generated/{name}/
触发词建议: {3-5个高区分度词}
理由: {一句话}
```

如果 50-79 分：
```
🟡 建议追加到已有技能
目标技能: {建议匹配的已有技能名}
理由: {一句话}
```

如果 <50 分：
```
🔴 不建议技能化
理由: {一句话}
建议: 仅通过门禁 5 沉淀到知识库即可
```

### Step 4: 埋点

```powershell
track-event.ps1 "skill.judge" '{"score":{score},"level":"{green|yellow|red}","task":"{任务简述}","dimensions":{"R":{R},"I":{I},"T":{T},"L":{L}}}'
```

### Step 5: 调用方执行
本技能输出判定结果后，由调用方（门禁 5 流程）根据结论执行 `skill_manage` 或跳过。

## 反模式

- ❌ 评分后不埋点 — 面板需要判定数据
- ❌ 只给数字不给理由 — 主人需要看懂为什么
- ❌ 跳过某个维度 — 四个维度必须全部评分
- ❌ 自行调用 skill_manage — 本技能只判定不创建
- ❌ 对纯闲聊/只读查询做判定 — 豁免场景直接跳过

## 验证

```powershell
# 确保可以被 skill_read 加载
# 确保 triggers 中的词汇在向量检索中可命中
# 在 memory_store 中注册描述向量
```
```

---

## T14：门禁 5 操作手册升级 — 精确改动

### 文件

`C:\Users\lixin\.openclaw\workspace\AGENTS.md`

### 当前门禁 5 操作手册（在域二中）

现有内容（约 30 行），需要在步骤后追加以下内容：

### 追加内容（在现有门禁 5 操作手册的步骤之后）

```markdown
### 门禁 5 — 三要素完整性检查清单

每个门禁 5 完成前，必须执行以下自检（不可跳过）：

```
□ 向量库写入
   ├─ memory_store 调用次数: ≥1
   ├─ 写入内容: 本次最关键决策 + 新发现 + 可复用流程
   └─ 验证: wiki_search(corpus="memory", query="<关键决策关键词>") 可检索到

□ 内链建立
   ├─ 方式 A: 涉及 brain/ 文件 → 在对应 brain/ 文件中追加「五、关联知识」章节
   │   - 格式: `- [笔记标题](../notes/sessions/YYYY-MM-DD--标签.md) — 关联说明`
   ├─ 方式 B: 不涉及 brain/ → 在会话笔记末尾追加「## 关联知识」章节
   │   - 列出相关 brain/ 文件 + MEMORY.md 条目
   └─ 验证: 至少 1 条内链可追溯

□ MEMORY.md 回溯
   ├─ 格式: `YYYY-MM-DD <主题> — <一句话摘要>`
   ├─ 位置: MEMORY.md 域二
   └─ 验证: 追加后 MEMORY.md 行数增加
```

三项均打勾 → 门禁 5 通过，触发技能化判定。

### 门禁 5 — 技能化判定衔接

门禁 5 三要素检查通过后，立即执行：

1. **调取判定输入**：本轮的 3 问提取 + 任务性质
2. **调用 skill-judge**：`skill_read("skill-judge")` 加载判定引擎，执行四级评分
3. **执行判定结论**：
   - ≥80 分 → `skill_manage create` 创建技能，位置 `~/.openclaw/skills/auto-generated/{name}/`
   - 50-79 分 → `skill_manage patch` 追加到已有技能
   - <50 分 → 跳过，标注「⏩ 不技能化」
4. **埋点记录**：`track-event.ps1 "skill.judge" <payload>`
5. **创建后标记**：新技能 frontmatter 中设 `needsCleanup: true`
6. **向量注册**：新技能或补丁后立即调用 `register-skill.ps1` 写入向量库
```

---

## T15：创建 5 个新 Cron — 精确 Brief 内容

### 前置条件

- 埋点 SDK 已可用（T10 通过）
- AGENTS.md 域十已落地（T11 完成）

### 精确的 cron add 调用

#### Cron 1: daily-pipeline

**调用**：
```javascript
cron({
  action: "add",
  job: {
    name: "daily-pipeline",
    description: "[InfraLoop] 每日 09:00 6合1管道: knowledge-sync→gbrain-sync→gbrain-embed→gbrain-autopilot→error-scan→audit",
    enabled: true,
    schedule: { kind: "cron", expr: "0 9 * * *", tz: "Asia/Shanghai" },
    sessionTarget: "isolated",
    wakeMode: "now",
    payload: {
      kind: "agentTurn",
      message: `执行 InfraLoop 每日管道（6 合 1，顺序执行）：

**Step 1** — knowledge-sync
运行 \`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\workspace\\knowledge\\sync-knowledge.ps1"\`。记录变更文件数。

**Step 2** — gbrain-sync
运行 \`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\workspace\\knowledge\\sync-gbrain.ps1"\`。记录新导入页面数。

**Step 3** — gbrain-embed
调用 gbrain__get_health 检查 missing_embeddings。如果 >0，调用 gbrain__submit_job(name="embed")。记录缺口数和 job ID。

**Step 4** — gbrain-autopilot
调用 gbrain__submit_job(name="autopilot-cycle")。记录 job ID。

**Step 5** — error-scan
运行 \`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\.audit\\scan.ps1"\`（如有扫描脚本）。否则搜索最近 24h 的 cron 失败记录。

**Step 6** — audit
检查 MEMORY.md 域四中是否有教训出现 3 次待升级 wiki。有则标记，无则跳过。

**埋点**：每步完成后调用：
\`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\analytics\\sdk\\track-event.ps1" "cron.daily_pipeline.step{N}" '{"step":"{step_name}","status":"{ok|fail}","duration_ms":{ms}}'\`

全部 6 步完成后，输出一行摘要（步数/成功/失败/总耗时）。任何步骤失败不阻塞后续步骤。`,
      timeoutSeconds: 1200,
      lightContext: true
    },
    delivery: { mode: "none" },
    failureAlert: { after: 2, channel: "qqbot", to: "qqbot:c2c:8BB8B88EDA8FB5A4BA4515E7FCBFAF07", mode: "announce" }
  }
})
```

#### Cron 2: gateway-health-daily

**说明**：此 cron 已存在（ID: `1a82469f`），只需更新 brief 追加埋点 + enabled=true。不新建。

**更新调用**：
```javascript
cron({
  action: "update",
  jobId: "1a82469f-f732-4b16-bf62-b778546870e9",
  patch: {
    enabled: true,
    payload: {
      kind: "agentTurn",
      message: `快速检查 OpenClaw gateway 状态（只查关键指标）：

1. 调用 session_status(sessionKey="current") 确认 gateway 在线
2. 检查插件状态：lossless-claw/hermes-borrow / deepseek / volcengine / memory-milvus / openclaw-qqbot
3. 埋点：
\`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\analytics\\sdk\\track-event.ps1" "cron.gateway_health" '{"gateway":"{ok|fail}","plugins":{"hermes-borrow":"{ok|fail}","deepseek":"{ok|fail}","volcengine":"{ok|fail}","memory-milvus":"{ok|fail}","qqbot":"{ok|fail}"}}'\`

全部正常则静默。有异常输出一句告警。`,
      timeoutSeconds: 120,
      lightContext: true
    }
  }
})
```

#### Cron 3: weekly-housekeeping

**调用**：
```javascript
cron({
  action: "add",
  job: {
    name: "weekly-housekeeping",
    description: "[InfraLoop] 每周一 10:00 6合1 周维护: context-arch→growth-manifest→skill-evolver→evolution-report→health-check→skill-index-refresh",
    enabled: true,
    schedule: { kind: "cron", expr: "0 10 * * 1", tz: "Asia/Shanghai" },
    sessionTarget: "isolated",
    wakeMode: "now",
    payload: {
      kind: "agentTurn",
      message: `执行 InfraLoop 每周综合维护（6 合 1，顺序执行）：

**Step 1** — context-arch-check
- 检查 project-status.md 是否与当前状态一致
- 检查 brain/ 文件数变化
- 检查 AGENTS.md / MEMORY.md / HEARTBEAT.md 大小是否在阈值内
- 检查 notes/sessions/ 文件数（>50 告警）
- 埋点：track-event.ps1 "cron.weekly.context_arch"

**Step 2** — growth-manifest-refresh
- 运行 \`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\workspace\\growth-patches\\generate-manifest.ps1"\`
- 记录技能总数变化和 outdatedSkills 变化
- 埋点：track-event.ps1 "cron.weekly.growth_manifest"

**Step 3** — skill-evolver
- 扫描 auto-generated/ 和 staging/ 下的技能
- 检测重复技能 → 标记合并
- 检测 >30 天未触发的技能 → 标记休眠
- 检测违反 7 原则的技能 → 标记修正
- 埋点：track-event.ps1 "cron.weekly.skill_evolver"

**Step 4** — evolution-report
- 运行 generate-report.ps1 生成本周报告
- 报告写入 growth-patches/reports/YYYY-MM-DD.md

**Step 5** — health-check
- 确认 gateway 在线
- 确认 5 个 cron 前一天均有成功执行记录
- 确认 vector-store 条目数增长（与上周对比）
- 埋点：track-event.ps1 "cron.weekly.health_check"

**Step 6** — skill-index-refresh
- 运行 build-skill-index.ps1 重建向量索引
- 模拟 20 个典型查询验证覆盖率
- 埋点：track-event.ps1 "skill.trigger.coverage" '{"hit_rate":...,"total":20}'

全部完成后，输出中文摘要（字数 ≤300），推送到 QQ。`,
      timeoutSeconds: 600,
      lightContext: true
    },
    delivery: { mode: "announce", channel: "qqbot", to: "qqbot:c2c:8BB8B88EDA8FB5A4BA4515E7FCBFAF07", bestEffort: true },
    failureAlert: { after: 1, channel: "qqbot", to: "qqbot:c2c:8BB8B88EDA8FB5A4BA4515E7FCBFAF07", mode: "announce" }
  }
})
```

#### Cron 4: memory-reindex-weekly

**调用**：
```javascript
cron({
  action: "add",
  job: {
    name: "memory-reindex-weekly",
    description: "[InfraLoop] 每周一 03:00 重建向量索引",
    enabled: true,
    schedule: { kind: "cron", expr: "0 3 * * 1", tz: "Asia/Shanghai" },
    sessionTarget: "isolated",
    wakeMode: "now",
    payload: {
      kind: "agentTurn",
      message: `重建技能向量索引：

1. 运行 \`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\workspace\\build-skill-index.ps1"\`
2. 记录：注册技能数、新增数、删除数、失败数
3. 埋点：
\`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\analytics\\sdk\\track-event.ps1" "skill.index.rebuild" '{"registered":{N},"new":{N},"deleted":{N},"failed":{N}}'\`

静默执行。仅失败时告警。`,
      timeoutSeconds: 300,
      lightContext: true
    },
    delivery: { mode: "none" },
    failureAlert: { after: 2, channel: "qqbot", to: "qqbot:c2c:8BB8B88EDA8FB5A4BA4515E7FCBFAF07", mode: "announce" }
  }
})
```

#### Cron 5: daily-health-silent

**调用**：
```javascript
cron({
  action: "add",
  job: {
    name: "daily-health-silent",
    description: "[InfraLoop] 每日 09:00 完整性检查: 向量库状态 + 门禁5笔记活跃度",
    enabled: true,
    schedule: { kind: "cron", expr: "0 9 * * *", tz: "Asia/Shanghai" },
    sessionTarget: "isolated",
    wakeMode: "now",
    payload: {
      kind: "agentTurn",
      message: `执行 InfraLoop 每日完整性检查：

1. **向量库完整性**
   - 用 wiki_search(corpus="memory", query="门禁5") 检查可检索条目数
   - 对比昨日记录（如有），检测条目数变化
   - 如果连续 3 天无增长 → 告警

2. **门禁 5 笔记活跃度**
   - 检查 notes/sessions/ 最近 7 天是否有新文件
   - 无新文件 → 说明 7 天无门禁 5 触发 → 告警

3. **埋点**
   \`powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Users\\lixin\\.openclaw\\analytics\\sdk\\track-event.ps1" "cron.daily_health" '{"vector_store_items":{N},"notes_7d":{N}}'\`

全部正常静默。异常仅记录到日志（不推送 QQ）。`,
      timeoutSeconds: 120,
      lightContext: true
    },
    delivery: { mode: "none" },
    failureAlert: { after: 3, channel: "qqbot", to: "qqbot:c2c:8BB8B88EDA8FB5A4BA4515E7FCBFAF07", mode: "announce" }
  }
})
```

---

## T16：删除被合并的旧 Cron — 精确清单

### 必须删除的 12 个 cron

| # | Cron 名称 | Cron ID |
|---|-----------|---------|
| 1 | knowledge-sync-daily | `05c84c70-a335-4693-9d6a-53d946f85cac` |
| 2 | gbrain-sync-daily | `560b64a4-2978-41cf-b0e6-fc7a23b297af` |
| 3 | gbrain-embed-pending | `4df5f54c-1747-4d57-8960-b209b5798791` |
| 4 | gbrain-autopilot-daily | `8c2cdf90-6cb1-4cc2-b648-1dbcab76a815` |
| 5 | error-scan-hourly | 需 list 名称 `error-scan-hourly` 搜索 |
| 6 | audit-recent-hourly | 需 list 名称 `audit-recent-hourly` 搜索 |
| 7 | context-arch-weekly-check | `07a2eb80-c7aa-44e7-ae83-559a1cdcd019` |
| 8 | growth-manifest-refresh | `83526d3c-8c08-4672-a209-1cf086ed345c` |
| 9 | skill-evolution-report | `959198b8-7c0c-4af3-8e12-44aacadcba0f` |
| 10 | openclaw-weekly-health-check | 需 list 名称搜索 |
| 11 | skill-evolver-weekly | `882600d8-a9da-41ae-a8f8-fb253477fe17` |
| 12 | growth-patches-report | 需 list 名称搜索 |

### 删除流程

```
Step 1: 先 disable（cron update enabled=false）
Step 2: 确认新 cron 已创建并 enabled=true
Step 3: 等待 24h，确认无异常后 cron remove
```

### 保留（更新但不删除）

| Cron 名称 | Cron ID | 动作 |
|-----------|---------|------|
| gateway-health-daily | `1a82469f-f732-4b16-bf62-b778546870e9` | 更新 brief（追加埋点）+ enable |

---

## T17：HEARTBEAT.md 更新 — 精确最终内容

### 操作

重写 HEARTBEAT.md，移入被 cron 替代的检查项，保留心跳中必须在线的检查。

### 最终内容（完整替换）

```markdown
# HEARTBEAT.md — 心跳维护脚本
> 版本: 1.3.0 | 最后更新: 2026-05-26

# Personality restoration on heartbeat
python ~/.openclaw/workspace/skills/personality-switcher/scripts/restore_personality.py

# 🎯 Training auto-advance
# 1. Read training-state.json
# 2. If trainingMode=true + pendingAdvance=true + waitForUser=false → sessions_send("agent:main:main", "advance")
# 3. Else → HEARTBEAT_OK

# 📊 Context health (thresholds per context-monitor.md)
# AGENTS.md > 14KB ⚠️ | MEMORY.md > 6KB ⚠️ | HEARTBEAT.md > 2KB ⚠️
# Bootstrap > 25KB ⚠️

# 🌱 Self-improving (skip if is_self_improving=false)
# heartbeat-state >24h → check corrections.md (3x same lesson → wiki upgrade)
# corrections.md >50 lines → compact | memory.md >100 lines → archive

# 🆕 Knowledge pipeline
# notes/sessions/ >50 files → archive warning

# 📊 InfraLoop: 每日系统快照（仅 1 次/天，凌晨首次心跳触发）
# 写入 system_health 到 analytics/metrics.db
# powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\lixin\.openclaw\analytics\sdk\system-health-snapshot.ps1"

# Weekly (Monday only): 以下检查已迁移到 weekly-housekeeping cron
#   ❌ growth-patches manifest → weekly-housekeeping step 2
#   ❌ wiki_lint → weekly-housekeeping step 1
#   ❌ knowledge decay check → weekly-housekeeping step 1
#   ❌ gate-5 notes 7-day check → daily-health-silent cron
# Monthly (1st): knowledge decay → weekly-housekeeping step 1
```

### 被移除的项目（已迁移）

| 原检查项 | 迁移到 | 理由 |
|----------|--------|------|
| growth-patches manifest | weekly-housekeeping step 2 | 周检足够 |
| wiki_lint | weekly-housekeeping step 1 | 周检足够 |
| knowledge decay check | weekly-housekeeping step 1 | 月度 → 周检降频 |
| gate-5 notes 7-day check | daily-health-silent cron | 已独立 cron |
| check corrections.md → wiki upgrade | HEARTBEAT 保留 | 仍在心跳 |

### 新增项目

| 新增 | 说明 |
|------|------|
| system-health-snapshot | 每日子时心跳写入 system_health 表，供可视化面板读取 |

---

## T18：端到端闭环验证 — 精确验证流程

### 验证场景

**测试任务**：「优化 AGENTS.md 的健康告警阈值，当前 MEMORY.md 6KB 阈值过小导致频繁告警」

这是一个真实的小任务，可以触发完整循环：

```
1. 任务执行（Goal Harness）
2. 门禁 4 交付
3. 门禁 5 知识沉淀（三要素）
4. 技能化判定（skill-judge）
5. 判定结果处理
6. 埋点验证
```

### 验证步骤

```
Step 1 — 执行任务
  执行方式：直接在 main agent 中完成（小任务，不 spawn）
  任务内容：评估 MEMORY.md 预警阈值 6KB → 9KB 是否合理，如合理则修改 context-monitor.md

Step 2 — 门禁 5 触发
  门禁 4 确认后自动触发门禁 5
  执行 3 问提取 + 会话笔记 + MEMORY.md 回溯
  执行三要素检查清单（自检打勾）

Step 3 — 技能化判定
  调取 3 问提取内容
  调用 skill-judge：
    - 复用频率：阈值调整是一次性操作，频率低 → 评分 2/10
    - 独立性：依赖 context-monitor.md 上下文 → 评分 3/10
    - 可触发性：关键词「阈值调整」「健康告警」区分度低 → 评分 3/10
    - 轻量换收益：创建成本 > 重复成本 → 评分 2/10
  预期结果：< 50 分 → 🔴 不技能化

Step 4 — 埋点验证
  查询 analytics/metrics.db：
  SELECT event_type, COUNT(*) FROM events GROUP BY event_type;
  预期至少包含：
    - task.complete
    - gate5.memory_store
    - gate5.backlink
    - gate5.memory_append
    - gate5.complete
    - skill.judge

Step 5 — 向量库验证
  wiki_search(corpus="memory", query="AGENTS.md 阈值调整") 
  预期：可检索到门禁 5 写入的向量条目

Step 6 — 内链验证
  检查会话笔记中是否包含「## 关联知识」章节
  或 brain/ 相关文件中是否追加了「五、关联知识」

Step 7 — MEMORY.md 回溯验证
  Get-Content MEMORY.md | Select-String "阈值"
  预期：域二中有今天的回溯条目
```

### 验证通过标准

```
✅ events 表有 gate5.* 事件（≥3 条）
✅ events 表有 skill.judge 事件（1 条，含评分）
✅ wiki_search 可检索到门禁 5 写入的向量
✅ 会话笔记含「关联知识」章节
✅ MEMORY.md 域二有当天回溯
✅ skill.judge 判定分数 < 50（符合预期）
```

---

## 附录 A：文件改动总览

| 文件 | 任务 | 改动类型 |
|------|------|---------|
| `AGENTS.md` | T11, T14 | 追加域十 + 门禁5操作手册追加 |
| `EVOLUTION.md` | T12 | 末尾追加两个章节 |
| `skills/skill-judge/SKILL.md` | T13 | **新建文件** |
| `HEARTBEAT.md` | T17 | 完整替换 |
| Cron: `daily-pipeline` | T15 | **新建** |
| Cron: `gateway-health-daily` | T15 | 更新 brief |
| Cron: `weekly-housekeeping` | T15 | **新建** |
| Cron: `memory-reindex-weekly` | T15 | **新建** |
| Cron: `daily-health-silent` | T15 | **新建** |
| 12 个旧 cron | T16 | 先 disable 后删除 |

## 附录 B：依赖关系（修正）

```
T6 (门禁5埋点) → T11 (域十) → T14 (门禁5升级) → T13 (skill-judge)
                              → T12 (EVOLUTION) → T15 (新cron) → T16 (删旧cron) → T17 (HEARTBEAT)
T13 ──────────────────────────→ T18 (闭环验证)
T14 ──────────────────────────→ T18
T15 ──────────────────────────→ T18
T17 ──────────────────────────→ T18
```
