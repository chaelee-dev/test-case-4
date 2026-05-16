---
description: Use this when the user has a clear idea and needs to formalize it (default mode), OR when the user has only a vague idea and needs to explore alternatives before committing (use --brainstorm). The default mode produces a one-pager intent doc. The --brainstorm mode produces a 3+ alternatives comparison without committing. This consolidates the previous /product-brainstorm into --brainstorm mode.
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch
---

# /intention-brief

## 목적
의도를 **하나의 결정으로 응축**. brainstorm 결과(또는 사용자 입력)를 받아 1장짜리 brief로 만들어 다음 모든 단계의 기준점으로 삼는다.

> **Schema 강제 (ADR-0010)**: NEW_PROJECT 진입은 `doc_type=brief`(01) + `--brainstorm`은 `doc_type=feasibility`(02). FEATURE 진입은 `doc_type=feature-brief`. 산출 시 `bash .claude/scripts/scaffold-doc.sh <doc_type> <output>`로 골격 생성 → 작성 → `bash .claude/scripts/validate-doc.sh <output>`로 검증. BLOCK 위반 시 `/plan-eng-review` 차단.

> **2026-04-30 통합** — 기존 `/product-brainstorm`을 `--brainstorm` 모드로 흡수. 의도가 모호하면 먼저 brainstorm 모드로 대안 탐색 후, 기본 모드로 결정 응축.

## 모드 (2종)

| 모드 | 호출 | 목적 | 산출 |
|---|---|---|---|
| **기본** (default) | `/intention-brief "..."` | 의도 응축 → 1장 brief | NEW_PROJECT: `docs/planning/01-project-brief/01-project-brief.md` · FEATURE: `docs/features/<slug>/<slug>.brief.md` (8섹션) |
| **brainstorm** | `/intention-brief --brainstorm "..."` | 대안 탐색·비교 → 결정 보류 | `docs/planning/_brainstorm/<slug>.md` (3+ 대안 비교, 미결정 단계 산출 — feature-bound 아님) |

> brainstorm 모드는 **결정 금지**. 후보 나열만. 결정은 기본 모드에서.

## 사용 시점
- `/product-brainstorm` 직후
- 의도가 명확하지만 문서화 안 된 상태
- `/flow-feature-add` Phase 2 진입 시

## 입력
- `docs/planning/_brainstorm/<slug>.md` (있으면)
- 또는 사용자 자연어 의도 + GitHub Issue 본문

## 산출물 (위치 분기)

| Flow | 출력 경로 |
|---|---|
| flow-new-project | `docs/planning/01-project-brief/01-project-brief.md` |
| flow-feature mode=add/modify | `docs/features/<slug>/<slug>.brief.md` (slug에 `feat-`·`mod-` 접두 권장 — schema filename_pattern 정합) |
| flow-feature mode=bug | `docs/features/<slug>/<slug>.brief.md` (보조, slug에 `bug-` 접두) |
| flow-feature mode=design | `docs/features/<slug>/<slug>.brief.md` (slug에 `design-` 접두) |

## 문서 구조 (필수 8섹션)
1. **One-liner** — 1줄 정의
2. **Problem** — 누구의 어떤 문제인가
3. **Why now** — 왜 지금
4. **Scope** — In / Out
5. **Success criteria** — 측정 가능한 KPI 후보
6. **Constraints** — 기술·일정·인력 제약
7. **Open questions** — 미결정 항목 (ID로 관리)
8. **Next** — 이 brief가 어떤 Command의 입력이 되는가

## 실행 단계
1. 입력 자료 읽기
2. 1~8 섹션 채우기 (각 1단락 이내)
3. docs/planning/open-items.md (Open Items)와 충돌 검사
4. 산출 경로에 저장
5. (있으면) 관련 GitHub Issue에 링크 코멘트 추가

## 완료 조건
- 8섹션 모두 작성됨
- One-liner ≤ 1줄
- Open questions에 ID(O-XX) 부여
- 다음 단계(`/change-contract` or `/ux-flow-design`)로 넘기기에 충분

## Artifact Binding
- 입력: `_brainstorm/<slug>.md` (선택, brainstorm 모드 산출)
- 출력: → `/change-contract`, `/ux-flow-design`, `/acceptance-criteria` 모두의 입력

---

## `--brainstorm` 모드 상세

의도가 모호한 상태에서 **문제 정의·대안 탐색·근거 수집**. 결정은 내리지 않고, 기본 모드의 입력을 만든다.

### 사용 시점
- "뭔가 만들고 싶긴 한데..." 상태
- 대안 비교가 필요한 상황 (3개 이상)
- 기존 자산(`docs/devtoolkit/PRD.md` archive, paperclip 등)을 reference로 활용해야 할 때

### 입력
- 1줄 의도 (자연어, 필수)
- 제약 조건 (선택: 기간·인력·기술 스택 leaning)

### 산출물
- `docs/planning/_brainstorm/<slug>.md` (1~2장)
  - 문제 정의 (Why now)
  - 페르소나 / 사용 시나리오 후보
  - 대안 3+ 개 (장단점)
  - leaning (확정 아님 명시)
  - 미결정 항목

### 실행 단계
1. 사용자 의도 파싱 + 5W1H 질문 (모호한 항목만)
2. 기존 자산 스캔: `docs/devtoolkit/`, `docs/planning/INDEX.md`, ADR, paperclip 참조
3. 문제 정의 1단락
4. 대안 3+ 개 도출 (각 5줄 이내)
5. 비교표 작성
6. leaning + 미결정 항목 정리

### 완료 조건
- 산출 문서가 자급적(self-contained) — 다른 세션에서 읽어도 이해 가능
- 대안 ≥ 3개
- 다음 단계(기본 `/intention-brief` 호출)의 입력으로 쓸 수 있을 만큼 정리됨

### Strict Rules
- **결정 금지** — 본 모드는 "후보 나열"
- **레퍼런스 인용 시 출처 명시** — 추측 vs 사실 구분
