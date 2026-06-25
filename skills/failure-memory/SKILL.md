---
name: failure-memory
display_name: "失败记忆库"
version: 1.0.0
description: "记录和分析任务执行中的错误模式与成功经验。当错误发生、工具调用失败、用户纠正或发现新经验时使用。仅做记录与分析，不修改系统配置。"
triggers:
  - "记错"
  - "record error"
  - "错误分析"
  - "failure pattern"
  - "success pattern"
  - "错误模式"
  - "经验记录"
tools:
  - exec
  - write
  - read
  - edit
  - lcm_grep
  - lcm_describe
  - lcm_expand_query
  - memory_recall
  - memory_store
mutating: true
metadata:
  openclaw:
    emoji: "📝"
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
    configPaths: ["~/.openclaw/skills/failure-memory/"]

---

# Failure Memory

记录和分析任务执行中的错误模式与成功经验。从工具调用失败、用户纠正、对话历史中提取可复用的模式，写入持久化文件供后续任务参考。

---

## Contract

1. **记录规则** — 每条记录包含：时间戳、上下文/命令、错误或成功摘要、根因、修复方式（失败时）或复用条件（成功时）。
2. **去重规则** — 写入前检查是否已存在相同模式（按摘要文本相似度），避免重复累积。
3. **主动召回** — 当工具调用失败、同一错误模式重复出现或用户提及"上次""之前"等时，自动查询失败记忆文件。
4. **文件一致性** — 只读写 `failure-memory.yaml` 和 `success-memory.yaml` 两个文件，不分散记录。
5. **验收标准** — 记录的条目在 24 小时内可被 `memory_recall` 或直接文件搜索独立召回验证。

---

## 执行步骤

### 步骤 1：检查现有记录（去重）

**输入：** 待记录的错误或成功摘要文本
**操作：** 读取 `~/.openclaw/skills/failure-memory/failure-memory.yaml` 或 `success-memory.yaml`
**检查：** 用字符串匹配或简单关键词对比，判断是否已有相似记录
**输出：** 无重复 → 继续；有重复 → 跳过并通知用户

### 步骤 2：结构化记录

**输入：** 原始错误输出、工具调用失败信息、用户反馈或成功经验
**操作：** 按以下模板提取并组织信息

| 字段 | 说明 | 必填 |
|------|------|------|
| `date` | ISO 8601 日期时间 | 是 |
| `context` | 执行上下文（任务/命令/工具） | 是 |
| `summary` | 一句话摘要 | 是 |
| `root_cause` | 错误根因（失败）或关键因素（成功） | 是 |
| `fix` | 修复方式（失败）或复用条件（成功） | 是 |
| `evidence` | 来源引用（日志路径/LCM ID/对话引用） | 否 |

**输出：** 一条格式化的 YAML 记录

### 步骤 3：持久化写入

**输入：** 步骤 2 的结构化记录
**操作：**
1. 若 YAML 文件不存在则创建（写入空列表 `[]` 的 YAML 表示）
2. 用 `exec` 通过 PowerShell 追加记录到 YAML 数组末尾
3. 用 `read` 回读最后一条记录验证写入成功
**输出：** 确认写入成功或报错

### 步骤 4：同步到记忆系统（可选）

**输入：** 刚刚写入的记录中的 `summary` 和 `fix`
**操作：** 调用 `memory_store` 写入长期记忆，分类设为 `fact`
**输出：** `memory_store` 确认

### 步骤 5：分析模式（按需）

**输入：** `~/.openclaw/skills/failure-memory/failure-memory.yaml` 全部记录
**操作：**
1. 读取全部记录
2. 按 `root_cause` 分组统计频率
3. 提取出现 ≥ 3 次的模式作为"高频失败模式"
4. 输出分析报告
**输出：** 模式分析文本（高频根因列表、趋势说明）

---

## 输出格式

### 写入单条记录后的确认消息

```
📝 失败记忆已记录
  摘要：<summary>
  根因：<root_cause>
  修复：<fix>
```

### 模式分析报告

```
📊 失败模式分析（共 N 条记录）
  高频根因：
  1. <根因> — <次数> 次
  2. <根因> — <次数> 次
  建议关注：<最高频模式说明>
```

---

## 验证方式

### 自测命令（PowerShell）

```powershell
# 验证文件存在且可读
$yamlPath = "$env:USERPROFILE\.openclaw\skills\failure-memory\failure-memory.yaml"
if (Test-Path $yamlPath) { Write-Host "PASS: failure-memory.yaml exists" } else { Write-Host "FAIL: missing failure-memory.yaml" }

# 验证 YAML 可解析（简单检查）
$content = Get-Content $yamlPath -Raw -ErrorAction SilentlyContinue
if ($content -match '^- date:') { Write-Host "PASS: YAML entries found" } else { Write-Host "INFO: no entries yet (expected on fresh install)" }

# 验证 test 目录存在
$testDir = "$env:USERPROFILE\.openclaw\skills\failure-memory\test"
if (Test-Path $testDir) { Write-Host "PASS: test directory exists" } else { Write-Host "WARN: test directory missing" }
```

---

## 反模式

1. **不记录纯噪声** — 不该记录临时性网络波动、已知的平台限制、用户误操作验证过的非问题行为。仅记录有根因分析价值的模式。
2. **不覆盖已有记录** — 追加模式到 YAML 数组，不覆写整个文件。用去重检查避免重复，但不去修改或删除历史记录。
3. **不自行诊断未知错误** — 当工具调用返回完全陌生（从未见过）的错误时，记录事实但不猜测根因。等待用户解释或后续重复出现后再补全。
4. **不将本技能用于系统配置变更** — 不做配置修改、服务启停、插件管理。`deniedTools` 已禁止 `gateway` 和 `cron` 操作。仅做记录和分析。
5. **不批量转储全量日志** — 不把整段日志、完整错误堆栈或工具调用的全量输出复制到记录中。只抽取摘要和根因，必要时用 `evidence` 字段指向外部来源（LCM ID 或文件路径）。
