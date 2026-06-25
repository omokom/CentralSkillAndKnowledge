---
name: error-scanner
display_name: "错误扫描器"
version: 1.0.0
description: "扫描 OpenClaw 日志和对话记录检测新错误模式。按需运行，输出结构化报告供 failure-memory 技能使用。不修改系统配置。"
triggers:
  - "scan errors"
  - "错误扫描"
  - "check logs"
  - "查找错误"
  - "error pattern"
tools:
  - exec
  - lcm_grep
  - lcm_describe
  - memory_recall
mutating: false
metadata:
  openclaw:
    emoji: "🔍"
    requires:
      bins: []
    deniedTools:
      - gateway
      - sessions_spawn
    configPaths: ["~/.openclaw/skills/error-scanner/"]
---

# Error Scanner

## Contract

1. **只读保证** — 本技能绝不修改日志文件、对话历史、系统配置或知识库。所有操作为只读扫描和查询。
2. **输入格式** — 接受一个日志文件路径（字符串）或对话 ID（数字/字符串），或留空以自动扫描最近会话。
3. **去重保证** — 同一错误模式的多次出现合并为一条记录，附带出现次数列表。
4. **幂等保证** — 同一输入多次运行产生相同输出（时间戳精细到分钟级，但结构化报告内容相同）。
5. **输出格式** — 输出结构化 `ErrorReport`，包含模式签名、严重度、首次发现时间、最新发现时间、出现次数和相关片段。

### 验收标准

- 给定一个已知错误模式的日志文件，报告包含该模式且正确标记其严重度
- 同一输入的两次连续运行输出语义相同（时间戳允许分钟级偏差）
- 空日志输入返回空报告（无崩溃）
- 无效路径/ID 返回明确的错误消息而非静默失败

## 执行步骤

### Step 1: 确定扫描范围

**输入：** 用户提供的日志路径 / 对话 ID / 空（默认自动）

**行为：**
- 如果提供了日志路径 → 检查文件存在性和可读性，记录路径
- 如果提供了对话 ID → 后续通过 `lcm_grep` 在该对话中搜索错误模式
- 如果留空（默认） → 自动确定范围：
  1. `exec("ls -t ~/.openclaw/logs/*.log 2>/dev/null | head -3")` — 检查最近 3 个日志文件
  2. `lcm_grep(pattern="error|exception|fail|crash", mode="full_text", sort="recency", limit=10)` — 搜索当前对话历史

**输出：** `ScanScope { type: "log"|"conversation"|"auto", sources: string[], resolved: boolean }`

**失败出口：** 所有日志路径都不存在且 LCM 返回空 → 返回空报告。

---

### Step 2: 加载已知错误模式

**输入：** 上一步的 ScanScope

**行为：**
1. `memory_recall(query="error patterns known failures", limit=5)` — 从长期记忆获取已知错误模式列表
2. 每个已知模式包含：`patternName`、`regex`（匹配正则）、`severity`（critical|high|medium|low）、`lastSeen`、`knownFix`

**输出：** `KnownPattern[]`（可能是空数组，首次运行无已知模式）

---

### Step 3: 搜索新错误

**输入：** ScanScope + KnownPattern[]

**行为 — 按范围类型分支：**

#### 分支 A: 日志文件扫描
1. 对每个日志源：
   ```python
   exec("grep -n -i -E '(error|exception|fail|crash|fatal|abort|panic|unhandled)' \"<path>\" | tail -200")
   ```
   (Windows: `Select-String -Pattern '(error|exception|fail|crash|fatal|abort|panic|unhandled)' -Path "<path>" -CaseSensitive:$false | Select-Object -Last 200`)
2. 解析匹配行，提取：时间戳、错误消息、堆栈摘要（第一行）

#### 分支 B: 对话扫描
1. `lcm_grep(pattern="error|exception|fail|crash|abort", mode="full_text", scope="both", sort="recency", limit=30)`
2. 对匹配到的关键摘要用 `lcm_describe(id="<summaryId>")` 获取完整上下文
3. 合并对话错误与已知模式

#### 分支 C: 混合扫描（自动模式）
先执行分支 B，如果结果少于 5 条，再执行分支 A 追加。

**输出：** `RawMatch[]`（未去重的原始匹配行列表）

---

### Step 4: 归类与去重

**输入：** RawMatch[] + KnownPattern[]

**行为：**
1. 对每条 RawMatch，提取规范化错误签名：
   - 移除时间戳、进程 ID、内存地址等易变部分
   - 保留错误类型 + 关键消息 + 文件名/模块名
