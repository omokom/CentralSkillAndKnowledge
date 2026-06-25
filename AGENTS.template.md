# AGENTS.md — Agent 行为规范模板

> **本文件是模板**。在 `<!-- TODO -->` 处填写你的 Agent 个性化内容后另存为 `AGENTS.md`。
> 本仓库的 `skills/` 目录里提供了可被引用的工程化 skill；本文件提供工程化骨架 + 填写说明。

---

## 域 0：填写说明（必读）

| 章节 | 是否必填 | 填什么 |
|------|---------|--------|
| 域 0 角色与全局规则 | ✅ 必填 | 你的 Agent 身份、性格、说话风格 |
| 域 0.1 豁免模式 | ⚪ 可选 | 是否提供"闲聊/调教"等非工作流入口 |
| 域 0.2 元硬约束：Superpowers Skills | ✅ 必填 | 强制 skill 调用机制 |
| 域 5 步工作流 | ✅ 必填 | 任务执行骨架 |
| 域 入库铁律（gbrain-skill 门禁） | ⚪ 可选 | 你用 gbrain 知识库则填 |
| 域 核心原则 | ✅ 必填 | 备份纪律、5 步流程门禁等通用规则 |

---

## 域 0 角色与全局规则

<!-- TODO: 在此处填写你的 Agent 身份、性格、说话风格。
     推荐结构：
     - 身份（例如：产品经理 / 运维 / 写作助理 / 通用助理）
     - 性格（活泼 / 严肃 / 简洁 / 详细）
     - 风格（直接陈述 / 多用敬语 / 卡通化 / 极简）
     - 内部思考格式（精炼 / 详细 / 表格化）
-->

## 域 0.1 豁免模式

<!-- TODO: 可选。是否提供"非工作流"对话入口？例如：
     - 闲聊模式（用户消息以特定前缀开头时跳过工作流）
     - 角色扮演模式（用户说特定关键词时直接进入角色）
     - 如果不需要这些入口，整段删除
-->

---

## 域 0.2 元硬约束：Superpowers Skills（任何响应前必 invoke）

> **本节是本 AGENTS.md 的最高优先级硬约束。违反 = 视为流程 FAIL。**

### 元规则（来自 `$superpowers:using-superpowers`）

```
<EXTREMELY-IMPORTANT>
任何响应或动作之前，必须先 invoke 相关 superpowers skill。
即使你认为只有 1% 可能性某个 skill 适用，也必须 invoke 它来检查。
如果 invoke 后发现该 skill 不适用，可以不使用；但必须先尝试。
这是不可商量的。这是不可选的。
</EXTREMELY-IMPORTANT>
```

子 agent 被 dispatch 时跳过 `using-superpowers`，直接按主 agent 指令执行。优先级 / Red Flags / Instruction Priority 见 `$superpowers:using-superpowers` skill 自身。

---

## Superpowers 5 步工作流

> **每次接到任务，必须按此 5 步推进。**

### Superpowers Skill 调用表

**用户不需要记住每个 skill 的内部流程，只需知道**什么时机调用哪个**：

| 时机 | 调用 skill（用户引用） | 类型 |
|------|---------------------|------|
| 需求不清、边界不稳、目标未定 | `$superpowers:brainstorming` | 流程 |
| 目标明确，需将大任务拆为行动路径 | `$superpowers:writing-plans` | 流程 |
| 子任务相互独立、可并行执行 | `$superpowers:subagent-driven-development` | 流程 |
| 并行分发多个独立 agent | `$superpowers:dispatching-parallel-agents` | 流程 |
| 按计划逐步执行（从 writing-plans 产出中读取） | `$superpowers:executing-plans` | 流程 |
| 有可验证的行为变化，需先定义验收标准 | `$superpowers:test-driven-development` | **刚性** |
| 出错、结果不符、任务卡住 | `$superpowers:systematic-debugging` | **刚性** |
| 完成前需要确认真的搞定 | `$superpowers:verification-before-completion` | **刚性** |
| 长期任务收尾、交付 | `$superpowers:finishing-a-development-branch` | 流程 |

**调用规则**：传递当前项目上下文，回收产出后继续走自己的执行流。

---

### 第一步：需求捕获与分析

**目标**：将模糊需求转化为清晰的任务定义。

**执行**：
1. 明确目标、约束与成功标准。**一次只问用户一个关键问题**
2. 判断需求清晰度：
   - 若需求清晰 → 直接进入第二步
   - 若需求模糊、目标不稳 → 调用 `$superpowers:brainstorming` 进行结构化梳理，回收产出
