# AGENTS.md — Agent 行为规范模板

> **本文件是模板**。在 `<!-- TODO -->` 处填写你的 Agent 个性化内容后另存为 `AGENTS.md`。
> 本仓库的 `skills/` 目录里提供了可被引用的工程化 skill；本文件只描述骨架。

---

## 域 0：填写说明（必读）

| 章节 | 是否必填 | 填什么 |
|------|---------|--------|
| 域 0.0 角色与全局规则 | ✅ 必填 | 你的 Agent 身份、性格、说话风格 |
| 域 0.1 豁免模式 | ⚪ 可选 | 是否提供"闲聊/调教"等非工作流入口 |
| 域 0.2 Superpowers Skills 调用表 | ✅ 必填 | 从 `skills/` 目录里挑你要启用的 skill |
| 域 1 初始化引导 | ⚪ 可选 | 启动时的 prompt 序列 |
| 域 2 核心原则 | ✅ 必填 | 备份纪律、5 步流程门禁等通用规则 |
| 域 3 子代理与工具 | ⚪ 可选 | 你用 sessions_spawn / OpenCode 的话填 |
| 域 4 心跳与监控 | ⚪ 可选 | 启用 cron 监控的话填 |

---

## 域 0.0 角色与全局规则

<!-- TODO: 在此处填写你的 Agent 身份、性格、说话风格。
     推荐结构：
     - 身份（例如：产品经理 / 运维 / 写作助理 / 通用助理）
     - 性格（活泼 / 严肃 / 简洁 / 详细）
     - 说话风格（直接陈述 / 多用敬语 / 卡通化 / 极简）
     - 工具调用偏好（先看 skill / 优先 CLI / 优先 WebUI）
-->

## 域 0.1 豁免模式

<!-- TODO: 可选。是否提供"非工作流"对话入口？例如：
     - 闲聊模式（用户消息以 // 开头时跳过工作流）
     - 角色扮演模式（用户说"开始调教"时直接进入角色）
     - 如果不需要这些入口，整段删除
-->

## 域 0.2 Superpowers Skills 调用表

> **重要**：调用前先确认 skill 在 `skills/<name>/SKILL.md` 存在，并按 skill 自身的流程执行。
> 如果 skill 不适用，可不调用；但**必须先尝试再决定不用**（这是硬约束）。

| 时机 | 调用 skill | skill 在仓库中的路径 | 类型 |
|------|------------|----------------------|------|
| 需求不清、边界不稳、目标未定 | `<!-- TODO: 填 skill 名 -->` | `skills/<name>/` | 流程 |
| 目标明确，需将大任务拆为行动路径 | `<!-- TODO -->` | `skills/<name>/` | 流程 |
| 子任务相互独立、可并行执行 | `<!-- TODO -->` | `skills/<name>/` | 流程 |
| 并行分发多个独立子 agent | `<!-- TODO -->` | `skills/<name>/` | 流程 |
| 按计划逐步执行 | `<!-- TODO -->` | `skills/<name>/` | 流程 |
| 有可验证的行为变化，需先定义验收标准 | `<!-- TODO -->` | `skills/<name>/` | 刚性 |
| 出错、结果不符、任务卡住 | `<!-- TODO -->` | `skills/<name>/` | 刚性 |
| 完成前需要确认真的搞定 | `<!-- TODO -->` | `skills/<name>/` | 刚性 |
| 长期任务收尾、交付 | `<!-- TODO -->` | `skills/<name>/` | 流程 |

> **填写示例**：第 1 行 `brainstorming` → 写到第 1 个 TODO，路径写 `skills/superpowers/`（superpowers skill 集成了 brainstorming 等所有流程类 skill）

---

## 域 1：初始化引导（新会话）

<!-- TODO: 可选。是否要在新会话第一句注入引导 prompt？
     示例：
     1. 加载 using-superpowers skill
     2. 从 域 0.0 角色定义开始扮演
     3. 询问用户意图
-->

---

## 域 2：核心原则

> 本节是**通用工程纪律**，推荐所有 Agent 都保留。

### 安全
- 破坏性操作前必须备份（如 `D:\备份\`）
- 涉及账号/资金/外部发送的操作必须等用户亲口批准

### 流程
- 任务门禁：上一步未完成不进下一步
- 5 步工作流（需求 → 方案 → 执行 → 验证 → 交付）可裁剪但不可跳过

### 数据
- 可验证事实必须用工具查询，禁止猜测
- 重要信息立刻写入文件，不依赖模型记忆

---

## 域 3：子代理与工具（可选）

<!-- TODO: 如果你用 sessions_spawn / OpenCode / 浏览器自动化，在此处填：
     - 子代理 brief 模板
     - 工具调用偏好（黑名单/白名单）
     - 心跳/超时默认值
-->

---

## 域 4：心跳与监控（可选）

<!-- TODO: 如果你用 cron 监控 Agent 健康，在此处填：
     - 心跳频率
     - 监控指标（文件大小 / 任务积压 / 错误率）
     - 告警阈值
-->

---

## 附录：仓库结构

```
CentralSkillAndKnowledge/
├── README.md              ← 仓库说明
├── AGENTS.template.md     ← 本文件（Agent 规范模板）
├── LICENSE                ← MIT
└── skills/                ← 可被引用的 skill 集合
    ├── superpowers/        ← 9 个核心流程 skill 的元库
    ├── openclaw-superpowers/
    ├── gbrain-skill/       ← gbrain 知识库入口
    ├── gbrain-ops/         ← gbrain 运维
    ├── task-planner/
    ├── prompt-architect/
    ├── humanizer/
    ├── writing-polish/
    ├── skill-evolver/
    ├── skill-judge/
    ├── skill-evolution-approval/
    ├── auto-generated/
    ├── agent-file-update/
    ├── agent-reflection/
    ├── audit-skill/
    ├── error-scanner/
    ├── failure-memory/
    ├── backup-discipline/
    └── file-organization-standards/
```

> **v1.2.0 移除**（不在本仓库）：`agent-team-orchestration` / `longtask-orchestrator` / `humanizer` / `writing-polish`
> 仓库当前 17 个 skill。v1.0.0 推 26，v1.1.0 减至 21，v1.2.0 减至 17。

---

> **如何开始使用本仓库**：
> 1. 把 `AGENTS.template.md` 复制成你自己的 `AGENTS.md`
> 2. 填完所有 `<!-- TODO -->` 标记
> 3. 在你的 Agent runtime 里把仓库路径加进 skill 搜索目录
> 4. 按"Superpowers Skills 调用表"的"时机"列，触发对应 skill
>
> **Skill 数量说明**：仓库当前 21 个 skill。v1.0.0 推 26 个，v1.1.0 精简为 21 —— 废弃了 5 个知识类 skill（`knowledge` / `knowledge-pipeline` / `knowledge-searcher` / `knowledge-precipitator` / `ontology`），理由是功能已被 `gbrain-skill` + `multi_search` + AGENTS.md 门禁 5 复盘总结覆盖。
