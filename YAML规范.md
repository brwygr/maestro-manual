# Maestro YAML 规范

> 一页纸讲清 Flow 文件的写法规则。所有示例都按 AIGun（`com.aigun.app`，Flutter）的场景写。

---

## 1. 文件解剖

一个 Flow 文件由 **头部（YAML map）** + **`---` 分隔符** + **步骤（YAML list）** 三部分组成：

```yaml
appId: com.aigun.app          # ← 头部：文件级配置
name: 01 冷启动冒烟
tags:
  - smoke
env:
  TIMEOUT: "30000"
---
- launchApp                    # ← 步骤：一行一个命令，本质是 list
- tapOn: '钱包[\s\S]*'
```

**硬规则：**

| 规则 | 说明 |
|---|---|
| 必须有 `---` | 少了它 = 解析失败，新手第一大坑 |
| 每个步骤以 `- ` 开头 | 是一个 YAML 数组元素 |
| `appId` 必填（或用 config.yaml 兜底） | 决定 `launchApp` 启动谁 |
| 缩进用 2 空格，不能用 Tab | YAML 语法 |
| 字符串含 `:`、`#`、`[`、`{` 时加引号 | 否则被当语法 |

---

## 2. 头部可用键

```yaml
appId: com.aigun.app
name: 钱包页冒烟
tags: [smoke, wallet]        # 也可以是 - 列表
env:                          # 文件内变量，${VAR} 引用
  TIMEOUT: "30000"
onFlowStart:                  # 前置钩子：整个 flow 开始前跑一次
  - runFlow: subflows/login.yaml
onFlowComplete:               # 后置钩子：结束后跑（清理、登出）
  - takeScreenshot: teardown
```

---

## 3. 命令目录（按用途记，别背）

### 生命周期
| 命令 | 写法 | 备注 |
|---|---|---|
| `launchApp` | `- launchApp` / `- launchApp: {clearState: true}` | **默认不清状态**；清了会掉登录 |
| `stopApp` / `killApp` | `- stopApp` | 区别：kill 更彻底，可带 `clearState` |
| `clearState` | `- clearState` | 只清数据不启动 |
| `back` | `- back` | 系统返回 |
| `pressKey` | `- pressKey: Enter` | Home/Back/Enter/Volume |

### 交互
| 命令 | 写法 |
|---|---|
| `tapOn` | `- tapOn: "文本"` / `- tapOn: {id: "x", index: 0, repeat: 2, delay: 200, optional: true}` |
| `longPressOn` | 参数同 tapOn |
| `doubleTapOn` | 同上 |
| `inputText` | `- inputText: "hello"` |
| `eraseText` | `- eraseText: 10`（删 10 个字符，不填=全清） |
| `hideKeyboard` | `- hideKeyboard` |
| `scroll` | `- scroll`（默认向下） |
| `scrollUntilVisible` | `- scrollUntilVisible: {element: "xxx", direction: DOWN, timeout: 20000, speed: 40}` |
| `swipe` | `- swipe: {direction: LEFT, duration: 500}` |

### 断言
| 命令 | 写法 | 备注 |
|---|---|---|
| `assertVisible` | `- assertVisible: "交易历史"` | 自带重试（默认约 5s） |
| `assertNotVisible` | `- assertNotVisible: "加载中"` | |
| `extendedWaitUntil` | `- extendedWaitUntil: {visible: "x", timeout: 30000}` | 长等待用这个，**不要 sleep** |
| `assertTrue` | `- assertTrue: ${output.count > 0}` | JS 表达式 |
| `assertWithAI` | `- assertWithAI: {assertion: "K线已渲染", optional: false}` | 实验性，截图上传 LLM |
| `assertScreenshot` | 视觉回归，需基线图 | 对像素敏感，慎用 |

### 证据
| 命令 | 写法 |
|---|---|
| `takeScreenshot` | `- takeScreenshot: 03-wallet`（落到测试产物目录） |
| `startRecording` / `stopRecording` | 录屏片段 |
| `copyTextFrom` | `- copyTextFrom: {id: "balance"}` → `${maestro.copiedText}` |

### 流程复用 / 控制
```yaml
- runFlow: subflows/login.yaml
- runFlow:
    file: subflows/open_tab.yaml
    env:
      TAB: 钱包
- runFlow:
    when:
      visible: "暂不开启"
    commands:
      - tapOn: "暂不开启"
- repeat:
    times: 3
    commands:
      - scroll
- retry:
    maxRetries: 2
    commands:
      - tapOn: "重试"
```

### 设备/环境
```yaml
- setPermissions: {all: deny}          # 或 {camera: allow}
- setDarkMode: true
- setOrientation: LANDSCAPE
- setLocation: {latitude: 31.23, longitude: 121.47}
- setAirplaneMode: true
- openLink: "aigun://intelligence/123"
- addMedia: ["./fixtures/a.png"]
```

---

## 4. 选择器（决定用例稳不稳）

