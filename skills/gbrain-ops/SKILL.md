---
name: gbrain-ops
display_name: "GBrain 操作手册"
version: 1.0.0
description: |
  GBrain 知识引擎操作手册。覆盖嵌入、同步、worker 维护、查询、故障排查。
  GBrain 通过 OpenClaw 的 gbrain__* 工具集调用（非独立 CLI），
  工作区路径 ~/.openclaw/workspace/node_modules/gbrain v0.38.2。
  覆盖 skillification-criteria.md 的 C1/SC1-SC5/F1/F2 条件。
  不做：知识条目内容的编辑（由 knowledge-pipeline 负责）。Milvus 已于 2026-06-09 随容器移除而废弃。
triggers:
  - "gbrain"
  - "GBrain"
  - "知识引擎"
  - "brain 查询"
  - "gbrain 嵌入"
  - "gbrain 同步"
  - "gbrain worker"
  - "gbrain 故障"
  - "gbrain OOM"
  - "知识图谱"
  - "brain 页面"
  - "gbrain 迁移"
tools:
  - exec
  - read
  - write
mutating: false
metadata:
  openclaw:
    emoji: "🧠"
    layer: 1
    layer_label: "Atomic Skills"
    priority: high
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
    blast_radius:
      depends_on: [Milvus (向量存储), LM Studio (嵌入), Bun (编译运行时)]
      depended_by: [知识检索, 记忆召回, wiki_search, 技能路由]
      config_impact: [TOOLS.md (GBrain 配置), openclaw.json (subagent_model)]
      version_sensitive: true
    known_failures:
      - "worker 重启网关后掉线 → cron 自动拉起"
      - "大规模嵌入 OOM (1000+ 页) → 每日 cron 增量补齐"
      - "子代理模型默认 google/gemini 无 key → gbrain config set subagent_model custom-2/deepseek-v4-flash-beta"
      - "载荷超限 → 单次嵌入 ≤7KB 拆分"
---

# 🧠 GBrain Ops — GBrain 知识引擎操作手册

## Contract

1. **通过工具调用** — GBrain 操作通过 `gbrain__*` 工具集执行，不直接调用 CLI
2. **嵌入容量敏感** — 大量嵌入需增量处理
3. **worker 状态管理** — worker 掉线自动恢复
4. **配置变更后更新 TOOLS.md**

## 当前环境

| 参数 | 值 |
|------|-----|
| GBrain 版本 | v0.38.2 |
| 路径 | `~/.openclaw/workspace/node_modules/gbrain` |
| 调用方式 | OpenClaw 内置 `gbrain__*` 工具集 |
| 子代理模型 | `custom-2/deepseek-v4-flash-beta` |
| 嵌入模型 | Qwen3-Embedding-4B-Q8_0（LM Studio 本地） |

## 执行步骤

### Step 1: 状态检查

通过 `gbrain__*` 工具查询：
- `gbrain__get_brain_identity()` — 版本 + 引擎状态
- `gbrain__get_stats()` — 页面/块/嵌入计数
- `gbrain__get_health()` — 嵌入覆盖、过期页面、孤立页
- `gbrain__run_doctor()` — 结构化健康报告

### Step 2: 嵌入管理

**增量嵌入（日常）：**
- 由 daily cron 自动执行
- 小批量嵌入直接用 `gbrain__submit_job({name: "embed"})`

**大批量嵌入（>1000 页）：**
- 拆分为多个小任务
- 单次嵌入载荷 ≤7KB（超出拆分）
- 监控 `gbrain__get_job_progress(id)` 查看进度

**OOM 预防：**
- 如果 GBrain worker 进程崩溃（SIGKILL）
- 检查是否单次嵌入量过大
- 设置 cron 分时段增量补齐

### Step 3: Worker 维护

**已知问题：**
- 重启网关后 GBrain worker 可能掉线
- cron 应自动拉起（检查 cron 列表中是否有 gbrain-worker 拉起任务）

**手动检查：**
```powershell
# 查看 worker 状态
gbrain__list_jobs()
# 查看最近日志
gbrain__get_ingest_log()
```

### Step 4: 子代理模型配置

**如果 `gbrain__*` 工具报模型错误：**
```powershell
# 根因：默认模型无 key
# 修复：gbrain config set subagent_model custom-2/deepseek-v4-flash-beta
# 在 OpenClaw 中通过 TOOLS.md 记录配置值
```

### Step 5: 配置同步

修改 GBrain 配置后：
1. 执行 `backup-discipline` 备份 TOOLS.md
2. 更新 TOOLS.md 域二「GBrain 知识引擎」节
3. 更新 MEMORY.md 域一「环境快照」
4. 执行 `agent-file-update` 波及范围检查

## 常用操作速查

| 操作 | 工具 | 说明 |
|------|------|------|
| 搜索 | `gbrain__query(query, ...)` | 混合搜索（向量+关键词） |
| 读页 | `gbrain__get_page(slug)` | 获取页面内容 |
| 写页 | `gbrain__put_page(slug, content)` | 创建/更新页面 |
| 思考 | `gbrain__think(question)` | 多跳推理 |
| 搜索 | `gbrain__search(query)` | 全文检索 |
| 知识条目 | `gbrain__recall(entity)` | 回忆事实 |
| 链接 | `gbrain__traverse_graph(slug)` | 图遍历 |
| 异常 | `gbrain__find_anomalies()` | 活动异常检测 |
| 矛盾 | `gbrain__find_contradictions()` | 知识矛盾检测 |
| 专家 | `gbrain__find_experts(topic)` | 主题专家查找 |
| 医生 | `gbrain__run_doctor()` | 健康检查 |
| 文件 | `gbrain__file_upload(path)` | 上传文件到 brain |
| 文件 URL | `gbrain__file_url(storage_path)` | 获取文件 URL |

## 已知版本兼容性

| GBrain 版本 | 状态 | 备注 |
|-------------|:----:|------|
| v0.38.x | ✅ | 当前版本 |
| v0.37.x | ✅ | 兼容 |
| v0.36.x | ⚠️ | 可能有小变动 |

## 反模式（Anti-Patterns）

- 大批量嵌入不拆分 ❌
- worker 掉线时不检查 cron 是否拉起 ❌
- 修改配置后不更新 TOOLS.md ❌
- 用 `gbrain__submit_job` 提交任务后不检查进度 ❌
- 不知道当前版本就执行操作 ❌

## 验证方式

```powershell
# 验证 brain 状态
gbrain__get_brain_identity()
gbrain__get_health()
# 验证搜索
gbrain__query(query="test", limit=1)
```
