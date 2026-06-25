---
name: gbrain-skill
version: 1.0.0
description: 强制结构化的 gbrain 知识库入口。所有 agent(主 agent、Codex、Hermes、OpenCode、Sophia、Tongji、若葉)写入 gbrain 或从 gbrain 检索时必须先调用本 skill,确保 frontmatter、wikilink、related 字段、验证回读四步不遗漏。
triggers:
  - 记忆
  - 记下
  - 入库
  - 入知识库
  - 写到 gbrain
  - 存到 gbrain
  - 查 gbrain
  - 用 gbrain
  - gbrain
  - 知识库
  - 这个以后用得上
  - put_page
  - 归档
  - 沉淀到 gbrain
---

# gbrain-skill — 知识库强制入口

> **本 skill 是 AGENTS.md "入库铁律" 的执行版。不调 skill 直接 `put_page` = 污染知识库,主人可拒绝接受。**

## 1. 何时必须调用本 skill

**任一命中**:
- 你想把任何内容存入 gbrain(对话发现、任务结果、概念解释、事实记录、踩坑教训)
- 你要从 gbrain 检索任何知识(查定义、查流程、查先例、查相关概念)
- 你要修改/补全/删除 gbrain 已有的 page
- Codex/Hermes/子 agent 收到"去查 X"、"去记忆 Y" 类指令

## 2. 强制 4 步流程(无 step 跳过,违反 = WorkStep2 FAIL)

### Step 1:查重 + 找 related 候选(必跑)

**绝对不能跳过**。直接 `put_page` 写一个新 slug 会被主人视为污染。

```bash
# 必须先搜,即使你"知道"这是新概念
gbrain__resolve_slugs(partial="<概念关键词>")
gbrain__query(query="<同义/相关表达>")
```

**产出**:
- **目标 slug**(新写则用,已存在则复用)
- **related 候选**(必须从查询结果里挑 ≥1,作为下一步 `related:` 字段的 wikilink 目标)

### Step 2:写标准 frontmatter

**必备 4 字段**(`templates/page.md` 有完整模板):

```yaml
---
type: concept | note | fact | project | lesson
tags: [tag1, tag2, tag3]
related: [[[existing-slug-1]]], [[[existing-slug-2]]]
source: <来源描述,如 "main agent 2026-06-25 对话" 或 "codex 工作区 lesson-001">
created: YYYY-MM-DD
confidence: high | medium | low
---
```

**type 选择规则**:
- `concept`:抽象概念、定义、原理(如 "Box2D 物理引擎"、"贝叶斯更新")
- `note`:具体事件、发现、对话记录、临时笔记
- `fact`:硬事实、API 文档片段、命令清单
- `project`:项目/任务/Agent 编排
- `lesson`:踩坑教训(任何"我犯过错"的归档)

**related 硬规则**:
- `related:` 字段必须填,**至少 1 个** `[[[xxx]]]`,**从 Step 1 的查询结果里挑**
- 例外:真的是孤岛概念(全新领域无任何已有 page)→ 写 `related: [孤岛]`,主人会复核
- **禁止**:`related: []` 空数组且无说明

### Step 3:`gbrain__put_page` 写入

- **slug 命名**:英文小写,短横线分隔,语义清晰(如 `unity-physics-box2d` 而非 `box2d`)
- **content**:frontmatter + 正文,正文用 markdown
- **正文建议结构**(概念类):定义 → 关键属性 → 相关概念(已链回 gbrain) → 例子 → 引用
- **正文建议结构**(note 类):事件 → 现象 → 根因 → 解决 → 关联
- **正文建议结构**(lesson 类):场景 → 我做了什么 → 为什么错 → 应该怎么做 → 避免下次

### Step 4:写后验证(必跑,否则不算完成)

```bash
page = gbrain__get_page(slug="<刚写的>")
# 检查:
# 1. frontmatter 4 字段都在
# 2. related 字段非空
# 3. content 含正文(非空)
# 4. type/tags 都正确
```

**验证失败自动重试(本次 v1.1.0 升级)**:
- 轮数 ≤ 2 → 自动重新 `put_page` 修复该问题(补 frontmatter / 重查 related / 精简内容),再回 Step 4
- 轮数 ≥ 3 → 升级 escalate:**立刻停止当前写入**,输出诊断给主人(slug/失败原因/已尝试的修复),等主人决策

