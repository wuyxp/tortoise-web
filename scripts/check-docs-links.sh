#!/bin/bash
# 跨仓死链 lint: 主页 src/ 内 hardcode 的 /docs/<slug> 链接, 验证 src/content/tortoise-source/
# (submodule, tortoise-docs PUBLIC 仓内容) 存在对应 .md.
# 议题: MEETING-2026-05-11-06-docs-isolation Phase B (P1-4)

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
SRC_DIR="$REPO_ROOT/src"
DOCS_DIR="$REPO_ROOT/src/content/tortoise-source"

if [ ! -d "$DOCS_DIR" ]; then
  echo "❌ docs submodule 未初始化 ($DOCS_DIR 不存在). 跑 'git submodule update --init --recursive'"
  exit 1
fi

echo "==> 扫描主页 hardcode docs 链接 (src/**/*.{astro,ts,tsx})"

# grep src/ 内 href="/docs/<slug>" 或 href={'/docs/<slug>'} 形式的链接
links=$(grep -rEhno 'href=["{`]?/docs/[A-Za-z0-9_/.-]+/?["}\` ]' "$SRC_DIR" 2>/dev/null \
  | grep -oE '/docs/[A-Za-z0-9_/.-]+' \
  | sed 's|/$||' \
  | sort -u)

if [ -z "$links" ]; then
  echo "    (主页内无 hardcode /docs/* 链接)"
  exit 0
fi

echo "    发现 $(echo "$links" | wc -l | tr -d ' ') 个 hardcode 链接"

dead=()
checked=0
for link in $links; do
  # 把 /docs/01-overview/product-overview → src/content/tortoise-source/01-overview/product-overview
  # Astro slug 是文件名小写, 但 tortoise-docs 文件名可能含大写 (例 README.md slug=readme)
  # 多形式查找:
  slug=${link#/docs/}
  # 1. 直接匹配 (lower or upper)
  found=""
  for candidate in \
    "$DOCS_DIR/${slug}.md" \
    "$DOCS_DIR/${slug}.mdx" \
    "$DOCS_DIR/${slug}/index.md"; do
    if [ -f "$candidate" ]; then
      found="$candidate"
      break
    fi
  done

  # 2. 大小写不敏感模糊查 (slug=readme → README.md)
  if [ -z "$found" ]; then
    base_dir=$(dirname "$DOCS_DIR/$slug")
    base_name=$(basename "$slug")
    if [ -d "$base_dir" ]; then
      found_file=$(ls "$base_dir"/*.md 2>/dev/null | grep -i "/${base_name}\.md$" | head -1 || true)
      if [ -n "$found_file" ] && [ -f "$found_file" ]; then
        found="$found_file"
      fi
    fi
  fi

  if [ -z "$found" ]; then
    dead+=("$link")
  fi
  checked=$((checked + 1))
done

echo "    检查 $checked 个链接"

if [ ${#dead[@]} -gt 0 ]; then
  echo ""
  echo "❌ 死链 (${#dead[@]} 个):"
  printf '    %s\n' "${dead[@]}"
  echo ""
  echo "可能原因:"
  echo "  (a) 主仓 docs/ 删了某文件, 但 tortoise-docs 没 sync (重跑 sync-public-docs.sh)"
  echo "  (b) PM 把某章节标 public=false, sync 排除了, 但主页仍 hardcode (修主页或恢复 public=true)"
  echo "  (c) 链接路径敲错 (修主页)"
  exit 1
fi

echo "✓ 全部 $checked 个 docs 链接 OK"
