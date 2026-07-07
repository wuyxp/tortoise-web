// SEO/GEO 结构化数据工具。
// buildFaqLd: 从 FAQ markdown 正文抽取 `### Q: 问题` + 后续段落(答案), 生成 schema.org FAQPage。
// AI 引擎(ChatGPT/Perplexity/Gemini)对 FAQPage 抽取问答对友好, 提升被引用概率。

interface FaqLd {
  '@context': string;
  '@type': string;
  mainEntity: Array<{
    '@type': 'Question';
    name: string;
    acceptedAnswer: { '@type': 'Answer'; text: string };
  }>;
}

/** 把 markdown 行清成给 schema 用的纯文本(去粗体/行内代码/列表符/占位 token) */
function cleanLine(line: string): string {
  return line
    .replace(/`/g, '')
    .replace(/\*\*/g, '')
    .replace(/^\s*[-*]\s+/, '')
    .replace(/:min-android-version:/g, 'Android 7.0')
    .trim();
}

/**
 * 从 FAQ 文档正文构建 FAQPage JSON-LD。
 * 约定: 问题是 `### Q: ...` 行, 答案是其后到下一个标题之间的正文。
 * 无法解析出任何问答 → 返回 null(调用方不注入)。
 */
export function buildFaqLd(body: string): FaqLd | null {
  const lines = body.split('\n');
  const faqs: Array<{ q: string; a: string }> = [];
  let curQ: string | null = null;
  let curA: string[] = [];

  const flush = () => {
    if (curQ) {
      const answer = curA.join(' ').replace(/\s+/g, ' ').trim();
      if (answer) faqs.push({ q: curQ, a: answer });
    }
    curQ = null;
    curA = [];
  };

  for (const line of lines) {
    const qMatch = line.match(/^###\s*Q[:：]?\s*(.+?)\s*$/);
    if (qMatch) {
      flush();
      curQ = qMatch[1].trim();
      continue;
    }
    // 其它任意标题(##/###/#)结束当前答案
    if (/^#{1,6}\s/.test(line)) {
      flush();
      continue;
    }
    if (curQ) {
      const cleaned = cleanLine(line);
      if (cleaned) curA.push(cleaned);
    }
  }
  flush();

  if (faqs.length === 0) return null;
  return {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((f) => ({
      '@type': 'Question',
      name: f.q,
      acceptedAnswer: { '@type': 'Answer', text: f.a },
    })),
  };
}
