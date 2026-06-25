# CentralSkillAndKnowledge

> **去中心化的 Agent skill 和知识管理平台**
> 一个可被引用、可被克隆、可被裁剪的 Agent 工程化 skill 集合。

本仓库面向**所有想用一套成熟 Agent 工程规范**的人——从单 Agent 跑个人项目，到多 Agent 协作做复杂工作流，都能从这里取用。

---

## 这个仓库是什么

一个**只装骨架**的仓库：

| 包含 | 不包含 |
|------|--------|
| ✅ 26 个工程化 skill 的源文件 | ❌ 任何具体业务代码 |
| ✅ 一份 Agent 行为规范模板 | ❌ 任何 Agent 角色/性格/人设 |
| ✅ 仓库结构说明 + 引用方式 | ❌ 任何运行时配置 |
| ✅ MIT 协议 | ❌ 任何品牌/logo/水印 |

**没有"谁家的 Agent 模板"——你 fork 之后自己改，改完就是你的。**

---

## 仓库结构

```
CentralSkillAndKnowledge/
├── README.md                ← 本文件
├── AGENTS.template.md       ← Agent 行为规范模板（复制后改名 AGENTS.md）
├── LICENSE                  ← MIT
└── skills/                  ← 26 个 skill 的源文件集合
```

