---
name: scenario-derive
description: Use this skill when /wbs is composing issue bodies during sprint planning, to pull upstream SRS R-ID / PRD F-ID test scenarios (Given/When/Then) into the issue's DoD section. Cites 04 SRS or 05 PRD scenarios when available, or generates fallback inline when upstream is absent.
---

# scenario-derive — 상류 시나리오 → 이슈 DoD 인용

> **정합**: ADR-0014 (테스트 시스템 보강 + 시나리오 4단계), ADR-0015 (커버리지 ≥ 80% MUST), [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md)

## 1. 역할

이슈 본문 작성 시 *상류*(04 SRS R-ID / 05 PRD F-ID)에 정의된 검증 시나리오를 이슈 DoD에 자동 인용한다. 상류 부재 시 *이슈 단위 fallback 시나리오 생성*을 안내. 시나리오 4단계 흐름의 ②→③ 다리 역할.

## 2. 진입점

- `/wbs` 신규 작성 모드 — 각 이슈 본문 채울 때 자동 호출
- `/wbs` 갱신 모드 — Sprint Rollover 시 신규 이슈에 자동 호출
- 사용자 명시 호출: `/scenario-derive --r-id=R-AUTH-01` 또는 `--f-id=F-AUTH-LOGIN`

## 3. 입력

- **R-ID 또는 F-ID** (필수): 상류 매핑 식별자
- **이슈 컨텍스트** (선택): 이슈 제목·범위 (fallback 시나리오 생성 시 참고)

## 4. 동작

```
1. R-ID/F-ID로 상류 파일 식별:
   - R-ID → docs/planning/04-srs/04-srs.md (또는 도메인 분할 04-srs/<NN-domain>.md)
   - F-ID → docs/planning/05-prd/05-prd.md (또는 영역 분할)

2. 해당 ID의 "테스트 시나리오" 절 추출:
   - Given/When/Then 형식
   - Happy path + Failure path (ADR-0014 §2 3축 강제)
   - 테스트 레벨 (단위/통합/E2E)

3. 이슈 본문에 인용:

   ## 테스트 시나리오 (인용/생성)
   - **상류 인용**: 04#R-AUTH-01 / 05#F-AUTH-LOGIN
     - Given <전제>, When <행동>, Then <기대 결과> (Happy, 단위)
     - Given <오류 조건>, When <행동>, Then <실패 메시지> (Failure, 통합)
   - 출처: docs/planning/04-srs/04-srs.md §R-AUTH-01

4. 상류 부재 시 fallback:
   - 이슈 본문에 다음 안내:
     "⚠️ 상류 시나리오 부재 (R-XXX in 04-srs.md). 이슈 단위 fallback 시나리오 작성 필요.
      WBS 작성자가 Given/When/Then 1개 이상 직접 작성하거나 SRS 보강 후 본 Skill 재호출."

5. 출력 텍스트를 호출자(/wbs)에게 반환
```

## 5. 출력

- 인용된 시나리오 Markdown 블록
- 출처 cross-ref (`04#R-XXX` 형식)
- (fallback 시) 안내 메시지

## 6. 실패 케이스

| 케이스 | 동작 |
|---|---|
| R-ID/F-ID 형식 위반 (ADR-0014 정규식) | BLOCKED — ID 형식 안내 |
| 상류 파일 부재 | WARN — fallback 안내 + 진행 |
| 상류에 ID는 있으나 시나리오 절 비어있음 | BLOCKED — 04/05 schema BLOCK 위반. 상류 보강 요청 (ADR-0014) |

## 7. 정합 문서

- [INDEX.md §3.1](../../../../docs/planning/INDEX.md) — 시나리오 4단계 흐름 정본
- [ADR-0014](../../../../docs/planning/adr/0014-test-system-strengthening-and-glossary.md) — 시나리오 3축 강제
- [ADR-0015](../../../../docs/planning/adr/0015-mandatory-folder-structure-and-test-coverage.md) — 커버리지 80% + 레벨 매트릭스
- [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md) — 본 Skill 도입
- [`policies/sprint-cycle.md §1`](../../../../docs/planning/policies/sprint-cycle.md) — 자동화 진입점
