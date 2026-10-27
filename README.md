# Maestro 移动端 E2E 中文手册

> 基于一个真实 **Flutter App（Android）** 的实操总结：从装 CLI、用 Studio 点出第一条用例，到写出可维护的 YAML，再到用 AI（MCP）加速探索与修复。

Maestro 是 mobile-dev-inc 开源的 UI 自动化框架（Apache-2.0），用 YAML 描述流程，走系统无障碍层驱动 App，**不需要驱动、不需要编译、不侵入业务代码**。

- 官方仓库：https://github.com/mobile-dev-inc/Maestro
- 官方文档：https://docs.maestro.dev

## 目录

| 文档 | 讲什么 | 适合谁 |
|---|---|---|
| [新手教学](./新手教学.md) | 从零到第一条能跑的 Flow：YAML 三块结构、4 条常用命令、怎么找文案、Studio 右键、Flutter 拼接坑 | 完全没接触过 |
| [快速上手](./快速上手.md) | Maestro 由哪几块组成、CLI 与 Studio 怎么装、Studio 五步点出第一条用例、Flow 最小结构、常用命令 | 第一次接触，想先跑起来 |
| [YAML 规范](./YAML规范.md) | 文件解剖、命令目录、选择器、控制流、变量与 JS、config.yaml、命名约定、反模式、自查清单 | 要写、要 review、要进 CI |
| [AI 使用指南](./AI-使用指南.md) | Maestro MCP 接入、AI 写用例/修选择器、assertWithAI 的边界、提示词模板 | 想把 AI 接进测试流程 |

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
maestro test examples/
```

## 示例

[`examples/`](./examples) 里是三条可直接运行的 Flow，对应手册中提到的场景：

- `01_smoke_launch.yaml` — 冷启动冒烟（含首启弹窗处理）
- `02_bottom_tabs.yaml` — 底部 5 个 Tab 巡检
- `03_intel_to_trade.yaml` — 跨页面业务链路
- `04_wallet_receive.yaml` — 钱包收款地址（手写模板，逐行注释）
- `05_wallet_bnb.yaml` — 同 04 换 BNB Chain（练习用，只差一行）

> `appId` 用的是示例 App（`com.aigun.app`），换成你自己的包名即可；选择器写法可原样复用。

## 适用范围

- 验证环境：Maestro CLI 2.11.x、Windows 10、Android 15 模拟器、Flutter 3.x
- 结论均来自实测，但 Maestro 迭代较快，命令参数以[官方文档](https://docs.maestro.dev)为准
- 移动端为主，Web 场景同样适用（引擎换成 Chromium）

## 一句话总结

```
AI 负责「找得到、点得动、写得出来」  → MCP / Studio / assertWithAI
CI 负责「每次都一样、失败必须红」    → maestro test flows/*.yaml（纯 YAML，不烧 token）
```

## License

文档内容可自由使用、修改、转载，注明出处即可。