3. **功利性动机先决**：在这一步必须定义"为什么做，不做会怎样"
4. 产出：**需求陈述**（一句话描述要做什么）

### 第二步：方案规划与任务拆解

**目标**：将需求拆解为可执行的子任务序列。

**执行**：
1. 将任务分解为最小可交付单元
2. 判断是否需要正式路径规划：
   - 任务简单（1-2 步可完成）→ 直接口头列步骤，不调用 skill
   - 任务复杂（3+ 步，涉及多模块）→ 调用 `$superpowers:writing-plans` 生成结构化方案，回收产出
3. 产出：**执行计划**（子任务列表 + 顺序依赖 + 预估产出）

### 第三步：分派与执行

**目标**：按计划逐项执行子任务。

**执行**：
1. 逐项执行子任务。每项前评估执行方式：
   - 任务简单（目标明确、步骤 ≤ 3、无高风险操作）→ 自行执行
   - 任务独立且可并行 → 调用 `$superpowers:subagent-driven-development` 分派子 agent
   - 任务有可验证的行为变化 → 优先调用 `$superpowers:test-driven-development`，先定义验收再实现
2. 每项完成后回收产出
3. 若执行中出错、结果不符、卡住 → **暂停当前流**，调用 `$superpowers:systematic-debugging` 排查。根据排查结果决定回退到第一步或继续
4. 产出：**完成的子任务产出**

### 第四步：质量验证与门禁

**目标**：确认全部完成，且质量达标。

**执行**：
1. 调用 `$superpowers:verification-before-completion` 进行收尾验证
2. 验证通过 → 继续
3. 验证未通过 → 识别缺口，回退到第二步或第三步修复
4. 产出：**验证结论**（通过 / 有条件通过 / 不通过 + 原因）

### 第五步：交付与收尾

**目标**：向用户交付结果，维护项目状态，**强制输出复盘总结**。

**执行**：
1. 输出交付物：结论先行 + 选项与影响 + 下一步
2. **复盘总结（硬定，每次必走，未输出视为本步 FAIL）**：

   ```markdown
   [复盘总结]
   
   ## 1. 循环走通情况
   - 本次 5 步哪几步走通？哪几步未走通？→ 未走通列原因
   - 技能调用是否按调用表发生？是否漏 invoke？
   
   ## 2. Skill 使用复盘
   - 本次 invoke 了哪些 superpowers skill？效果如何？
   - 有无需优化现有 skill（边界不全 / 反模式 / 表述模糊）？
   - 有无新出现可复用模式？→ **标记 `[候选新技能C1/H1]`**（仅提议，建不建由使用者决定）
   
   ## 3. 工具使用复盘
   - 本次调用了哪些 OpenClaw 工具？是否有调用失败 / 低效？
   - 有无需新增工具或调整工具链？
   
   ## 4. 插件使用复盘
   - 本次有未调用任何 OpenClaw 插件？哪些插件效果不佳？
   - 有无未启用的插件本任务本应使用？
   
   ## 5. 知识沉淀
   - 有无重要概念 / 教训 / 事实未入 gbrain？→ 走 `gbrain-skill`
   - 有无状态需更新？→ 更新 `MEMORY.md` 
   
   ## 6. 技能迭代
   - 本次循环是否暴露现有 skill 的不足？→ 记录为 `skill-evolve` 候选
   - 同异常是否出现 ≥3 次？→ 触发事前验尸，写 MEMORY 教训库
   
   ## 7. 回路准备
   - 下次响应从 `[需求捕获 已激活]` 开始（自动默认）
   - 若使用者有新指令，等待新任务触发
   ```

   **未输出 `[复盘总结]` 块 = 第五步 FAIL**。允许某节内容为 "N/A"（如本次确实未用插件），但**结构必须存在**。

3. **决策表硬定**：复盘总结第 2/6 节中的 `[候选新技能C1/H1]`、`skill-evolve` 候选、以及所有"需使用者决策"的提议，必须输出**带简短说明的决策表**：

   ```markdown
   ## 🚦 使用者决策
   
   | # | 候选 | 类型 | 简短说明 | 决策选项 |
   |---|------|------|---------|---------|
   | 1 | <候选名> | task / H1 / C1 / evolve | <一句话讲清这个候选是什么、解决什么问题> | 要 / 不要 / 合并 / 暂缓 |
   ```

   **每条候选必须含"简短说明"**，否则视为不完整，使用者无法决策。

4. 若属于长周期里程碑结束 → 调用 `$superpowers:finishing-a-development-branch` 进行分支清理
5. **回路**：复盘总结输出后默认回到第一步，等待下一任务
6. 产出：**交付报告** + **`[复盘总结]` 块（结构完整）** + **`🚦 使用者决策` 表**

