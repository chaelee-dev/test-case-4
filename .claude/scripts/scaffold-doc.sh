#!/usr/bin/env bash
# scaffold-doc.sh — schema에서 빈 산출 .md 골격을 생성한다.
# LLM/사용자가 작성을 시작할 때 이 골격을 출발점으로 사용.
#
# 사용:
#   ./scaffold-doc.sh <doc_type> <output_path>
#   ./scaffold-doc.sh srs docs/planning/04-srs/04-srs.md
#   ./scaffold-doc.sh feature-contract docs/features/login-mfa/feat-login-mfa.contract.md
#
# Exit codes:
#   0 = 골격 생성 완료
#   2 = doc_type schema 미존재 또는 출력 경로 충돌
#   3 = 사용 오류
#
# 의존성: yq

set -uo pipefail

SCHEMAS_DIR="$(cd "$(dirname "$0")/../schemas" && pwd)"

DOC_TYPE="${1:-}"
OUT_PATH="${2:-}"
TODAY=$(date +%Y-%m-%d)

[ -z "${DOC_TYPE}" ] || [ -z "${OUT_PATH}" ] && { echo "usage: $0 <doc_type> <output_path>" >&2; exit 3; }

if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq 미설치 — operations/runbook.md §4 fallback 참조" >&2
  exit 3
fi

SCHEMA_FILE="${SCHEMAS_DIR}/${DOC_TYPE}.schema.yaml"
[ ! -f "${SCHEMA_FILE}" ] && { echo "ERROR: schema not found: ${SCHEMA_FILE}" >&2; echo "사용 가능한 doc_type:" >&2; ls "${SCHEMAS_DIR}"/*.schema.yaml | xargs -n1 basename | sed 's/\.schema\.yaml$//' >&2; exit 2; }

# ─── ADR-0030: 폴더 분할 모드 분기 ────────────────────────────────────
# OUT_PATH가 디렉토리(끝 `/`)이거나 기존 디렉토리이고 schema에 folder_split.enabled=true이면
# subfiles[]를 순회하며 sub-file 골격을 일괄 생성한다.
FOLDER_SPLIT_ENABLED=$(yq '.folder_split.enabled // false' "${SCHEMA_FILE}")
IS_DIR_INPUT="false"
case "${OUT_PATH}" in
  */) IS_DIR_INPUT="true" ;;
esac
[ -d "${OUT_PATH}" ] && IS_DIR_INPUT="true"

if [ "${FOLDER_SPLIT_ENABLED}" = "true" ] && [ "${IS_DIR_INPUT}" = "true" ]; then
  TARGET_DIR="${OUT_PATH%/}"
  mkdir -p "${TARGET_DIR}"

  SUB_COUNT=$(yq '.folder_split.subfiles | length // 0' "${SCHEMA_FILE}")
  if [ "${SUB_COUNT}" -lt 1 ]; then
    echo "ERROR: folder_split.subfiles 비어 있음 — schema 점검 필요: ${SCHEMA_FILE}" >&2
    exit 2
  fi

  GATE_VALUE=$(yq '.gate_value // ""' "${SCHEMA_FILE}" | tr -d '"')
  GENERATED=0
  SKIPPED=0

  for s in $(seq 0 $((SUB_COUNT - 1))); do
    SUB_SLUG=$(yq ".folder_split.subfiles[${s}].slug" "${SCHEMA_FILE}" | tr -d '"')
    SUB_TITLE=$(yq ".folder_split.subfiles[${s}].title" "${SCHEMA_FILE}" | tr -d '"')
    SUB_OUT="${TARGET_DIR}/${SUB_SLUG}.md"

    if [ -e "${SUB_OUT}" ]; then
      echo "[SKIP] ${SUB_OUT} — 이미 존재 (덮어쓰지 않음)"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    cat > "${SUB_OUT}" <<EOF
---
doc_type: ${DOC_TYPE}
version: v0.1 (Draft)
status: Draft
author: <name@email>
date: ${TODAY}
gate: ${GATE_VALUE}
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# ${SUB_SLUG} ${SUB_TITLE} — ${DOC_TYPE}

