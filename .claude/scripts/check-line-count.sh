#!/usr/bin/env bash
# WARN-only 분량 가드. 300줄 권고 초과 시 stderr 경고만, 차단 없음.
# 호출: settings.json hooks.PreToolUse Write|Edit 매처에서.
# CLAUDE_TOOL_INPUT_FILE_PATH 환경 변수에서 대상 파일 경로를 받는다.
#
# === 가드 적용 범위 (사용자 정책, 2026-05-07 정정 / 2026-05-13 ADR-0020 갱신) ===
# 운영 문서만 가드 대상 — 툴킷 자체를 작은 컨텍스트로 유지하기 위함:
#   ✅ .claude/commands/  .claude/harness/  .claude/agents/
#   ✅ CLAUDE.md  .claude/USAGE_GUIDE.md
#   ✅ docs/planning/conventions/  docs/planning/policies/  docs/planning/operations/
#   ✅ docs/planning/adr/  docs/planning/CHANGELOG.md  docs/install/
#
# 산출 문서는 가드 외 — RFP/맥락에 따라 분량 자유:
#   ❌ docs/planning/0[0-9]-*.md 1수준 산출 (01-brief, 04-srs, 06-architecture 등)
#   ❌ docs/planning/04-srs/  05-prd/  07-hld/  08-lld-module-spec/  12-scaffolding/  retro/  분할
#   ❌ docs/features/<slug>/*  feature 단계 산출
#
# 면제 (인덱스/이력/격리):
#   ❌ COMMANDS_REFERENCE.md  INDEX.md  CHANGELOG.md(누적 이력)  _archive/

set -u
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-${CLAUDE_TOOL_INPUT_file_path:-}}"

# 대상 미존재 또는 빈 경로면 통과
[ -z "${FILE}" ] && exit 0
[ ! -f "${FILE}" ] && exit 0

# .md 파일만 측정 대상
case "${FILE}" in
  *.md) ;;
  *) exit 0 ;;
esac

# 1단계: 면제 패턴 (인덱스·이력·격리)
case "${FILE}" in
  */COMMANDS_REFERENCE.md|*/INDEX.md|*/CHANGELOG.md|*/_archive/*)
    exit 0
    ;;
esac

# 2단계: 가드 대상 화이트리스트 — 운영 문서만
case "${FILE}" in
  */.claude/commands/*.md|\
  */.claude/harness/*.md|\
  */.claude/agents/*.md|\
  */.claude/USAGE_GUIDE.md|\
  */CLAUDE.md|\
  */docs/planning/conventions/*.md|\
  */docs/planning/policies/*.md|\
  */docs/planning/operations/*.md|\
  */docs/planning/adr/*.md|\
  */docs/install/*.md)
    # 측정 진행 (아래)
    ;;
  *)
    # 산출 문서·기타 — 가드 외, 통과
    exit 0
    ;;
esac

# 3단계: 분량 측정 (WARN-only)
LINES=$(wc -l <"${FILE}" 2>/dev/null || echo 0)
if [ "${LINES}" -gt 300 ]; then
  echo "WARN: ${FILE} = ${LINES}줄 — 운영 문서 300줄 권고 초과. 분할 검토 (conventions/file-numbering.md §2). 산출 문서가 아닌지 확인" >&2
fi

exit 0
