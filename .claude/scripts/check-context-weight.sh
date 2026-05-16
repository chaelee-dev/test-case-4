#!/usr/bin/env bash
# UserPromptSubmit hook — /flow-* 작업 전 컨텍스트 무게 점검
# 정합: .claude/commands/flow-feature.md "Pre-P0 컨텍스트 위생"
# 정책: 차단 없음 (exit 0). stdout에 system-reminder 주입 — 모델이 사용자에게 안내.
#
# 트리거: 사용자 프롬프트에 /flow-feature, /flow-init, /flow-design, /flow-wbs,
#         /flow-bootstrap, /flow-new-project 중 하나가 포함될 때.
# 임계값: 트랜스크립트 ≥ 500줄 (~10k 토큰 추정).

set -u

INPUT=$(cat)

# JSON 파싱 (jq 의존 회피 — grep + sed 기반)
PROMPT=$(echo "$INPUT" | grep -oE '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"prompt"[[:space:]]*:[[:space:]]*"//; s/"$//')
TRANSCRIPT=$(echo "$INPUT" | grep -oE '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"transcript_path"[[:space:]]*:[[:space:]]*"//; s/"$//')

# /flow-* 명령어 매칭 (다른 입력은 무시)
case "$PROMPT" in
  */flow-feature*|*/flow-init*|*/flow-design*|*/flow-wbs*|*/flow-bootstrap*|*/flow-new-project*) ;;
  *) exit 0 ;;
esac

# 트랜스크립트 무게 측정
[ -z "${TRANSCRIPT:-}" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

LINES=$(wc -l <"$TRANSCRIPT" 2>/dev/null || echo 0)
THRESHOLD=500

if [ "$LINES" -gt "$THRESHOLD" ]; then
  cat <<EOF
<system-reminder>
[Pre-Flow 컨텍스트 위생 점검]

현재 세션 트랜스크립트가 누적되어 있습니다 (${LINES}줄, ~$((LINES / 50))k 토큰 추정, 임계 ${THRESHOLD}줄).

새 /flow-* 작업 전 다음을 권장합니다:
  1. 직전 작업 마무리/저장 상태 확인
  2. /compact 실행 — Claude Code 네이티브 대화 압축 (컨텍스트 토큰 절감)
  3. 본 /flow-* 명령어 재호출

본 안내는 **권고이며 차단하지 않습니다**. 작업은 그대로 진행됩니다.

사용자에게 위 사실을 알리고, /compact 실행 여부를 한 번 확인한 뒤 진행해 주세요.
정책 정본: docs/planning/operations/commands/flow-feature.md "Pre-P0 컨텍스트 위생"
</system-reminder>
EOF
fi

exit 0