<!-- scaffold-doc.sh 폴더 분할 모드 자동 생성 (${TODAY}, ADR-0030).
     본 sub-file은 schema(${DOC_TYPE}.schema.yaml) folder_split.subfiles[${s}]에서 추출.
     관련 정책: docs/planning/adr/0030-test-design-folder-split-scaffold.md -->

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | ${TODAY} | <author> | 초안 (scaffold-doc.sh folder-split 생성) |

EOF

    SEC_COUNT=$(yq ".folder_split.subfiles[${s}].sections | length // 0" "${SCHEMA_FILE}")
    for i in $(seq 0 $((SEC_COUNT - 1))); do
      SEC_HEADING=$(yq ".folder_split.subfiles[${s}].sections[${i}]" "${SCHEMA_FILE}" | tr -d '"')
      echo "${SEC_HEADING}" >> "${SUB_OUT}"
      echo "" >> "${SUB_OUT}"
      echo "<!-- TODO: ${SUB_TITLE} 의 ${SEC_HEADING} 본문 작성 -->" >> "${SUB_OUT}"
      echo "" >> "${SUB_OUT}"
    done

    echo "WROTE: ${SUB_OUT}"
    GENERATED=$((GENERATED + 1))
  done

  # 폴더 INDEX.md 자동 생성 (없을 때만)
  if [ ! -f "${TARGET_DIR}/INDEX.md" ]; then
    FOLDER_NAME=$(basename "${TARGET_DIR}")
    {
      echo "---"
      echo "doc_type: index"
      echo "version: v0.1"
      echo "status: Draft"
      echo "author: <name@email>"
      echo "date: ${TODAY}"
      echo "gate: ${GATE_VALUE}"
      echo "related:"
      echo "  R-ID: []"
      echo "  F-ID: []"
      echo "  supersedes: null"
      echo "---"
      echo ""
      echo "# ${FOLDER_NAME} — Index"
      echo ""
      echo "> 본 폴더는 ${DOC_TYPE} 폴더 분할 산출 (ADR-0030). 폴더 내 sub-file 목록."
      echo ""
      echo "## 변경 이력"
      echo ""
      echo "| Version | Date | Author | Change |"
      echo "|---|---|---|---|"
      echo "| v0.1 | ${TODAY} | <author> | 초안 (scaffold-doc.sh folder-split 생성) |"
      echo ""
      echo "## 파일 목록"
      echo ""
      echo "| 파일 | 한 줄 요약 |"
      echo "|---|---|"
      for s in $(seq 0 $((SUB_COUNT - 1))); do
        SUB_SLUG=$(yq ".folder_split.subfiles[${s}].slug" "${SCHEMA_FILE}" | tr -d '"')
        SUB_TITLE=$(yq ".folder_split.subfiles[${s}].title" "${SCHEMA_FILE}" | tr -d '"')
        echo "| [${SUB_SLUG}.md](${SUB_SLUG}.md) | ${SUB_TITLE} |"
      done
      echo ""
      echo "## 정합"
      echo "- 정본 schema: \`.claude/schemas/${DOC_TYPE}.schema.yaml\` (\`folder_split\` 블록)"
      echo "- 폴더 분할 결정: [ADR-0030](../adr/0030-test-design-folder-split-scaffold.md)"
      echo "- 게이트: ${GATE_VALUE}"
    } > "${TARGET_DIR}/INDEX.md"
    echo "WROTE: ${TARGET_DIR}/INDEX.md (ADR-0030 분할 모드 INDEX)"
  fi

  echo ""
  echo "폴더 분할 모드 완료: 생성 ${GENERATED} / skip ${SKIPPED} / 총 ${SUB_COUNT}"
  echo ""
  echo "다음 단계:"
  echo "  1. 각 sub-file frontmatter의 author/date를 실제 값으로 채우기"
  echo "  2. 각 sub-file의 <!-- TODO --> 채우기"
  echo "  3. 검증(각 파일): bash .claude/scripts/validate-doc.sh ${TARGET_DIR}/<slug>.md"
  exit 0
