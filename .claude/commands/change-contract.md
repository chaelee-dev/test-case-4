---
description: Use this when the user is about to modify code or behavior, asks to plan a refactor, needs to declare what will change before/after, or is about to introduce a breaking change without an explicit contract.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /change-contract

## 목적
**계약 없이 변경 금지** 원칙의 핵심. 변경 전/후·이유·영향·롤백을 명세하여 코드 작성 전 리뷰 가능 상태로 만든다.

> **Schema 강제 (ADR-0010 + ADR-0018)**: `doc_type=feature-contract`. `scaffold-doc.sh feature-contract docs/features/<slug>/<slug>.contract.md` → 작성 → `validate-doc.sh`. §0 Referenced-IDs·Before/After 표·호출자 표·Backward(yes/no)·Rollback 절차·R-ID 매핑 BLOCK. schema: `.claude/schemas/feature-contract.schema.yaml`.

## 사용 시점
- 모든 `/flow-feature-modify` Phase 3 (필수)
- `/flow-feature-add`에서 기존 코드를 수정해야 할 때
- breaking change 가능성 1% 이상 시

## 입력
- `feat-<slug>.brief.md` (또는 이슈 본문)
- 영향 코드 위치 식별 (`/context-loader` 결과 활용)
- **상류 정본 산출 (ADR-0018)** — §0 작성을 위해 다음을 참조:
  - `docs/planning/04-srs/04-srs.md` (R-ID)
  - `docs/planning/05-prd/05-prd.md` (F-ID, 있으면)
  - `docs/planning/08-lld-module-spec/` (영향 모듈, ADR-0031 재할당)
  - `docs/planning/09-lld-api-spec/09-lld-api-spec.md` (영향 엔드포인트, 있으면)
  - `docs/planning/11-coding-conventions/11-coding-conventions.md` (적용 컨벤션 절, 있으면)

## 산출물
- `docs/features/<slug>/<slug>.contract.md`

## 문서 구조 (필수)

```markdown
# Change Contract — <slug>

## 0. 참조 정본 ID (Referenced-IDs)

> ADR-0018. 본 contract가 건드리는 게이트 C 정본을 명시. 영향 없는 종류는 "(none)"으로 명시.
> 후속 `/implementation-planner` FEATURE 분기가 본 표를 파싱해 selective read한다.

| 종류 | 정본 위치 | 영향 ID |
|---|---|---|
| R-ID (요구) | 04-srs | R-04, R-07 |
| F-ID (기능) | 05-prd | F-12 |
| 영향 모듈 | 08-lld-module-spec | auth/session, billing/invoice |
| 영향 엔드포인트 | 09-lld-api-spec | POST /api/v1/login |
| 적용 컨벤션 절 | 11-coding-conventions | §2 에러코드, §3 명명 |

## 1. 변경 의도
한 줄

## 2. Before / After
| 항목 | Before | After |
|---|---|---|
| API 시그니처 | ... | ... |
| 동작 | ... | ... |
| UI 텍스트 | ... | ... |

## 3. 호출자·의존자 (Call Sites)
| 위치 | 영향 | 조치 |
|---|---|---|
| <파일:라인> | <설명> | <조치> |

## 4. Backward Compatibility
- Breaking: yes / no
- 마이그레이션 필요: yes / no
- migration plan (Breaking=yes인 경우)
- deprecation 일정

## 5. Rollback 전략
- revert 가능: yes / no
- rollback 절차 (3단계 이내)
- 데이터 손상 위험: 없음 / 있음 (대응)

## 6. 비목표
- 의도적으로 다루지 않는 범위

## 변경 이력
| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | <date> | <author> | 초안 |
```

## §0 작성 가이드 (모드별)

| mode | R-ID | F-ID | 영향 모듈 | 영향 엔드포인트 | 적용 컨벤션 절 |
|---|---|---|---|---|---|
| **add** | 1+ 필수 | 보통 1 | 신규 가능 | 해당 시 | 해당 시 |
| **modify** | 1+ 필수 | 해당 시 | 1+ 필수 (Before·After 모듈 모두 명시) | 해당 시 | 시그니처 변경 시 §3 명명 인용 |
| **bug** | 1+ 필수 (회귀 R-ID) | 해당 시 | 결함 모듈 1 | 해당 시 | (none) 자주 |
| **design** | 해당 시 | 1+ 필수 (화면 기능) | UI 모듈 | (none) 자주 | UI 컨벤션 절 |

빈 케이스는 표 행을 지우지 말고 `(none)`으로 명시 — schema 강제로 5행 모두 BLOCK 라벨 검증.

## 실행 단계
1. **§0 Referenced-IDs 채움 우선** — 04-srs/05-prd/07/08/10 정본을 열어 영향 ID 추출 (mode별 가이드 참조)
2. 영향 코드 식별 (Grep / Glob)
3. Before/After 표 작성
4. 호출자 모두 추적 (Reference 그래프)
5. breaking 판정
6. Rollback 절차 시뮬레이션 (가능한가?)
7. 검증 방법 → `/acceptance-criteria`의 입력으로 연결

## 완료 조건
- §0 + §1~§6 + 변경 이력 모두 작성
- §0 R-ID 빈 칸 금지 (mode 재판정 신호)
- Breaking=yes면 migration plan 필수
- Rollback "revert 가능=no"인 경우 → ADR로 사유 + 사용자 명시 승인 필수
- `validate-doc.sh` PASS

## Strict Rules
- **이 문서 없이 코드 수정 금지** (Strict Harness Mode)
- 호출자를 모두 추적하지 않은 contract는 INVALID
- **§0 Referenced-IDs 미작성 contract는 INVALID (ADR-0018)** — schema validate가 자동 BLOCK

## Artifact Binding
- 출력: → `/implementation-planner` (FEATURE 분기가 §0 표 파싱해 selective read), `/risk-check`, `/code-review` 모두의 입력
