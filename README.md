# tortoise-web

> Tortoise 主页 — 6-14 岁儿童短视频时间管理 App 官网与文档

## 架构

- **Astro 6 + Tailwind 4** — 静态生成, 不需要服务器运行时
- **docs 内容**通过 CI 从私有内容仓同步 → `src/content/tortoise-source/` → Astro Content Collections 静态生成 `/docs/*` 路由
- **双发部署**: GitHub Pages (国外用户) + 阿里云 nginx (国内用户)
- **变量化**: 域名 / 邮箱 / 商店 URL 全在 `.env` (复制 `.env.example`), 后续换域名只改一行

## 目录

```
src/
├── content.config.ts       # Astro Content Collections schema (docs)
├── content/
│   └── tortoise-source/    # git submodule → Tortoise 主仓
├── layouts/
│   └── BaseLayout.astro    # 顶栏 + 页脚 (Gemini 后续视觉精修)
├── pages/
│   ├── index.astro         # 主页 7 块骨架 (Gemini 后续视觉精修)
│   └── docs/[...slug].astro  # docs 动态路由
└── styles/global.css       # Tailwind 4 + Tortoise brand tokens
```

## 本地开发

```bash
git clone --recurse-submodules git@github.com:wuyxp/tortoise-web.git
cd tortoise-web
cp .env.example .env       # 改默认值或保持
npm install
npm run dev                # http://localhost:4321
```

## 本地 build

```bash
npm run build              # 产出 dist/
npm run preview            # 预览 production build
```

## 同步 docs 更新

Tortoise 主仓 push `docs/**` 改动 → `repository_dispatch` 自动触发本仓 `sync-docs.yml` → submodule 升级 commit → 触发 `deploy.yml` 双发。

兜底: dependabot 周一自动 PR submodule 升级。

## 部署

- GitHub Pages: <https://wuyxp.github.io/tortoise-web> (国外用户, Cloudflare 前置 — 可选)
- 阿里云: <https://serpilo.com> (国内用户, 备案 + nginx + Let's Encrypt)

部署链路: push main → `.github/workflows/deploy.yml` 并行 build + 双发 (任一失败不阻塞另一边).

## 域名变量化 (PL 硬要求)

后续换域名只需:
1. 改 `.env` 的 `PUBLIC_SITE_URL` 一行
2. 改 GitHub Secrets 同名值
3. 改阿里云 DNS A 记录指向新域名
4. 重跑一次 nginx 配置 (`scripts/setup-aliyun.sh` 第二次)

## License

MIT — 见 [LICENSE](./LICENSE)
