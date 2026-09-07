#!/bin/zsh
# 生成《简单数学》EPUB / 全书 HTML / PDF（输出到 release/）
# 用法：在项目根目录执行  bash epub_build/build_epub.sh
#   或：bash epub_build/build_epub.sh html     （只重新生成 HTML）
#   或：bash epub_build/build_epub.sh epub     （只重新生成 EPUB）
#   或：bash epub_build/build_epub.sh pdf      （只重新生成 PDF，需先 brew install tectonic）
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
    --metadata author="WorldHema" \
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

# 4) pandoc 转 PDF（LaTeX 引擎 tectonic；中文字体自动探测）
if [ "$TARGET" = "all" ] || [ "$TARGET" = "pdf" ]; then
  # PDF 不设 lang：pandoc 老模板会把 zh-CN 交给 polyglossia（\setmainlanguage 空参崩溃）；中文由 CJKmainfont(xeCJK) 处理
  # mainfont 同用宋体：正文裸 π/≠/框线等字形 Latin Modern 无，Songti 含
  # monofont 用 Menlo：等宽且含 ─ 等框线字符（代码块示意图需要）
  # 中文字体：优先宋体（正文易读），无则回退苹方
  PDF_CJK="${PDF_CJK:-}"
  if [ -z "$PDF_CJK" ]; then
    for f in "Songti SC" "STSong" "Adobe Song Std" "PingFang SC"; do
      if fc-list ":lang=zh" family 2>/dev/null | grep -qF "$f"; then PDF_CJK="$f"; break; fi
    done
    PDF_CJK="${PDF_CJK:-PingFang SC}"
  fi
  echo "PDF 中文字体: $PDF_CJK"

  # 优先直接 --pdf-engine=tectonic；若 pandoc 版本过老不认识该引擎，回退为 tex → tectonic
  if ! pandoc "$BUILD_DIR/full.md" -o "$RELEASE_DIR/简单数学-全书.pdf" \
      --pdf-engine=tectonic --toc --toc-depth=2 \
      --metadata title="简单数学" --metadata author="WorldHema" \
      --metadata date="2026-09-01" \
      --highlight-style=pygments \
      --include-in-header=epub_build/tex-header.tex \
      -f markdown+tex_math_dollars+tex_math_double_backslash+raw_tex \
      -V mainfont="$PDF_CJK" \
      -V monofont="Menlo" \
      -V CJKmainfont="$PDF_CJK" \
      -V CJKsansfont="$PDF_CJK" \
      -V CJKmonofont="$PDF_CJK" \
      -V geometry:margin=2.2cm -V fontsize=11pt -V colorlinks=true \
      2>/tmp/_pdf_pandoc.err; then
    echo "  --pdf-engine=tectonic 不可用（pandoc 2.1.2 较老），回退：tex → tectonic"
    pandoc "$BUILD_DIR/full.md" -t latex --standalone --toc --toc-depth=2 \
      --metadata title="简单数学" --metadata author="WorldHema" \
      --metadata date="2026-09-01" \
      --highlight-style=pygments \
      --include-in-header=epub_build/tex-header.tex \
      -f markdown+tex_math_dollars+tex_math_double_backslash+raw_tex \
      -V mainfont="$PDF_CJK" \
      -V monofont="Menlo" \
      -V CJKmainfont="$PDF_CJK" \
      -V CJKsansfont="$PDF_CJK" \
      -V CJKmonofont="$PDF_CJK" \
      -V geometry:margin=2.2cm -V fontsize=11pt -V colorlinks=true \
      -o "$BUILD_DIR/full.tex"
    tectonic "$BUILD_DIR/full.tex"
    mv "$BUILD_DIR/full.pdf" "$RELEASE_DIR/简单数学-全书.pdf"
  fi
  echo "PDF 已生成: $RELEASE_DIR/简单数学-全书.pdf"
  ls -lh "$RELEASE_DIR/简单数学-全书.pdf"
fi

echo "构建完成。"
