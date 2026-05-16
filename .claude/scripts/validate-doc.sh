#!/usr/bin/env bash
# validate-doc.sh — 산출 문서가 .claude/schemas/<doc_type>.schema.yaml에 적합한지 검증.
#
# 사용:
#   ./validate-doc.sh <doc_path>                # doc_type은 frontmatter에서 자동 추출
#   ./validate-doc.sh <doc_path> --doc-type=X   # 명시
#
# Exit codes:
#   0 = OK (모든 BLOCK 통과, WARN은 stderr로 보고)
#   2 = BLOCK 위반 (schema 강제 사항 미충족, /plan-eng-review BLOCKED)
#   3 = 사용 오류 (doc 미존재, schema 미존재, doc_type 불명)
#
# 검증 항목 (정합: docs/planning/conventions/document-manifest.md + .claude/schemas/_common.yaml):
#   - frontmatter 7필드 + doc_type별 enum/pattern
#   - 필수 섹션 존재 + 순서 (severity 따라 BLOCK/WARN)
#   - 표 컬럼 일치 (행 수 강제 X — _common.yaml 안내 참조)
#   - subsection 패턴 (개수 강제 X)
#   - ID 패턴 (R-/F-/UC-/RISK-/AC- 등)
#   - 변경 이력 표 형식
#
# 의존성: yq (mikefarah/yq v4+)
# yq 미설치 시 안내: docs/planning/operations/runbook.md §4

set -uo pipefail

SCHEMAS_DIR="$(cd "$(dirname "$0")/../schemas" && pwd)"
DOC_PATH=""
DOC_TYPE=""
EXIT_CODE=0

usage() {
  echo "usage: $0 <doc_path> [--doc-type=X]" >&2
  exit 3
}

# 인자 파싱
for arg in "$@"; do
  case "${arg}" in
    --doc-type=*) DOC_TYPE="${arg#--doc-type=}" ;;
    -h|--help) usage ;;
    *) [ -z "${DOC_PATH}" ] && DOC_PATH="${arg}" || usage ;;
  esac
done

[ -z "${DOC_PATH}" ] && usage
[ ! -f "${DOC_PATH}" ] && { echo "ERROR: doc not found: ${DOC_PATH}" >&2; exit 3; }

# yq 확인
if ! command -v yq >/dev/null 2>&1; then
  echo "ERROR: yq 미설치 — operations/runbook.md §4 fallback 참조" >&2
  exit 3
fi

# frontmatter 추출 (--- 블록 사이)
FRONTMATTER=$(awk '/^---$/{c++; next} c==1' "${DOC_PATH}")
if [ -z "${FRONTMATTER}" ]; then
  echo "BLOCK: frontmatter 없음 — document-manifest.md §1" >&2
  exit 2
fi

# doc_type 자동 추출 (인자 미지정 시)
if [ -z "${DOC_TYPE}" ]; then
  DOC_TYPE=$(echo "${FRONTMATTER}" | yq '.doc_type // ""' 2>/dev/null | tr -d '"')
fi

if [ -z "${DOC_TYPE}" ] || [ "${DOC_TYPE}" = "null" ]; then
  echo "BLOCK: doc_type 추출 실패 — frontmatter에 doc_type 필드 필수" >&2
  exit 2
fi

SCHEMA_FILE="${SCHEMAS_DIR}/${DOC_TYPE}.schema.yaml"
COMMON_FILE="${SCHEMAS_DIR}/_common.yaml"

[ ! -f "${SCHEMA_FILE}" ] && { echo "ERROR: schema not found for doc_type=${DOC_TYPE}: ${SCHEMA_FILE}" >&2; exit 3; }
[ ! -f "${COMMON_FILE}" ] && { echo "ERROR: _common.yaml not found: ${COMMON_FILE}" >&2; exit 3; }

report_block() { echo "BLOCK [${DOC_TYPE}] $1" >&2; EXIT_CODE=2; }
report_warn()  { echo "WARN  [${DOC_TYPE}] $1" >&2; }
report_info()  { echo "INFO  [${DOC_TYPE}] $1" >&2; }

# === 1. frontmatter 7필드 검증 ===
for field in doc_type version status author date gate related; do
  VAL=$(echo "${FRONTMATTER}" | yq ".${field} // \"\"" 2>/dev/null)
  if [ -z "${VAL}" ] || [ "${VAL}" = "null" ] || [ "${VAL}" = '""' ]; then
    report_block "frontmatter 누락 — ${field}"
  fi
done

