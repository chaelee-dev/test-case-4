---
doc_type: test-design
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-N-01, R-N-02, R-N-03, R-N-04, R-N-05, R-N-06, R-N-07, R-N-08]
  F-ID: [F-01, F-02, F-03, F-04, F-05, F-06, F-07, F-08, F-09]
  supersedes: null
---

# Conduit (RealWorld 클론) — Test Strategy

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — BDD 변형 + 4 레벨 (단위/통합/E2E/contract) + 커버리지 85% |

## 1. 방법론 (TDD/BDD)

본 프로젝트는 **BDD 변형 (Given/When/Then 기반)**을 사실상의 합의로 채택한다. 04 SRS·05 PRD의 모든 R-ID·F-ID Acceptance가 이미 Given/When/Then 형식으로 작성되어 있으며(schema BLOCK), 그 문구가 그대로 통합·E2E 시나리오 이름이 된다.

TDD는 *모듈 신규 작성 시*에만 권고: 새 R-ID에 대해 실패 테스트 작성 → 구현 → 통과 → 리팩터. 기존 코드 수정은 TDD 강제하지 않음 (속도 우선).

비-TDD 모드는 PoC·spike·실험 코드에 한해 허용 — 단 PR merge 전 12 catalog에 시나리오 fan-in 필수.

**테스트 작성 책임**: 구현자가 단위 + 통합 작성. E2E는 QA(또는 reviewer) 작성 — Generator ≠ Evaluator 원칙(CLAUDE.md §에이전트 규칙).

## 2. 도구 선택

| 레벨 | 도구 | 이유 |
|---|---|---|
| **단위 (BE)** | JUnit 5 + AssertJ + Mockito 5 | Spring Boot 표준, JUnit 5 매개변수 테스트로 XSS 페이로드 등 다중 입력 |
| **단위 (FE)** | Vitest + @testing-library/react + @testing-library/user-event | Vite 정합, Jest 대비 빠름 |
| **통합 (BE)** | @SpringBootTest + **Testcontainers (PostgreSQL 16)** + RestAssured | 실 DB로 마이그레이션 + N+1 검출. ADR-0014 §2.2 통합 = 실 DB |
| **통합 (FE)** | Vitest + **MSW** (Mock Service Worker) + RTL | API 모킹 + 컴포넌트 결합 |
| **E2E** | **Playwright** + 캐노니컬 RealWorld E2E 슈트 fork | 19 API + 9 페이지 골든패스 자동화 |
| **API contract** | **Bruno** (캐노니컬 RealWorld 슈트 fork) | OpenAPI 2.0.0 100% 일치 검증 |
| **성능** | **k6** | 50 동시 / 글 1만 부하 시나리오 (R-N-01) |
| **보안** | OWASP ZAP (선택, CI 야간) + 단위 테스트 XSS 페이로드 | R-N-03, R-N-02 |

## 3. 커버리지 목표 (≥ 80%)

- **라인 커버리지**: **85%** 이상 (BE Jacoco + FE Vitest coverage)
- **브랜치 커버리지**: 80% 이상
- **R-ID 커버리지**: **100%** — 35 R-ID 모두 단위·통합·E2E 매트릭스 행 존재 (13/02-catalog §4 BLOCK)
- **F-ID 커버리지**: **100%** — 9 F-ID 모두 매트릭스 행 존재
- **OpenAPI 엔드포인트 커버리지**: **100%** — 19 엔드포인트 모두 contract test (Bruno)

분야별 예외 (ADR-0015 §2.3 권고 범위 80~100% 내):
- M-BE-WEB GlobalExceptionHandler: 통합 80% (모든 예외 분기 검증 어려움 — Throwable 분기는 시뮬레이션 한정)
- M-FE-MARKDOWN: 단위 100% (XSS 페이로드 8종 필수 — 보안 R-N-03)
- M-BE-MARKDOWN: 단위 100% (동일 사유)

> 80% 미만은 ADR 신설 필수. 본 사이클은 일괄 85% 목표.

CI 게이트: `./gradlew jacocoTestCoverageVerification` + `pnpm test --coverage` 통과 후에만 PR merge.
