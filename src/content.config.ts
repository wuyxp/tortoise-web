import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Content Layer API (Astro 5+):
// 从私有内容仓 (tortoise-docs) 同步的 .md 作为 'docs' collection.
// public 字段三态: "user-facing" | "derived" | "internal" (旧 true/false 向后兼容).
const docs = defineCollection({
  loader: glob({
    pattern: '**/*.md',
    base: './src/content/tortoise-source',
  }),
  schema: z.object({
    title: z.string().optional(),
    description: z.string().optional(),
    public: z
      .union([
        z.boolean(),
        z.enum(['user-facing', 'derived', 'internal']),
      ])
      .default(true),
    // user-facing 篇标注受众 (D-5)
    audience: z.enum(['parent', 'child', 'both']).optional(),
    // 派生篇引用主仓 source (D-5): "path@commit, path2@commit2"
    'derived-from': z.string().optional(),
    // 原创篇标记 (D-5): user-facing 篇必带 derived-from OR original=true 二选一
    original: z.boolean().optional(),
  }),
});

export const collections = { docs };
