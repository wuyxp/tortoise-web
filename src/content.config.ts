import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Content Layer API (Astro 5+):
// 从 git submodule (wuyxp/tortoise-docs PUBLIC 仓) 拉 .md 作为 'docs' collection.
// MEETING-2026-05-11-06-docs-isolation: PRIVATE 主仓 docs/ 公开子集已 sync 到
// PUBLIC tortoise-docs, root 是主题域目录 (不再有 docs/ 嵌套层).
const docs = defineCollection({
  loader: glob({
    pattern: '**/*.md',
    base: './src/content/tortoise-source',
  }),
  schema: z.object({
    title: z.string().optional(),
    description: z.string().optional(),
    // _sidebar.md meta=public 默认 true; PM 后续逐篇过审改 false 即从公开站隐藏
    public: z.boolean().default(true),
  }),
});

export const collections = { docs };
