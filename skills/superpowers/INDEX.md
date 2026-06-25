# Superpowers Skills — OpenClaw 平台适配层

> **本目录是从 codex 移植的 superpowers 系列 skill,OpenClaw 平台专用适配。**
> 原作者保留所有权利,本目录仅做**平台工具映射 + 触发器命名**,内容逻辑保持原样。

## 1. 触发器命名映射(用户 → 平台)

**用户层跨平台约定**(固定不变):
- 用户写 AGENTS.md / 对话 / 文档时,统一用 `$superpowers:<name>` 风格引用
- 这是**用户意图层**约定,跨平台统一

**平台层实现**(可有差异):
| 平台 | 触发方式 |
|------|---------|
| OpenClaw | `skill_read('superpowers-<name>')` 或匹配 skill `description` 触发器 |
| Claude Code | `Skill` tool 原生调用 |
| Codex | Skills 原生加载,无需显式调用 |
| Copilot CLI | `skill` tool |
| Gemini CLI | `activate_skill` tool |

**映射示例**:
| 用户写 | OpenClaw | Claude Code | Codex |
|--------|---------|-----------|-------|
| `$superpowers:brainstorming` | `skill_read('superpowers-brainstorming')` | `Skill('superpowers:brainstorming')` | 原生激活 |
| `$superpowers:writing-plans` | `skill_read('superpowers-writing-plans')` | `Skill('superpowers:writing-plans')` | 原生激活 |
| ... 其他同理 | | | |

**核心约定**:**用户层引用前缀统一(`$superpowers:xxx`),平台层 invoke 方式允许差异**——这是 superpowers 框架的 Platform Adaptation 机制本身支持的。

## 2. OpenClaw 工具映射

superpowers skill 用的是 "抽象动作"("Read file"、"Edit file"、"Run command"),OpenClaw 对应:

| 抽象动作 | OpenClaw 工具 |
|---------|--------------|
| Read file | `read(path)` |
| Write file | `write(path, content)` |
| Edit file | `edit(path, edits[])` |
| Run shell | `exec(command, timeout=N)` |
| Apply patch | `apply_patch(input)` |
| Background work | `sessions_spawn(...)` / `process(...)` |
| Search files | `exec` + `Get-ChildItem` / `Select-String` |
| Get git context | `exec` + `git` 命令 |
| List skills | `skill_list()` |
| Read skill | `skill_read(skillName)` |
| Write memory/note | `memory_write(key, value)` |

完整映射见 `references/claude-code-tools.md` 等原文件——但 OpenClaw 工具名不同,使用前查 TOOLS.md 域四。

## 3. 10 个 skill 总览

| Skill | 触发场景 | 类型 |
|-------|---------|------|
| `using-superpowers` | **每次响应前**(元技能) | 流程硬约束 |
| `brainstorming` | 需求不清、目标不稳、设计未明 | 流程 |
| `writing-plans` | 多步任务,需拆解为行动路径 | 流程 |
| `subagent-driven-development` | 子任务独立可并行 | 流程 |
| `dispatching-parallel-agents` | (额外)并行分发多个子 agent | 流程 |
| `executing-plans` | (额外)按计划逐步执行 | 流程 |
| `test-driven-development` | 有可验证行为变化,需先写验收 | 刚性 |
| `systematic-debugging` | 出错、卡住、结果不符 | 刚性 |
| `verification-before-completion` | 完成前自验 | 刚性 |
| `finishing-a-development-branch` | 长周期里程碑收尾 | 流程 |

## 4. 使用规则(从 `using-superpowers/SKILL.md` 继承)

### EXTREMELY-IMPORTANT
- 任何响应前**必须** invoke 至少一个相关 skill(1% 可能性也要 invoke)
- 用户指令 > superpowers skill > 默认 system prompt
- 不能用"我熟悉这 skill"绕过 → 必须 invoke

### Red Flags(自我检查)
- "这是简单问题" → 不,问题是任务,先 invoke
- "先看下文件" → 不,先 invoke 看怎么探索
- "我先看下 git" → 不,先 invoke 看 git 怎么用
- "这个不需要正式 skill" → 如果 skill 存在,**必须用**

### Priority
1. **流程 skill 优先**(brainstorming / systematic-debugging)
2. **实现 skill 次之**(frontend-design / mcp-builder 等)
3. 子 agent 被 dispatch 时,**跳过 using-superpowers**(直接按主 agent 指令执行)

## 5. AGENTS.md 集成方案(本次会话任务)

主人要让"通用 AGENTS.md"——意味着:
- **新 AGENTS.md 主体用 superpowers 5 步流程**(替代现有 WorkStep1-3)
- **保留主人"灵魂"风格**(SOUL.md 触发的语气)
- **保留 gbrain-skill 入库铁律**(前次任务的产出)
- **D:\备份 作为备份目录**(主人新定的纪律)

详细见后续任务输出(等主人确认后再覆盖现有 AGENTS.md)。

## 6. 备份与版本

- **原始 source**:C:\Users\lixin\.codex\skills\*
- **OpenClaw 副本**:C:\Users\lixin\.openclaw\skills\superpowers\*(本目录)
- **D:\备份**:D:\备份\superpowers-skills-2026-06-25\
- **版本基线**:2026-06-25 移植,基于 codex 当前版本
- **同步策略**:codex 升级时,本目录需手动同步(或建 git 仓库)

## 7. 与 gbrain-skill 的关系

**独立 skill**。superpowers 负责"怎么思考/执行",gbrain-skill 负责"怎么入库"。两者正交:

- superpowers 流程里任何**新概念/发现/教训**,都触发 gbrain-skill 走 4 步入库
- gbrain-skill 的 4 步流程**本身**就是 superpowers 5 步流程的一个具体应用(第二步拆解 + 第四步验证)

---

**本目录结构**:
```
C:\Users\lixin\.openclaw\skills\superpowers\
├── INDEX.md                                    # 本文件
├── using-superpowers/                          # 元技能
├── brainstorming/                              # 流程:需求不清
├── writing-plans/                              # 流程:多步任务拆解
├── subagent-driven-development/                # 流程:并行分派
├── dispatching-parallel-agents/                # 流程(额外)
├── executing-plans/                            # 流程(额外)
├── test-driven-development/                    # 刚性:有验收变化
├── systematic-debugging/                       # 刚性:出错排查
├── verification-before-completion/             # 刚性:完成前自验
└── finishing-a-development-branch/             # 流程:里程碑收尾
```