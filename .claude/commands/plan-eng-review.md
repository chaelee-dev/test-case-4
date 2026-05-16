---
description: Use this when the user is about to start coding, asks for an engineering sanity check on a plan, needs the dev team to gate the design before implementation, or is about to leave the design phase (Gate C in policies/flow-and-gates.md §2).
allowed-tools: Read, Write, Glob, Grep
---

# /plan-eng-review

## 목적
**개발 착수 전 엔지니어링 검토 게이트**. policies/flow-and-gates.md §2 게이트 C에 해당. `change-contract` + `implementation-planner` 결과를 평가하여 진행/회귀 결정.

## 사용 시점
- 모든 Flow의 "구현 전 마지막 게이트"
- `change-contract` + `implementation-planner` 작성 직후

## 입력
- `<slug>.contract.md`
- `<slug>.plan.md`
- (NEW_PROJECT) `06-architecture.md`, `07-hld.md`, `09-lld-api-spec.md` (ADR-0031 재할당)

## 산출물
- `docs/features/<slug>/<slug>.eng-review.md`
  - PASS / FAIL / NEEDS-WORK
  - 항목별 코멘트
  - 후속 액션 리스트

## 점검 항목

### 1. 코드 변경 검토 (FEATURE)

```
[ ] contract의 호환성 판정이 정확한가
[ ] plan이 contract를 모두 cover하는가
[ ] 단위 테스트 plan이 명시됐는가
[ ] 코딩 컨벤션(docs/planning/11-coding-conventions/11-coding-conventions.md) 위반 없는가
[ ] 보안 룰(CLAUDE.md) 위반 없는가
[ ] 의존성(Blocked-by) 모두 해소되었는가
[ ] Rollback이 실행 가능한가
[ ] 추정 작업량이 1~3 working days 범위인가 (이슈 단위)
```

### 2. Schema 검증 (ADR-0010, 자동)

본 게이트 진입 시 **모든 산출**에 대해 `validate-doc.sh`를 자동 호출. 하나라도 BLOCK이면 verdict=FAIL.

```bash
# 본 Phase에서 작성된 산출 검증
for f in $(git diff --name-only --diff-filter=AM | grep -E '^docs/(planning|features)/.*\.md$'); do
  bash .claude/scripts/validate-doc.sh "$f" || VERDICT=FAIL
done
```

### 2.5 1수준 산출 전수 존재 검증 (NEW_PROJECT, ADR-0013 + ADR-0031)

`/flow-new-project` 게이트 C 진입 시 다음을 강제:

```bash
# 1수준 15건 + adr/ 폴더 전수 확인 (ADR-0015 전수 폴더 구조 + ADR-0031 +1 재할당)
# 모든 1수준은 폴더 + 메인 파일 + INDEX.md 검증

REQUIRED_FOLDERS=(
  "docs/planning/01-project-brief"
  "docs/planning/02-feasibility"
  "docs/planning/03-user-scenarios"
  "docs/planning/04-srs"
  "docs/planning/05-prd"
  "docs/planning/06-architecture"
  "docs/planning/07-hld"                # ADR-0031 신설
  "docs/planning/08-lld-module-spec"
  "docs/planning/09-lld-api-spec"
  "docs/planning/10-lld-screen-design"
  "docs/planning/11-coding-conventions"
  "docs/planning/12-scaffolding"        # 평면 명명, §3.2
  "docs/planning/13-test-design"        # 5절 폴더, ADR-0014·0030
  "docs/planning/14-wbs"
  "docs/planning/15-risk"
  "docs/planning/adr"                   # 4자리 평면, §3.3
)

for d in "${REQUIRED_FOLDERS[@]}"; do
  if [ ! -d "$d" ]; then
    echo "BLOCKED: 1수준 폴더 부재 — $d (ADR-0013·0015·0031 전수 폴더 강제)"
    VERDICT=FAIL
    continue
  fi
  # 폴더 내 INDEX.md 존재 (file-numbering §4)
  if [ ! -f "$d/INDEX.md" ]; then
    echo "BLOCKED: INDEX.md 부재 — $d/INDEX.md"
    VERDICT=FAIL
  fi
  # 메인 파일 존재 (12-scaffolding/, adr/, 13-test-design/ 예외)
  case "$d" in
    */12-scaffolding|*/adr|*/13-test-design) ;;
    *)
      NAME=$(basename "$d")
      if [ ! -f "$d/$NAME.md" ] && ! ls "$d"/[0-9][0-9]-*.md >/dev/null 2>&1; then
        echo "BLOCKED: 메인 파일 또는 분할 sub 파일 부재 — $d/$NAME.md"
        VERDICT=FAIL
      fi
      ;;
  esac
done

# 10 Screen Design은 BE-only면 frontmatter status: N/A 골격 허용 (ADR-0013)
```

> **분할 정책 (file-numbering §3.1)**: 04 SRS, 05 PRD, 07 HLD, 08 Module Spec은 분량/도메인에 따라 메인 파일을 `NN-<slug>.md` sub 파일로 분할. 분할 시 메인 파일 부재해도 sub + INDEX.md 충족.

### 3. 정합 검증

```
[ ] 분할 폴더에 INDEX.md 존재 (file-numbering.md §4)
[ ] 06 Architecture에 §Stack Decision 박스 존재 (NEW_PROJECT, foldering-rules.md §3 + architecture.schema.yaml)
[ ] 07 HLD §1 핵심 모듈 표 존재 (NEW_PROJECT, hld.schema.yaml, ADR-0031)
[ ] 08 Module Spec §1에 "07 HLD §1 참조" 명시 (ADR-0031)
[ ] R-ID/F-ID가 04 SRS·05 PRD에 실재
[ ] 각 산출 frontmatter 7필드 충족 (document-manifest.md §2)
[ ] 6단계 폴더링 충족 (NEW_PROJECT, foldering-rules.md §2)
```

## 실행 단계
1. 입력 문서 모두 읽기
2. 체크리스트 적용
3. FAIL/NEEDS-WORK 항목별 사유 + 권장 수정
4. PASS 시 `/implement` 진입 허가 명시
5. FAIL 시 회귀할 Phase 명시 (`/change-contract` 또는 `/implementation-planner`)

## 완료 조건
- 판정 결과 명시 (PASS만이 다음 진행 허가)
- FAIL 항목 ≥ 1개면 진입 거부
- PASS 시 다음 Command(`/acceptance-criteria` 또는 `/implement`) 안내

## Strict Rules
- **PASS 없이 코드 작성 금지** (CLAUDE.md 명시 규칙)
- Generator≠Evaluator — 본 리뷰는 contract/plan 작성자와 다른 컨텍스트로 수행 권장
