#!/bin/bash
# ============================================================
# Playwright 시스템 의존성 설치 (sudo 필요)
# 사용법: sudo bash scripts/setup-playwright.sh
# ============================================================

set -e

echo "=== Playwright 시스템 의존성 설치 ==="

apt-get update
apt-get install -y \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2

echo ""
echo "=== gstack setup 재실행 ==="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_ROOT/.claude/skills/gstack/setup" ]; then
    cd "$PROJECT_ROOT/.claude/skills/gstack"
    su "${SUDO_USER:-$(whoami)}" -c "./setup"
    echo "gstack setup 완료"
else
    echo "gstack 미설치. 먼저 bash scripts/setup.sh 실행하세요."
fi
