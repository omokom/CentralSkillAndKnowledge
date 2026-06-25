---
name: file-organization-standards
display_name: "文件组织规范"
version: 1.0.0
layer: 2
layer_label: "Workflow Library"
priority: normal
description: "文件组织与项目维护规范。定义工作空间文件存放标准、待办事项管理（单一来源原则）、文件创建决策树、命名规范、去重合并规则、清理归档策略。触发词：文件组织、文件规范、待办管理、项目维护、归档清理。"
triggers:
  - "文件组织"
  - "文件规范"
  - "文件命名"
  - "待办管理"
  - "项目维护"
  - "归档清理"
  - "去重合并"
  - "文件登记"
tools:
  - read
  - write
  - edit
  - exec
mutating: true
needsCleanup: false
depends_on: []
cross_agent: true
governance:
  auto_cleanup_days: 0
  min_judge_score: 65
metadata:
  openclaw:
    emoji: "📁"
    requires:
      bins: []
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
---

# 📁 File Organization Standards — 文件组织与项目维护规范

## Contract

1. **触发条件**：需要新建文件、创建待办、生成文档、清理归档时
2. **铁律 8 强制**：违反本规范被 AGENTS.md 铁律 8 捕获
3. **输入**：待创建/修改的文件描述
4. **输出**：目标路径 + 命名建议 + 登记要求

---

## 1. 工作空间标准结构

```
C:\Users\lixin\.openclaw\
├── workspace/
│   ├── notes/
│   │   ├── sessions/          # 会话笔记 (YYYY-MM-DD--<标签>.md)
│   │   ├── learnings/         # 学习笔记 (YYYY-MM-DD--<标签>.md)
│   │   └── README.md          # 笔记模板说明
│   ├── projects/              # 项目专属文件
│   │   ├── project-status.md  # 所有项目状态和待办总索引 ★
│   │   ├── <project-A>/       # 项目A文档、设计、数据
│   │   └── <project-B>/
│   ├── skills/                # 技能定义（由技能管理工具维护）
│   ├── staging/               # 临时区，任务完成后必须清理
│   └── archive/               # 归档 (过时会话笔记、废弃项目)
├── knowledge/
│   ├── brain/                 # 成熟知识理论
│   └── wiki/                  # 结构化 wiki 条目
├── analytics/
│   └── metrics.db             # 系统指标
├── .audit/                    # 审计日志
├── openclaw.json              # 主配置
└── MEMORY.md, AGENTS.md 等    # 核心指令文件
```

## 2. 待办事项管理（单一来源原则）

- **唯一索引文件**：所有待办事项、项目状态、活跃任务必须统一记录在 `workspace/projects/project-status.md` 中
- **格式要求**：`- [ ] <任务描述> | 优先级: P0-P3 | 截止: <日期> | 状态: <进行中/阻塞/完成>`
- **禁止**：在聊天记录、代码注释、临时文件、桌面便签中单独维护待办
- **更新时机**：任务创建时、状态变更时、门禁 4 交付时

## 3. 文件创建决策树

```
需要创建新文件？
  ├─ 是待办/状态更新？ → 写入 project-status.md（不新建文件）
  ├─ 是会话记录/学习笔记？ → 存入 notes/sessions/ 或 notes/learnings/
  ├─ 是项目文档/设计稿/数据？ → 存入 projects/<项目名>/
  ├─ 是技能或配置？ → 交由对应工具管理，不手动建
  ├─ 是临时中间文件？ → 存入 staging/，任务结束后清理
  └─ 不确定？ → 先在门禁 0 中标注，等门禁 2 方案确认路径
```

## 4. 文件命名规范

- 笔记类：`YYYY-MM-DD--<简短标签>.md`
- 项目文档：`<项目名>--<内容描述>.ext`
- 备份文件：`<原文件名>.bak.<日期>`
- 禁止：空格、特殊字符、无意义数字串

## 5. 去重与合并规则

- 创建前必须搜索确认没有同类文件
- 相似度 >0.7 必须合并（追加而非新建）
- 合并后删除旧文件，更新 project-status.md

## 6. 清理与归档

- 门禁 5 执行时：检查 `staging/`，删除 >24h 的临时文件
- 每日：`notes/sessions/` >50 条 → 归档提醒
- 项目：>30 天无更新 → 移入 `archive/`，标记 `[已归档]`
- 周检：weekly-housekeeping 扫描同名或高度相似文件

## 7. 文件登记强制

- 任何新建持久文件必须在创建后 5 分钟内更新 `project-status.md`
- 门禁 4 终检时必须验证文件登记情况

## 反模式

- ❌ 不搜索现有文件直接新建
- ❌ 在非标准位置创建持久文件
- ❌ 多个项目状态文件并存
- ❌ 临时文件不清理
