# Maestro × AI 实操指南（针对 AIGun / Flutter）

> 目标：不是"用 AI 替代测试"，而是把 AI 放在**探索、写用例、修选择器**这三个最费人的环节，
> 让真正进 CI 的东西仍然是**确定性的 YAML**。

---

## 0. 先记住一句话

```
AI 负责「找得到、点得动、写得出来」    →  MCP / Studio / assertWithAI
CI 负责「每次都一样、失败必须红」      →  maestro test flows/*.yaml（纯 YAML，不烧 token）
```

一旦让 AI 断言承担关键业务校验（金额、订单状态、余额），你的流水线就会开始"随机红"。

---

## 1. 三条结合路径

### 路径 A：Maestro MCP（最推荐，日常主力）

Maestro CLI 内置了 MCP server，`maestro mcp` 一条命令就能让 Claude Code / Codex / Cursor / Copilot
直接操作你连着的模拟器：看屏幕、点、滑、断言、跑 flow，**边改边验**。

MCP 暴露的工具（CLI 2.12 实测 `tools/list` 返回 10 个，agent 自己会调，你不用背）：

| 工具 | 作用 |
|---|---|
| `list_devices` | 列出可用的模拟器/真机 |
| `inspect_screen` | 把当前界面导出成紧凑 JSON（元素树）—— agent 靠它拿真实选择器 |
| `take_screenshot` | 截图 |
| `run` | 执行 flow：内联 YAML / 指定文件 / 整个目录 |
| `cheat_sheet` | 返回 Maestro 命令速查表 |
| `open_maestro_viewer` | 返回 Maestro Viewer 地址，把设备画面嵌进 IDE/浏览器 |
| `list_cloud_devices` / `run_on_cloud` / `get_cloud_run_status` / `describe_cloud_run` | Maestro Cloud 相关（本地不用管） |

**配置（Windows，实测可用）：**

```powershell
# Claude Code
claude mcp add maestro -- "E:\maestro\maestro.cmd" mcp

# Codex CLI
codex mcp add maestro -- "E:\maestro\maestro.cmd" mcp

# Gemini CLI
gemini mcp add maestro "E:\maestro\maestro.cmd" mcp
```

```json
// Cursor: ~/.cursor/mcp.json ；Trae / VS Code 的 MCP 面板也是同一份结构
{
  "mcpServers": {
    "maestro": {
      "command": "E:\\maestro\\maestro.cmd",
      "args": ["mcp"]
    }
  }
}
```

> **两个 Windows 专有坑：**
>
> 1. **不用配 `JAVA_HOME`** —— `E:\maestro\maestro.cmd` 里已经把 JAVA_HOME 指向 JDK 17 了。
> 2 **Node 20+ 的客户端不能直接 spawn `.cmd`**（会报 `spawn EINVAL`）。遇到就包一层：
>
> ```json
> {
>   "mcpServers": {
>     "maestro": {
>       "command": "cmd",
>       "args": ["/c", "E:\\maestro\\maestro.cmd", "mcp"]
>     }
>   }
> }
> ```

**前提**：模拟器/真机必须已经起来（`adb devices` 能看到 `device`），否则 `list_devices` 返回空。

配好后重启 agent，先让它调一次 `list_devices`，再说 **"open the maestro viewer"**，设备画面就嵌进来了。

**它适合干什么：**

- 第一次摸一个页面，不知道有哪些元素、文案是什么 → 让它 `inspect_screen` 报给你
- flow 挂了，让它自己看现场、改选择器、重跑，直到绿
- 把一次手工探索"沉淀"成 `flows/xxx.yaml`

**它不适合干什么：**

- 每次 CI 都让它现场生成 → 不确定 + 烧 token
- 需要精确到像素/坐标的稳定回归

### 路径 B：AI 写用例，人 review，CI 只跑 YAML

这是最终形态。典型一天：

1. 用 MCP 让 agent 把流程走通（探索）
2. 让它"把刚才的步骤写成 `flows/07_xxx.yaml`，用我们 config 里的规范"
3. 你看一遍 YAML（人类 30 秒能读完，这就是 Maestro 选 YAML 的意义）
4. 进 CI：`maestro test flows/ --include-tags smoke`

### 路径 C：Flow 内嵌 AI 断言（实验性，慎用）

```yaml
- assertWithAI:
    assertion: K 线图已经渲染出来，并且至少有一根绿色蜡烛
    optional: false        # 默认 true，失败也不阻断，别指望它守门
```

- 原理：截图 → 上传 LLM → 返回 true/false，报告落在 `~/.maestro/tests/<时间戳>/ai-report-*.html`
- 适合：图表渲染、流式打字效果、空态/错误态、复杂视觉布局
- 不适合：金额、余额、订单状态、任何"错了要赔钱"的地方
- **隐私红线**：截图会上传，AIGun 的钱包地址/余额会一起上去 → 只在测试账号环境开

同类还有 `assertNoDefectsWithAI`（UI 缺陷检测）、`extractTextWithAI`（从截图抠结构化数据）。

