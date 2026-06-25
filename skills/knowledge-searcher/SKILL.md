---
name: knowledge-searcher
version: 1.0.0
description: "知识搜索技能。通过文件检索、gbrain__* 工具集等方式，从本地知识库、wiki_search 语义记忆和 GBrain 知识图谱中搜索信息。适用于跨来源的知识检索场景。不做：直接修改知识库内容、非查询类文件操作。"
triggers:
  - "搜索"
  - "查找知识"
  - "查询"
  - "检索"
  - "知识库查询"
  - "查一下"
  - "找资料"
  - "搜一下"
tools:
  - read
  - write
  - edit
  - exec
  - gbrain__query
  - gbrain__search
  - gbrain__think
mutating: false
metadata:
  codex:
    emoji: "🔍"
---

# 🔍 Knowledge Searcher — 多源知识搜索

## 职责

在接到搜索需求时，从多个知识源中定位相关信息并返回摘要。

## 可用的知识源（按优先级排序）

| 优先级 | 来源 | 途径 | 命令/方法 |
|--------|------|------|----------|
| P1 | 本地知识库文件 | `read` | 直接读 `knowledge/` 目录下的 wiki 条目和笔记 |
| P2 | GBrain 知识图谱 | `gbrain__query`/`gbrain__search` | `gbrain__query(query=..., limit=5)` |
| P3 | 语义记忆 | `wiki_search(corpus="memory")` | `wiki_search(query=..., corpus="memory")` |
| P4 | 工作区文件全文 | `exec` + `Select-String` | PowerShell 全文搜索 |
| P5 | 项目文档 | `read` | 读 `Docs/` 目录下的策划文档 |

> ⚠️ Milvus 向量库源已于 2026-06-09 废弃（容器已移除），语义记忆检索改用 `wiki_search(corpus="memory")`。

## 搜索工作流

### 步骤 1：确定搜索范围和关键词
1. 从任务描述中拆解出搜索意图
2. 提取 2-5 个核心关键词
3. 判断是否需要跨源搜索

### 步骤 2：搜索知识库文件（P1）
```
exec("Get-ChildItem -Path C:\Users\lixin\.openclaw\workspace\knowledge -Recurse -Name | Select-String \"<关键词>\"")
```
或直接读取已知路径的知识文件。

### 步骤 3：搜索 GBrain 知识图谱（P2）
```
gbrain__query(query="<自然语言问题>", limit=5, expand=true)
```
或精确匹配：
```
gbrain__search(query="<关键词>", limit=5)
```
复杂推理：
```
gbrain__think(question="<复杂问题>")
```

### 步骤 4：搜索语义记忆（P3）
```
wiki_search(query="<关键词>", corpus="memory", maxResults=5)
```

### 步骤 5：全文搜索工作区（P4）
```
exec("Select-String -Path \"C:\\Users\\lixin\\.openclaw\\workspace\\**\\*.md\" -Pattern \"<关键词>\" -SimpleMatch | Select-Object -First 20")
```

### 步骤 6：整理结果
1. 合并各来源结果，去重
2. 按相关度排序
3. 标注来源（文件路径/API/来源名）
4. 输出摘要 + 详细引用

## 输出格式

```
【搜索结果】<相关度: 高/中/低>
来源: <文件路径/API接口>
结果摘要: <一句话概括>
详细内容: <粘贴关键段落>
```

## 注意事项

- ⚠️ GBrain 查询用 `gbrain__query`（模糊/语义）或 `gbrain__search`（精确关键词）
- ⚠️ 复杂跨页面推理用 `gbrain__think`
- ⚠️ 语义记忆（原 Milvus）改用 `wiki_search(corpus="memory")`
- ⚠️ 搜索结果超 20 条时，只返回前 20 条最相关的
- ⚠️ 找不到结果时不要编造，返回"未找到匹配信息"
- ⚠️ 尊重 AGENTS.md 铁律 4：搜索结果必须标注来源和置信度
