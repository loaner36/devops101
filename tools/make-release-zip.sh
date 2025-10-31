#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
PKG="sysdiag_release_${TS}.zip"

FILES=()
[[ -f "sysdiag.sh" ]] && FILES+=("sysdiag.sh")
[[ -f "pack_sysdiag.sh" ]] && FILES+=("pack_sysdiag.sh")
[[ -f "windows/sysdiag.ps1" ]] && FILES+=("windows/sysdiag.ps1")
[[ -f "windows/pack_sysdiag.ps1" ]] && FILES+=("windows/pack_sysdiag.ps1")
[[ -f "README.md" ]] && FILES+=("README.md")

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "没有可打包的文件，请检查路径" >&2
  exit 1
fi

zip -9 -r "$PKG" "${FILES[@]}"
echo "生成：$PKG"