# === 2. doc_type별 frontmatter enum/pattern 검증 ===
EXPECTED_DT=$(yq ".frontmatter.doc_type.value // \"\"" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
if [ -n "${EXPECTED_DT}" ] && [ "${EXPECTED_DT}" != "null" ]; then
  ACTUAL_DT=$(echo "${FRONTMATTER}" | yq '.doc_type // ""' | tr -d '"')
  [ "${ACTUAL_DT}" != "${EXPECTED_DT}" ] && report_block "doc_type 불일치 — expected=${EXPECTED_DT}, actual=${ACTUAL_DT}"
fi

EXPECTED_GATE=$(yq ".frontmatter.gate.value // \"\"" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
if [ -n "${EXPECTED_GATE}" ] && [ "${EXPECTED_GATE}" != "null" ]; then
  ACTUAL_GATE=$(echo "${FRONTMATTER}" | yq '.gate // ""' | tr -d '"')
  [ "${ACTUAL_GATE}" != "${EXPECTED_GATE}" ] && report_block "gate 불일치 — expected=${EXPECTED_GATE}, actual=${ACTUAL_GATE}"
fi

# status enum
STATUS=$(echo "${FRONTMATTER}" | yq '.status // ""' | tr -d '"')
case "${STATUS}" in
  Draft|Accepted|Deprecated|Superseded) ;;
  *) report_block "status enum 위반 — ${STATUS} (Draft/Accepted/Deprecated/Superseded)" ;;
esac

# author 형식 (이메일)
AUTHOR=$(echo "${FRONTMATTER}" | yq '.author // ""' | tr -d '"')
echo "${AUTHOR}" | grep -q "@" || report_block "author 이메일 형식 위반 — ${AUTHOR}"

# date 형식
DATE=$(echo "${FRONTMATTER}" | yq '.date // ""' | tr -d '"')
echo "${DATE}" | grep -qE "^[0-9]{4}-[0-9]{2}-[0-9]{2}$" || report_block "date 형식 위반 — ${DATE}"

