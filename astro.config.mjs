// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';

// 域名变量化 (PL 硬要求, MEETING-2026-05-11-05-static-website-v1):
// 优先读 .env / GitHub Secrets, 兜底 serpilo.com.
// 切换主域名: 改 .env 的 PUBLIC_SITE_URL 一行 + GitHub Secrets 同名
const siteUrl = process.env.PUBLIC_SITE_URL || 'https://serpilo.com';

export default defineConfig({
  site: siteUrl,
  output: 'static',
  build: {
    format: 'directory',
  },
  vite: {
    plugins: [tailwindcss()],
  },
  integrations: [
    sitemap(),
    mdx(),
  ],
  i18n: {
    defaultLocale: 'zh',
    locales: ['zh', 'en'],
    routing: {
      prefixDefaultLocale: false,
    },
  },
  markdown: {
    shikiConfig: {
      theme: 'github-light',
      wrap: true,
    },
  },
});
