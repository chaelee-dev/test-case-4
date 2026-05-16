#!/usr/bin/env bash
# 분할 폴더의 INDEX.md 자동 생성·갱신.
# 호출: ./gen-index.sh <폴더경로>
# 예: ./gen-index.sh docs/planning/08-lld-module-spec/auth
#
# - 폴더 내 NN-<slug>.md 또는 <lang>.md 파일을 스캔
# - 각 파일의 첫 # 헤더 + frontmatter related.R-ID/F-ID 추출
# - INDEX.md를 새로 작성 (수동 입력한 "한 줄 요약" 칼럼은 가능하면 보존 — 단순 모드: 덮어쓰기 + 안내 코멘트)

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <folder>" >&2
  exit 2
fi

FOLDER="$1"
[ ! -d "${FOLDER}" ] && { echo "ERROR: 폴더 없음: ${FOLDER}" >&2; exit 2; }

INDEX="${FOLDER}/INDEX.md"
TODAY=$(date +%Y-%m-%d)
BASENAME=$(basename "${FOLDER}")
PARENT=$(basename "$(dirname "${FOLDER}")")

# 임시 파일에 새 본문 작성 → 끝에 ${INDEX}로 이동 (atomic)
TMP=$(mktemp)
trap 'rm -f "${TMP}"' EXIT

cat >"${TMP}" <<EOF
---
doc_type: index
version: v0.1
status: Draft
author: gen-index.sh
date: ${TODAY}
gate: (해당 산출의 게이트)
related: { R-ID: [], F-ID: [], supersedes: null }
---

# ${PARENT}/${BASENAME} Index

> 이 파일은 \`gen-index.sh\`가 자동 생성한다. "한 줄 요약" 칼럼은 수동으로 보강 후 보존하라.

| NN | slug | 한 줄 요약 | R-ID/F-ID |
|---|---|---|---|
EOF

# NN-<slug>.md 또는 <lang>.md 파일 수집·정렬
for f in "${FOLDER}"/*.md; do
  [ -f "${f}" ] || continue
  fname=$(basename "${f}")
  # INDEX.md 자체는 건너뜀
  [ "${fname}" = "INDEX.md" ] && continue

  # NN-<slug>.md 분리
  if [[ "${fname}" =~ ^([0-9]{2})-(.+)\.md$ ]]; then
    NN="${BASH_REMATCH[1]}"
    SLUG="${BASH_REMATCH[2]}"
  else
    # <lang>.md 평면
    NN="--"
    SLUG="${fname%.md}"
  fi

  # 첫 # 헤더 한 줄
  HEADER=$(grep -m1 -E '^# ' "${f}" 2>/dev/null | sed -E 's/^# //; s/[|]/-/g' || echo "")
  # frontmatter related.R-ID, F-ID
  RIDS=$(awk '/^---$/{c++; next} c==1 && /^[[:space:]]*R-ID:/ {sub(/^[[:space:]]*R-ID:[[:space:]]*/, ""); gsub(/[\\[\\]]/, ""); print; exit}' "${f}" 2>/dev/null || echo "")
  FIDS=$(awk '/^---$/{c++; next} c==1 && /^[[:space:]]*F-ID:/ {sub(/^[[:space:]]*F-ID:[[:space:]]*/, ""); gsub(/[\\[\\]]/, ""); print; exit}' "${f}" 2>/dev/null || echo "")

  TAGS="${RIDS}"
  [ -n "${FIDS}" ] && TAGS="${TAGS:+${TAGS}, }${FIDS}"

  printf "| %s | %s | %s | %s |\n" "${NN}" "${SLUG}" "${HEADER}" "${TAGS}" >>"${TMP}"
done

cat >>"${TMP}" <<'EOF'

## 의존성 메모

<!-- TODO: 도메인/하위 영역 간 선후 관계 1줄 -->
EOF

mv "${TMP}" "${INDEX}"
echo "WROTE: ${INDEX}"
