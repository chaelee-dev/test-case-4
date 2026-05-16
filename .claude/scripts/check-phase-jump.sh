#!/usr/bin/env bash
# UserPromptSubmit hook — 사용자가 직접 슬래시 명령 입력 시 phase 점프 차단 (ADR-0026)
#
# 정합: .claude/state/flow-state.yaml current_phase
#
# 동작:
#  - 사용자 prompt에서 슬래시 명령 추출 (/implement, /qa-test 등)
#  - flow-state.yaml current_phase 확인
#  - 점프 매트릭스 lookup → 허용 phase가 아니면 system-reminder 주입 (차단은 안 함 — exit 0)
#
# 정책: 본 hook은 **권고 출력만**. 강제 차단은 축 1(gate-precondition.sh)이 담당.
#       사용자가 의도적으로 phase를 건너뛸 수 있는 유연성 보존.
#
# 임계: /context-loader, /intention-brief 등 진입점 Skill은 항상 허용 (체인 시작점)

set -u

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | grep -oE '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed -E 's/^"prompt"[[:space:]]*:[[:space:]]*"//; s/"$//')

# 슬래시 명령 추출 (첫 번째 토큰)
SLASH_CMD=$(echo "$PROMPT" | grep -oE '/[a-z][a-z0-9-]*' | head -1 | sed 's|^/||')
[ -z "$SLASH_CMD" ] && exit 0

# 진입점 Skill은 항상 허용
case "$SLASH_CMD" in
  context-loader|intention-brief|start-feature|flow-init|flow-design|flow-wbs|flow-bootstrap|flow-new-project|flow-feature|install-toolkit|compact|clear|help)
    exit 0 ;;
esac

# Skill → 기대 직전 phase 매핑
case "$SLASH_CMD" in
  ux-flow-design|debug-investigator|change-contract) EXPECTED="P1-brief|P2-ux" ;;
  implementation-planner)                            EXPECTED="P3-contract" ;;
  plan-eng-review)                                   EXPECTED="P4-plan" ;;
  acceptance-criteria)                               EXPECTED="P5-eng-review" ;;
  risk-check)                                        EXPECTED="P6-acceptance" ;;
  implement)                                         EXPECTED="P7-risk" ;;
  code-review)                                       EXPECTED="P8-implement" ;;
  qa-test)                                           EXPECTED="P9-code-review|P10-qa" ;;
  ui-design-review)                                  EXPECTED="P8-implement|P10-qa" ;;
  docs-update)                                       EXPECTED="P10-qa|P12-ui-review" ;;
  *) exit 0 ;;
esac

STATE_FILE=".claude/state/flow-state.yaml"
[ ! -f "$STATE_FILE" ] && exit 0

CURRENT=$(grep -oE '^current_phase:[[:space:]]*[A-Za-z0-9-]+' "$STATE_FILE" | head -1 \
  | sed -E 's/^current_phase:[[:space:]]*//')
[ -z "$CURRENT" ] && exit 0

# 기대 phase에 매칭되는지 검사
if echo "$CURRENT" | grep -qE "^($EXPECTED)$"; then
  exit 0
fi

# Phase 점프 감지 — system-reminder 주입 (차단 안 함)
cat <<EOF
<system-reminder>
[Phase 점프 감지 — ADR-0026 권고]

사용자 명령: /$SLASH_CMD
flow-state 현재 phase: $CURRENT
기대 직전 phase: $EXPECTED

체인 순서를 건너뛴 명령일 수 있습니다. 직전 Skill을 먼저 호출하는 게 일반적입니다.

판단 옵션:
  1. (권장) 직전 Skill 먼저 실행 후 본 명령 재호출
  2. 의도된 점프라면 그대로 진행 — 단, /$SLASH_CMD 진입 시 PreToolUse 게이트(gate-precondition.sh)가 선행 산출 검증을 강제하므로 산출 누락 시 차단됨

본 안내는 권고이며 차단하지 않습니다.
정책 정본: docs/planning/adr/0026-hook-chain-enforcement.md
</system-reminder>
EOF

exit 0