fi
# ─── 단일 파일 모드 (기존 동작) ─────────────────────────────────────

# 출력 경로 충돌 검사
if [ -e "${OUT_PATH}" ]; then
  echo "ERROR: 출력 경로 이미 존재 — ${OUT_PATH} (덮어쓰기 방지)" >&2
  exit 2
fi

# 출력 디렉토리 생성
mkdir -p "$(dirname "${OUT_PATH}")"

# schema에서 추출
GATE_VALUE=$(yq '.gate_value // ""' "${SCHEMA_FILE}" | tr -d '"')

# title_pattern을 사람이 읽기 좋은 placeholder로 변환
# 정규식 메타문자 → 플레이스홀더
# ADR-0013: 06/07/08/09 schema에 (HLD)/(LLD — ...) 마커가 포함됨 — 리터럴 괄호는 보존
TITLE_HINT=$(yq '.title_pattern // "# <Title>"' "${SCHEMA_FILE}" | tr -d '"' \
  | sed -E 's/^\^//; s/\$$//' \
  | sed -E 's/\[0-9\]\{4\}/NNNN/g; s/\[0-9\]\{2,\}/NN/g; s/\[0-9\]\+/N/g' \
  | sed -E 's/\.\+/<TITLE>/g' \
  | sed -E 's/\\\(/(/g; s/\\\)/)/g' \
  | sed -E 's/\\\\//g')

# 빈 제목 방어
[ -z "${TITLE_HINT}" ] && TITLE_HINT="# <Title>"

# frontmatter 작성
cat > "${OUT_PATH}" <<EOF
---
doc_type: ${DOC_TYPE}
version: v0.1 (Draft)
status: Draft
author: <name@email>
date: ${TODAY}
gate: ${GATE_VALUE}
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

${TITLE_HINT}

<!-- 본 제목은 schema(${DOC_TYPE}.schema.yaml)의 title_pattern에서 자동 생성된 placeholder.
     플레이스홀더(<TITLE>, NNNN 등)를 실제 값으로 채워주세요. -->

<!-- scaffold-doc.sh 자동 생성 (${TODAY}). 본 골격은 schema(${DOC_TYPE}.schema.yaml)에서 추출되었다.
     검증: .claude/scripts/validate-doc.sh ${OUT_PATH}
     관련 정책: docs/planning/conventions/document-manifest.md, file-numbering.md, foldering-rules.md -->

EOF

