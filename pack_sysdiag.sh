#!/usr/bin/env bash
set -euo pipefail

[[ -x ./sysdiag.sh ]] || { echo "请先 chmod +x sysdiag.sh"; exit 1; }
./sysdiag.sh                                  # 🔧 生成最新诊断

LATEST="$(ls -t sysdiag_*.txt 2>/dev/null | head -n 1 || true)"
[[ -n "${LATEST:-}" ]] || { echo "未找到 sysdiag_*.txt"; exit 1; }

TS="$(date +%Y%m%d_%H%M%S)"
PKG="sysdiag_bundle_${TS}.tar.gz"

tar -czf "$PKG" sysdiag.sh "$LATEST"         # 🧠 打包：脚本 + 最新结果
echo "打包完成：$PKG（包含：sysdiag.sh + $LATEST）"
