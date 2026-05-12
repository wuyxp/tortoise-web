import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Content Layer API (Astro 5+):
// 从 git submodule (Tortoise 主仓) 拉 docs/*.md 作为 'docs' collection
// MEETING-2026-05-11-05-static-website-v1
const docs = defineCollection({
  loader: glob({
    pattern: '**/*.md',
    base: './src/content/tortoise-source/docs',
  }),
  schema: z.object({
    title: z.string().optional(),
    description: z.string().optional(),
    // _sidebar.md meta=public 默认 true; PM 后续逐篇过审改 false 即从公开站隐藏
    public: z.boolean().default(true),
  }),
});

export const collections = { docs };
