#!/usr/bin/env bash
# 用系统环境里的 bash 执行
set -e                                   # 🧠 任一命令失败就退出
set -u                                   # 🧠 使用未定义变量时报错
set -o pipefail                          # 🧠 管道任一环节失败算失败

TS="$(date +%Y%m%d_%H%M%S)"              # 🔧 生成时间戳（例 20251106_142233）
OUT="sysdiag_${TS}.txt"                  # 🔧 输出文件名（避免覆盖）

{                                        # 🔧 将以下输出全部写入 $OUT
  echo "=== BASIC / OS ==="
  uname -a                               # 💡 内核/主机名/架构
  [[ -r /etc/os-release ]] && (echo; cat /etc/os-release); echo

  echo "=== UPTIME & LOAD ===";  uptime; echo
  echo "=== CPU ===";            command -v lscpu >/dev/null && lscpu || echo "无 lscpu"; echo
  echo "=== MEM ===";            free -m; echo
  echo "=== DISK (SPACE) ===";   df -h; echo
  echo "=== DISK (INODES) ===";  df -i; echo

  echo "=== TOP PROCESSES ==="
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 10; echo

  echo "=== NETWORK ==="
  ip addr; ip route
  echo "LISTEN PORTS"
  ss -tulpn 2>/dev/null | head -n 30; echo

  echo "=== DNS ==="
  if command -v resolvectl >/dev/null; then
    resolvectl status 2>/dev/null || true
  else
    echo "[/etc/resolv.conf]"; cat /etc/resolv.conf 2>/dev/null || true
  fi; echo

  echo "=== CONNECTIVITY ==="
  (ping -c 2 1.1.1.1 || true); echo; (ping -c 2 8.8.8.8 || true); echo

  echo "=== ERRORS (journalctl) ==="
  journalctl -p 3 -n 80 --no-pager 2>/dev/null || echo "无 journalctl"; echo

  echo "=== DMESG (last 100) ==="
  dmesg -T 2>/dev/null | tail -n 100 || echo "无 dmesg"; echo
} > "$OUT"

echo "已保存诊断结果到: $OUT"             # 结束提示
