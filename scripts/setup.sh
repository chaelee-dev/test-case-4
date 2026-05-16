#!/bin/bash
# ============================================================
# DevToolKit 설치 스크립트
# 사용법: bash scripts/setup.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "============================================================"
echo "  DevToolKit 설치"
echo "============================================================"
echo ""

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
info "프로젝트 루트: $PROJECT_ROOT"

# ─── 1/7. Bun ───
echo ""
info "=== 1/7. Bun ==="
if command -v bun > /dev/null 2>&1 || [ -f "$HOME/.bun/bin/bun" ]; then
    export PATH="$HOME/.bun/bin:$PATH"
    info "Bun $(bun --version) 이미 설치됨"
else
    info "Bun 설치 중..."
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
    info "Bun $(bun --version) 설치 완료"
fi

# ─── 2/7. gstack 글로벌 설치 ───
echo ""
info "=== 2/7. gstack 글로벌 ==="
GSTACK_GLOBAL="$HOME/.claude/skills/gstack"
if [ -f "$GSTACK_GLOBAL/SKILL.md" ]; then
    info "gstack 글로벌 이미 설치됨"
else
    info "gstack 글로벌 설치 중..."
    git clone https://github.com/garrytan/gstack.git "$GSTACK_GLOBAL"
    cd "$GSTACK_GLOBAL" && ./setup
    cd "$PROJECT_ROOT"
    info "gstack 글로벌 설치 완료"
fi

# ─── 3/7. gstack 워크스페이스 설치 ───
echo ""
info "=== 3/7. gstack 워크스페이스 ==="
GSTACK_LOCAL=".claude/skills/gstack"
if [ -f "$GSTACK_LOCAL/SKILL.md" ]; then
    info "gstack 워크스페이스 이미 설치됨"
else
    info "gstack 워크스페이스 설치 중..."
    mkdir -p .claude/skills
    cp -Rf "$GSTACK_GLOBAL" "$GSTACK_LOCAL"
    rm -rf "$GSTACK_LOCAL/.git"
    cd "$GSTACK_LOCAL" && ./setup
    cd "$PROJECT_ROOT"
    info "gstack 워크스페이스 설치 완료"
fi

# ─── 4/7. gstack 설정 ───
echo ""
info "=== 4/7. gstack 설정 ==="
GSTACK_CONFIG="$GSTACK_LOCAL/bin/gstack-config"
if [ -f "$GSTACK_CONFIG" ]; then
    bash "$GSTACK_CONFIG" set telemetry off 2>/dev/null || true
    info "telemetry: off"
else
    warn "gstack-config 없음, 수동 설정 필요"
fi

# ─── 5/7. Playwright 시스템 의존성 ───
echo ""
info "=== 5/7. Playwright 의존성 ==="
if ldconfig -p 2>/dev/null | grep -q libnss3; then
    info "Playwright 시스템 의존성 이미 설치됨"
else
    warn "Playwright 시스템 의존성 미설치"
    echo "  아래 명령을 sudo로 실행하세요:"
    echo "  sudo bash scripts/setup-playwright.sh"
fi

# ─── 6/7. DevToolKit 스킬 심볼릭 링크 ───
echo ""
info "=== 6/7. DevToolKit 스킬 링크 ==="
cd "$PROJECT_ROOT/.claude/skills"
for skill in devtoolkit/init devtoolkit/scaffold devtoolkit/orchestrate devtoolkit/sprint devtoolkit/task-sync; do
    name=$(basename "$skill")
    ln -sfn "$skill" "$name" 2>/dev/null
done
info "DevToolKit 스킬 링크 완료 (5개)"
cd "$PROJECT_ROOT"

# ─── 7/7. 디렉토리 구조 확인/생성 ───
echo ""
info "=== 7/7. 디렉토리 구조 ==="
for dir in \
    .claude/agents \
    .claude/skills/devtoolkit/init \
    .claude/skills/devtoolkit/scaffold \
    .claude/skills/devtoolkit/orchestrate \
    .claude/skills/devtoolkit/sprint \
    .claude/skills/devtoolkit/task-sync \
    docs/analysis \
    docs/design \
    docs/plan/sprint-contracts \
    docs/plan/tasks \
    docs/review/screenshots \
    docs/deploy \
    frontend \
    backend \
    logs
do
    mkdir -p "$dir"
done
info "디렉토리 구조 확인 완료"

# ─── 검증 ───
echo ""
echo "============================================================"
info "설치 완료. 환경 검증 실행:"
echo "============================================================"
echo ""
bash scripts/check-env.sh
