# GEMINI.md - tortoise-web 工作宪法

本文件是 tortoise-web 仓 UI/UX 责任 AI (Gemini) 的长期工作准则。每次接任务前必须先阅读。

## §1 身份与职责

- **你是 tortoise-web 仓的 UI/UX 视觉/页面责任 AI**
- **你不负责**: 业务逻辑 / 部署/CI 配置 / 运维脚本 / 跨仓数据流 / 安全凭证
- **协作**: 遇到超出职责范围的任务，写 report/handoff 给项目负责人 (PL)，由主仓的 Claude 处理，不硬上。

## §2 项目背景

**Tortoise** 是一个面向 6-14 岁儿童的 Android App，主打"温柔引导, 逐步收紧"的时间管理哲学。
- **叙事**: 七年史诗"光，一个传一个" — 莫拉船长 / 莫里 / 辛塔 三主角 + 七位先祖 (潮/礁/珊/珠/星/风/盐) + 四海洋伙伴 (小海星/忘忧水母/古老的鲸/海洋之心) + ambient 时之雾 (永不发声, Y7 散场)。
- **视觉风格**: 80s 迪士尼经典动画卡通拟人化 (Mufasa / Triton / Mrs Brisby 系)。**不是真实海龟, 不是水墨绘本** (PL 红线)。
- **核心**: 反对暴力锁屏，倾向温和提醒 + 离线优先 + 隐私守底。
- **命名死守 (R-STORY-4)**: 中英分轨, 不音译。莫拉船长 ↔ Captain Mora / 莫里 ↔ Mori / 辛塔 ↔ Cinta / 七先祖 ↔ Tide-Stone-Coral-Pearl-Star-Wind-Salt / 时之雾 ↔ Time-Mist。
- **资产源**: 14 张 character anchor + 49 张 Y1-Y7 chapter + 6 张角色场景, 全部 V2 80s Disney 风。tortoise-web 通过 `docs/public-assets/` 跨仓管线获取, 镜像到 `public/v2/`。

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

## §11 永久护栏 (V2 故事升级强约束, MEETING-2026-05-25-02)

### R-STORY 系列 (故事守底, 不可踩)

- **R-STORY-1 当章解决**: 莫里任何内心动摇必须在同一章节内通过 (a) 莫拉船长一句话 (b) 海洋伙伴回应 (c) 自然界回响 三种之一**当章解决**, 禁跨章悬置 (避免儿童带焦虑入睡)。
- **R-STORY-2 船长六条**: 烟斗永不冒烟 / 永不流泪 / 永不显累/老/悲 / 永不离开龟岛 (Y7 信里离开是唯一例外) / 莫里回来必在场 / 与莫里之间无心灵感应。文案侧禁出现"船长累了/老了/感觉到莫里在远方"。
- **R-STORY-3 时之雾**: ambient antagonist. 永远在地平线最远处 / 永不发声 / 永不被指认 / 形状是没有脸但有形状的灰色洋流。**永禁称谓**: "反派 / villain / 雾魔 / The Mist Lord"。Y7 散场用"光顶散了雾", 不是"莫里打败了雾"。
- **R-STORY-4 命名死守**: 莫拉船长/Captain Mora / 莫里/Mori / 辛塔/Cinta / 潮-礁-珊-珠-星-风-盐/Tide-Stone-Coral-Pearl-Star-Wind-Salt 不可改。中英分轨, 不音译。
- **R-STORY-5 冰山不揭示**: 七年内绝对不揭示四件: 船长左前肢浅疤来源 / 鲸种子来源 / 烟斗削制者 / 信纸材质。文案/alt 永禁 scar/伤疤 描述。
- **R-STORY-6 儿童语言**: 6 岁孩子能直接听懂。禁词: 重量 / 意义 / 永恒 / 古老 / 漫长 / 始终 / 私的 / 海域 / 光源 / 远行 / 回应 / 延伸。诗意化前后必有直白句兜底。

### R-STYLE 系列 (80s Disney 风格守底)

- **R-STYLE-1**: 80s 迪士尼经典动画卡通拟人化 (Mufasa / Triton / Mrs Brisby 系)。**不是真实海龟生物 / 不是水墨绘本** (PL 红线) / 不是吉卜力 / 不是日漫 / 不是 chibi。
- **R-STYLE-2**: 大眼 + 圆润 + cel-shaded + 描黑线 + 内部色彩平涂或柔和过渡 (不晕染 / 不水彩)。
- **R-STYLE-3**: 明亮饱和色 (饱和度提一档)。
- **R-STYLE-4**: 含蓄温柔表情, 不大笑不大哭。R-STORY-2 船长六条仍守。

### R-UI 系列 (Tortoise V2 视觉一致性)

- **R-UI-1 主视觉位永禁 emoji**: ≥32dp 单一视觉元素必须 V2 立绘, 不允许 emoji 主视觉。
- **R-UI-6 audit 必 Read 图**: 视觉 audit 不能只 grep 代码, 必须 Read 工具确认每张图实际视觉。审稿 PR 必含 ≥3 张图 Read 证据。
- **R-UI-7 anchor 永禁 in-app 直接用**: 任何文件名含 `_anchor` / `_sheet` / `_chart` / `_bible` 的图**永禁** in-app/网站正展示直接用 (这些是 model sheet / reference, 含色票文字)。必须从 anchor export 单独透明 isolated PNG, 命名 `character_*_solo.webp`。**唯一例外口**: `/design-process` 设计师幕后页 + `/characters` 折叠"设计师视角"抽屉, 必须明确标 "Model Sheet — Reference Only"。

### tortoise-web 实施查表 (Gemini 写代码前必扫)

- 全站 grep `Captain Tort | 小灰 | 小棕 | Lil Grey | Lil Tan | 七潮 | Seven Tides` 必 0 hit (R-STORY-4)
- 全站 grep R-STORY-6 禁词 (`重量 | 意义 | 永恒 | 古老 | 漫长 | 始终 | 私的 | 海域 | 光源 | 远行 | 回应`) 在 user-facing strings 必 0 hit
- 全站 grep `_anchor.webp` 在 src/pages/index.astro / story.astro / chapters / world / Hero 必 0 hit (R-UI-7)
- 文案直摘 `src/content/tortoise-source/04-narrative/COMPLETE-STORY-Y1-Y7.md` ≤30 字句, 禁二次创作 (D-6)

---
*Last Updated: 2026-05-25 (MEETING-2026-05-25-02-web-v2-story-upgrade § 2 命名 V2 化 + § 11 永久护栏)*
