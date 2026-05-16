#!/usr/bin/env bash
# scripts/check-local-md-sync.sh — newProject 루트 LOCAL.md 구조 + profile 3분기 env + 부팅 자산 lint
#
# 정본:
# - ADR-0040 (LOCAL.md = newProject 루트 부팅 가이드 정본)
# - ADR-0037 v1.1 (profile 3분기 dev/stg/prod 강제)
#
# 호출:
#   bash scripts/check-local-md-sync.sh       # newProject 루트에서 실행
#
# CI:
#   .github/workflows/ci.yml의 local-md-sync job에서 호출 (ci.yml.template 참조)
#
# 검증 항목 (단순 grep 기반 — α 정책, false positive 낮음):
#   1. LOCAL.md 정본 절 구조 (§1·§2·§3·§4·§5)
#   2. profile 3분기 env 참조 (.env.{dev,stg,prod}.example) — 단일 환경 운영(.env.example만)은 LOCAL.md에 사유 명시 시 허용
#   3. profile 3분기 env 파일 존재 (root)
#   4. lockfile 1종 존재 (root) — 도입 스택별 다양 허용
#   5. LOCAL.md §4 부팅 자산 표 비어 있지 않음 (헤더 + 데이터 행 ≥ 1)
#
# 12-scaffolding §7과의 *깊은* 동기 lint(자산 경로 1:1 매칭 등)는 newProject 스택별
# 자체 lint로 추가 권장 — 본 스크립트는 stack-agnostic minimal lint이다.
#
# Exit codes:
#   0 = OK
#   1 = BLOCKER (FAIL 1건 이상 — LOCAL.md 갱신 또는 자산 보강 필요)

set -euo pipefail

LOCAL_MD="LOCAL.md"

if [[ ! -f "$LOCAL_MD" ]]; then
  echo "ERROR: $LOCAL_MD not found in cwd $(pwd)"
  echo "       (본 스크립트는 newProject 루트에서 호출되어야 합니다.)"
  exit 1
fi

fail=0
warn=0

# ─── 1. LOCAL.md 정본 절 구조 (ADR-0040) ───────────────────────
for sec_pat in "^## 1\." "^## 2\." "^## 3\." "^## 4\." "^## 5\."; do
  if ! grep -qE "$sec_pat" "$LOCAL_MD"; then
    echo "[FAIL] $LOCAL_MD — 정본 절 헤더 누락: $sec_pat"
    fail=$((fail+1))
  fi
done

# ─── 2. profile 3분기 env 참조 ─────────────────────────────────
# .env.{dev,stg,prod}.example 3종 모두 LOCAL.md에 등장하거나,
# 단일 환경 운영 시 사유 명시("stg=prod 공유"·"단일 환경"·"N/A") 허용.
missing_env_refs=0
for p in dev stg prod; do
  if ! grep -q ".env.${p}.example" "$LOCAL_MD"; then
    missing_env_refs=$((missing_env_refs+1))
  fi
done
if [[ $missing_env_refs -gt 0 ]]; then
  if grep -qiE "stg=prod 공유|단일 환경|N/A — stg|N/A 표기" "$LOCAL_MD"; then
    echo "[INFO] LOCAL.md — profile 3분기 env 일부 누락이나 단일 환경 운영 사유 명시 OK"
  else
    echo "[FAIL] $LOCAL_MD — .env.{dev,stg,prod}.example 3종 모두 참조되지 않음 ($missing_env_refs종 누락) 그리고 단일 환경 운영 사유 미명시 (ADR-0037 v1.1)"
    fail=$((fail+1))
  fi
fi

# ─── 3. profile 3분기 env 파일 존재 ────────────────────────────
profile_files=0
for p in dev stg prod; do
  [[ -f ".env.${p}.example" ]] && profile_files=$((profile_files+1))
done
if [[ $profile_files -lt 3 ]]; then
  if [[ -f ".env.example" ]]; then
    echo "[INFO] .env.example 단일 발견 — 단일 환경 운영 가정 (LOCAL.md 사유 명시 확인 필요)"
  else
    echo "[FAIL] root에 .env.{dev,stg,prod}.example 3종 (또는 단일 .env.example) 부재 (ADR-0037 v1.1 부팅 자산)"
    fail=$((fail+1))
  fi
fi

# ─── 4. lockfile 1종 존재 (스택 무관) ──────────────────────────
lockfiles=(
  "pnpm-lock.yaml" "package-lock.json" "yarn.lock"
  "poetry.lock" "uv.lock" "Pipfile.lock" "requirements.txt"
  "Cargo.lock"
  "go.sum"
  "gradle.lockfile" "build.gradle.lockfile"
  "composer.lock"
)
found_lock=""
for lf in "${lockfiles[@]}"; do
  if [[ -f "$lf" ]]; then
    found_lock="$lf"
    break
  fi
done
if [[ -z "$found_lock" ]]; then
  echo "[WARN] root에 lockfile 1종도 발견되지 않음 — 의존성 재현성 확인 필요 (예상: ${lockfiles[*]})"
  warn=$((warn+1))
fi

# ─── 5. LOCAL.md §4 부팅 자산 표 비어 있지 않음 ────────────────
# §4 헤더 ~ 다음 §5 헤더 사이에 마크다운 표 데이터 행(파이프 4개) 1개 이상 존재 확인
if ! awk '/^## 4\./,/^## 5\./' "$LOCAL_MD" | grep -qE "^\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|$"; then
  echo "[FAIL] $LOCAL_MD §4 부팅 자산 표가 비어 있거나 컬럼 형식 어긋남 (4컬럼 강제)"
  fail=$((fail+1))
fi

# ─── 결과 ───────────────────────────────────────────────
if [[ $fail -eq 0 ]]; then
  if [[ $warn -gt 0 ]]; then
    echo "✅ LOCAL.md 구조 + profile 3분기 env 정합 OK (WARN: $warn건)"
  else
    echo "✅ LOCAL.md 구조 + profile 3분기 env 정합 OK"
  fi
  exit 0
fi
echo "❌ $fail FAIL — LOCAL.md 또는 부팅 자산 보강 필요 (ADR-0040 정본 구조 + ADR-0037 v1.1 profile 3분기)"
exit 1