# 섹션 골격 작성
SECTION_COUNT=$(yq '.sections | length // 0' "${SCHEMA_FILE}")
for i in $(seq 0 $((SECTION_COUNT - 1))); do
  HEADING=$(yq ".sections[${i}].heading" "${SCHEMA_FILE}" | tr -d '"')
  REQUIRED=$(yq ".sections[${i}].required // false" "${SCHEMA_FILE}")
  SEVERITY=$(yq ".sections[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')
  HAS_TABLE=$(yq ".sections[${i}].must_contain_table // false" "${SCHEMA_FILE}")
  HAS_CODEBLOCK=$(yq ".sections[${i}].must_contain_codeblock // false" "${SCHEMA_FILE}")

  echo "${HEADING}" >> "${OUT_PATH}"
  echo "" >> "${OUT_PATH}"

  # 변경 이력 섹션은 자동 표 삽입 (heading 끝이 "변경 이력"으로 끝나는 경우)
  if echo "${HEADING}" | grep -qE "변경 이력$"; then
    cat >> "${OUT_PATH}" <<EOF
| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | ${TODAY} | <author> | 초안 (scaffold-doc.sh 생성) |

EOF
    continue
  fi

  REQ_TAG=""
  [ "${REQUIRED}" = "true" ] && REQ_TAG="필수, severity=${SEVERITY}"

  echo "<!-- TODO ${REQ_TAG} -->" >> "${OUT_PATH}"
  echo "" >> "${OUT_PATH}"

  # 표가 필요한 경우 — schema에서 컬럼 찾아 헤더 생성
  if [ "${HAS_TABLE}" = "true" ]; then
    # tables 배열에서 in_section 일치하는 항목 찾기
    TABLE_COUNT=$(yq '.tables | length // 0' "${SCHEMA_FILE}")
    for t in $(seq 0 $((TABLE_COUNT - 1))); do
      T_SECTION=$(yq ".tables[${t}].in_section" "${SCHEMA_FILE}" | tr -d '"')
      if [ "${T_SECTION}" = "${HEADING}" ]; then
        COLS=$(yq ".tables[${t}].columns | join(\" | \")" "${SCHEMA_FILE}" | tr -d '"')
        SEP=$(yq ".tables[${t}].columns | map(\"---\") | join(\" | \")" "${SCHEMA_FILE}" | tr -d '"')
        echo "| ${COLS} |" >> "${OUT_PATH}"
        echo "| ${SEP} |" >> "${OUT_PATH}"
        echo "" >> "${OUT_PATH}"
        break
      fi
    done
  fi

  # 코드블록이 필요한 경우
  if [ "${HAS_CODEBLOCK}" = "true" ]; then
    echo '```' >> "${OUT_PATH}"
    echo "<!-- TODO: 코드블록 본문 -->" >> "${OUT_PATH}"
    echo '```' >> "${OUT_PATH}"
    echo "" >> "${OUT_PATH}"
  fi
done

# ADR-0019: 변경 이력은 schema 28종 모두 sections[0]에 강제되므로 fallback 불필요.
# schema sections 순회 §86~139에서 이미 H1 직후에 자동 작성된다.

echo "WROTE: ${OUT_PATH}"

# ADR-0015 §2.1 — 1수준 산출 폴더 안 INDEX.md 자동 골격 생성
# 출력 경로가 docs/planning/NN-<name>/NN-<name>.md 패턴이면 부모 폴더에 INDEX.md 자동 생성
PARENT_DIR=$(dirname "${OUT_PATH}")
if [[ "${PARENT_DIR}" =~ docs/planning/(0[1-9]|1[0-4])-[a-z][a-z0-9-]*$ ]] && [ ! -f "${PARENT_DIR}/INDEX.md" ]; then
  FOLDER_NAME=$(basename "${PARENT_DIR}")
  OUT_FILENAME=$(basename "${OUT_PATH}")
  cat > "${PARENT_DIR}/INDEX.md" <<EOF
---
doc_type: index
version: v0.1
status: Draft
author: <name@email>
date: ${TODAY}
gate: ${GATE_VALUE}
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# ${FOLDER_NAME} — Index

> 본 폴더는 1수준 산출 \`${FOLDER_NAME}\` (ADR-0015 §2.1 전수 폴더 구조). 폴더 내 메인 파일·분할 sub 파일 목록.

<!-- gen-index.sh가 폴더 내 .md를 자동 스캔하여 갱신. 수동 작성한 "한 줄 요약"은 보존. -->

| 파일 | 한 줄 요약 |
|---|---|
| [${OUT_FILENAME}](${OUT_FILENAME}) | <한 줄 요약 작성> |

## 정합
- 정본 schema: \`.claude/schemas/${DOC_TYPE}.schema.yaml\`
- 게이트: ${GATE_VALUE}
- 폴더 구조: [ADR-0015](../adr/0015-mandatory-folder-structure-and-test-coverage.md)
EOF
  echo "WROTE: ${PARENT_DIR}/INDEX.md (ADR-0015 자동 골격)"
fi

echo ""
echo "다음 단계:"
echo "  1. frontmatter의 author/date를 실제 값으로 채우기"
echo "  2. title의 placeholder(<TITLE>, NNNN, N 등)를 실제 값으로 교체"
echo "  3. 각 섹션의 <!-- TODO --> 채우기"
echo "  4. 검증: bash .claude/scripts/validate-doc.sh ${OUT_PATH}"
echo ""
echo "참고: 골격 자체는 placeholder 잔존 시 validate FAIL이 정상 (schema 강제)"
