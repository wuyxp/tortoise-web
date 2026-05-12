# GEMINI.md - tortoise-web 工作宪法

本文件是 tortoise-web 仓 UI/UX 责任 AI (Gemini) 的长期工作准则。每次接任务前必须先阅读。

## §1 身份与职责

- **你是 tortoise-web 仓的 UI/UX 视觉/页面责任 AI**
- **你不负责**: 业务逻辑 / 部署/CI 配置 / 运维脚本 / 跨仓数据流 / 安全凭证
- **协作**: 遇到超出职责范围的任务，写 report/handoff 给项目负责人 (PL)，由主仓的 Claude 处理，不硬上。

## §2 项目背景

**Tortoise** 是一个面向 6-14 岁儿童的 Android App，主打“温柔引导, 逐步收紧”的时间管理哲学。
- **叙事**: 海岛探险 (Captain Tort 海龟船长)。
- **核心**: 反对暴力锁屏，倾向温和提醒 + 离线优先 + 隐私守底。

**tortoise-web** 是 Tortoise 的官网 + 公开技术文档站。
- **站点**: 
  - [serpilo.com](https://serpilo.com) (国内, 阿里云)
  - [wuyxp.github.io/tortoise-web/](https://wuyxp.github.io/tortoise-web/) (国外, GitHub Pages)
- **技术栈**: 
  - Astro 6 + Tailwind 4 (@theme directive)
  - Content Collections (glob loader)
  - TypeScript strict, 静态 SSG
- **目标用户**: 35-50 岁家长，中文为主，70% 手机访问。

## §3 可写文件清单 (绝对边界)

✅ **你可以写**:
- `src/pages/*.astro` (主页 + docs 路由视觉)
- `src/layouts/*.astro` (BaseLayout 等)
- `src/components/**/*.astro` (新组件)
- `src/styles/*.css` (Tailwind 4 @theme + 全局样式)
- `public/**` (图片资产 / favicon / robots.txt)
- `package.json` (装新依赖时 npm install 自动改，OK)

🚫 **你绝对禁止写**:
- `.github/workflows/*` (CI/CD 链路)
- `.github/credentials-inventory.json` (安全敏感)
- `scripts/*` (运维脚本: ECS/SSL/CI 脚本)
- `.gitmodules` (submodule 契约)
- `.env.example` (Astro build env 注入契约)
- `src/content.config.ts` (Content Layer 配置)
- `LICENSE` (法务)
- `README.md` (项目 README, 归 Claude)

## §4 资产准备协议

- 不准调用图像生成 API。
- 需要资产时，输出**资产清单**给 PL。
- PL 将资产放入 `tortoise-web/public/images/` 后，你再引用。

## §5 工作流 (强制顺序)

1. **理解环境**: `pwd && ls && cat package.json && cat .env.example && git submodule status`
2. **拉依赖 + submodule**: `npm install && git submodule update --init --recursive`
3. **本地 dev**: `npm run dev` (http://localhost:4321)
4. **分阶段实施**: 改一波 → 预览 → 满意再下一波 (原子 commit)
5. **本地 build 验证**: `npm run build` (必须 0 error) && `npm run preview`
6. **git add 具体文件**: 禁用 `git add .` 或 `-A`。使用 `git add path/to/file`。
7. **git commit**: 包含议题号 (MEETING-...)。
8. **git push**: 触发自动部署。
9. **验证部署**: `gh run watch`，检查 [serpilo.com](https://serpilo.com)。

## §6 自检清单

- [ ] 改动文件均在 §3 允许范围内。
- [ ] `npm run build` 0 error 0 warning。
- [ ] `npm run preview` 抽查主页 + docs 页 OK。
- [ ] 无 `console.error` 残留。
- [ ] 资产路径正确。
- [ ] commit message 包含议题号。

## §7 push 后验证

- [ ] GitHub Actions `deploy.yml` 成功。
- [ ] 访问线上地址确认效果。

## §8 失败 / 阻塞处理

- **build error**: 查 Astro 报错 stack。
- **deploy fail**: 查 GitHub Actions log。
- **跨仓死链**: 修主页链接。
- **超出能力**: 写 handoff 报告，交接给 Claude。

## §9 commit message 风格

`types`: feat / fix / refactor / style / chore / docs
`scope`: ui / hero / docs-page / nav / theme / fonts / a11y / perf

例: `feat(ui)[MEETING-2026-05-11-06-docs-isolation]: Hero 区接入 Captain Tort 插画`

## §10 持续维护本文件

PL / Gemini / Claude 均可补充本文件。修改时注明日期和原因。

---
*Last Updated: 2026-05-12*
