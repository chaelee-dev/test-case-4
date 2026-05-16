#!/usr/bin/env bash
# PostToolUse hook — Skill 완료 후 flow-state.yaml phase·산출 갱신 (ADR-0026)
#
# 정합: .claude/state/flow-state.example.yaml (current_phase, last_command, artifacts.*)
#
# 동작:
#  - Skill 이름을 환경변수에서 추출
#  - Skill → phase 매핑 lookup
#  - flow-state.yaml의 current_phase / last_command / last_command_at / artifacts.<type>.{path,exists} 갱신
#  - 산출 파일 path는 glob으로 최신 1건 자동 검출 (산출 작성된 직후 가정)
#
# 한계:
#  - flow-state.yaml 갱신은 sed/awk 기반 단순 치환 (yq 의존 회피)
#  - 동시 다중 이슈 작업 미지원 (single-issue 가정)
#  - 멱등성: 같은 Skill 재실행 시 동일 결과
#
# 실패 시 exit 0 — PostToolUse는 차단 책임 없음 (축 1·3이 차단 담당)

set -u

SKILL="${CLAUDE_TOOL_INPUT_skill:-${CLAUDE_TOOL_INPUT_SKILL:-}}"
[ -z "$SKILL" ] && exit 0

STATE_FILE=".claude/state/flow-state.yaml"
[ ! -f "$STATE_FILE" ] && exit 0

# Skill → phase + artifact type 매핑
case "$SKILL" in
  context-loader)         PHASE="P0-context";   ARTIFACT="" ;;
  intention-brief)        PHASE="P1-brief";     ARTIFACT="brief" ;;
  ux-flow-design)         PHASE="P2-ux";        ARTIFACT="ux" ;;
  debug-investigator)     PHASE="P3a-debug";    ARTIFACT="investigation" ;;
  change-contract)        PHASE="P3-contract";  ARTIFACT="contract" ;;
  implementation-planner) PHASE="P4-plan";      ARTIFACT="plan" ;;
  plan-eng-review)        PHASE="P5-eng-review"; ARTIFACT="eng-review" ;;
  acceptance-criteria)    PHASE="P6-acceptance"; ARTIFACT="acceptance" ;;
  risk-check)             PHASE="P7-risk";      ARTIFACT="risk" ;;
  implement)              PHASE="P8-implement"; ARTIFACT="" ;;
  code-review)            PHASE="P9-code-review"; ARTIFACT="code-review" ;;
  qa-test)                PHASE="P10-qa";       ARTIFACT="qa-report" ;;
  ui-design-review)       PHASE="P12-ui-review"; ARTIFACT="ui-review" ;;
  docs-update)            PHASE="P13-docs";     ARTIFACT="" ;;
  *) exit 0 ;;
esac

# KST 타임스탬프 (CLAUDE.md 필수 규칙 10)
NOW=$(TZ=Asia/Seoul date +"%Y-%m-%dT%H:%M:%S KST" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S KST")

# current_phase / last_command / last_command_at 갱신 (멱등 sed)
# 매칭 라인이 없으면 skip (손상 보호 — /context-loader가 재구성)
sed -i.bak \
  -e "s|^current_phase:.*|current_phase: $PHASE|" \
  -e "s|^last_command:.*|last_command: /$SKILL|" \
  -e "s|^last_command_at:.*|last_command_at: \"$NOW\"|" \
  -e "s|^updated_at:.*|updated_at: \"$NOW\"|" \
  "$STATE_FILE" 2>/dev/null
rm -f "$STATE_FILE.bak" 2>/dev/null

# artifacts.<type>.path 자동 검출 (glob 최신 1건)
if [ -n "$ARTIFACT" ]; then
  # Normalize type → yaml key (hyphen → underscore for eng-review, code-review 등)
  YAML_KEY=$(echo "$ARTIFACT" | sed 's/-/_/g')
  # qa-report → qa_report, eng-review → eng_review, ui-review → ui_review, code-review → code_review
  FOUND=$(ls docs/features/*/*."$ARTIFACT".md 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then
    # path: null → path: <FOUND>, exists: false → exists: true (해당 키 블록만)
    # YAML 들여쓰기 구조: artifacts:\n  <key>:\n    path: ...\n    exists: ...
    # awk 블록 치환 (해당 키 블록 안의 path·exists만 갱신)
    awk -v key="$YAML_KEY" -v path="$FOUND" '
      BEGIN { in_block=0 }
      /^artifacts:/ { in_artifacts=1; print; next }
      in_artifacts && /^[a-z_]+:/ && !/^artifacts:/ { in_artifacts=0; in_block=0 }
      in_artifacts && $0 ~ "^  " key ":$" { in_block=1; print; next }
      in_artifacts && in_block && /^  [a-z_]+:/ { in_block=0 }
      in_block && /^    path:/ { print "    path: " path; next }
      in_block && /^    exists:/ { print "    exists: true"; next }
      { print }
    ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  fi
fi

exit 0
