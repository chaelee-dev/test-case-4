#!/bin/bash
# ============================================================
# DevToolKit 환경 검증 스크립트
# 사용법: bash scripts/check-env.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local cmd="$2"

    # 1차: 명령 자체 존재 검사 (eval 전에 첫 토큰만 추출).
    # pipefail 미설정 상태에서 `cmd | head -1` 평가는 head 의 exit 0 만 반영
    # → gh 미설치인데 OK 로 잘못 표시되던 버그(false positive) 차단.
    local bin="${cmd%% *}"
    if ! command -v "$bin" > /dev/null 2>&1; then
        echo -e "  ${RED}FAIL${NC}  $name"
        FAIL=$((FAIL + 1))
        return
    fi

    # 2차: 실제 실행하여 버전 한 줄 캡처. 에러는 stderr 로 분리 (버전 자리에 에러 메시지 박히는 것 방지).
    local ver
    if ver=$(eval "$cmd" 2>/dev/null | head -1) && [ -n "$ver" ]; then
        echo -e "  ${GREEN}OK${NC}  $name ($ver)"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC}  $name"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================================"
echo "  DevToolKit 환경 검증"
echo "============================================================"
echo ""

# --- 필수 도구 ---
echo "=== 필수 도구 ==="
check "Claude Code" "claude --version"
check "Git" "git --version"
check "Node.js (18+)" "node --version"

# Bun
if command -v bun > /dev/null 2>&1; then
    check "Bun (1.0+)" "bun --version"
elif [ -f "$HOME/.bun/bin/bun" ]; then
    export PATH="$HOME/.bun/bin:$PATH"
    check "Bun (1.0+)" "bun --version"
else
    echo -e "  ${RED}FAIL${NC}  Bun (1.0+)"
    FAIL=$((FAIL + 1))
fi

# Java (선택)
if command -v java > /dev/null 2>&1; then
    check "Java (21+)" "java -version 2>&1 | head -1 | cat"
else
    echo -e "  ${YELLOW}WARN${NC}  Java (백엔드 Spring Boot 사용 시 필요)"
    WARN=$((WARN + 1))
fi

echo ""

# --- GitHub ---
echo "=== GitHub ==="
check "gh CLI" "gh --version | head -1"
if gh auth status > /dev/null 2>&1; then
    local_user=$(gh auth status 2>&1 | grep "account" | awk '{print $7}')
    echo -e "  ${GREEN}OK${NC}  gh 인증 ($local_user)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}FAIL${NC}  gh 인증 (gh auth login 실행 필요)"
    FAIL=$((FAIL + 1))
fi

echo ""

# --- gstack ---
echo "=== gstack ==="
GSTACK_GLOBAL="$HOME/.claude/skills/gstack"
GSTACK_LOCAL=".claude/skills/gstack"

if [ -f "$GSTACK_LOCAL/SKILL.md" ]; then
    skill_count=$(find "$GSTACK_LOCAL" -maxdepth 2 -name "SKILL.md" | wc -l)
    echo -e "  ${GREEN}OK${NC}  gstack 워크스페이스 ($skill_count SKILL.md)"
    PASS=$((PASS + 1))
elif [ -f "$GSTACK_GLOBAL/SKILL.md" ]; then
    echo -e "  ${YELLOW}WARN${NC}  gstack 글로벌만 설치됨 (워크스페이스 설치 필요: scripts/setup.sh)"
    WARN=$((WARN + 1))
else
    echo -e "  ${RED}FAIL${NC}  gstack 미설치"
    FAIL=$((FAIL + 1))
fi

# 심볼릭 링크 (gstack 27 + devtoolkit 5 = 32)
link_count=$(find .claude/skills -maxdepth 1 -type l 2>/dev/null | wc -l)
if [ "$link_count" -ge 32 ]; then
    echo -e "  ${GREEN}OK${NC}  스킬 심볼릭 링크 ($link_count/32: gstack 27 + devtoolkit 5)"
    PASS=$((PASS + 1))
