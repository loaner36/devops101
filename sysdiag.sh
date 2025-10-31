#!/usr/bin/env bash                    
# 用系统环境里的 bash 执行
set -e                                   # 任一命令失败（返回非0）就退出脚本
set -u                                   # 使用未定义变量时报错，避免拼写问题
set -o pipefail                          # 管道中任一环节失败都算失败，避免误判成功

TS="$(date +%Y%m%d_%H%M%S)"              # 统一时间戳（例：20251031_093015）
OUT="sysdiag_${TS}.txt"                  # 输出文件名：带时间戳避免覆盖

{                                        # 将以下所有输出重定向到 $OUT
  echo "=== BASIC / OS RELEASE ==="
  uname -a                               # 内核/主机名/架构
  if [ -r /etc/os-release ]; then        # -r：存在且可读
    echo; echo "[/etc/os-release]"; cat /etc/os-release
  fi; echo

  echo "=== UPTIME & LOAD ===";  uptime; echo
  echo "=== CPU INFO ==="
  if command -v lscpu >/dev/null 2>&1; then lscpu; else echo "lscpu 不可用（跳过）"; fi; echo
  echo "=== MEMORY ===";          free -m; echo
  echo "=== DISK (SPACE) ===";    df -h; echo
  echo "=== DISK (INODES) ===";   df -i; echo

  echo "=== TOP PROCESSES ==="
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 10
  echo

  echo "=== NETWORK ==="
  ip addr; ip route
  echo "LISTEN PORTS"
  ss -tulpn 2>/dev/null | head -n 30     # 没权限显示进程名时也不报错中断
  echo

  echo "=== DNS INFO ==="
  if command -v resolvectl >/dev/null 2>&1; then
    resolvectl status 2>/dev/null || true
  else
    echo "[/etc/resolv.conf]"; cat /etc/resolv.conf 2>/dev/null || true
  fi; echo

  echo "=== BASIC CONNECTIVITY TEST ==="
  (ping -c 2 1.1.1.1 || true); echo; (ping -c 2 8.8.8.8 || true); echo

  echo "=== RECENT ERRORS (journalctl) ==="
  journalctl -p 3 -n 80 --no-pager 2>/dev/null || echo "journalctl 不可用（跳过）"; echo

  echo "=== KERNEL RING BUFFER (last 100) ==="
  dmesg -T 2>/dev/null | tail -n 100 || echo "dmesg 不可用（跳过）"; echo
} > "$OUT"

echo "已保存诊断结果到: $OUT"            # 结束提示
