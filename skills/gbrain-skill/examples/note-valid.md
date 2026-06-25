---
type: note
tags: [infra, cron, debugging, openclaw]
related: [[[gbrain-embed-cron-failure]]], [[[deepseek-billing-error]]], [[[openclaw-gateway-restart]]]
source: main agent 日向 2026-06-25 对话
created: 2026-06-25
confidence: high
---

# gbrain cron 恢复实战 2026-06-25

## 现象
所有 gbrain 相关 cron 持续 5 天失败,master 报 `custom-1 (deepseek-v4-flash) returned a billing error`。

## 根因
deepseek-v4-flash API key 欠费。

## 解决
1. 重启 pm2 `embedding-proxy` worker(僵死 5 天)
2. 取消 32 个卡死 waiting job
3. 把所有引用 deepseek-v4-flash 的位置(`agents.defaults.model.primary` 等 6 处)替换为 `custom/glm-5.1`
4. gateway restart
5. 手动跑 `cron run --force` 验证 → ok

## 关联
- 教训: [[api-billing-exhaustion-pattern]]
- 概念: [[gbrain-deployment-architecture]], [[openclaw-model-provider]]
- 流程: [[openclaw-gateway-restart-procedure]]

## 验证
- 入库时间: 2026-06-25
- 验证状态: verified
- 最后检查: 2026-06-25 by main agent
