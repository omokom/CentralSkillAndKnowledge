---
type: note
tags: [random]
related: []
source: 随手记
created: 2026-06-25
confidence: low
---

# 今天看了一下 xxxxx

今天跟主人聊了一些东西。我发现了一些有意思的事。

主要是要记录一下。

以后用到再说。
```

## 为什么这是反模式

1. **type=note 但没有具体场景** — 主人哪天回来根本不知道这页在说啥
2. **tags=[random] 无意义** — 跟"无标签"没区别
3. **related: [] 空数组** — 这是 **绝对禁止** 的状态。要么填 wikilink,要么写 `[孤岛]` 显式说明
4. **正文纯散文,无结构** — 检索时 chunk 化会切成 1-2 段,语义搜索命中率低
5. **source 太模糊** — "随手记" 哪天想追溯原始上下文找不到
6. **confidence: low** — 没错,但你 low 还不写说明,等于没标

## 修复版本

```yaml
---
type: note
tags: [具体标签,如 unity-physics, debugging]
related: [[[已有相关 page slug]]], [[[另一个]]]
source: main agent 2026-06-25 跟主人讨论 X 主题时的对话记录
created: 2026-06-25
confidence: low
---

# X 主题讨论记录

## 场景
2026-06-25 跟主人讨论 X 主题。

## 关键发现
- 发现 1
- 发现 2

## 关联
- 相关 page: [[[已有相关]]]

## 验证
- 入库时间: 2026-06-25
- 验证状态: pending
```
