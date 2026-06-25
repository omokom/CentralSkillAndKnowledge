---
name: knowledge-pipeline
version: 2.0.0
description: |
  知识沉淀管道。管理从会话笔记到 wiki 条目的升级流程：笔记写入、教训频次监控、
  升级判定（3次触发）、wiki 条目创建/更新、归档清理。
  同时负责每轮对话结束时的 gbrain__extract_facts 事实提取入库，
  以及门禁 5 的技能化判定回顾（A1/D1/F1 条件）。
  覆盖 AGENTS.md 域十（成长循环）+ 域三（门禁 5 沉淀）的部分职责。
  不做：日常工具操作、编码任务、文件整理。
triggers:
  - "知识沉淀"
  - "升级教训到 wiki"
  - "会话笔记归档"
  - "教训频次检查"
  - "域十"
  - "成长循环"
  - "知识管道"
  - "笔记归档"
  - "wiki 升级判定"
tools:
  - read
  - write
  - edit
  - exec
  - memory_recall
  - memory_store
  - wiki_search
mutating: true
metadata:
  openclaw:
    emoji: "📚"
    layer: 2
    layer_label: "Workflow Library"
    priority: normal
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
    depends_on:
      - agent-file-update
    configPaths: ["~/.openclaw/workspace/notes/sessions/", "~/.openclaw/workspace/wiki/lessons/"]
    replaces: "AGENTS.md 域十"
---

# 📚 Knowledge Pipeline — 知识沉淀管道

## Contract

1. **笔记即写** — 每轮对话后自动写入轻量笔记，格式固定
2. **3次触发升级** — 同一教训出现 3 次才触发 wiki 升级，不提前
3. **48h 静默否决** — 升级需主人批准，48h 无回复视为否决
4. **50条归档阈值** — 笔记目录超过 50 条触发归档
5. **5次交付审查** — 每 5 次门禁 4 交付后审查高频教训

## 执行步骤

### Step 0: 事实提取入库（每轮对话）

**触发：** 门禁 0（准入判断时）和门禁 5（知识沉淀时）
**操作：**
```
gbrain__extract_facts(
  turn_text: "当前对话内容摘要",
  entity_hints: ["涉及的实体slug列表"],
  visibility: "private"
)
```
**说明：**
- 门禁 0 提取**上一轮**对话的事实，避免在对话中被压缩丢失
- 门禁 5 提取**本轮**对话的事实，作为沉淀的一部分
- 不等到门禁 5 才提取的原因是：长时间对话可能在门禁 5 之前就被 LCM 压缩
- 提取内容包括：事件、偏好、承诺、信念四类

### Step 1: 笔记写入

**输入：** 当前对话内容摘要
**输出：** `notes/sessions/YYYY-MM-DD--<标签>.md`
**格式：**
```markdown
# <日期> <主题>

## 做了什么
- <关键操作>

## 学到了什么
- <教训/发现>

## 待办延续
- <下次需要继续的内容>
```

### Step 2: 教训频次监控

**输入：** 新写入的笔记
**操作：** 扫描 MEMORY.md 域三和 `corrections.md`，检查新教训是否已在已有记录中出现

### Step 3: 升级判定

**触发条件：** 同一教训在 MEMORY.md 域三中出现 ≥3 次
**操作：**
1. 向主人发送：「XX 教训已在 [时间1] [时间2] [时间3] 出现 3 次，建议升级为 wiki/lessons/ 条目，是否批准？」
2. 48h 无回复 → 视为否决
3. 批准 → 执行 Step 4

### Step 4: Wiki 条目创建

**输入：** 教训内容 + 出现记录（时间/来源/置信度）
**输出：** `wiki/lessons/<slug>.md`
**格式：**
```markdown
---
title: <教训标题>
tags: [lessons, <类别>]
sources:
  - <第一次出现>
  - <第二次出现>
  - <第三次出现>
---

# <教训标题>

## 教训
<教训描述>

## 证据
- <来源1>
- <来源2>
- <来源3>

## 置信度
<高/中/低>
```

### Step 5: 归档检查

**触发：** `notes/sessions/` 文件数 >50
**操作：**
1. 将最早的 30 条笔记打包为 `notes/archives/YYYY-Q<N>-session-notes.tar.gz`
2. 删除已归档的笔记文件
3. 更新 MEMORY.md 域二（会话回溯）保留一行摘要

### Step 6: 交付审查

**触发：** 完成 5 次门禁 4 交付
**操作：**
1. 审查最近 5 次交付中出现的高频教训
2. 检查是否需要更新 AGENTS.md/MEMORY.md 基线
3. 输出审查报告追加到 `~/.openclaw/.audit/knowledge-review/YYYY-MM-DD.md`

## 输出格式

每次执行后输出：
```
[Knowledge Pipeline] 操作: <笔记写入/升级判定/wiki创建/归档/审查>
详情: <简述> | 触发条件: <A1/3次/50条/5次> | 状态: OK/已跳过
```

## 反模式（Anti-Patterns）

- 单次教训就升级为 wiki 条目（过度工程）❌
- 笔记不写日期标签 ❌
- 升级前不通知主人 ❌
- 归档后不更新 MEMORY.md ❌
- 跨文件引用同一教训时不同步 ❌

## 验证方式

```powershell
# 检查笔记文件
Get-ChildItem "C:\Users\lixin\.openclaw\workspace\notes\sessions\"
# 检查教训升级记录
Select-String -Path "C:\Users\lixin\.openclaw\workspace\MEMORY.md" -Pattern "出现: \d+次"
```
