# 技术文档脱敏与重构实施计划

本项目旨在解决 `tortoise-web` 官网技术文档中存在的隐私泄露、专业性不足、复杂度过高以及缺乏直观图解的问题。我们将通过内容重塑、结构拆分及叙事化包装，将原本的“内部日志”转化为面向公众的“官方白皮书”。

## 用户评审要求

- **脱敏力度确认**: 是否需要完全移除所有 Android API 名称（如 `UsageStatsManager`），还是仅移除具体的使用策略？
- **叙事化程度**: 是否接受将技术组件与“海岛探险”隐喻深度绑定（例如：监控服务 = 瞭望塔）？
- **文件拆分建议**: 同意将单个巨型 `product-overview.md` 拆分为多个主题文档吗？

## 提议的变更

### 1. 内容审计与脱敏 (Audit & De-sensitization)

我们将对 `src/content/tortoise-source` 进行深度扫描，识别并处理以下敏感信息：

- **内部会议号**: 移除所有 `MEETING-2026-XXXX-XX`。
- **内部路径**: 移除对 `scripts/`、`.github/` 等非公开目录的直接引用。
- **敏感包名**: 将 `com.example.tortoise` 统一替换为 `com.tortoise.app`。
- **绕过细节**: 弱化对厂商（EMUI/MIUI）特定绕过逻辑的文字描述，改为更通用的“厂商兼容性方案”。

### 2. 结构重构 (Structural Refactoring)

#### [NEW] `src/content/tortoise-source/architecture/philosophy.md`
- 阐述“温柔引导”核心哲学。
- 介绍六阶段提醒系统（移除底层实现细节，保留逻辑）。

#### [NEW] `src/content/tortoise-source/architecture/system-design.md`
- 介绍 Clean Architecture 架构。
- 包含模块依赖图（脱敏版）。

#### [NEW] `src/content/tortoise-source/architecture/engine-logic.md`
- 解释监控与锁定机制的高层逻辑。
- 重点描述“四层锁定”的业务价值而非代码实现。

### 3. UI/UX 视觉增强 (Visual Support)

#### [BaseLayout.astro](file:///Users/wuyang/code/tortoise-web/src/layouts/BaseLayout.astro)
- 在文档页面引入“叙事化徽章”系统。

#### [[...slug].astro](file:///Users/wuyang/code/tortoise-web/src/pages/docs/[...slug].astro)
- 优化 Mermaid 图表样式，使其符合“海岛探险”视觉风格。
- 引入 `<Details>` 组件折叠高难度技术细节。

---

## 验证计划

### 自动化验证
- 运行自定义脚本扫描输出结果，确保不含 `com.example` 或 `MEETING-` 关键字。
- `npm run build` 确保 SSG 编译通过。

### 手动验证
- 抽查 `http://localhost:4321/docs/...` 各页面，确认排版正常且无死链。
- 确认 Mermaid 图表在暗色模式下的可读性。
