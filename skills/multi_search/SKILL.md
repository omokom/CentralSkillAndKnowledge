---
name: multi_search
description: 并行搜索多个知识源（对话历史、语义记忆、GBrain 知识图谱），合并排序返回。适用于跨知识源全面检索场景。
type: reference
tags: [search, retrieval, knowledge, lcm]
related: [[[gbrain-ops]], [[gbrain-skill]]]
source: "main agent - multi-source search pattern"
---

# multi_search — 多源合并搜索

## 架构概览

> 当前三层检索体系：
> - **L1** — LCM（FTS5 全文搜索，对话历史压缩存储）— `lcm_grep` / `lcm_expand_query`
> - **L2** — wiki_search（`corpus="wiki"` 搜 brain/ 文件，`corpus="memory"` 走 Milvus 搜语义记忆）
> - **L4/GBrain** — GBrain 直接工具（PostgreSQL + pgvector 知识图谱）

> ⚠️ 原 four-layer 模型中 Milvus 是独立层（L4/Milvus），现已被 `wiki_search(corpus="memory")` 统一接入。无需单独调用 Milvus 工具。

## 输入

- `query` : 搜索关键词（必填）
- `limit` : 每源返回最多 N 条（可选，默认 5）

## 执行步骤

当用户需要深度检索或跨知识源查询时，按以下三路**并行**搜索：

### 1. L1: 搜索对话历史

调用 `lcm_grep` 搜索压缩对话历史：

```
lcm_grep(
  pattern: query,
  mode: "full_text",      // 全文模式；正则用 "regex"
  scope: "both",          // 搜消息 + 摘要
  sort: "relevance",      // 相关性优先
  limit: 5
)
```

如果需要对结果深度展开，再用 `lcm_expand_query` 委托子代理提取确切内容。

### 2. L2: 搜索语义记忆 + 文件知识

**并行**调两轮 `wiki_search`（不同 corpus，互补去重）：

```
wiki_search(query=query, corpus="memory", maxResults=5)  // Milvus 语义记忆
wiki_search(query=query, corpus="wiki", maxResults=5)     // brain/ 文件知识
```

### 3. L4/GBrain: 搜索知识图谱

GBrain 工具已在 OpenClaw 直接注册，优先用 `gbrain__query`：

```
gbrain__query(query=query, limit=5, expand=true)
```

| 工具 | 用途 | 推荐场景 |
|------|------|---------|
| `gbrain__query` | 混合搜索（向量+关键词+多轮扩展） | **首选**，语义模糊查询 |
| `gbrain__search` | 关键词全文搜索 | 精确匹配已知术语 |
| `gbrain__think` | 多跳推理搜索 | 复杂跨页面推理 |

### 4. 合并排序

将上述源的结果合并去重后，使用 RRF（倒数排序融合）：

```
RRF_score = Σ(1 / (60 + rank_in_source))
k=60 为标准 RRF 常数
```

## 输出格式

```markdown
## 搜索结果：{query}

**[GBrain] · 标题** (score: 0.85)
来源: 知识图谱
摘要: ...

**[语义记忆] · 标题** (score: 0.72)
来源: Milvus 语义记忆
摘要: ...

**[对话历史] · 标题** (score: 0.60)
来源: LCM 对话记录
摘要: ...
```

## 注意事项

1. **并行调用** — 三路同时发出，不等上一路返回
2. **容错** — 任何源失败不影响其他源，跳过继续合并
3. **LCM 工具名** — 无 `__` 前缀（`lcm_grep`，不是 `lcm__grep`）
4. **GBrain 直接调用** — 无 MCP 前缀，直接 `gbrain__query` / `gbrain__search`
5. **Milvus 已内置** — `wiki_search(corpus="memory")` 底层即 Milvus，不需要单独脚本
6. **RRF k=60** — 标准参数，平衡高频源和低频源的权重
