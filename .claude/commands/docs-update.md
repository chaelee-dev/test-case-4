---
description: Use this when the user is about to close an issue or merge a PR, asks to update docs/CHANGELOG/ADR, needs to record a non-trivial decision, or is about to ship without updating docs/planning/CHANGELOG.md §"Current Status" progress.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /docs-update

## 목적
변경의 흔적을 **재개 가능한 문서**로 남긴다. policies/flow-and-gates.md §3 (Resumability) 원칙 준수.

## 사용 시점
- 모든 Flow의 마지막 Phase
- ADR 필요 결정 발생 직후
- docs/planning/CHANGELOG.md §"Current Status" "현재 진행 상황" 갱신 필요 시점

## 입력
- 변경된 코드 + PR
- 결정 컨텍스트 (왜 이 방식?)

## 산출물 (선택적, 변경의 성격에 따라)

| 변경 종류 | 갱신 대상 |
|---|---|
| 결정 발생 | `docs/planning/adr/NNNN-<slug>.md` (필수) |
| 의미 있는 산출 | `docs/planning/CHANGELOG.md §"Current Status"` 진행 상황 |
| 사용자 노출 변화 | `CHANGELOG.md` |
| 디자인 시스템 변경 | 디자인 시스템 changelog |
| API 변경 | `docs/planning/09-lld-api-spec/09-lld-api-spec.md` 보강 |
| 운영 절차 변경 | `CLAUDE.md` Addendum |

## ADR 템플릿

```markdown
# ADR NNNN: <decision>

- Status: Accepted / Proposed / Deprecated
- Date: YYYY-MM-DD
- Author: ...

## Context
왜 이 결정이 필요한가

## Decision
무엇을 결정했는가

## Alternatives considered
- A: 장단점
- B: 장단점

## Consequences
- 긍정적
- 부정적
- 후속 작업
```

## 실행 단계
1. 변경 성격 분류 (위 표)
2. ADR 작성 분기 — `bash .claude/scripts/scaffold-doc.sh adr docs/planning/adr/<NNNN>-<slug>.md` → 작성 → `bash .claude/scripts/validate-doc.sh <output>` (ADR-0010, doc_type=adr)
3. Retro 작성 분기 — `bash .claude/scripts/scaffold-doc.sh retro docs/planning/retro/sprint-N.md` → 작성 → `validate-doc.sh` (doc_type=retro)
4. 해당 문서 갱신
5. ADR 필요 여부 판정 (계약·아키텍처·외부 의존 변경 시 필수)
6. docs/planning/CHANGELOG.md §"Current Status" 갱신 (✅ 추가, ⏳ 다음 단계 갱신)
7. docs/planning/open-items.md (Open Items) 해소되면 제거 + Section 2 결정 표로 이관
8. docs/planning/CHANGELOG.md 변경 이력에 한 줄 추가
9. **13/02-catalog 동기화 검사 (ADR-0035)** — `bash .claude/scripts/check-test-catalog-sync.sh`
   - **WARN 출력 시**: 04·05의 신규/변경 R-/F-ID를 13/02-catalog의 해당 레벨 섹션(`## 1. 단위`/`## 2. 통합`/`## 3. E2E`)에 `### R-NN`/`### F-NN` subsection으로 fan-in (한 시나리오가 여러 레벨이면 중복 인용, 정본은 04·05 — ADR-0036)
   - **OK 시**: skip
   - 04·05·13 산출 부재 시 exit 3 (이는 Phase 2 아직 안 끝났다는 신호 — `/flow-design` 우선)

## 완료 조건
- 필요한 모든 문서 갱신 완료
- ADR 필요 시 작성됨
- docs/planning/CHANGELOG.md §"Current Status"가 현재 상태와 일치
- 다음 세션 협업자가 본 변경을 PLAN.md만으로 이해 가능

## Strict Rules (policies/flow-and-gates.md §3.3)
- **모든 결정은 1결정-1ADR**
- **PLAN.md가 단일 진실의 원천** — 다른 문서와 충돌 시 갱신 필수
- **미완 문서에는 명시적 마커**: `> [DRAFT]`, `> [TODO: 결정 필요]`, `> [BLOCKED: …]`

## Artifact Binding
- 입력: PR, 결정 컨텍스트
- 출력: ADR / docs/planning/CHANGELOG.md §"Current Status" / CHANGELOG (재개의 재료)
