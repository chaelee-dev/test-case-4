---
doc_type: test-design
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-N-01, R-N-02, R-N-03]
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — Performance & Security Tests

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 성능/보안 테스트 시나리오 + 도구 |

## 1. 성능 테스트

### 시나리오 P1 — 단일 사용자 응답 시간 (R-N-01)
- **목표**: 각 19 엔드포인트 95p < 300ms (BE 로컬, in-memory DB)
- **도구**: k6 또는 Spring Boot Actuator + JMH 단위
- **실행**: PR CI (nightly), 결과 trend는 Grafana 또는 Allure 리포트
- **시드**: 글 100건, 사용자 10명, 댓글 500개

### 시나리오 P2 — 동시 50명 + 글 1만 부하 (R-N-01)
- **목표**: 동시 50 가상 사용자가 글 목록·단일 글·좋아요를 30분간 호출. 95p < 500ms, error rate < 1%
- **도구**: k6
- **시드**: 글 10,000건, 사용자 100명, follow 1,000건, favorite 5,000건
- **시나리오 분배**:
  - 50% GET /articles?limit=20&offset=random
  - 20% GET /articles/{slug}
  - 15% GET /tags
  - 10% POST/DELETE /favorite (인증 사용자)
  - 5% POST /articles (인증 사용자)

### 시나리오 P3 — 페이지네이션 경계 (R-N-07)
- **목표**: offset=1,000,000 호출 시 < 500ms + 빈 결과 + OOM 없음
- **도구**: k6 단일 요청

## 2. 보안 테스트

### 시나리오 S1 — 마크다운 XSS 페이로드 (R-N-03)
- **목표**: 8종 XSS 페이로드를 글 body·댓글 body에 입력 → 응답·렌더에서 제거 확인
- **페이로드**:
  1. `<script>alert(1)</script>`
  2. `<img src=x onerror=alert(1)>`
  3. `<iframe src="javascript:alert(1)"></iframe>`
  4. `[click me](javascript:alert(1))`
  5. `<svg onload=alert(1)>`
  6. `<a href="data:text/html,<script>alert(1)</script>">x</a>`
  7. `<style>body { background: url("javascript:alert(1)") }</style>`
  8. `<object data="javascript:alert(1)"></object>`
- **도구**: 단위 (BE MarkdownSanitizeTest + FE MarkdownView.test) + Playwright (브라우저에서 `dialog` 이벤트 미수신 확인)

### 시나리오 S2 — JWT 위변조 (R-N-02)
- **목표**: 보호 엔드포인트에 (a) 없는 토큰, (b) 만료 토큰, (c) HMAC 위변조 토큰, (d) 다른 비밀키로 서명된 토큰 → 모두 401
- **도구**: JUnit 5 + RestAssured (통합)

### 시나리오 S3 — 권한 거부 (R-N-04)
- **목표**: 사용자 A가 사용자 B의 글/댓글에 PUT/DELETE 직접 호출 → 403
- **도구**: 통합 테스트 + E2E

### 시나리오 S4 — OWASP ZAP baseline (옵션, nightly)
- **목표**: 일반 웹 취약점 (HTTP 헤더, CSP, CSRF 등) baseline scan
- **도구**: OWASP ZAP `zap-baseline.py`
- **참고**: 본 사이클은 nightly 실행만, 실패 시 issue 발행 (PR 차단 X)

### 시나리오 S5 — 평문 패스워드 저장 금지 (R-N-02)
- **목표**: DB users 테이블에 password 평문 컬럼 없음 + password_hash가 `$2a$` BCrypt 형식인지
- **도구**: 통합 (회원가입 후 DB 직접 조회)

## 3. 도구·시점

| 종류 | 도구 | 시점 | R-ID |
|---|---|---|---|
| 성능 (P1) | k6 | PR + nightly | R-N-01 |
| 성능 (P2) | k6 | nightly | R-N-01 |
| 성능 (P3) | k6 | PR | R-N-07 |
| 보안 (S1 XSS) | JUnit5 + Vitest + Playwright | PR | R-N-03, R-F-18 |
| 보안 (S2 JWT) | RestAssured 통합 | PR | R-N-02 |
| 보안 (S3 권한) | 통합 + Playwright | PR | R-N-04 |
| 보안 (S4 ZAP) | OWASP ZAP | nightly | R-N-02, R-N-03 |
| 보안 (S5 BCrypt) | 통합 + 직접 DB 조회 | PR | R-N-02 |

성능·보안 실패 시 PR 차단 정책:
- PR 시점 (P1·P3·S1·S2·S3·S5): 1개라도 실패 → 머지 차단
- nightly (P2·S4): 실패 → issue 발행, 다음 PR에서 BLOCK 알림 (다음 PR 작업자가 fix 책임)
