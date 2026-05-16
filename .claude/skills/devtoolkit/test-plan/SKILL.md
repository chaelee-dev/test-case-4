---
name: test-plan
description: Use this skill when /qa-test --ai is entering the AI gate (D-06 1단) and needs to compose the PR body's Test Plan 4-block (Build / Automated tests / Manual verification / DoD coverage). Pulls the issue's DoD checklist and upstream SRS/PRD scenarios cited in 12 Test Design fan-in catalog.
---

# test-plan — PR Test Plan 4블록 자동 생성

> **정합**: [ADR-0001](../../../../docs/planning/adr/0001-test-gate-ai-and-human.md) (D-06 2단 게이트), [ADR-0014](../../../../docs/planning/adr/0014-test-system-strengthening-and-glossary.md) (12 Test Design fan-in), [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md)

## 1. 역할

이슈 DoD + 상류 SRS/PRD 시나리오를 fan-in해 **PR 본문 Test Plan 4블록**(Build / Automated tests / Manual verification / DoD coverage)을 자동 생성한다. AI 게이트(`/qa-test --ai`)의 PASS 직후 PR 생성 시 본문 채움 책임.

## 2. 진입점

- `/qa-test --ai` PASS 직후 PR 생성 시점
- 사용자 명시 호출: `/test-plan --issue=#N`

## 3. 입력

- **이슈 번호** (필수): `--issue=#N`
- **acceptance 파일 경로** (필수): `docs/features/<slug>/<slug>.acceptance.md`
- **상류 13 Test Design fan-in 카탈로그 경로** (선택): 기본 `docs/planning/13-test-design/02-catalog/` (ADR-0031)

## 4. 동작

```
1. 이슈 본문 Read
   - DoD Checklist 항목 추출
   - 매핑.R-ID / 매핑.F-ID 추출

2. acceptance.md Read
   - AC-XX (Given/When/Then) 추출

3. 12 Test Design fan-in 카탈로그 조회
   - R-ID/F-ID 별 시나리오 인용 가져오기
   - 상류 부재 시 acceptance.md 단독 사용 (fallback 안내)

4. Test Plan 4블록 조립:

   ### Build
   - [ ] <build cmd> (output: ...)

   ### Automated tests
   - [ ] <test cmd> — N tests, M passed, 0 failed   # AI 게이트가 1차 실행 후 결과 첨부

   ### Manual verification
   - [ ] {{acceptance Functional 항목}}            # acceptance.md AC-XX에서 풀어 적기
   - [ ] {{acceptance UX 항목}}
   - [ ] {{회귀 시나리오}}

   ### DoD coverage
   | Acceptance | PR diff | 검증 |
   |---|---|---|
   | Functional A | src/x.ts:42 | 단위 테스트 x.test.ts |

5. PR body에 삽입 위치 결정 (.github/pull_request_template.md 정합)
6. gh pr create 또는 gh pr edit 호출 시 --body 인자로 전달
```

## 5. 출력

- 완성된 PR body Markdown 문자열
- 누락 항목 보고 (예: "fan-in 카탈로그에 R-AUTH-01 없음 — acceptance.md 단독 사용")

## 6. 실패 케이스

| 케이스 | 동작 |
|---|---|
| 이슈 본문에 DoD 없음 | BLOCKED — wbs.md 4필드 강제(ADR-0008) 위반. 이슈 본문 보강 요청 |
| acceptance.md 부재 | BLOCKED — `/acceptance-criteria` 선행 호출 요청 |
| 12 fan-in 카탈로그 부재 + acceptance.md만 있음 | WARN — fallback 진행 (출력에 경고 명시) |
| Build 명령어 미정의 | WARN — 빈 체크박스로 출력 (사용자가 PR 생성 후 추가) |

## 7. 정합 문서

- [`policies/sprint-cycle.md §2`](../../../../docs/planning/policies/sprint-cycle.md) — D-06 게이트 + Test Plan 4블록 구조
- [`policies/sprint-cycle.md §1`](../../../../docs/planning/policies/sprint-cycle.md) — 자동화 진입점
- [ADR-0014](../../../../docs/planning/adr/0014-test-system-strengthening-and-glossary.md) — 12 Test Design fan-in
- [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md) — 본 Skill 도입
- [`.github/pull_request_template.md`](../../../../.github/pull_request_template.md) — PR body 표준 템플릿
