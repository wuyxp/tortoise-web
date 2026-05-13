# 任务清单: 技术文档脱敏与 UI/UX 强化 (V2)

- [ ] 仓库本地源码脱敏
    - [ ] 替换所有 `tortoise@example.com` 为正式反馈邮箱
    - [ ] 移除源码注释中的 `MEETING-` 会议号
- [ ] 文档展示层 UI 增强
    - [ ] 在 `[...slug].astro` 中通过正则自动为 Markdown 中的某些复杂块（如 Schema, SQL）包裹 `<details>` 标签
    - [ ] 完善文档叙事徽章系统
    - [ ] 优化 Mermaid 图表的 CSS 样式
- [ ] 验证与部署
    - [ ] 运行 `npm run build`
    - [ ] 提交 Commit 并 Push
