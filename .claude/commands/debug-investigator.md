---
description: Use this when the user reports unexpected behavior, asks "why is this happening", needs to find a root cause before patching, or is about to apply a fix without first reproducing the bug.
allowed-tools: Read, Bash, Glob, Grep
---

# /debug-investigator

## 목적
**조사 없이 수정 금지** (CLAUDE.md 규칙). 재현 → 가설 수립 → 검증 → 근본 원인 식별까지. 본 Command 통과 없이 `/implement` 진입 거부.

> **Schema 강제 (ADR-0010)**: `doc_type=feature-investigation`. `scaffold-doc.sh feature-investigation docs/features/<slug>/<slug>.investigation.md` → 작성 → `validate-doc.sh`. 현상/재현 빈도/재현 절차(기대/실제)/가설 표/근본 원인/회귀 테스트 항목 BLOCK. schema: `.claude/schemas/feature-investigation.schema.yaml`.

## 사용 시점
- `/flow-bug-fix` Phase 1 (필수)
- 알 수 없는 동작 / 간헐적 실패
- 프로덕션 인시던트 트리아지

## 입력
- 결함 보고 (에러 메시지, 로그, 스크린샷, 재현 절차)
- 환경 정보 (OS, 버전, 데이터)

## 산출물
- `docs/features/<slug>/<slug>.investigation.md` (mode=bug 한정, slug에 bug- 접두 권장 — schema filename_pattern과 정합)
  - 재현 절차 (재현 가능 여부)
  - 영향 범위
  - 근본 원인 가설 (≥ 2개)
  - 검증 결과
  - 수정 plan (최소 침습)

## 문서 구조

```markdown
# Investigation — bug-<slug>

## 1. 결함 요약
사용자 보고 그대로

## 2. 재현 절차
- 환경: ...
- 단계 1: ...
- 단계 2: ...
- 결과: ...
- 재현률: X/Y회

## 3. 영향 범위
- 영향 받는 사용자/기능
- 데이터 손상 가능성

## 4. 가설
- H1: ... (검증 방법)
- H2: ... (검증 방법)

## 5. 검증
- H1: PASS/FAIL + 증거
- H2: ...

## 6. 근본 원인
1줄

## 7. 수정 plan
최소 침습 변경 + 회귀 테스트
```

## 실행 단계
1. 보고 내용 정확히 인용
2. 재현 절차 작성 → 실제 재현 시도
3. 재현 실패 시 → BLOCKED, 사용자에게 추가 정보 요청
4. 가설 ≥ 2개 (하나만 세우면 confirmation bias)
5. 가설 검증 (로그·디버거·grep)
6. 근본 원인 1줄로 응축
7. 수정 plan을 `change-contract`로 넘김

## 완료 조건
- 재현 가능 (또는 명시적 BLOCKED)
- 가설 ≥ 2개 검증 완료
- 근본 원인 1줄 명시
- 수정 plan이 `/change-contract`의 입력으로 충분

## Strict Rules
- **재현 없이 수정 plan 작성 금지**
- **추측 기반 fix 금지** — 가설 검증 필수
- **Workaround만 적용하는 경우 ADR로 사유 + 후속 이슈 강제**

## Artifact Binding
- 입력: 결함 보고
- 출력: → `/change-contract`, `/risk-check`