```yaml
- tapOn: "文本"                    # 简写 = text 选择器
- tapOn: {text: ".*钱包.*"}         # 正则（全匹配）
- tapOn: {id: "wallet_receive_btn"} # 无障碍 identifier（Flutter 3.19+ 的 Semantics(identifier:)）
- tapOn: {index: 1}                 # 命中多个时取第几个（0 基）
- tapOn: {point: "50%,92%"}         # 坐标，最后手段
```

**关系选择器**（找不到唯一元素时很有用）：

```yaml
- tapOn:
    text: "交易"
    below: "LAUNCH"          # 或 above / leftOf / rightOf
- assertVisible:
    containsChild:
      text: "USDT"
```

**状态过滤**：

```yaml
- tapOn:
    text: "买入"
    enabled: true
```

**Flutter 必读**：Maestro 读 Semantics 树，节点文本常是拼接的：

```
"钱包\n第 5 个标签，共 5 个"
```

```yaml
- tapOn: 钱包          # ❌ 全匹配失败
- tapOn: '钱包[\s\S]*'  # ✅ 单引号 + 跨行正则
```

> 单引号是关键：YAML 双引号里 `\s` 是非法转义，直接报错。

---

## 5. 变量与 JS

```yaml
# 1) 命令行注入
# maestro test f.yaml -e EMAIL=qa@x.com
- inputText: ${EMAIL}

# 2) 文件头 env
env:
  EMAIL: "qa@x.com"

# 3) runFlow 传参
- runFlow:
    file: subflows/login.yaml
    env:
      EMAIL: ${EMAIL}

# 4) JS 计算
- evalScript: ${output.total = 0}
- evalScript: ${output.total = output.total + 1}
- assertTrue: ${output.total > 0}

# 5) 外部脚本
- runScript: scripts/check.js     # 里面写 output.xxx = ...
```

---

## 6. config.yaml（工作区级）

放在项目根目录或 `.maestro/` 下：

```yaml
flows:
  - "flows/*.yaml"
  - "!flows/_wip.yaml"        # ! 前缀 = 排除
includeTags: [smoke]           # 只跑这些标签
excludeTags: [flaky]
testOutputDir: maestro-output  # 截图/日志落这里
executionOrder:
  continueOnFailure: false
  flowsOrder: [01_smoke, 02_tabs]
platform:
  android:
    disableAnimations: true    # **仅 Cloud 生效**
```

CLI 的 `--include-tags` 会覆盖 config 里的设置。

---

## 7. 命名与目录规范（团队约定，建议照抄）

```
maestro/
├── config.yaml
├── flows/
│   ├── 01_smoke_launch.yaml        # 序号_模块_场景
│   ├── 02_bottom_tabs.yaml
│   └── 03_intel_to_trade.yaml
├── subflows/
│   ├── login.yaml                  # 复用片段，不会被单独跑
│   └── open_tab.yaml
├── scripts/
│   └── check.js
└── fixtures/
    └── avatar.png
```

- **flow 文件用序号前缀**：决定执行顺序 + 一眼看出层级
- **subflows 目录不匹配 `flows/*`**，避免被当用例跑
- **一条用例 ≤ 15 步**，长了就拆 subflow
- **断言写在关键节点**：页面进入后断言一个"只有这页有"的元素

---

## 8. 反模式（这几件事别做）

| 反模式 | 为什么错 | 改成 |
|---|---|---|
| `- sleep: 3000`（不存在该命令） | Maestro 没有 sleep；用 `extendedWaitUntil` | `- extendedWaitUntil: {visible: "x", timeout: 30000}` |
| 精确匹配 `- tapOn: 钱包` | Flutter 语义是拼接的 | `- tapOn: '钱包[\s\S]*'` |
| 到处 `point: "50%,50%"` | 换分辨率就挂 | 用 text/id + 关系选择器 |
| `clearState: true` | 掉登录，AIGun 要重新 OTP | 保持登录态，用测试号 |
| 用 `assertWithAI` 守关键业务 | 实验性，默认 `optional: true` 不阻断 | 关键断言用 `assertVisible` |
| 一条 flow 塞 40 步 | 失败定位难 | 拆 subflow + 分段截图 |
| 只断言"页面上有文字" | 弱断言，改版无感 | 断言业务结果（余额变化、状态标签） |

---

## 9. 提交前自查清单

- [ ] 有 `---`，缩进 2 空格、无 Tab
- [ ] 所有 Flutter 文案选择器用了 `'xxx[\s\S]*'`
- [ ] 没有 `clearState: true`（除非就是要测冷装）
- [ ] 长等待用 `extendedWaitUntil`，超时 ≥ 15s
- [ ] 弹窗类步骤都有 `optional: true` 或 `when`
- [ ] 关键节点有 `takeScreenshot`
- [ ] 单独跑过：`maestro test flows/0X.yaml`
- [ ] 全量跑过：`maestro test flows/`（顺序依赖没坏）