# === ADR-0030: sub-file 검증 위임 분기 ===
# schema에 folder_split.enabled=true이고 doc 파일명이 subfiles[].slug 중 하나와 일치하면
# 메인 schema의 title_pattern·sections·tables 등 검증을 건너뛰고,
# sub-file 자체 sections + 변경 이력 §0만 검증한 뒤 early exit.
FOLDER_SPLIT_ENABLED=$(yq '.folder_split.enabled // false' "${SCHEMA_FILE}" 2>/dev/null)
if [ "${FOLDER_SPLIT_ENABLED}" = "true" ]; then
  DOC_BASENAME=$(basename "${DOC_PATH}" .md)
  SUB_COUNT=$(yq '.folder_split.subfiles | length // 0' "${SCHEMA_FILE}" 2>/dev/null)
  SUBFILE_INDEX=-1
  for s in $(seq 0 $((SUB_COUNT - 1))); do
    SLUG=$(yq ".folder_split.subfiles[${s}].slug" "${SCHEMA_FILE}" | tr -d '"')
    if [ "${DOC_BASENAME}" = "${SLUG}" ]; then
      SUBFILE_INDEX=${s}
      break
    fi
  done

  if [ "${SUBFILE_INDEX}" -ge 0 ]; then
    report_info "ADR-0030 sub-file 검증 모드 (slug=${DOC_BASENAME}) — 메인 schema title/sections/tables 건너뜀 / ADR-0034 sub-file 본문 BLOCK 적용"

    # 변경 이력 §0 BLOCK (ADR-0019 정합)
    grep -qF "## 변경 이력" "${DOC_PATH}" || report_block "sub-file 변경 이력 §0 누락"

    # sub-file 자체 sections 검증 (WARN 강도 — 골격 채워가는 과정에서 유연성)
    SUB_SEC_COUNT=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].sections | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
    for i in $(seq 0 $((SUB_SEC_COUNT - 1))); do
      SUB_HEADING=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].sections[${i}]" "${SCHEMA_FILE}" | tr -d '"')
      grep -qF "${SUB_HEADING}" "${DOC_PATH}" || report_warn "sub-file 섹션 누락 — ${SUB_HEADING}"
    done

    # === ADR-0034: sub-file 본문 BLOCK 검증 ===

    # (1) subfiles[].must_contain[] — 패턴 grep (in_section 옵션 있으면 해당 섹션 본문만)
    # ADR-0034: 헤딩 라인(^#)과 TODO 주석 라인(<!--)은 *본문이 아니므로* 검색에서 제외
    # (scaffold-doc.sh의 TODO 마커가 헤딩 텍스트를 반복 포함하여 false-positive 통과 차단)
    MC_COUNT=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
    for i in $(seq 0 $((MC_COUNT - 1))); do
      MC_LABEL=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain[${i}].label" "${SCHEMA_FILE}" | tr -d '"')
      MC_PATTERN=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain[${i}].pattern // \"\"" "${SCHEMA_FILE}" | tr -d '"')
      MC_SEV=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')
      MC_IN_SEC=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain[${i}].in_section // \"\"" "${SCHEMA_FILE}" | tr -d '"')

      [ -z "${MC_PATTERN}" ] || [ "${MC_PATTERN}" = "null" ] && continue

      # 검색 범위: in_section 지정 시 해당 섹션 본문만, 아니면 전체 문서
      if [ -n "${MC_IN_SEC}" ] && [ "${MC_IN_SEC}" != "null" ]; then
        SEC_START=$(grep -nF "${MC_IN_SEC}" "${DOC_PATH}" | head -1 | cut -d: -f1)
        if [ -z "${SEC_START}" ]; then
          # 섹션 자체가 없으면 sections 검증에서 WARN 처리, must_contain은 skip
          continue
        fi
        SEARCH_BODY=$(awk -v s="${SEC_START}" '
          NR == s { print; in_block=1; next }
          in_block && /^## / { exit }
          in_block { print }
        ' "${DOC_PATH}")
      else
        SEARCH_BODY=$(cat "${DOC_PATH}")
      fi

      # ADR-0034: 헤딩(^#)·HTML 주석(<!--)·표 헤더/구분(|---|)·frontmatter 라인 제외 후 본문에서만 검색
      SEARCH_BODY_CLEAN=$(echo "${SEARCH_BODY}" | grep -vE "^(#|<!--|---|frontmatter:)" | grep -v "^$")

      if ! echo "${SEARCH_BODY_CLEAN}" | grep -qE "${MC_PATTERN}"; then
        SCOPE_LABEL="${MC_IN_SEC:-문서 전체}"
        case "${MC_SEV}" in
          BLOCK) report_block "sub-file 본문 누락 — ${SCOPE_LABEL} 에 [${MC_LABEL}] 없음 (pattern: ${MC_PATTERN}) — ADR-0034" ;;
          WARN)  report_warn  "sub-file 본문 누락 (권고) — ${SCOPE_LABEL} 에 [${MC_LABEL}]" ;;
        esac
      fi
    done

    # (2) subfiles[].subsection_patterns[] — 최소 개수 (예: ^### (R-|F-) ≥ 1)
    SP_COUNT=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].subsection_patterns | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
    for i in $(seq 0 $((SP_COUNT - 1))); do
      SP_PATTERN=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].subsection_patterns[${i}].pattern // \"\"" "${SCHEMA_FILE}" | tr -d '"')
      SP_MIN=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].subsection_patterns[${i}].min_count // 1" "${SCHEMA_FILE}")
      SP_SEV=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].subsection_patterns[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

      [ -z "${SP_PATTERN}" ] || [ "${SP_PATTERN}" = "null" ] && continue

      # grep -c는 0매치 시 exit 1 → set -u 환경에서 변수 오염 방지
      MATCH_COUNT=$(grep -cE "${SP_PATTERN}" "${DOC_PATH}" 2>/dev/null) || MATCH_COUNT=0
      [ -z "${MATCH_COUNT}" ] && MATCH_COUNT=0
      if [ "${MATCH_COUNT}" -lt "${SP_MIN}" ] 2>/dev/null; then
        case "${SP_SEV}" in
          BLOCK) report_block "sub-file subsection 누락 — 패턴 '${SP_PATTERN}' ${MATCH_COUNT}건 < min_count ${SP_MIN} — ADR-0034" ;;
          WARN)  report_warn  "sub-file subsection 누락 (권고) — 패턴 '${SP_PATTERN}' ${MATCH_COUNT}건" ;;
        esac
      fi
    done

    # (3) subfiles[].must_contain_in_subsection[] — subsection 본문 안에 패턴
    MCS_COUNT=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain_in_subsection | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
    for i in $(seq 0 $((MCS_COUNT - 1))); do
      MCS_SUB_PAT=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain_in_subsection[${i}].in_subsection_pattern // \"\"" "${SCHEMA_FILE}" | tr -d '"')
      MCS_LABEL=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain_in_subsection[${i}].label" "${SCHEMA_FILE}" | tr -d '"')
      MCS_PATTERN=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain_in_subsection[${i}].pattern // \"\"" "${SCHEMA_FILE}" | tr -d '"')
      MCS_SEV=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].must_contain_in_subsection[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

      [ -z "${MCS_SUB_PAT}" ] || [ "${MCS_SUB_PAT}" = "null" ] && continue
      [ -z "${MCS_PATTERN}" ] || [ "${MCS_PATTERN}" = "null" ] && continue

      SUB_STARTS=$(grep -nE "${MCS_SUB_PAT}" "${DOC_PATH}" | cut -d: -f1)
      [ -z "${SUB_STARTS}" ] && continue

      for START in ${SUB_STARTS}; do
        HEADING_LINE=$(sed -n "${START}p" "${DOC_PATH}" | sed 's/^### //; s/^## //')
        BODY=$(awk -v s="${START}" '
          NR == s { print; in_block=1; next }
          in_block && /^(### |## )/ { exit }
          in_block { print }
        ' "${DOC_PATH}")

        if ! echo "${BODY}" | grep -qE "${MCS_PATTERN}"; then
          case "${MCS_SEV}" in
            BLOCK) report_block "sub-file subsection 내용 누락 — '${HEADING_LINE}' 에 [${MCS_LABEL}] 없음 (pattern: ${MCS_PATTERN}) — ADR-0034" ;;
            WARN)  report_warn  "sub-file subsection 내용 누락 (권고) — '${HEADING_LINE}' 에 [${MCS_LABEL}]" ;;
          esac
        fi
      done
    done

    # (4) subfiles[].tables[].forbidden_cells — in_section 표 안 cell 금지값
    TBL_COUNT=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].tables | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
    for i in $(seq 0 $((TBL_COUNT - 1))); do
      TBL_IN_SEC=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].tables[${i}].in_section // \"\"" "${SCHEMA_FILE}" | tr -d '"')
      TBL_FORB=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].tables[${i}].forbidden_cells | join(\",\") // \"\"" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
      TBL_SEV=$(yq ".folder_split.subfiles[${SUBFILE_INDEX}].tables[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

      [ -z "${TBL_IN_SEC}" ] || [ "${TBL_IN_SEC}" = "null" ] && continue
      [ -z "${TBL_FORB}" ] || [ "${TBL_FORB}" = "null" ] && continue

      grep -qF "${TBL_IN_SEC}" "${DOC_PATH}" || continue
      SEC_LINE=$(grep -nF "${TBL_IN_SEC}" "${DOC_PATH}" | head -1 | cut -d: -f1)
      TABLE_BLOCK=$(awk -v start="${SEC_LINE}" '
        NR > start && NR <= start + 500 {
          if (/^\|/) { print; in_table=1; next }
          if (in_table) exit
        }
      ' "${DOC_PATH}")
      [ -z "${TABLE_BLOCK}" ] && continue
      DATA_LINES=$(echo "${TABLE_BLOCK}" | awk 'NR > 2 && /^\|/ {print}')

      IFS=',' read -ra FORB_VALS <<< "${TBL_FORB}"
      # 표 데이터 영역 전체에서 forbidden 값이 셀로 등장하는지 검사
      # (헤더에 ❌가 나오지 않으므로 전체 grep으로 충분 + sub-shell EXIT_CODE 전파 문제 회피)
      for forb in "${FORB_VALS[@]}"; do
        forb_t=$(echo "${forb}" | sed 's/^ *//; s/ *$//')
        # 셀 경계 매칭: " ❌ " 또는 "|❌|" 형태
        if echo "${DATA_LINES}" | grep -qE "(\| *${forb_t} *\|| *${forb_t} *\|)"; then
          case "${TBL_SEV}" in
            BLOCK) report_block "sub-file 표 셀 금지값 — ${TBL_IN_SEC} 셀에 '${forb_t}' 존재 — ADR-0034 (✅ 또는 N/A만 허용)" ;;
            WARN)  report_warn  "sub-file 표 셀 금지값 (권고) — ${TBL_IN_SEC} 셀에 '${forb_t}'" ;;
          esac
        fi
      done
    done

    if [ ${EXIT_CODE} -eq 0 ]; then
      echo "OK [${DOC_TYPE}/subfile:${DOC_BASENAME}] ${DOC_PATH}"
    fi
    exit ${EXIT_CODE}
  fi
fi

# === 3. title_pattern 검증 ===
TITLE_PATTERN=$(yq '.title_pattern // ""' "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
if [ -n "${TITLE_PATTERN}" ] && [ "${TITLE_PATTERN}" != "null" ]; then
  TITLE_LINE=$(grep -m1 "^# " "${DOC_PATH}" || echo "")
  echo "${TITLE_LINE}" | grep -qE "${TITLE_PATTERN}" || report_block "title 패턴 위반 — '${TITLE_LINE}' !~ ${TITLE_PATTERN}"
fi

# === 4. 필수 섹션 검증 ===
SECTION_COUNT=$(yq '.sections | length // 0' "${SCHEMA_FILE}" 2>/dev/null)
for i in $(seq 0 $((SECTION_COUNT - 1))); do
  HEADING=$(yq ".sections[${i}].heading" "${SCHEMA_FILE}" | tr -d '"')
  REQUIRED=$(yq ".sections[${i}].required // false" "${SCHEMA_FILE}")
  SEVERITY=$(yq ".sections[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

  # heading은 정규식이 아니라 prefix 매칭 (## 1. ... 등)
  if grep -qF "${HEADING}" "${DOC_PATH}"; then
    continue
  fi

  if [ "${REQUIRED}" = "true" ]; then
    case "${SEVERITY}" in
      BLOCK) report_block "섹션 누락 — ${HEADING}" ;;
      WARN)  report_warn  "섹션 누락 (권고) — ${HEADING}" ;;
      INFO)  report_info  "섹션 누락 (선택) — ${HEADING}" ;;
    esac
  fi
