# 2026 MoonBit 8月黑客松项目申报书

## 项目基本信息

- 项目名称：edidkit
- 项目类型：原创 MoonBit 开源库
- 参赛者：陈旭日
- 手机号：15717687695
- GitHub 账户：BenPaoBaMingWangXing
- 代码仓库：`https://github.com/BenPaoBaMingWangXing/edidkit`
- Mooncakes 包名：`BenPaoBaMingWangXing/edidkit`
- 开源许可证：MIT

## 项目背景与价值

EDID 是显示器、投影仪、嵌入式屏幕、采集设备、KVM、显示模拟器等硬件向主机暴露显示能力的基础数据。硬件调试、驱动适配、板卡 bring-up、显示兼容性测试和固件 QA 中，经常需要快速确认 EDID 的厂商信息、校验和、首选分辨率、时序范围和兼容性边界。

`edidkit` 计划提供一个 MoonBit 原生的 EDID 解析与审计库，填补 MoonBit 生态中显示硬件数据解析工具的空白。项目可用于命令行工具、硬件测试脚本、WebAssembly 在线分析器、CI 质量检查和后续 DisplayID/CTA 扩展解析库。

## 现有基础

项目已完成 MoonBit 包结构、MIT 许可证、README、GitHub Actions CI、示例命令、测试用例和核心实现。当前实现已经包含 EDID 十六进制输入解析、128 字节 base block 校验、厂商与产品信息解析、显示输入与基本参数解析、色度坐标解析、established/standard/detailed timing 解析、显示模式归一化、时序目录匹配、审计 profile、文本/Markdown/JSON 报告输出和自包含测试样例。

截至 2026-08-11，本地有效 MoonBit 代码量已超过 4000 行，测试覆盖解析、错误处理、显示模式、审计、报告、时序目录和 profile matrix。

## 本次计划开发或新增内容

本次黑客松计划围绕 `edidkit` 完成可验收的 MoonBit 开源库：

- 完善 EDID base block 解析和诊断边界。
- 扩展常见显示时序目录，用于 DMT/CTA/CVT/reduced blanking/projector 时序匹配。
- 完善 baseline、desktop、embedded、large-format、full-HD、UHD、projector、gaming、workstation 等审计 profile。
- 提供文本、Markdown、JSON 多种报告格式。
- 提供可直接运行的示例工程。
- 补齐 README、API、设计说明、验收清单、测试记录、变更日志和 Mooncakes 查重说明。
- 配置 CI，并发布至 Mooncakes。

## 预期目标与技术路线

技术路线采用纯 MoonBit 实现核心解析、诊断和报告逻辑。输入层先将十六进制字符串转换为字节数组，再解析 EDID 1.x base block 的固定字段和 4 个 18 字节描述符。数据层使用强类型结构表达厂商、显示输入、色度、时序、描述符、诊断和审计结果。能力层将详细时序、标准时序和 established timings 归一化为统一的 `DisplayMode`。审计层根据 profile 判断最小分辨率、刷新率、首选时序、隔行模式和扩展块数量。输出层提供文本、Markdown、JSON 以适配人工审阅、文档展示和自动化流水线。

## 预计完成的功能、测试和文档

- 功能：EDID 解析、校验、显示能力提取、时序目录匹配、profile 审计、报告渲染、示例命令。
- 测试：解析成功路径、无效十六进制、长度错误、header 错误、checksum 错误、时序提取、审计通过/拒绝、报告字段、时序目录、profile matrix。
- 文档：README、项目申报书、API 文档、设计说明、验收清单、Mooncakes 查重记录、测试记录、开发记录、变更日志。

## 移植与许可证说明

本项目为原创 MoonBit 项目，不是移植项目。项目不包含第三方源代码、私有代码、闭源代码、商业代码、图片素材或来源不明内容。项目使用 MIT 许可证开源。

## Mooncakes 查重说明

2026-08-11 已检查 Mooncakes 公开模块数据和网页检索，关键词包括 EDID、DisplayID、VESA、DMT、CTA、monitor identification、display timing 等。未发现与 `edidkit` 功能边界高度重合的 Mooncakes 项目。近似关键词命中均属于文本布局、正则、dotenv、噪声生成、通用调度等无关方向。

## 后续维护计划

后续版本计划支持 CTA-861 extension block、DisplayID、真实二进制 EDID 文件读取辅助、更多显示 profile、WebAssembly 在线分析示例，以及面向硬件测试流水线的批量审计接口。
