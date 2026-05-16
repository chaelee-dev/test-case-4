---
doc_type: test-design
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-N-01, R-N-02, R-N-03, R-N-05, R-N-06]
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — Regression Test Policy

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 회귀 범위·자동화·트리거 |

## 1. 회귀 범위

매 PR에서 다음을 회귀로 실행한다 (CI):

1. **단위 테스트 전수** (BE Jacoco + FE Vitest) — < 3분
2. **통합 테스트 전수** (Testcontainers + MSW) — < 5분
3. **캐노니컬 Bruno API contract 슈트** — < 2분 (19 엔드포인트)
4. **Playwright E2E 핵심 9 spec** — < 8분
5. **3 profile 부팅 smoke** — dev/stg/prod 각각 헬스체크 200 확인 — < 2분 × 3
6. **빌드 + lint + format check** — < 3분

총 CI 시간 목표 < 25분.

야간(nightly)으로 다음 추가 실행:
- **k6 성능 부하 (R-N-01)** — 50 동시 / 글 1만 시드 — < 15분
- **OWASP ZAP baseline (R-N-02·R-N-03)** — < 30분
- **캐노니컬 Playwright E2E 전수** — fork된 모든 spec — < 60분

## 2. 자동화 정책

- 모든 회귀는 **CI에서 자동 실행 + 결과 코멘트** (GitHub Actions + PR 코멘트 봇)
- 단위/통합/contract/E2E 핵심은 **PR open + push 시 매번**
- 야간 회귀는 `cron '0 18 * * *' KST` (UTC 09:00) — main 브랜치 대상
- 회귀 실패 시 자동 GitHub Issue 발행 (label `flaky-test`, assign to last-author) — 1차 분석 후 fix
- 회귀 결과 trend는 GitHub Actions artifact + Allure 리포트 (`gh-pages` 호스팅)

## 3. 회귀 트리거

| 트리거 | 실행 범위 | 차단 정책 |
|---|---|---|
| PR open / push | 단위 + 통합 + contract + 핵심 E2E + 3 profile smoke + lint/format/build | 1개라도 실패 시 머지 차단 |
| main 머지 후 | 위 + nightly 전수 (성능·보안·E2E 전수) | 실패 시 issue 자동 발행, 다음 PR에 BLOCK 알림 |
| Daily cron 18:00 KST | nightly 전수 | 실패 시 ALERTS slack/issue |
| Release tag (`v*.*.0`) | 위 전수 + 데모 데이터 시드 + smoke production | 실패 시 release 차단 |
| 부팅 자산 변경 (12-scaffolding §7 또는 LOCAL.md) | 3 profile 부팅 smoke + LOCAL.md sync 검증 | 변경 PR이 자동 BLOCK 받음 (ADR-0037 v1.1 + 0040) |
| schema 변경 (`.claude/schemas/`) | 모든 산출 문서 re-validate | (toolkit dogfooding에 한정) |

회귀 통과 = D-06 게이트 PASS의 필요 조건 (충분 조건은 휴먼 게이트 `tested` 라벨).
