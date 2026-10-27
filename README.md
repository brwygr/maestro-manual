# Maestro 移动端 E2E 中文手册

> 基于一个真实 **Flutter App（Android）** 的实操总结：从装 CLI、用 Studio 点出第一条用例，到写出可维护的 YAML，再到用 AI（MCP）加速探索与修复。

Maestro 是 mobile-dev-inc 开源的 UI 自动化框架（Apache-2.0），用 YAML 描述流程，走系统无障碍层驱动 App，**不需要驱动、不需要编译、不侵入业务代码**。

- 官方仓库：https://github.com/mobile-dev-inc/Maestro
- 官方文档：https://docs.maestro.dev

## 文档

全部内容合并成了一份：[**新手教学.md**](./新手教学.md)

| 章节 | 讲什么 |
|---|---|
| 一、起步 | Maestro 是什么、装 CLI / Studio / Java、第一条用例（Studio 右键 + 手写） |
| 二、写用例 | Flow 三块结构、命令速查、选择器、控制流与复用、变量、断言、config.yaml |
| 三、组织与维护 | 模块 / 优先级 / 套件、已有用例怎么跑、CI、元素变了怎么修、反模式 |
| 四、AI | MCP 接入、提示词模板、分层策略 |
| 附录 | 排错速查、本项目专属的坑、常用命令一览 |

> 想直接看某一块，文档开头有目录，点锚点跳转。

## 快速开始

```powershell
# 1) 需要 Java 17+
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-17'

# 2) 装 CLI（Windows：下载 zip 解压后把 bin 加进 PATH）
#    https://github.com/mobile-dev-inc/maestro/releases/latest/download/maestro.zip
maestro --help

# 3) 确认设备在线
adb devices

# 4) 跑示例
cd examples; maestro test flows/
```

## 示例

[`examples/`](./examples) 里是五条可直接运行的 Flow：

- `flows/01_smoke_launch.yaml` — 冷启动冒烟（含首启弹窗处理）
- `flows/02_bottom_tabs.yaml` — 底部 5 个 Tab 巡检
- `flows/03_intel_to_trade.yaml` — 跨页面业务链路
- `flows/04_wallet_receive.yaml` — 钱包收款地址（手写模板，逐行注释）
- `flows/05_wallet_bnb.yaml` — 同 04 换 BNB Chain（练习用，只差一行）

配套：

| 路径 | 作用 |
|---|---|
| `examples/subflows/_open_wallet.yaml` | 公共步骤（Maestro 版「页面对象」） |
| `examples/config.yaml` | 全量套件 |
| `examples/config-smoke.yaml` | 冒烟套件（只跑 `p0`） |
| `examples/config-regression.yaml` | 回归套件（只跑 `p1`） |
| `examples/run.ps1` | 一键跑用例脚本 |

> `appId` 用的是示例 App（`com.aigun.app`），换成你自己的包名即可；选择器写法可原样复用。

## 适用范围

- 验证环境：Maestro CLI 2.12.x、Windows 10、Android 15 模拟器、Flutter 3.x
- 结论均来自实测，但 Maestro 迭代较快，命令参数以[官方文档](https://docs.maestro.dev)为准
- 移动端为主，Web 场景同样适用（引擎换成 Chromium）

## 一句话总结

```
AI 负责「找得到、点得动、写得出来」  → MCP / Studio / assertWithAI
CI 负责「每次都一样、失败必须红」    → maestro test flows/*.yaml（纯 YAML，不烧 token）
```

## License

文档内容可自由使用、修改、转载，注明出处即可。