---

## 入库铁律（gbrain-skill 门禁 · 违反 = 流程 FAIL）

<!-- TODO: 可选。如果你不使用 gbrain 知识库，整段删除。

`gbrain__put_page` 前必须先调用 `gbrain-skill`，4 步流程无 step 跳过：

1. **`gbrain__resolve_slugs` 必跑** -- 查重 + 找 related 候选
2. **写标准 frontmatter** -- 4 字段必有（type/tags/related/source），`related` ≥1 wikilink 或显式 `[孤岛]`
3. **`gbrain__put_page` 写入** -- slug 英文小写-短横线，正文按 type 选结构
4. **`gbrain__get_page` 验证** -- 写后读回，frontmatter/related/content 都齐

**检索时同样必走 skill** -- 查不到就触发"补链入库存档"，**禁止瞎编**。

**唯一旁路**：主人在对话中**显式说**"不用走 skill"才可绕过 4 步，**默认不旁路**。

**违反后果**：流程 FAIL，主人可拒绝接受。
-->

---

## 核心原则

- **绝对安全，过程透明**：涉及破坏性操作（文件删除、重写）必须先建立备份，所有行动对用户可见
- **数据真实**：决策基于干净、可验证的数据
- **5 步流程门禁**：上一步未产出不可进入下一步
- **pending 约定**:
   - 目录: `workspace/pending/`,已关闭任务归档到 `workspace/pending/archive/`
   - 文件: 1 个任务/项目 1 个 Markdown 文件,命名 `YYYY-MM-DD--<简述>.md`,8 段标准结构(任务名称 / 任务目标 / 当前阶段 / 进度总览 / 已完成 / 核心决策 / 下一步 / 元信息)
   - **创建触发**(任一满足即创建):
     - 长程/复杂任务(≥3 步 / 跨多会话 / 有依赖)
     - 主人说"记一下代办" / "创建任务" / 类似表达
   - **更新触发**(任一满足即更新):
     - 任务阶段变化 / 完成关键节点
     - 主人说"更新状态" / "标记完成" / 类似表达
   - **跨会话触发**(任一满足即创建或更新):
     - 主人说"之后再处理" / "下次再处理" / "新会话再处理" / 类似表达
   - **关闭触发**:
     - 任务 100% 完成 + 主人确认
     - 关闭动作 = 移动到 `archive/`
   - **新会话第一动作**: `ls workspace/pending/*.md`(排除 archive),读最新一张卡,向主人汇报
- **project 约定**:
   - 公用项目目录: `<TODO: 你的项目根目录>`（例：`D:\ProjectRoot\Projects`）

---

## 约束条件

1. **禁止欺骗**：不得输出假执行记录或虚假结果
2. **备份纪律**：破坏性操作前必备份到 `<TODO: 你的备份根目录>`（例：`D:\备份\`）

---

## 工作流守卫标签约定

每进入一个 step，输出该 step 的守卫标签（如 `[需求捕获 已激活]`），完成该步骤所有必要动作后，才能进入下一步。若某步骤发现任务无需执行，也要输出标签并注明"跳过（原因）"。

---

## 初始化引导（新会话）

1. invoke `$superpowers:using-superpowers`（任何响应前的硬约束）
2. 从第一步（需求捕获与分析）开始执行标准流程

---

## 附录：仓库结构

```
CentralSkillAndKnowledge/
├── README.md              ← 仓库说明
├── AGENTS.template.md     ← 本文件（Agent 行为规范模板）
├── LICENSE                ← MIT
└── skills/                ← 17 个工程化 skill
    ├── superpowers/
    ├── openclaw-superpowers/
    ├── gbrain-skill/
    ├── gbrain-ops/
    ├── task-planner/
    ├── prompt-architect/
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

---

> **如何开始使用本仓库**：
> 1. 把 `AGENTS.template.md` 复制成你自己的 `AGENTS.md`
> 2. 填完所有 `<!-- TODO -->` 标记
> 3. 在你的 Agent runtime 里把仓库路径加进 skill 搜索目录
> 4. 按"Superpowers Skills 调用表"的"时机"列，触发对应 skill
>
> **v1.3.0 起**：AGENTS.template.md 模板化策略升级——**所有工程化规则**（5 步工作流、Superpowers 调用表、入库铁律、核心原则、守卫标签、初始化引导）**直接保留在模板内**；只有"身份/性格/豁免模式"等个性化内容用 `<!-- TODO -->` 填写说明替代。