每个 skill 是一个独立目录，含 `SKILL.md`（入口）和必要的辅助文件。
完整 skill 清单见 [域 3：Skill 索引](#域-3skill-索引)。

---

## 谁应该用这个仓库

1. **搭新 Agent 的开发者**——把本仓库当 skill 库引用，避免从零造轮子
2. **维护多 Agent 集群的工程师**——统一团队内所有 Agent 的行为规范
3. **Agent 工程化的研究者**——观察一套真实在生产环境跑过的 skill 集合是怎么组织的
4. **fork 后改造成自家规范的团队**——MIT 协议下随便改

---

## 域 1：快速开始

### 1.1 作为 skill 源引用

```bash
# 1. 克隆到你的工作区
git clone https://github.com/omokom/CentralSkillAndKnowledge.git

# 2. 把 skills/ 路径加进你的 Agent runtime 配置
#    （具体写法取决于你的 runtime；OpenCode / Claude Code / 自研 Agent 各自不同）

# 3. 在 AGENTS.md 的 Superpowers 调用表里填入要启用的 skill
```

### 1.2 作为模板 fork

```bash
# 1. 在 GitHub 上点 Fork
# 2. clone 你的 fork
git clone https://github.com/<your-name>/CentralSkillAndKnowledge.git

# 3. 复制 AGENTS.template.md → AGENTS.md，填完所有 TODO
cp AGENTS.template.md AGENTS.md
# 编辑 AGENTS.md，把 <!-- TODO: ... --> 换成你的内容

# 4. 根据需要增删 skills/ 下的 skill
# 5. commit + push
```

---

## 域 2：使用流程建议

### 单 Agent 起步（最小集）

1. 复制 `AGENTS.template.md` → `AGENTS.md`
2. **必填项**填完：域 0.0（角色与全局规则）+ 域 0.2（Superpowers 调用表）+ 域 2（核心原则）
3. 在 runtime 里**至少启用以下 3 个 skill**：
   - `superpowers`（核心 9 个流程 skill 的元库，**必装**）
   - `gbrain-skill`（知识库入口，**必装**——所有 gbrain 操作走它）
   - `task-planner`（任务规划）
4. 按 `AGENTS.md` 的"Superpowers Skills 调用表"按时机触发 skill

### 知识库/研究型 Agent

在单 Agent 起步基础上**额外启用**：

- `gbrain-ops`（gbrain 运维）

> 已废弃（不放入仓库）：
> - 知识类 5 个：`knowledge` / `knowledge-pipeline` / `knowledge-searcher` / `knowledge-precipitator` / `ontology`（功能由 `gbrain-skill` + `multi_search` + AGENTS.md 门禁 5 复盘总结覆盖）
> - 多 Agent 集群 4 个：`agent-team-orchestration` / `longtask-orchestrator` / `humanizer` / `writing-polish`（单 Agent 起步不需要；多 Agent 场景属于另一条路径，本仓库暂不收录）

### Skill 自演化场景

- `skill-evolver` + `skill-judge` + `skill-evolution-approval`（提案/评审/批准三件套）
- `auto-generated`（自动生成的 skill 占位）

---

## 域 3：Skill 索引

### 域 3.1 核心循环骨架（必装）

| Skill | 用途 | 是否必装 |
|-------|------|---------|
| `superpowers` | 9 个核心流程 skill 的元库（brainstorming/writing-plans/executing-plans/TDD/systematic-debugging/verification-before-completion 等） | ✅ 必装 |
| `openclaw-superpowers` | OpenClaw runtime 对 superpowers 的包装 | ⚪ OpenClaw 用户必装 |
| `gbrain-skill` | gbrain 知识库入口（写/读/查重/补链） | ✅ 必装 |
| `gbrain-ops` | gbrain 运维（embed 推进、worker 拉起、doctor 巡检） | ⚪ 用 gbrain 才装 |
| `task-planner` | 任务规划/拆解 | ✅ 建议装 |

> v1.2.0 移除：`agent-team-orchestration` / `longtask-orchestrator`（多 Agent 集群路径不属于本仓库范围）

### 域 3.2 知识相关（精简后）

> **v1.1.0 起**：原 6 个 knowledge skill 精简为 2 个。删除 `knowledge` / `knowledge-pipeline` / `knowledge-searcher` / `knowledge-precipitator` / `ontology` —— 功能已被 `gbrain-skill` + `multi_search` + AGENTS.md 门禁 5 复盘总结覆盖。

| Skill | 用途 | 是否必装 |
|-------|------|---------|
| `gbrain-skill` | gbrain 知识库入口（写/读/查重/补链） | ✅ 必装 |
| `gbrain-ops` | gbrain 运维（embed 推进、worker 拉起、doctor 巡检） | ⚪ 用 gbrain 才装 |

### 域 3.3 文本产出

| Skill | 用途 |
|-------|------|
| `prompt-architect` | Prompt 工程化 |

> v1.2.0 移除：`humanizer` / `writing-polish`（单 Agent 起步不需要）

### 域 3.4 Skill 自演化

| Skill | 用途 |
|-------|------|
| `skill-evolver` | 技能提案生成 |
| `skill-judge` | 技能质量评分 |
| `skill-evolution-approval` | 技能提案批准 |
| `auto-generated` | 自动生成的 skill 占位 |

### 域 3.5 Agent 自省与纪律

| Skill | 用途 |
|-------|------|
| `agent-file-update` | agent 自身文件更新流程 |
| `agent-reflection` | agent 复盘/自省 |
| `audit-skill` | 审计（违规检测） |
| `error-scanner` | 错误扫描 |
| `failure-memory` | 失败记忆（教训库） |
| `backup-discipline` | 备份纪律 |
| `file-organization-standards` | 文件组织规范 |

---

## 域 4：模板化策略

本仓库**只提供骨架**。所有个性化内容（角色、性格、说话风格、豁免模式）都通过 `AGENTS.template.md` 的 `<!-- TODO -->` 标记交给使用者填写。

**为什么不内置 Agent 性格**：

- Agent 的角色/性格高度依赖业务场景（客服 vs 编程 vs 写作 vs 运维）
- 内置性格会污染所有使用者的默认值
- MIT 协议下"无默认"比"有默认"更易 fork

**哪些是骨架（保留）**：

- 5 步工作流（需求→方案→执行→验证→交付）
- Superpowers 调用时机表
- 核心原则（备份、5 步门禁、数据真实）
- 子代理/工具规范（可选）

**哪些是个性化（TODO 化）**：

- Agent 身份与人设
- 性格参数
- 说话风格
- 豁免模式（闲聊/调教等非工作流入口）

---

## 域 5：贡献指南（轻量版）

- 提交新 skill：在 `skills/<your-skill>/` 下建 `SKILL.md`，写明 `name/description/when-to-use/how-to-apply`
- 提交模板改进：改 `AGENTS.template.md` 时**保持 TODO 化策略**——不要把任何"具体人设"硬编码进模板
- 提交 issue：描述你的使用场景 + 卡在哪一步 + 期望 vs 实际

---

## 域 6：版本

- v1.0.0（2026-06-25）：初版，26 个 skill + AGENTS 模板 + README
- v1.1.0（2026-06-25）：精简知识类 skill，26 → 21；废弃 `knowledge` / `knowledge-pipeline` / `knowledge-searcher` / `knowledge-precipitator` / `ontology`
- v1.2.0（2026-06-25）：精简多 Agent 集群 + 文本润色，21 → 17；移除 `agent-team-orchestration` / `longtask-orchestrator` / `humanizer` / `writing-polish`（单 Agent 起步不需要）
- 后续遵循 semver；破坏性改动走 major 版本

---

## License

MIT — 见 [LICENSE](./LICENSE) 文件。
