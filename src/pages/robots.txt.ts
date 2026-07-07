import type { APIRoute } from 'astro';

// robots.txt 由端点动态生成, 跟随 astro.config `site` (PUBLIC_SITE_URL) 自动切换,
// 不硬编码域名。GEO: 显式欢迎主流生成式引擎爬虫 (ChatGPT / Perplexity / Claude / Gemini)。
const CRAWLERS = [
  'GPTBot', // OpenAI 训练/检索
  'OAI-SearchBot', // ChatGPT 搜索
  'ChatGPT-User', // ChatGPT 用户即时抓取
  'PerplexityBot', // Perplexity 索引
  'Perplexity-User', // Perplexity 用户即时抓取
  'ClaudeBot', // Anthropic Claude
  'Claude-User',
  'Claude-SearchBot',
  'Google-Extended', // Gemini / Vertex 训练许可
  'Applebot-Extended', // Apple Intelligence
  'Bingbot', // Bing 索引 (ChatGPT 搜索走 Bing)
  'Amazonbot',
  'cohere-ai',
];

export const GET: APIRoute = ({ site }) => {
  const origin = site ?? new URL('https://serpilo.com');
  const sitemapUrl = new URL('sitemap-index.xml', origin).href;

  const aiSection = CRAWLERS.map((ua) => `User-agent: ${ua}\nAllow: /`).join('\n\n');

  const body = `# https://www.robotstxt.org/robotstxt.html
# Tortoise Time (小龟时光) — all crawlers welcome.

User-agent: *
Allow: /

# ---- Generative-engine crawlers (GEO): explicitly allowed ----
${aiSection}

Sitemap: ${sitemapUrl}
`;

  return new Response(body, {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
};