done

# === 5. 표 컬럼 검증 (행 수 강제 없음) ===
TABLE_COUNT=$(yq '.tables | length // 0' "${SCHEMA_FILE}" 2>/dev/null)
for i in $(seq 0 $((TABLE_COUNT - 1))); do
  IN_SECTION=$(yq ".tables[${i}].in_section" "${SCHEMA_FILE}" | tr -d '"')
  COLS=$(yq ".tables[${i}].columns | join(\",\")" "${SCHEMA_FILE}" | tr -d '"')
  SEVERITY=$(yq ".tables[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

  # 해당 섹션 존재 여부 (없으면 스킵 — 섹션 검증에서 이미 보고)
  grep -qF "${IN_SECTION}" "${DOC_PATH}" || continue

  # 섹션 다음 첫 표 헤더 라인 추출 (단순화: 섹션 다음 30줄 안에서 |로 시작하는 라인)
  SECTION_LINE=$(grep -nF "${IN_SECTION}" "${DOC_PATH}" | head -1 | cut -d: -f1)
  TABLE_HEADER=$(awk -v start="${SECTION_LINE}" 'NR > start && NR <= start + 30 && /^\|/ {print; exit}' "${DOC_PATH}")

  if [ -z "${TABLE_HEADER}" ]; then
    case "${SEVERITY}" in
      BLOCK) report_block "표 누락 — ${IN_SECTION} (컬럼: ${COLS})" ;;
      WARN)  report_warn  "표 누락 (권고) — ${IN_SECTION}" ;;
    esac
    continue
  fi

  # 컬럼 일치 확인 (각 컬럼이 헤더 라인에 포함되어야)
  IFS=',' read -ra EXPECTED_COLS <<< "${COLS}"
  for col in "${EXPECTED_COLS[@]}"; do
    col_trimmed=$(echo "${col}" | sed 's/^ *//; s/ *$//')
    echo "${TABLE_HEADER}" | grep -qF "${col_trimmed}" || {
      case "${SEVERITY}" in
        BLOCK) report_block "표 컬럼 누락 — ${IN_SECTION}.${col_trimmed}" ;;
        WARN)  report_warn  "표 컬럼 누락 (권고) — ${IN_SECTION}.${col_trimmed}" ;;
      esac
    }
  done

  # === 5a. tables[].cell_constraints 검증 (ADR-0023) ===
  # 셀 값 강제 — 특정 컬럼에 금지값 없도록 (예: 12 test-design 카탈로그 단위/통합/E2E 컬럼에 ❌ 금지)
  CC_COUNT=$(yq ".tables[${i}].cell_constraints | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
  if [ "${CC_COUNT}" -gt 0 ] 2>/dev/null; then
    # 표 전체 블록 추출 (헤더 + 구분선 + 데이터 행)
    TABLE_BLOCK=$(awk -v start="${SECTION_LINE}" '
      NR > start && NR <= start + 500 {
        if (/^\|/) { print; in_table=1; next }
        if (in_table) exit
      }
    ' "${DOC_PATH}")

    if [ -n "${TABLE_BLOCK}" ]; then
      DATA_LINES=$(echo "${TABLE_BLOCK}" | awk 'NR > 2 && /^\|/ {print}')

      for j in $(seq 0 $((CC_COUNT - 1))); do
        CONS_COLS=$(yq ".tables[${i}].cell_constraints[${j}].columns | join(\",\")" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
        CONS_FORB=$(yq ".tables[${i}].cell_constraints[${j}].forbidden | join(\",\")" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
        CONS_SEV=$(yq ".tables[${i}].cell_constraints[${j}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')
        [ -z "${CONS_COLS}" ] || [ -z "${CONS_FORB}" ] && continue

        IFS=',' read -ra TGT_COLS <<< "${CONS_COLS}"
        IFS=',' read -ra FORB_VALS <<< "${CONS_FORB}"

        for tcol in "${TGT_COLS[@]}"; do
          tcol_t=$(echo "${tcol}" | sed 's/^ *//; s/ *$//')
          # 헤더에서 컬럼 인덱스 추출 (1-based, $1은 leading |로 empty)
          COL_IDX=$(echo "${TABLE_HEADER}" | awk -F'|' -v t="${tcol_t}" '
            { for (k=2; k<=NF; k++) { v=$k; gsub(/^ +| +$/, "", v); if (v == t) { print k; exit } } }')
          [ -z "${COL_IDX}" ] && continue

          while IFS= read -r ROW; do
            [ -z "${ROW}" ] && continue
            CELL=$(echo "${ROW}" | awk -F'|' -v c="${COL_IDX}" '{v=$c; gsub(/^ +| +$/, "", v); print v}')
            for forb in "${FORB_VALS[@]}"; do
              forb_t=$(echo "${forb}" | sed 's/^ *//; s/ *$//')
              if [ "${CELL}" = "${forb_t}" ]; then
                case "${CONS_SEV}" in
                  BLOCK) report_block "표 셀 금지값 — ${IN_SECTION}.${tcol_t}='${forb_t}' (ADR-0023). 각 R-/F-ID는 모든 테스트 레벨을 결정해야 함 (✅ 또는 N/A)" ;;
                  WARN)  report_warn  "표 셀 금지값 (권고) — ${IN_SECTION}.${tcol_t}='${forb_t}'" ;;
                esac
              fi
            done
          done <<< "${DATA_LINES}"
        done
      done
    fi
  fi
done

# === 5b. per-subsection must_contain 검증 (ADR-0014·0023) ===
# 04 SRS·05 PRD의 R-ID/F-ID별 검증 시나리오 3축(단위·통합·E2E) + happy/failure path BLOCK
# 12 test-design의 R-/F- fan-in 카탈로그 출처·레벨 BLOCK
for KEY in per_requirement_must_contain per_feature_must_contain scenario_fanin_must_contain; do
  SUBSEC_PATTERN=$(yq ".${KEY}.in_subsection_pattern // \"\"" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
  [ -z "${SUBSEC_PATTERN}" ] || [ "${SUBSEC_PATTERN}" = "null" ] && continue

  MC_COUNT=$(yq ".${KEY}.must_contain | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
  [ "${MC_COUNT}" -eq 0 ] 2>/dev/null && continue

  # subsection 시작 라인 모두 수집 (R-/F- 단위 등)
  SUB_STARTS=$(grep -nE "${SUBSEC_PATTERN}" "${DOC_PATH}" | cut -d: -f1)
  [ -z "${SUB_STARTS}" ] && continue

  for START in ${SUB_STARTS}; do
    HEADING_LINE=$(sed -n "${START}p" "${DOC_PATH}" | sed 's/^### //; s/^## //')
    # subsection 본문: START 라인부터 다음 ### 또는 ## 전까지
    BODY=$(awk -v s="${START}" '
      NR == s { print; in_block=1; next }
      in_block && /^(### |## )/ { exit }
      in_block { print }
    ' "${DOC_PATH}")

    for i in $(seq 0 $((MC_COUNT - 1))); do
      LABEL=$(yq ".${KEY}.must_contain[${i}].label" "${SCHEMA_FILE}" | tr -d '"')
      PATTERN=$(yq ".${KEY}.must_contain[${i}].pattern // \"\"" "${SCHEMA_FILE}" | tr -d '"')
      MC_SEV=$(yq ".${KEY}.must_contain[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

      [ -z "${PATTERN}" ] || [ "${PATTERN}" = "null" ] && continue

      if ! echo "${BODY}" | grep -qE "${PATTERN}"; then
        case "${MC_SEV}" in
          BLOCK) report_block "subsection 내용 누락 — '${HEADING_LINE}' 에 [${LABEL}] 없음 (pattern: ${PATTERN})" ;;
          WARN)  report_warn  "subsection 내용 누락 (권고) — '${HEADING_LINE}' 에 [${LABEL}]" ;;
          INFO)  report_info  "subsection 내용 누락 — '${HEADING_LINE}' 에 [${LABEL}]" ;;
        esac
      fi
    done
  done
done

# === 5c. in_section must_contain 검증 (strategy_must_contain 등) ===
# 12 test-design ## 1. 테스트 전략 안의 방법론·레벨·커버리지 BLOCK
# ADR-0037: runnability_assets_must_contain (scaffolding §7) + local_runnability (feature-ai-qa §7)
# ADR-0038: styling_solution_must_contain (scaffolding §8) + design_tokens_must_contain (screen-design §3)
# ADR-0039: ADR-0010 정합 완성 — 기존 schema 정의만 있고 미검증이던 5개 룰 자동 강제
#   - ai_gate_must_contain (feature-ai-qa §2 6축 라벨) ADR-0011/0037/0038
#   - verdict_must_contain (feature-ai-qa §0) ADR-0010/0011/0032
#   - ui_change_verification (feature-ai-qa §6) ADR-0011/0038
#   - design_pattern_must_contain (scaffolding §3 아키텍처 패턴) ADR-0010
for KEY in strategy_must_contain runnability_assets_must_contain styling_solution_must_contain design_tokens_must_contain local_runnability ai_gate_must_contain verdict_must_contain ui_change_verification design_pattern_must_contain env_var_separation_must_contain; do
  SECTION_HEAD=$(yq ".${KEY}.in_section // \"\"" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
  [ -z "${SECTION_HEAD}" ] || [ "${SECTION_HEAD}" = "null" ] && continue

  MC_COUNT=$(yq ".${KEY}.must_contain | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
  [ "${MC_COUNT}" -eq 0 ] 2>/dev/null && continue

  SEC_START=$(grep -nF "${SECTION_HEAD}" "${DOC_PATH}" | head -1 | cut -d: -f1)
  [ -z "${SEC_START}" ] && continue

  BODY=$(awk -v s="${SEC_START}" '
    NR == s { print; in_block=1; next }
    in_block && /^## / { exit }
    in_block { print }
  ' "${DOC_PATH}")

  for i in $(seq 0 $((MC_COUNT - 1))); do
    LABEL=$(yq ".${KEY}.must_contain[${i}].label" "${SCHEMA_FILE}" | tr -d '"')
    PATTERN=$(yq ".${KEY}.must_contain[${i}].pattern // \"\"" "${SCHEMA_FILE}" | tr -d '"')
    MC_SEV=$(yq ".${KEY}.must_contain[${i}].severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

    [ -z "${PATTERN}" ] || [ "${PATTERN}" = "null" ] && continue

    if ! echo "${BODY}" | grep -qE "${PATTERN}"; then
      case "${MC_SEV}" in
        BLOCK) report_block "섹션 내용 누락 — ${SECTION_HEAD} 에 [${LABEL}] 없음 (pattern: ${PATTERN})" ;;
        WARN)  report_warn  "섹션 내용 누락 (권고) — ${SECTION_HEAD} 에 [${LABEL}]" ;;
        INFO)  report_info  "섹션 내용 누락 — ${SECTION_HEAD} 에 [${LABEL}]" ;;
      esac
    fi
  done
done

# === 5d. in_section required_subsections 검증 (ADR-0039 — ADR-0010 정합 완성) ===
# in_section 안에 ### 시작 subsection이 정의된 순서대로 존재하는지 검증
# - test_plan_must_contain (feature-ai-qa §1 Test Plan 4블록): Build / Automated tests / Manual verification / DoD coverage
# - consequences_must_contain (adr §4 결과): 긍정 / 부정 / 영향 받는 문서
for KEY in test_plan_must_contain consequences_must_contain; do
  SECTION_HEAD=$(yq ".${KEY}.in_section // \"\"" "${SCHEMA_FILE}" 2>/dev/null | tr -d '"')
  [ -z "${SECTION_HEAD}" ] || [ "${SECTION_HEAD}" = "null" ] && continue

  RS_COUNT=$(yq ".${KEY}.required_subsections | length // 0" "${SCHEMA_FILE}" 2>/dev/null)
  [ "${RS_COUNT}" -eq 0 ] 2>/dev/null && continue

  RS_SEV=$(yq ".${KEY}.severity // \"WARN\"" "${SCHEMA_FILE}" | tr -d '"')

  SEC_START=$(grep -nF "${SECTION_HEAD}" "${DOC_PATH}" | head -1 | cut -d: -f1)
  if [ -z "${SEC_START}" ]; then
    # 섹션 자체 부재는 §4 sections 검증이 보고함 — 여기선 skip
    continue
  fi

  BODY=$(awk -v s="${SEC_START}" '
    NR == s { in_block=1; next }
    in_block && /^## / { exit }
    in_block { print }
  ' "${DOC_PATH}")

  for i in $(seq 0 $((RS_COUNT - 1))); do
    SUB_HEAD=$(yq ".${KEY}.required_subsections[${i}]" "${SCHEMA_FILE}" | tr -d '"')
    [ -z "${SUB_HEAD}" ] || [ "${SUB_HEAD}" = "null" ] && continue

    if ! echo "${BODY}" | grep -qF "${SUB_HEAD}"; then
      case "${RS_SEV}" in
        BLOCK) report_block "subsection 누락 — ${SECTION_HEAD} 안에 '${SUB_HEAD}' 없음" ;;
        WARN)  report_warn  "subsection 누락 (권고) — ${SECTION_HEAD} 안에 '${SUB_HEAD}'" ;;
        INFO)  report_info  "subsection 누락 — ${SECTION_HEAD} 안에 '${SUB_HEAD}'" ;;
      esac
    fi
  done
done

# === 6a. feature-ai-qa 조건부 BLOCK — ui_changed=true 시 (ADR-0011) ===
# UI/FE 변경 PR은 브라우저 골든패스 실증 BLOCK
if [ "${DOC_TYPE}" = "feature-ai-qa" ]; then
  UI_CHANGED=$(echo "${FRONTMATTER}" | yq '.ui_changed // ""' 2>/dev/null | tr -d '"')

  # ui_changed 필드 자체 누락은 항상 BLOCK
  if [ -z "${UI_CHANGED}" ] || [ "${UI_CHANGED}" = "null" ] || [ "${UI_CHANGED}" = '""' ]; then
    report_block "frontmatter 누락 — ui_changed (ADR-0011)"
  fi

  if [ "${UI_CHANGED}" = "true" ]; then
    # golden_path_verified 필수 + true 값
    GPV=$(echo "${FRONTMATTER}" | yq '.golden_path_verified // ""' 2>/dev/null | tr -d '"')
    [ "${GPV}" != "true" ] && report_block "ui_changed=true인데 golden_path_verified != true (ADR-0011)"

    # screenshots 배열 ≥ 1
    SHOTS_LEN=$(echo "${FRONTMATTER}" | yq '.screenshots | length // 0' 2>/dev/null)
    if [ -z "${SHOTS_LEN}" ] || [ "${SHOTS_LEN}" = "null" ] || [ "${SHOTS_LEN}" -lt 1 ] 2>/dev/null; then
      report_block "ui_changed=true인데 screenshots 배열 비었음 — 변경 화면별 1장 이상 필수 (ADR-0011)"
    fi

    # ## 6. UI/FE 변경 검증 섹션 존재
    if ! grep -qF "## 6. UI/FE 변경 검증" "${DOC_PATH}"; then
      report_block "ui_changed=true인데 '## 6. UI/FE 변경 검증' 섹션 누락 (ADR-0011)"
    else
      # 섹션 내 스크린샷 표 컬럼 검증
      SEC_LINE=$(grep -nF "## 6. UI/FE 변경 검증" "${DOC_PATH}" | head -1 | cut -d: -f1)
      SEC_HEADER=$(awk -v start="${SEC_LINE}" 'NR > start && NR <= start + 30 && /^\|/ {print; exit}' "${DOC_PATH}")
      if [ -z "${SEC_HEADER}" ]; then
        report_block "ui_changed=true인데 '## 6. UI/FE 변경 검증' 표 누락 (컬럼: 화면, 시나리오, 스크린샷경로)"
      else
        for col in 화면 시나리오 스크린샷경로; do
          echo "${SEC_HEADER}" | grep -qF "${col}" || report_block "UI/FE 변경 검증 표 컬럼 누락 — ${col} (ADR-0011)"
        done
      fi

      # 콘솔 에러 0개 또는 N/A 명시
      SEC_BODY=$(awk -v start="${SEC_LINE}" 'NR > start && NR <= start + 80 {print}' "${DOC_PATH}")
      echo "${SEC_BODY}" | grep -qE "(콘솔 에러.*(0개|none)|console.*0|N/A 사전 합의)" \
        || report_block "ui_changed=true인데 콘솔 에러 0개 검증 표기 누락 (ADR-0011)"
    fi
  fi
fi

# === 6. 변경 이력 표 검증 (_common.yaml의 version_history, ADR-0019) ===
# 3축: (a) 위치 = H1 직후 첫 ## 섹션, (b) 표 컬럼 = Version/Date/Author/Change,
#       (c) 첫 데이터 행 정합 = frontmatter.version / frontmatter.date
# heading은 ADR-0019로 무번호 강제: "## 변경 이력" (## 6. 변경 이력 등 번호 부착 금지)
if grep -qE "^## 변경 이력$" "${DOC_PATH}"; then
  CHANGELOG_LINE=$(grep -nE "^## 변경 이력$" "${DOC_PATH}" | head -1 | cut -d: -f1)

  # (a) 위치 검증 — H1 다음 첫 ## 섹션이 변경 이력인지
  H1_LINE=$(grep -nE "^# " "${DOC_PATH}" | head -1 | cut -d: -f1)
  if [ -n "${H1_LINE}" ]; then
    FIRST_H2_LINE=$(awk -v start="${H1_LINE}" 'NR > start && /^## / {print NR; exit}' "${DOC_PATH}")
    if [ -n "${FIRST_H2_LINE}" ] && [ "${FIRST_H2_LINE}" != "${CHANGELOG_LINE}" ]; then
      FIRST_H2_HEADING=$(sed -n "${FIRST_H2_LINE}p" "${DOC_PATH}")
      report_block "변경 이력 위치 위반 — H1 직후 첫 ## 섹션이 '${FIRST_H2_HEADING}'. '## 변경 이력'이 sections[0]이어야 함 (ADR-0019)"
    fi
  fi

  # (b) 표 헤더 컬럼 검증
  CHANGELOG_HEADER=$(awk -v start="${CHANGELOG_LINE}" 'NR > start && NR <= start + 10 && /^\|/ {print; exit}' "${DOC_PATH}")
  if [ -z "${CHANGELOG_HEADER}" ]; then
    report_block "변경 이력 표 누락"
  else
    for col in Version Date Author Change; do
      echo "${CHANGELOG_HEADER}" | grep -qF "${col}" || report_block "변경 이력 컬럼 누락 — ${col}"
    done

    # (c) 첫 데이터 행 정합 — ADR-0019
    # 헤더(${start+N}) 다음 |---|---| 구분선 1줄 건너뛴 후 첫 |로 시작하는 줄을 데이터 행으로
    FIRST_DATA_ROW=$(awk -v start="${CHANGELOG_LINE}" '
      NR > start && /^\|/ {
        if (header == "") { header = $0; next }
        if (separator == "" && /^\|[\s-]*\|/) { separator = $0; next }
        if (separator == "" && /^\|[ \t-]+\|/) { separator = $0; next }
        if (/^\|/) { print; exit }
      }' "${DOC_PATH}")

    if [ -n "${FIRST_DATA_ROW}" ]; then
      # | v0.3 | 2026-05-13 | chae.lee | 변경 내용 | → 첫 컬럼 = Version, 둘째 = Date
      TABLE_VERSION=$(echo "${FIRST_DATA_ROW}" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')
      TABLE_DATE=$(echo "${FIRST_DATA_ROW}" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
      FM_VERSION=$(echo "${FRONTMATTER}" | yq '.version // ""' | tr -d '"')
      FM_DATE=$(echo "${FRONTMATTER}" | yq '.date // ""' | tr -d '"')

      # frontmatter version은 "v0.3 (Draft)" 또는 "v1.0" 형식. 표는 보통 "v0.3"
      # 일치 판정: frontmatter version의 v… 토큰이 표 Version 컬럼에 포함되는지
      FM_VERSION_TOKEN=$(echo "${FM_VERSION}" | awk '{print $1}')
      if [ -n "${FM_VERSION_TOKEN}" ] && [ "${TABLE_VERSION}" != "${FM_VERSION_TOKEN}" ]; then
        report_block "변경 이력 정합 위반 — 표 첫 데이터 행 Version(${TABLE_VERSION}) ≠ frontmatter.version(${FM_VERSION_TOKEN}) (ADR-0019)"
      fi
      if [ -n "${FM_DATE}" ] && [ "${TABLE_DATE}" != "${FM_DATE}" ]; then
        report_block "변경 이력 정합 위반 — 표 첫 데이터 행 Date(${TABLE_DATE}) ≠ frontmatter.date(${FM_DATE}) (ADR-0019)"
      fi
    else
      report_block "변경 이력 표 데이터 행 누락 — 최소 1행 필수 (ADR-0019)"
    fi
  fi
elif grep -qE "^## .*변경 이력$" "${DOC_PATH}"; then
  # 번호 부착 헤딩 (## 6. 변경 이력 등) — ADR-0019로 금지
  report_block "변경 이력 헤딩 번호 위반 — '## 변경 이력' (번호 없음) 이어야 함 (ADR-0019)"
else
  report_block "## 변경 이력 섹션 누락 (ADR-0019: H1 직후 sections[0] 위치)"
fi

# === 결과 ===
if [ ${EXIT_CODE} -eq 0 ]; then
  echo "OK [${DOC_TYPE}] ${DOC_PATH}"
fi

exit ${EXIT_CODE}
