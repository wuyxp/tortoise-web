#!/usr/bin/env bash
# copy-public-assets-to-web.sh
#
# Mirror tortoise-docs submodule's public-assets/ into tortoise-web/public/v2/.
#
# 议题: MEETING-2026-05-25-02-web-v2-story-upgrade D-5
#
# 用途: Gemini 写页面时引用 /v2/<subdir>/<file>.webp 永远稳定路径,
#       不直接 import submodule 内部路径 (Dianne Hackborn idempotent-by-construction).
#
# 输入: tortoise-web/src/content/tortoise-source/public-assets/  (submodule)
# 输出: tortoise-web/public/v2/                                  (Astro 静态根)
#
# 触发: PL 跑完 `git submodule update --remote` 后执行本脚本,
#       然后 commit `chore(submodule): bump tortoise-docs to Wave-N assets`.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/src/content/tortoise-source/public-assets"
DST="$REPO_ROOT/public/v2"

if [ ! -d "$SRC" ]; then
  echo "❌ submodule public-assets 不存在: $SRC" >&2
  echo "   先跑 'git submodule update --init --remote' 拉 tortoise-docs" >&2
  exit 2
fi

mkdir -p "$DST"

echo "📦 mirror $SRC → $DST"

# rsync -a 保留属性 + 递归; --delete 清理旧文件; 仅同步图像类
rsync -a --delete \
  --include='*/' \
  --include='*.webp' --include='*.png' --include='*.jpg' --include='*.jpeg' \
  --include='*.svg' --include='*.gif' --include='*.avif' --include='*.mmd' \
  --exclude='*' \
  "$SRC"/ "$DST"/

# R-UI-7 防呆: anchor 文件命名只能出现在指定子目录
echo ""
echo "🔍 R-UI-7 验证 (anchor model sheet 命名约束)"
WRONG=$(find "$DST" -type f -name '*_anchor.webp' 2>/dev/null | \
  grep -vE '/(characters|ancestors|marine|design-process)/' || true)
if [ -n "$WRONG" ]; then
  echo "❌ R-UI-7 违规: 以下 anchor 文件放错目录 (允许目录: characters/ ancestors/ marine/ design-process/)" >&2
  echo "$WRONG" >&2
  exit 3
fi

# 汇总
ASSET_COUNT=$(find "$DST" -type f \( -name '*.webp' -o -name '*.png' -o -name '*.svg' \) 2>/dev/null | wc -l | tr -d ' ')
ANCHOR_COUNT=$(find "$DST" -type f -name '*_anchor.webp' 2>/dev/null | wc -l | tr -d ' ')
SOLO_COUNT=$(find "$DST" -type f -name 'character_*_solo.webp' 2>/dev/null | wc -l | tr -d ' ')
CHAPTER_COUNT=$(find "$DST" -type f -name 'chapter_y*.webp' 2>/dev/null | wc -l | tr -d ' ')
SCENE_COUNT=$(find "$DST" -type f -path '*/scenes/*.webp' 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "✅ mirror 完成"
echo "   总资产: $ASSET_COUNT"
echo "   anchor: $ANCHOR_COUNT  (仅 characters/ ancestors/ marine/ design-process/)"
echo "   solo  : $SOLO_COUNT"
echo "   章节图: $CHAPTER_COUNT"
echo "   场景图: $SCENE_COUNT"
echo ""
echo "👉 下一步: git add public/v2 src/content/tortoise-source"
echo "         git commit -m 'chore(submodule)[MEETING-2026-05-25-02]: bump tortoise-docs assets'"
