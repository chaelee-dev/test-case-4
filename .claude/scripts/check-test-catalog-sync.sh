#!/usr/bin/env bash
# check-test-catalog-sync.sh — 04 SRS·05 PRD의 R-/F-ID 갯수 vs 13/02-catalog의 ### R-/### F-
# subsection 갯수 비교 (ADR-0035 시간 축 갭 해소, WARN 강도).
#
# 사용:
#   bash .claude/scripts/check-test-catalog-sync.sh [--planning-dir=docs/planning]
#
# 출력:
#   stderr WARN — 누락된 R-/F-ID 목록
#   stdout OK   — 04·05와 13/02-catalog 갯수 일치
#
# 종료 코드:
#   0 = OK 또는 WARN (정보 제공, 차단 없음 — ADR-0035 §2.3)
#   3 = 사용 오류 (planning-dir 미존재, 04·05·13 산출 부재)
#
# 참고:
#   - 04는 `04-srs/` 폴더(폴더 분할) 또는 `04-srs.md` 단일 파일 모두 처리
#   - 05도 `05-prd/` 또는 `05-prd.md`
#   - 13/02-catalog는 `13-test-design/02-catalog.md` 단일 sub-file (ADR-0030)

set -uo pipefail

PLANNING_DIR="docs/planning"

for arg in "$@"; do
  case "${arg}" in
    --planning-dir=*) PLANNING_DIR="${arg#--planning-dir=}" ;;
    -h|--help)
      grep "^#" "$0" | head -25 | sed 's/^# //; s/^#//'
      exit 0
      ;;
  esac
done

[ ! -d "${PLANNING_DIR}" ] && { echo "ERROR: planning dir not found: ${PLANNING_DIR}" >&2; exit 3; }

# === 04·05·13 위치 결정 ===
find_doc() {
  local NN="$1" name="$2"
  if [ -d "${PLANNING_DIR}/${NN}-${name}" ]; then
    echo "${PLANNING_DIR}/${NN}-${name}"
  elif [ -f "${PLANNING_DIR}/${NN}-${name}.md" ]; then
    echo "${PLANNING_DIR}/${NN}-${name}.md"
  else
    echo ""
  fi
}

SRS_PATH=$(find_doc "04" "srs")
PRD_PATH=$(find_doc "05" "prd")
CATALOG_PATH="${PLANNING_DIR}/13-test-design/02-catalog.md"

[ -z "${SRS_PATH}" ] && { echo "ERROR: 04 SRS not found (04-srs/ or 04-srs.md)" >&2; exit 3; }
[ -z "${PRD_PATH}" ] && { echo "ERROR: 05 PRD not found (05-prd/ or 05-prd.md)" >&2; exit 3; }
[ ! -f "${CATALOG_PATH}" ] && { echo "ERROR: 13/02-catalog not found: ${CATALOG_PATH}" >&2; exit 3; }

# === ID 추출 ===
# 04·05에서 `^### R-NN` 또는 `^### F-NN` 패턴의 ID만 추출
extract_ids() {
  local prefix="$1" path="$2"
  if [ -d "${path}" ]; then
    grep -rhE "^### ${prefix}-[0-9]+" "${path}" 2>/dev/null \
      | grep -oE "${prefix}-[0-9]+" | sort -u
  else
    grep -E "^### ${prefix}-[0-9]+" "${path}" 2>/dev/null \
      | grep -oE "${prefix}-[0-9]+" | sort -u
  fi
}

SRS_IDS=$(extract_ids "R" "${SRS_PATH}")
PRD_IDS=$(extract_ids "F" "${PRD_PATH}")

# 13/02-catalog에서 `^### R-NN`/`^### F-NN` (각 레벨 섹션 안에 있음 — ADR-0036)
CATALOG_R_IDS=$(grep -E "^### R-[0-9]+" "${CATALOG_PATH}" 2>/dev/null \
  | grep -oE "R-[0-9]+" | sort -u)
CATALOG_F_IDS=$(grep -E "^### F-[0-9]+" "${CATALOG_PATH}" 2>/dev/null \
  | grep -oE "F-[0-9]+" | sort -u)

# === 차집합 (04·05 ID 중 13에 없는 것) ===
missing_ids() {
  local source_ids="$1" target_ids="$2"
  comm -23 <(echo "${source_ids}") <(echo "${target_ids}")
}

MISSING_R=$(missing_ids "${SRS_IDS}" "${CATALOG_R_IDS}")
MISSING_F=$(missing_ids "${PRD_IDS}" "${CATALOG_F_IDS}")

SRS_COUNT=$(echo "${SRS_IDS}" | grep -c "R-" 2>/dev/null || true)
PRD_COUNT=$(echo "${PRD_IDS}" | grep -c "F-" 2>/dev/null || true)
CATALOG_R_COUNT=$(echo "${CATALOG_R_IDS}" | grep -c "R-" 2>/dev/null || true)
CATALOG_F_COUNT=$(echo "${CATALOG_F_IDS}" | grep -c "F-" 2>/dev/null || true)

WARN_COUNT=0

if [ -n "${MISSING_R}" ]; then
  MISSING_R_FLAT=$(echo "${MISSING_R}" | tr '\n' ',' | sed 's/,$//')
  echo "WARN: 04 SRS R-ID ${SRS_COUNT}개 vs 13/02-catalog R- subsection ${CATALOG_R_COUNT}개 — 누락 [${MISSING_R_FLAT}]" >&2
  echo "      해소: docs/planning/13-test-design/02-catalog.md 의 ## 1./## 2./## 3. 레벨 섹션에 ### R-NN fan-in (ADR-0035·0036)" >&2
  WARN_COUNT=$((WARN_COUNT + 1))
fi

if [ -n "${MISSING_F}" ]; then
  MISSING_F_FLAT=$(echo "${MISSING_F}" | tr '\n' ',' | sed 's/,$//')
  echo "WARN: 05 PRD F-ID ${PRD_COUNT}개 vs 13/02-catalog F- subsection ${CATALOG_F_COUNT}개 — 누락 [${MISSING_F_FLAT}]" >&2
  echo "      해소: docs/planning/13-test-design/02-catalog.md 의 ## 1./## 2./## 3. 레벨 섹션에 ### F-NN fan-in (ADR-0035·0036)" >&2
  WARN_COUNT=$((WARN_COUNT + 1))
fi

if [ "${WARN_COUNT}" -eq 0 ]; then
  echo "OK [test-catalog-sync] 04 SRS ${SRS_COUNT} R-ID + 05 PRD ${PRD_COUNT} F-ID ↔ 13/02-catalog (모두 fan-in)"
fi

exit 0