---

## 2. 你这套环境怎么起（Windows）

```powershell
# 1) JDK 17（Maestro 硬要求，你机器上已有）
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-17'

# 2) CLI：已经给你放在工作区了，也可以装到 C:\maestro 并加 PATH
& 'E:\Work\AIGun\tools\maestro\bin\maestro.bat' --version

# 3) 连设备
adb devices                                  # 要有 emulator-5554  device
adb shell am start -n com.aigun.app/com.aigun.MainActivity

# 4) 跑用例
& 'E:\Work\AIGun\tools\maestro\bin\maestro.bat' test E:\Work\AIGun\maestro
```

常用命令：

```bash
maestro test flows/01_smoke_launch.yaml          # 单条
maestro test flows/ --include-tags smoke         # 按标签筛
maestro studio                                   # 可视化元素检查 + 点选生成 YAML
maestro test flows/ --format junit --output report.xml   # CI 报告
maestro record flows/01_smoke_launch.yaml        # 录成 mp4
```

---

## 3. 可以直接抄的提示词

**探索一个陌生页面：**

> 用 maestro 连上当前模拟器，打开 com.aigun.app。
> 依次进入底部 5 个 Tab（情报/追踪/Agent/交易/钱包），每个 Tab 用 inspect_screen 告诉我：
> 页面标题、可点击元素、以及一个"只有这个页面才有"的稳定文案。
> 先别写 flow。

**沉淀成用例：**

> 按 E:\Work\AIGun\maestro\config.yaml 的规范，写 flows/04_wallet_receive.yaml：
> 冷启动 → 钱包 Tab → 点「接收」→ 断言出现收款地址或二维码 → 截图 → 返回。
> 注意 AIGun 是 Flutter，底部 Tab 的 content-desc 是「钱包\n第 5 个标签，共 5 个」，
> 要用正则 '钱包[\s\S]*'，不要写死全串。

**修一条挂掉的 flow：**

> flows/03 在「限价单」这步超时了。用 inspect_screen 看现在停在哪，
> 判断是页面没跳转、还是文案变了，改选择器后重跑，直到通过；把你改了什么告诉我。

**加一个视觉断言：**

> 在 03 的 K 线区域后面加一个 assertWithAI，验证「图表已渲染且能看到蜡烛」，
> optional 保持默认 true，别让它阻断 CI。

---

## 4. AIGun 这个 App 的特殊坑（很关键）

| 坑 | 说明 | 对策 |
|---|---|---|
| **没有源码** | 只能靠 Semantics 里的文案，文案一改/一翻译就挂 | 用正则前缀 `'钱包[\s\S]*'`；长期解法是让客户端加 `Semantics(identifier:)`（Flutter 3.19+），然后 `id:` 选择器 |
| **Flutter 语义是拼接的** | 一个节点常是 `"机会\n第 1 个标签，共 4 个"` | 绝不用精确匹配，统一正则 |
| **Tab 由后端下发** | `option/tab`、`bottom-nav` 是 feature flag 驱动的，灰度用户可能少一个 Tab | 断言"存在"而不是"第 N 个"；或用 tags 分套件 |
| **登录态** | OTP/Privy，自动化登录很脆 | **绝不 `clearState`**；用已登录的模拟器跑；要隔离就用快照/专用测试号 |
| **启动慢** | SplashBoot 要域名探测 + session 恢复 + feature flags | `extendedWaitUntil` 给 30s，别用 `sleep` |
| **首启弹窗** | 「开启通知，别错过情报」 | 固定第一步 `tapOn: {text: '暂不开启', optional: true}` |
| **WebView 页面** | 邀请落地页等 H5 部分，Flutter 语义树里看不到 | 走 web 引擎单独测，或 `openLink` |

---

## 5. 建议的分层（别一上来全 AI）

```
L1 冒烟（每天/每 PR）      纯 YAML，5 条以内，2 分钟内       ✅ 已有 01/02/03
L2 核心链路（每晚）        纯 YAML，情报→交易→钱包→AI 对话   ← AI 帮你写，人来维护
L3 视觉/文案巡检（每周）    assertWithAI / assertNoDefects   ← 实验性，失败不阻断
L4 探索（改版时）          MCP 现场点点点，产出新 flow        ← 完全交给 agent
```

**成本参考**：L1+L2 跑一次 0 token；MCP 探索一轮大概几万 token；assertWithAI 每张截图一次调用。

---

## 6. 下一步（如果你想继续）

1. `maestro studio` 打开，亲手点一遍 → 它会把点击翻译成 YAML，比看文档快
2. 把 MCP 接进你常用的 agent，让它把 `flows/04`、`05` 补齐（AI 对话、钱包收款、设置改语言）
3. 补 CI：GitHub Actions 里 `maestro test flows/ --include-tags smoke`，失败上传 `~/.maestro/tests` 里的截图和 mp4
4. 真要长期维护，推动客户端给关键控件加 `Semantics(identifier: 'wallet_receive_btn')` —— 这是投入产出比最高的一步
