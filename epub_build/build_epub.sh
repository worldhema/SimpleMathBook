#!/bin/zsh
# 生成《简单数学》EPUB 与 全书 HTML（输出到 release/）
# 用法：在项目根目录执行  bash epub_build/build_epub.sh
#   或：bash epub_build/build_epub.sh html     （只重新生成 HTML）
#   或：bash epub_build/build_epub.sh epub     （只重新生成 EPUB）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_DIR=epub_build/gen
RELEASE_DIR=release
TARGET="${1:-all}"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$RELEASE_DIR"

# 1) 按顺序拼接章节
{
  cat epub_build/00-title.md
  echo ""
  for part in "0-第〇部分" "1-第一部分" "2-第二部分" "3-第三部分" "4-第四部分" "5-第五部分" "6-第六部分"; do
    partnum=${part%%-*}; partname=${part#*-}
    # 部分标题页（简单占位）
    printf '\n\n# %s\n\n（本部分各章见目录）\n\n' "$partname" > /tmp/_part.md
    cat /tmp/_part.md
    echo ""
    for f in chapters/${partnum}-*.md; do
      echo ""
      # 章节标题作为 h1 分隔（原文件 h1 保留，这里加 h2 前的小节分隔）
      echo ""
      cat "$f"
      echo ""
      echo ""
    done
  done
  # 结语
  echo ""
  echo "# 结语：一栋楼俯瞰"
  cat chapters/epilogue.md | sed '1d'  # 去掉 epilogue 自带的 h1，避免重复
  echo ""
  # 尾声
  echo ""
  echo "# 尾声：AI 时代，如何把这本书用起来"
  cat chapters/coda.md | sed '1d'  # 去掉 coda 自带的 h1，避免重复
  echo ""
} > "$BUILD_DIR/full.md"

# 2) pandoc 转 epub（--toc 生成目录；--toc-depth 2）
if [ "$TARGET" = "all" ] || [ "$TARGET" = "epub" ]; then
  pandoc "$BUILD_DIR/full.md" -o "$RELEASE_DIR/简单数学-预览稿.epub" \
    --toc --toc-depth=2 \
    --metadata title="简单数学" \
    --metadata author="（待定）" \
    --metadata lang="zh-CN" \
    --highlight-style=pygments \
    -f markdown+tex_math_dollars+tex_math_double_backslash+raw_tex
  echo "EPUB 已生成: $RELEASE_DIR/简单数学-预览稿.epub"
  ls -lh "$RELEASE_DIR/简单数学-预览稿.epub"
fi

# 3) pandoc 转 全书 HTML（含左侧目录 + MathJax 公式 + 纸感 CSS）
if [ "$TARGET" = "all" ] || [ "$TARGET" = "html" ]; then
  pandoc "$BUILD_DIR/full.md" -o "$RELEASE_DIR/简单数学-全书.html" \
    --standalone --toc --toc-depth=2 \
    --metadata title="简单数学" \
    --metadata author="一栋从地基盖到屋顶的数学科普书" \
    --metadata date="2026-09-01" \
    --metadata lang="zh-CN" \
    --mathjax "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.2/MathJax.js?config=TeX-AMS_CHTML-full" \
    -f markdown+tex_math_dollars+tex_math_double_backslash+raw_tex \
    --include-in-header=epub_build/html-header.html
  echo "HTML 已生成: $RELEASE_DIR/简单数学-全书.html"
  ls -lh "$RELEASE_DIR/简单数学-全书.html"
fi

echo "构建完成。"
