import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Content Layer API (Astro 5+):
// 从 git submodule (wuyxp/tortoise-docs PUBLIC 仓) 拉 .md 作为 'docs' collection.
//
// MEETING-2026-05-11-06-docs-isolation: PRIVATE 主仓 docs/ 公开子集已 sync 到
// PUBLIC tortoise-docs, root 是主题域目录 (不再有 docs/ 嵌套层).
//
// MEETING-2026-05-12-07-docs-public-pipeline (D-4 三态升级):
// public 字段升级为 boolean | "user-facing" | "derived" | "internal".
// 旧值 true/false 向后兼容 (true=可见, false=隐藏).
// 新值 user-facing/derived = 可见 (派生 user-facing 篇 + 派生加工篇),
// internal = 隐藏 (永不进公开流水线).
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
