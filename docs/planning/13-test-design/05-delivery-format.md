---
doc_type: test-design
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — Customer Delivery Format

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 시나리오 ID 채번 + 전달 시점 |

## 1. 산출 범위 (단위·통합·E2E 시나리오)

본 프로젝트는 *외부 고객*에게 제출하는 정식 납품 산출이 없는 dogfooding 프로젝트이지만, agent-toolkit dogfooding의 일환으로 다음 표본을 보관한다.

- **단위 테스트 리포트**: Jacoco HTML (BE) + Vitest c8 (FE) — `build/reports/jacoco/test/html/`, `coverage/lcov-report/`
- **통합 테스트 리포트**: 동일
- **E2E 테스트 리포트**: Playwright HTML report — `playwright-report/`
- **API contract**: Bruno runner output — `specs/api/bruno/results/`
- **성능 리포트**: k6 summary.json + Grafana 스크린샷 (nightly artifact)
- **보안 리포트**: OWASP ZAP HTML report (nightly artifact)

리포트는 GitHub Actions artifact + `gh-pages` 호스팅으로 외부 접근 가능 — 라이센스: MIT.

## 2. 포맷·도구 (HTML/XLSX/Allure 등)

| 산출 | 포맷 | 도구 | 위치 |
|---|---|---|---|
| 단위/통합 커버리지 | HTML | Jacoco / c8 | CI artifact |
| 단위/통합 결과 매트릭스 | HTML + JUnit XML | Surefire / Vitest | CI artifact |
| E2E 결과 + trace | HTML + video/zip | Playwright HTML reporter | CI artifact + gh-pages |
| API contract 결과 | JSON + HTML | Bruno CLI | CI artifact |
| 성능 trend | HTML + JSON | k6 + Grafana | nightly artifact |
| 보안 결과 | HTML + JSON | OWASP ZAP | nightly artifact |
| 통합 대시보드 (옵션) | Allure | `allure generate` | gh-pages |

XLSX 출력은 본 사이클 비범위 (dogfooding이라 고객 납품 없음). 추후 사용자가 요청하면 `allure → xlsx export` 스크립트 추가 가능.

## 3. 시나리오 ID 채번 규칙

| Prefix | 사용 위치 | 예 |
|---|---|---|
| **TC-** | 단위 테스트 케이스 (BE+FE 통합) | TC-AUTH-LOGIN-001, TC-MARKDOWN-XSS-002 |
| **IT-** | 통합 테스트 케이스 | IT-ARTICLE-CRUD-001, IT-FOLLOW-IDEMPOTENT-002 |
| **E2E-** | Playwright spec | E2E-AUTH-GOLDEN-001, E2E-EDITOR-NEW-002 |
| **SC-** | 시나리오 카탈로그(02-catalog.md) 행 | SC-RF-09 (R-F-09 묶음), SC-F-04 (F-04 묶음) |
| **UC-** | 03 user-scenarios use case (재인용) | UC-04 (글 작성) |
| **CT-** | Bruno contract test | CT-ARTICLES-GET-001 |
| **PT-** | 성능 시나리오 (04-performance.md) | PT-P1, PT-P2 |
| **ST-** | 보안 시나리오 (04-performance.md) | ST-S1, ST-S2 |

채번 규칙: `<PREFIX>-<도메인>-<연번 3자리>`. 도메인 약어는 04 SRS 도메인 prefix와 정렬(AUTH/USER/ARTICLE/COMMENT/FAVORITE/TAG/MARKDOWN).

## 4. 전달 시점 (스프린트 종료·릴리스·고객 요청)

| 시점 | 산출 | 방식 |
|---|---|---|
| **매 PR 머지 후** | 단위 + 통합 + contract 결과 | CI artifact (자동) |
| **스프린트 종료** (Sprint 1~4 각각) | 위 + E2E 결과 + 커버리지 trend | `gh-pages` 정적 호스팅 + retro 문서에 링크 |
| **릴리스 (v1.0.0 등)** | 위 전부 + nightly 성능/보안 | Release 노트에 artifact 링크 첨부 |
| **고객 요청** | 위 + Allure 묶음 zip | (현재 외부 고객 없음 — dogfooding) |

릴리스 시 추가로 RealWorld 캐노니컬 Bruno 슈트 통과율을 README badge로 노출.