**轮数追踪**:
- 每次写入记住 `retry_count = 0`
- 验证失败递增
- 达到阈值 → escalate,**不静默重试**

**重试限制背后的原因**:
- 防止"LLM 幻觉导致死循环"(LLM 可能反复修复同一个错误但根因不是字段问题)
- 防止"gbrain 服务端异常被掩盖"(连续失败很可能是上游问题,不是字段问题)
- 保护 gbrain 不被污染(失败重试可能产生半成品 page)

**手动覆盖**:主人在对话中显式说"重试 N 次以上"可放宽阈值,默认不覆盖。

## 3. 检索模式(查 gbrain 时)

### 3.1 概念查询(查定义/原理)

```bash
result = gbrain__query(query="<关键词>")
# 看 confidence 和 chunk 数,如果太薄,可能是孤岛
```

### 3.2 实体发现(查相关/找 related 候选)

```bash
slugs = gbrain__resolve_slugs(partial="<部分 slug 或关键词>")
```

### 3.3 图谱遍历(查关系网)

```bash
# Codex 这类需要"找出 X 周围还有什么"
nodes = gbrain__traverse_graph(slug="<目标 slug>", depth=2)
```

### 3.4 失败模式处理

**查不到东西时**(Codex 高频痛点):
1. 用 1-3 个**不同关键词**重试(同义词、改写)
2. 用 `gbrain__resolve_slugs` 模糊匹配
3. 用 `gbrain__find_orphans` 看是否需要补链
4. 仍查不到 → **入库新 page**,**别瞎编**。本 skill 规定:宁可"主人说没数据",也不可"假装有"

## 4. 反模式(L0 严禁)

| 反模式 | 后果 | 正确做法 |
|--------|------|---------|
| 跳过 `resolve_slugs` 直接 `put_page` | 新 slug 跟已有概念重复/不链接 | 必跑 Step 1 |
| 写散文不写 frontmatter | 知识图谱无法构建 | Step 2 模板硬写 |
| `related: []` 留空 | 永远孤岛,图谱不增长 | 回 Step 1 补 |
| 写完不验证 | 写失败/被截断不知道 | Step 4 必跑 |
| 把 gbrain 当临时记事本 | 内容碎片,无法检索 | note 类型也必须有 related |
| 写"查不到"就瞎编 | Codex 拿到假数据 | 宁可写"孤岛,待补",也不编 |
| 入库后不更新 `related` | 单向图谱,无法反向链接 | 写新 page 时,记得**回头**给相关旧 page 加 `related: [[[新 slug]]]` |

## 5. Codex/Hermes 特定指引

### Codex 查不出东西的标准应对
- **别退化成"凭印象答"**。查不到就告诉主人"知识库里没有 X",并触发本 skill 的 Step 1-3 入库动作
- **触发"补链入库存档"**:Codex 跑完一次查询后,如果有"我应该知道但库里没有"的事,记下来 → 入库(走 skill)

### Hermes 跨 session 入库
- Hermes 的记忆是 `hermes-borrow` 压缩的,主人如果要让某段对话"以后能查到",必须显式调本 skill 写 gbrain
- 压缩只会保留对话内容,不会自动建知识图谱

### OpenCode 编码任务入库
- 任何"我刚解决了一个 bug"、"这个 API 怎么用"、"项目结构是这样"的发现,完成后**必走 skill 入库**
- 写 `type: lesson` 或 `type: fact`,related 链接到对应的项目/concept page

## 6. 模板与示例

- `templates/page.md` — 完整 frontmatter 模板
- `examples/concept-valid.md` — 标准概念入库示例
- `examples/note-valid.md` — 标准 note 入库示例
- `examples/lesson-valid.md` — 标准 lesson(踩坑)入库示例
- `examples/anti-pattern-no-related.md` — 反面教材

## 7. 紧急旁路(主人显式批准可绕过 4 步)

主人在对话中**显式说**"不用走 skill,直接 put_page"时,可以跳过。但**默认不旁路**。

---

**版本**:v1.1.0 (2026-06-25)
**作者**:主 agent 日向,应主人要求建立
**变更日志**:
- v1.1.0 (2026-06-25): Step 4 验证失败增加自动重试机制,≤2 次自动修复,≥3 次 escalate 主人
- v1.0.0 (2026-06-25): 初版,4 步流程 + 反模式 + Codex/Hermes 指引

**约束来源**:AGENTS.md 域一 "入库铁律" 段
