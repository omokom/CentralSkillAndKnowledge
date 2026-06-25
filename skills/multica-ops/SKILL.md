---
name: multica-ops
version: 1.1.0
description: |
  Multica Agent Runtime 操作手册。覆盖 daemon 管理、agent 操作、配置查看、
  故障排查。Multica 是本地 Agent 运行时，通过 CLI 管理 agents/issues/projects。
  覆盖 skillification-criteria.md 的 C1/SC1-SC5/F1/F2 条件。
  不做：OpenClaw 配置修改、其他外部工具操作。
triggers:
  - "multica"
  - "Multica"
  - "agent runtime"
  - "multica daemon"
  - "multica agent"
  - "multica issue"
  - "multica 配置"
  - "multica 故障"
  - "multica 日志"
  - "multica model"
  - "multica 模型"
  - "agent model"
  - "agent create"
tools:
  - exec
  - read
mutating: false
metadata:
  openclaw:
    emoji: "🤖"
    layer: 1
    layer_label: "Atomic Skills"
    priority: high
    requires:
      bins: [multica]
    deniedTools:
      - gateway
      - cron
      - sessions_spawn
    blast_radius:
      depends_on: [本地 HTTP 服务 (port 8080)]
      depended_by: [Hermes, agent 编排]
      config_impact: ["~/.multica/config.json"]
      version_sensitive: true
    known_failures:
      - "daemon 进程存活但无监听端口 → 重新启动 daemon"
      - "认证错误 (401) → 检查 token 是否有效"
      - "config.json 中 server_url/app_url 指向 localhost，需本地服务运行中"
      - "agent model 填错格式: 用了 OpenClaw 别名 (custom-1/xxx)，OpenCode 要求 provider/model (deepseek/xxx)"
type: workflow
tags: [multica, agent-runtime, daemon, operations]
related: [[[agent-file-update]]]
source: "main agent - Multica runtime operations"
---

# 🤖 Multica Ops — Multica Agent Runtime 操作手册

## Contract

1. **只读优先** — 查询操作为主，agent 创建等写操作需额外确认
2. **daemon 状态是关键** — 大部分问题源于 daemon 未正确运行
3. **配置本地服务** — server_url 指向 localhost:8080，需本地服务运行

## 当前环境

| 参数 | 值 |
|------|-----|
| Multica 版本 | v0.3.12 |
| 二进制路径 | `C:\Users\lixin\.multica\bin\multica.exe` |
| 配置文件 | `~/.multica/config.json` |
| 日志文件 | `~/.multica/daemon.log` |
| Daemon PID 文件 | `~/.multica/daemon.pid` |
| Server URL | `http://localhost:8080` |
| App URL | `http://localhost:3000` |
| 工作区 ID | `50e24bb7-8eda-4b24-a98e-8831387b9771` |

## 执行步骤

### Step 1: 状态检查

```powershell
# 检查 daemon 进程
Get-Process -Name "multica" -ErrorAction SilentlyContinue
Get-Content "C:\Users\lixin\.multica\daemon.pid" -ErrorAction SilentlyContinue

# 检查监听端口
netstat -ano | findstr ":8080"

# 检查日志尾部
Get-Content "C:\Users\lixin\.multica\daemon.log" -Tail 10
```

### Step 2: Daemon 管理

**启动 daemon：**
```powershell
& "C:\Users\lixin\.multica\bin\multica.exe" daemon start --foreground
```

**停止 daemon：**
```powershell
& "C:\Users\lixin\.multica\bin\multica.exe" daemon stop
```

**检查 daemon 状态：**
```powershell
& "C:\Users\lixin\.multica\bin\multica.exe" daemon status
```

### Step 3: Agent 操作

```powershell
# 列出 agents
& "C:\Users\lixin\.multica\bin\multica.exe" agent list

# 查看 agent 详情
& "C:\Users\lixin\.multica\bin\multica.exe" agent get <agent-id>
```

### ⚠️ 重要: 模型命名空间隔离

**Multica 的 runtime 是 OpenCode**，模型参数使用 `<provider>/<model-id>` 格式，**不是** OpenClaw 内部别名。

