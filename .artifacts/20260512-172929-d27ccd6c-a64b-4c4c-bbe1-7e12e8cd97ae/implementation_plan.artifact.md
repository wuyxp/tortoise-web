# 技术文档脱敏与 UI/UX 强化实施计划 (V2 - 聚焦仓库本地)

根据最新指示，我们将重点处理 `tortoise-web` 仓库本身存在的脱敏、专业性及易读性问题，暂时不涉及对 `tortoise-source` 子模块的进一步物理修改（后续将由自动化方案处理）。

## 用户评审要求

- **示例信息替换**: 确认是否将 `tortoise@example.com` 替换为真实的反馈邮箱（或通用的 `support@serpilo.com`）？
- **会议号清理**: 确认是否移除所有源码注释中的 `MEETING-` 编号，以防在浏览器控制台或 Source Map 中泄露？

## 提议的变更

### 1. 仓库本地脱敏 (Desensitization)

我们将清理主仓库源码及配置文件中的占位符和开发元数据：

- **[BaseLayout.astro](file:///Users/wuyang/code/tortoise-web/src/layouts/BaseLayout.astro)** & **[index.astro](file:///Users/wuyang/code/tortoise-web/src/pages/index.astro)**:
    - 替换 `tortoise@example.com` 为正式的反馈渠道。
- **i18n/ui.ts**:
    - 清理包含 `MEETING-` 编号的注释，防止其出现在生产构建的静态资源中。
- **[...slug].astro**:
    - 移除或替换注释中对内部议题的引用。

### 2. UI/UX 强化 (UX & Clarity)

为了解决“文档太复杂”和“没有架构图支持”的问题，我们将通过 Astro 组件增强展示效果：

- **[[...slug].astro](file:///Users/wuyang/code/tortoise-web/src/pages/docs/[...slug].astro)**:
    - **叙事徽章系统**: 为不同类别的文档（ARCHITECTURE, LORE, SPEC）自动分配视觉徽章。
    - **折叠展示 (Details)**: 引入 `<details>` 标签支持，将 Room Migration 或具体的 Schema 细节默认折叠，降低非技术用户的认知负担。
    - **Mermaid 样式优化**: 进一步优化 Mermaid 图表的 UI，使其呈现“玻璃质感”并符合海岛叙事主色调（Brand Blue）。

### 3. 内容补全 (Missing Support)

- **叙事架构图**: 在文档渲染层增加对“技术-叙事映射”的说明，例如通过悬浮提示或全局侧边栏组件。

---

## 验证计划

### 自动化验证
- `grep` 扫描 `dist/` 目录，确保不含 `example.com` 或 `MEETING-`。
- `npm run build` 确保编译通过。

### 手动验证
- 检查 `http://localhost:4321` 首页邮箱显示。
- 检查文档页面，确认高难度细节已被默认折叠。
