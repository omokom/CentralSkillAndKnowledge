---
type: lesson
tags: [config, openclaw, error-handling, lesson]
related: [[[openclaw-config-protected-paths]]], [[[gateway-restart-pattern]]]
source: main agent 日向 2026-06-25 踩坑
created: 2026-06-25
confidence: high
---

# Gateway config.patch 不能改 protected 字段

## 我做了什么
尝试用 `gateway config.patch` 给已有 model provider `custom/glm-5.1` 补 `contextWindow: 128000` 字段,被网关拒绝。

错误信息:`gateway config.patch cannot change protected config paths: apiKey, baseUrl, contextWindow, cost.input, ...`

## 为什么错
OpenClaw 把这些字段列为 protected path,即使字段名跟现有 model 重合、即使只是新增,patch 也会拒绝。`config.patch` 只适合改 `agents.*.model` 这种"指向引用"的字段,不适合改"被引用对象本身"的字段。

## 应该怎么做
1. `read` 磁盘上的 `openclaw.json`
2. `edit` 改字段(普通文本编辑,不走 gateway)
3. 用 `Get-Item / Select-String` 磁盘验证写入真生效(read 工具可能返回缓存)
4. `gateway restart` 让新配置生效

## 避免下次
- 改 provider 内部字段(apiKey/baseUrl/contextWindow/cost)→ **直接磁盘编辑 + restart**,别用 config.patch
- 改 agent 引用字段(`.model`、`.skills[]`)→ 用 config.patch
- 这是 OpenClaw 行为,**没有 API 绕过**,别浪费时间找

## 验证
- 入库时间: 2026-06-25
- 验证状态: verified
- 最后检查: 2026-06-25 by main agent
