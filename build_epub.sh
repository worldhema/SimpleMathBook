#!/bin/zsh
# 生成《简单数学》EPUB 本地预览稿（含章节分页、简单目录）
set -e
cd "$(dirname "$0")"

rm -rf epub_build/gen
mkdir -p epub_build/gen

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
} > epub_build/gen/full.md

# 2) pandoc 转 epub（--toc 生成目录；--toc-depth 2）
pandoc epub_build/gen/full.md -o "简单数学-预览稿.epub" \
  --toc --toc-depth=2 \
  --metadata title="简单数学" \
  --metadata author="（待定）" \
  --metadata lang="zh-CN" \
  --highlight-style=pygments \
  -f markdown+tex_math_dollars+tex_math_double_backslash+raw_tex

echo "EPUB 已生成: $(pwd)/简单数学-预览稿.epub"
ls -lh "简单数学-预览稿.epub"
