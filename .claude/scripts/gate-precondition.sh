#!/usr/bin/env bash
# PreToolUse hook — Skill 호출 시 선행 산출 게이트 (ADR-0026)
#
# 정합: .claude/commands/flow-feature.md Phase Sequence (P0~P15)
#       CLAUDE.md §"Strict Harness Mode" 9개 정책
#
# 동작:
#  - Skill 이름을 환경변수에서 추출 (CLAUDE_TOOL_INPUT_skill)
#  - 매트릭스 lookup → 필요한 선행 산출 type 목록
#  - docs/features/<slug>/<slug>.<type>.md glob 검증 (하나라도 존재 = 통과)
#  - 미충족 시 exit 2 + stderr (BLOCKED)
#
# 한계:
#  - slug 특정은 flow-state.yaml `issue.number` 또는 `active_flow` 의존 (축 2에서 갱신)
#  - active_flow 미설정 시 glob `docs/features/*/<slug>.<type>.md` 폭넓게 매칭 (위양성 가능)
#  - AI가 Skill tool 안 쓰고 텍스트로만 진행 시 무력화 (정책 텍스트로 보완)

set -u

SKILL="${CLAUDE_TOOL_INPUT_skill:-${CLAUDE_TOOL_INPUT_SKILL:-}}"

# Skill 이름 없으면 통과 (다른 tool 호출 또는 환경변수 미주입)
[ -z "$SKILL" ] && exit 0

# 선행 산출 매트릭스 (없으면 통과 = 게이트 없음)
case "$SKILL" in
  context-loader|intention-brief|start-feature|flow-init|flow-design|flow-wbs|flow-bootstrap|flow-new-project|flow-feature|install-toolkit)
    exit 0 ;;
  ux-flow-design|debug-investigator|change-contract)
    REQUIRED="brief" ;;
  implementation-planner)
    REQUIRED="contract" ;;
  plan-eng-review)
    REQUIRED="contract plan" ;;
  acceptance-criteria)
    REQUIRED="plan eng-review" ;;
  risk-check)
    REQUIRED="acceptance" ;;
  implement)
    REQUIRED="contract plan acceptance eng-review risk" ;;
  qa-test)
    REQUIRED="acceptance" ;;
  docs-update|ui-design-review|code-review|learning-note|issue-sync)
    exit 0 ;;
  *)
    exit 0 ;;
esac

# slug 후보 추출 (flow-state.yaml 또는 가장 최근 features 폴더)
STATE_FILE=".claude/state/flow-state.yaml"
SLUG=""
if [ -f "$STATE_FILE" ]; then
  # issue.number → slug 매칭은 복잡 → 단순화: artifacts.contract.path에서 slug 추출
  SLUG=$(grep -oE 'docs/features/[a-z0-9-]+/' "$STATE_FILE" | head -1 | sed -E 's|docs/features/([a-z0-9-]+)/|\1|')
fi

# slug 미특정 시 모든 feature 폴더 대상 광범위 검증
MISSING=""
for TYPE in $REQUIRED; do
  if [ -n "$SLUG" ]; then
    PATTERN="docs/features/$SLUG/$SLUG.$TYPE.md"
  else
    PATTERN="docs/features/*/*.$TYPE.md"
  fi
  # glob 결과 1건 이상 존재?
  # shellcheck disable=SC2086
  FOUND=$(ls $PATTERN 2>/dev/null | head -1)
  if [ -z "$FOUND" ]; then
    MISSING="$MISSING $TYPE"
  fi
done

if [ -n "$MISSING" ]; then
  cat >&2 <<EOF
BLOCKED: /$SKILL 선행 산출 누락 — ADR-0026 (Strict Harness Mode 게이트)

누락된 산출 type:$MISSING
검증 패턴: docs/features/<slug>/<slug>.<type>.md
${SLUG:+활성 slug: $SLUG}

조치:
  1. 직전 Phase Skill을 먼저 실행하여 산출을 생성
  2. 또는 .claude/state/flow-state.yaml의 artifacts.<type>.path 갱신
  3. flow-feature.md Phase Sequence 참조

본 게이트는 ADR-0026로 도입되었습니다. 정책 정본: docs/planning/adr/0026-hook-chain-enforcement.md
EOF
  exit 2
fi

exit 0