elif [ "$link_count" -ge 27 ]; then
    echo -e "  ${YELLOW}WARN${NC}  gstack 링크만 ($link_count/32, DevToolKit 스킬 링크 필요: scripts/setup.sh)"
    WARN=$((WARN + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  심볼릭 링크 부족 ($link_count/32, setup.sh 재실행 필요)"
    WARN=$((WARN + 1))
fi

# browse 바이너리
if [ -f "$GSTACK_LOCAL/browse/dist/browse" ]; then
    echo -e "  ${GREEN}OK${NC}  browse 바이너리 (Playwright QA용)"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  browse 바이너리 없음 (gstack setup 재실행 필요)"
    WARN=$((WARN + 1))
fi

echo ""

# --- Playwright ---
echo "=== Playwright (브라우저 QA) ==="
if ls ~/.cache/ms-playwright/chromium*/chrome-linux64/chrome > /dev/null 2>&1 || \
   ls ~/.cache/ms-playwright/chromium_headless_shell*/chrome-headless-shell-linux64/chrome-headless-shell > /dev/null 2>&1; then
    echo -e "  ${GREEN}OK${NC}  Chromium 설치됨"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  Chromium 미설치 (/qa, /browse 사용 불가)"
    WARN=$((WARN + 1))
fi

if ldconfig -p 2>/dev/null | grep -q libnss3; then
    echo -e "  ${GREEN}OK${NC}  시스템 의존성 (libnss3 등)"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  Playwright 시스템 의존성 미설치 (sudo bash scripts/setup-playwright.sh)"
    WARN=$((WARN + 1))
fi

echo ""

# --- DevToolKit 설정 파일 ---
echo "=== DevToolKit 설정 ==="
for f in ".claude/settings.json" "CLAUDE.md" "devtoolkit.config.yaml"; do
    if [ -f "$f" ]; then
        echo -e "  ${GREEN}OK${NC}  $f"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC}  $f"
        FAIL=$((FAIL + 1))
    fi
done

# 에이전트 정의
agent_count=$(ls .claude/agents/*.md 2>/dev/null | wc -l)
if [ "$agent_count" -ge 6 ]; then
    echo -e "  ${GREEN}OK${NC}  에이전트 정의 ($agent_count/6)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}FAIL${NC}  에이전트 정의 ($agent_count/6)"
    FAIL=$((FAIL + 1))
fi

# DevToolKit 스킬
dt_skill_count=$(find .claude/skills/devtoolkit -name "SKILL.md" 2>/dev/null | wc -l)
if [ "$dt_skill_count" -ge 6 ]; then
    echo -e "  ${GREEN}OK${NC}  DevToolKit 스킬 ($dt_skill_count/6)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}FAIL${NC}  DevToolKit 스킬 ($dt_skill_count/6)"
    FAIL=$((FAIL + 1))
fi

# 설치 스크립트
for f in "scripts/setup.sh" "scripts/check-env.sh" "scripts/setup-playwright.sh"; do
    if [ -f "$f" ]; then
        echo -e "  ${GREEN}OK${NC}  $f"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC}  $f"
        FAIL=$((FAIL + 1))
    fi
done

# 보안
if [ -f ".gitignore" ]; then
    if grep -q "\.env" .gitignore; then
        echo -e "  ${GREEN}OK${NC}  .gitignore (보안 파일 차단)"
        PASS=$((PASS + 1))
    else
        echo -e "  ${YELLOW}WARN${NC}  .gitignore에 .env 패턴 없음"
        WARN=$((WARN + 1))
    fi
else
    echo -e "  ${RED}FAIL${NC}  .gitignore 없음"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "============================================================"
echo -e "  결과: ${GREEN}PASS $PASS${NC} / ${RED}FAIL $FAIL${NC} / ${YELLOW}WARN $WARN${NC}"
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}DevToolKit 사용 준비 완료${NC}"
else
    echo -e "  ${RED}FAIL 항목을 해결한 후 다시 실행하세요${NC}"
    echo "  설치: bash scripts/setup.sh"
fi
echo "============================================================"

exit $FAIL