| 环境 | 格式 | 示例 |
|------|------|------|
| OpenClaw 内部 | `custom-<N>/<别名>` | `custom-1/deepseek-v4-flash` |
| **OpenCode (Multica runtime)** | **`<provider>/<model-id>`** | **`deepseek/deepseek-v4-flash`** |
| Hermes ACP | `<provider>/<model-id>` | `nvidia/nemotron-4-340b-instruct` |

**创建 agent 时指定 model：**
```powershell
# ✅ 正确（OpenCode 格式）
& "C:\Users\lixin\.multica\bin\multica.exe" agent create --name "MyAgent" --runtime-id <id> --model deepseek/deepseek-v4-flash

# ❌ 错误（OpenClaw 格式，不会工作）
& "C:\Users\lixin\.multica\bin\multica.exe" agent create --name "MyAgent" --runtime-id <id> --model custom-1/deepseek-v4-flash
```

**更新已有 agent 的 model：**
```powershell
& "C:\Users\lixin\.multica\bin\multica.exe" agent update <agent-id> --model deepseek/deepseek-v4-flash
```

**可用 OpenCode 模型查看：**
```powershell
opencode models
```

### Step 4: 项目与 Issue 操作

```powershell
# 列出项目
& "C:\Users\lixin\.multica\bin\multica.exe" project list

# 列出 issues
& "C:\Users\lixin\.multica\bin\multica.exe" issue list

# 创建工作区
& "C:\Users\lixin\.multica\bin\multica.exe" workspace list
```

### Step 5: 故障排查

**故障 A：Daemon 进程在但无监听端口**
- **检查**：`netstat -ano | findstr ":8080"` 无结果
- **修复**：`daemon stop` → `daemon start --foreground`
- **验证**：`netstat -ano | findstr ":8080"` 有监听

**故障 B：认证错误 (401)**
- **检查**：`Get-Content "C:\Users\lixin\.multica\config.json"` 看 token 是否存在
- **修复**：token 过期需重新登录或配置新 token
- **验证**：`multica agent list` 返回正常

**故障 C：配置文件缺失**
- **检查**：`Test-Path "C:\Users\lixin\.multica\config.json"`
- **修复**：重新运行 multica 初始化流程

### Step 6: 日志分析

```powershell
# 搜索日志中的错误
Select-String -Path "C:\Users\lixin\.multica\daemon.log" -Pattern "error|fail|panic" -CaseSensitive -SimpleMatch | Select -First 20

# 按时间查看
Get-Content "C:\Users\lixin\.multica\daemon.log" -Tail 50
```

## 常用命令速查

| 命令 | 用途 |
|------|------|
| `multica agent list` | 列出 agents |
| `multica agent get <id>` | 查看 agent 详情 |
| `multica issue list` | 列出 issues |
| `multica project list` | 列出项目 |
| `multica repo list` | 列出仓库 |
| `multica skill list` | 列出技能 |
| `multica squad list` | 列出团队 |
| `multica workspace list` | 列出工作区 |
| `multica daemon start --foreground` | 启动 daemon |
| `multica daemon stop` | 停止 daemon |
| `multica daemon status` | 查看 daemon 状态 |

## 反模式（Anti-Patterns）

- daemon 没启动就执行 agent 操作 ❌
- 不检查 daemon.log 就猜问题 ❌
- 直接编辑 config.json 改 token（应用重启会覆盖）❌
- 不知道当前 multica 版本就操作 ❌
- 给 Multica agent 设 model 时用 OpenClaw 的 `custom-1/xxx` 格式 ❌
  （正确：先确定 agent 的 runtime 是 OpenCode 还是 Hermes，再用对应格式）

## 模型名验证方式

```powershell
# 检查 agent 当前的 model 是否用了正确格式
& "C:\Users\lixin\.multica\bin\multica.exe" agent list --json | ConvertFrom-Json | Select-Object name, model

# 如果 model 包含 "custom-" 前缀 → 格式错误，需要改
```

## 验证方式

```powershell
# 验证 daemon 运行
Get-Process -Name "multica" -ErrorAction SilentlyContinue | Format-Table Id, StartTime
# 验证 CLI 可用
& "C:\Users\lixin\.multica\bin\multica.exe" --version
# 验证连接
netstat -ano | findstr ":8080"
```