2. 与 KnownPattern[].regex 逐一匹配：
   - 匹配 → 标记为已知模式，记录时间戳
   - 不匹配 → 标记为新发现模式，生成临时签名
3. 按签名分组，合并时间戳范围
4. 对新模式自动推断严重度：
   - 含 `fatal`/`panic` → `critical`
   - 含 `unhandled`/`exception`/`crash` → `high`
   - 含 `fail`/`timeout` → `medium`
   - 其余 → `low`

**输出：** `DeduplicatedPattern[]`

---

### Step 5: 生成结构化报告

**输入：** DeduplicatedPattern[]

**行为：** 构建以下结构的 JSON 报告：

```json
{
  "scanTimestamp": "2026-05-25T02:00:00+08:00",
  "scanScope": { "type": "auto", "sources": ["conv:current"] },
  "summary": { "total": 3, "new": 1, "known": 2, "critical": 0, "high": 1 },
  "patterns": [
    {
      "id": "err-001",
      "signature": "TypeError: Cannot read property 'x' of undefined",
      "severity": "high",
      "status": "new",
      "firstSeen": "2026-05-25T01:45:00+08:00",
      "lastSeen": "2026-05-25T01:45:00+08:00",
      "occurrences": 1,
      "sampleFragment": "at Object.run (src/engine.js:42:10)",
      "knownFix": null
    },
    {
      "id": "err-002",
      "signature": "ECONNREFUSED connect to localhost:8080",
      "severity": "medium",
      "status": "known",
      "firstSeen": "2026-05-20T10:00:00+08:00",
      "lastSeen": "2026-05-25T01:30:00+08:00",
      "occurrences": 5,
      "sampleFragment": "Error: connect ECONNREFUSED 127.0.0.1:8080",
      "knownFix": "检查 localhost:8080 服务是否启动"
    }
  ]
}
```

**输出：** 报告文本（控制台输出 + 内存暂存）

---

### Step 6: 写入输出文件

**输入：** 上一步生成的 JSON 报告字符串

**行为：**
1. 确定输出目录：`~/.openclaw/skills/error-scanner/output/`
2. 文件名：`scan-<YYYY-MM-DD-HHmmss>.json`
3. `exec("powershell -NoProfile -Command \"if (!(Test-Path '~/.openclaw/skills/error-scanner/output/')) { New-Item -ItemType Directory -Path '~/.openclaw/skills/error-scanner/output/' -Force }\"")` 确保输出目录存在
4. 将 JSON 写入文件

**输出：** 成功写入的文件路径

---

## 输出格式

最终输出按优先级依次为：

1. **摘要文本** — 一句话总结：「扫描了 N 个来源，发现 M 个错误模式，其中 X 个为新模式，Y 个为已知模式」
2. **严重度告警** — 如果有 critical/high 模式，高亮显示
3. **完整 JSON 报告** — 作为代码块内的格式化 JSON
4. **文件路径** — 「详细报告已保存至：<path>」

## 验证方式

运行以下测试：

```
# 测试 1：空日志输入
Input: path=/nonexistent/log.log
Expected: 空报告，{"patterns": []}

# 测试 2：已知错误输入
Input: 包含 TypeError 的日志片段
Expected: 报告包含 err-001，severity=high，status=new

# 测试 3：幂等性
Input: 相同日志文件运行两次
Expected: 两次输出语义相同（仅时间戳秒级不同）

# 测试 4：严重度推断
Input: 含 "fatal: out of memory" 的行
Expected: severity=critical
```

在终端执行：
```powershell
# 检查文件是否已创建
Test-Path "~/.openclaw/skills/error-scanner/SKILL.md"
```

## 反模式

- ❌ 不要修改日志文件或系统配置 — 本技能是只读的
- ❌ 不要在输出中包含完整的原始日志 — 使用摘要和片段引用
- ❌ 不要覆盖已有输出文件 — 每条扫描生成唯一文件名
- ❌ 不要对对话执行 `lcm_expand` 展开所有层次 — 仅展开匹配到的摘要
- ❌ 不要在技能内部调用 `sessions_spawn` 或 `gateway` — 这些工具在 skills 中被禁止
- ❌ 不要对已知错误模式重复告警 — 同一会话中同一模式只报告一次状态变更

## 依赖

- `exec` — 用于读日志文件和创建输出目录
- `lcm_grep` — 用于搜索对话历史中的错误
- `lcm_describe` — 用于展开匹配摘要获取完整上下文
- `memory_recall` — 用于加载已知错误模式
- 输出目录 `~/.openclaw/skills/error-scanner/output/` 在首次运行时自动创建
