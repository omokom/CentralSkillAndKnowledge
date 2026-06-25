---
type: concept
tags: [unity, physics, engine, game-dev]
related: [[[unity-game-development]]], [[[rigidbody-component]]], [[[collision-detection]]]
source: codex agent 2026-06-25 任务中总结
created: 2026-06-25
confidence: high
---

# Box2D 物理引擎

## 定义
Box2D 是一款 2D 刚体物理引擎,广泛用于 Unity 和其他游戏引擎,处理碰撞检测、刚体动力学、关节约束等。

## 关键要点
- 纯 C++ 实现,Unity 版本通过 C# wrapper 调用
- 固定时间步 1/60s,不能改
- 单位建议米/千克,大数会失真
- 不支持 3D(那是 PhysX 的事)

## 详细内容
Box2D 内部使用 SAT(Separating Axis Theorem) 做碰撞检测,Sweep and Prune 做 broad phase,Impulse 序列解算器做 constraint solver。

Unity 里通常用 [[unity-2d-physics]] 替代(基于 PhysX 2D),但在性能敏感或需要精确控制时仍会嵌入 Box2D。

## 关联
- 父概念: [[game-physics-engine]]
- 子概念: [[box2d-shape-types]], [[box2d-joint-types]]
- 兄弟概念: [[chipmunk-physics]], [[unity-physx-2d]]

## 验证
- 入库时间: 2026-06-25
- 验证状态: verified
- 最后检查: 2026-06-25 by codex agent
