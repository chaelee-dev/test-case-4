---
doc_type: test-design
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-F-01, R-F-02, R-F-03, R-F-04, R-F-05, R-F-06, R-F-07, R-F-08, R-F-09, R-F-10, R-F-11, R-F-12, R-F-13, R-F-14, R-F-15, R-F-16, R-F-17, R-F-18, R-F-19, R-F-20, R-F-21, R-F-22, R-F-23, R-F-24, R-F-25, R-F-26, R-F-27, R-N-01, R-N-02, R-N-03, R-N-04, R-N-05, R-N-06, R-N-07, R-N-08]
  F-ID: [F-01, F-02, F-03, F-04, F-05, F-06, F-07, F-08, F-09]
  supersedes: null
---

# Conduit (RealWorld 클론) — Test Scenario Catalog (단위·통합·E2E 별 묶음)

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 35 R-ID + 9 F-ID 시나리오 카탈로그 + 레벨 매트릭스 |

본 카탈로그는 04 SRS R-ID·05 PRD F-ID의 시나리오를 단위/통합/E2E 별로 fan-in한다. 매 시나리오는 **출처**(`04#R-...`/`05#F-...`)와 **테스트 레벨**을 명시한다 (ADR-0036 BLOCK).

## 1. 단위 테스트 카탈로그

### R-F-02: 로그인 비밀번호 검증
- 출처: 04#R-F-02
- 테스트 레벨: 단위
- 대상: `AuthService.login` + `PasswordEncoder.matches`
- 케이스: 정상 자격 → token 발급; 잘못된 password → InvalidCredentialsException; 비등록 email → InvalidCredentialsException

### R-F-17: 슬러그 생성기
- 출처: 04#R-F-17
- 테스트 레벨: 단위
- 대상: `SlugGenerator.generate(title)`
- 케이스: "Hello World" → "hello-world"; 충돌 시 nanoid suffix; 특수문자만 → "untitled-<nano>"

### R-F-18: 마크다운 sanitize (BE 검증용)
- 출처: 04#R-F-18, 04#R-N-03
- 테스트 레벨: 단위
- 대상: `MarkdownService.sanitize`
- 케이스: 8종 XSS 페이로드(`<script>`, `<iframe>`, `onerror`, `javascript:`, data URL, `<style>`, `<svg onload>`, `<a href="javascript:...">`) 모두 제거; 일반 마크다운 보존

### R-N-02: JWT 발급/검증
- 출처: 04#R-N-02
- 테스트 레벨: 단위
- 대상: `JwtService.create / verify`
- 케이스: 정상 토큰 verify → userId; 만료 → 401 매핑; 위변조 서명 → 401; HS256 + 256bit 비밀키 검증

### R-N-07: 페이지네이션 경계
- 출처: 04#R-N-07
- 테스트 레벨: 단위
- 대상: `PaginationValidator`
- 케이스: 음수 offset → 422; limit > 100 clamp(100); offset > 1M → 200 + 빈 결과 < 500ms

### R-F-25: 헤더 활성 메뉴 (FE)
- 출처: 04#R-F-25
- 테스트 레벨: 단위
- 대상: `<Header>` 컴포넌트
- 케이스: 비로그인 4개 메뉴; 로그인 4개 메뉴; active class 적용

### R-F-27: M-FE-API 401 인터셉터
- 출처: 04#R-F-27
- 테스트 레벨: 단위
- 대상: `apiClient` 인터셉터
- 케이스: 401 응답 시 localStorage clear + auth context null + 보호 라우트에서만 navigate

### F-06: 마크다운 sanitize (FE 렌더)
- 출처: 05#F-06
- 테스트 레벨: 단위
- 대상: `<MarkdownView>`
- 케이스: 동일 XSS 페이로드 8종 React tree에서 제거; alert 미발생

## 2. 통합 테스트 카탈로그

### R-F-01: 회원가입 통합
- 출처: 04#R-F-01, 05#F-01
- 테스트 레벨: 통합
- 대상: `UserController POST /users` + DB
- 케이스: 정상 → 201 + token; 중복 username → 422; 중복 email → 422; password BCrypt 저장 확인

### R-F-02: 로그인 통합
- 출처: 04#R-F-02
- 테스트 레벨: 통합
- 케이스: 정상 → 200 + new token; 잘못된 password → 401; 비등록 → 401

### R-F-03: 사용자 조회/수정 통합
- 출처: 04#R-F-03
- 테스트 레벨: 통합
- 케이스: GET 정상; PUT 부분 갱신 atomic; 토큰 부재 401; email 중복 422

### R-F-05: Follow/Unfollow 통합
- 출처: 04#R-F-05
- 테스트 레벨: 통합
- 케이스: idempotent POST/DELETE; 자기 자신 422; UNIQUE 제약 검증

### R-F-06: 글 목록 + 필터 + 페이지네이션 통합
- 출처: 04#R-F-06
- 테스트 레벨: 통합
- 케이스: 빈 결과; tag/author/favorited 필터 각각; limit/offset 경계; 정렬 createdAt DESC

### R-F-07: Your Feed 통합
- 출처: 04#R-F-07
- 테스트 레벨: 통합
- 케이스: 팔로잉 0명 → 빈; N명 글만 노출; 401 (비로그인)

### R-F-09: 글 작성 + slug + tag upsert 통합
- 출처: 04#R-F-09, 04#R-F-17
- 테스트 레벨: 통합
- 케이스: 정상 → 201; 동일 title 2건 → 두 번째 nanoid suffix; tagList 새 태그 upsert; tagList 빈 OK

### R-F-10: 글 수정 권한 통합
- 출처: 04#R-F-10
- 테스트 레벨: 통합
- 케이스: 본인 → 200; 타인 → 403; title 변경 시 slug 재생성; title 미변경 시 slug 보존 (OQ-SR-02)

### R-F-11: 글 삭제 cascade 통합
- 출처: 04#R-F-11
- 테스트 레벨: 통합
- 케이스: 본인 → 200; 연관 comments/favorites/article_tags cascade 제거; 타인 → 403

### R-F-12: Favorite/Unfavorite count 통합
- 출처: 04#R-F-12, 05#F-07
- 테스트 레벨: 통합
- 케이스: idempotent; favoritesCount atomic; 동시 호출 race 없음

### R-F-13~15: 댓글 CRUD 통합
- 출처: 04#R-F-13, 04#R-F-14, 04#R-F-15, 05#F-08
- 테스트 레벨: 통합
- 케이스: list 0건/N건; 작성 정상/빈 body 422; 삭제 본인/타인 403/없는 id 404

### R-F-16: 인기 태그 통합
- 출처: 04#R-F-16
- 테스트 레벨: 통합
- 케이스: 0건 빈; N건 빈도 정렬; 상위 20 한도

### R-N-02: Security filter chain 통합
- 출처: 04#R-N-02
- 테스트 레벨: 통합
- 케이스: 보호 엔드포인트 토큰 부재 401; 만료 토큰 401; 정상 토큰 200; BCrypt 평문 저장 금지 확인

### R-N-04: 권한 거부 (Policy) 통합
- 출처: 04#R-N-04
- 테스트 레벨: 통합
- 케이스: 타인 글 PUT/DELETE 403; 타인 댓글 DELETE 403

### R-N-05: 응답 형식 contract 통합 (Bruno fork)
- 출처: 04#R-N-05
- 테스트 레벨: 통합
- 케이스: 19 엔드포인트 모두 캐노니컬 Bruno 슈트 통과; 단일/다건/에러 wrap 형식

### R-N-06: 3 profile 부팅 통합
- 출처: 04#R-N-06
- 테스트 레벨: 통합
- 케이스: CI matrix dev/stg/prod 각각 fresh checkout → ready 신호 + 헬스체크 200

### R-N-08: traceId 로깅 통합
- 출처: 04#R-N-08
- 테스트 레벨: 통합
- 케이스: 임의 요청 로그 1줄에 traceId + method + path + status + duration + userId 6키 포함

### F-09: M-FE-API 401 자동 처리 통합 (MSW)
- 출처: 05#F-09, 04#R-F-27
- 테스트 레벨: 통합
- 케이스: MSW 401 응답 → 토큰 제거 + 보호 라우트 → /login redirect; 비보호 라우트는 페이지 유지

## 3. E2E 테스트 카탈로그

### F-01: 회원가입 + 로그인 골든패스
- 출처: 05#F-01, 04#R-F-01, 04#R-F-02
- 테스트 레벨: E2E
- 대상: 캐노니컬 Playwright `auth.spec.ts` (fork)
- 케이스: /register 폼 작성 → 헤더 갱신; logout → /login 폼 → 헤더 갱신

### F-02: Settings + Logout E2E
- 출처: 05#F-02
- 테스트 레벨: E2E
- 케이스: /settings 폼 부분 갱신 → 헤더 username 갱신; Logout → 익명 헤더

### F-03: Follow/Unfollow + Profile E2E
- 출처: 05#F-03
- 테스트 레벨: E2E
- 케이스: /profile/<other> 진입 → Follow → 버튼 토글 → Your Feed에 해당 사용자 글 노출

### F-04: Editor 작성·수정·삭제 E2E
- 출처: 05#F-04
- 테스트 레벨: E2E
- 케이스: /editor 새 글 → /article/<slug> 이동; /editor/<slug> 수정 → 반영; Delete 다이얼로그 → /

### F-05: Home Feed (Global/Your/Tag) + 인기 태그 E2E
- 출처: 05#F-05
- 테스트 레벨: E2E
- 케이스: Global Feed 페이지네이션; 로그인 후 Your Feed 자동 활성; 사이드바 태그 클릭 → "# tagname" 탭 활성

### F-06: Article 마크다운 + XSS 방어 E2E
- 출처: 05#F-06, 04#R-F-18, 04#R-N-03
- 테스트 레벨: E2E
- 케이스: 정상 마크다운 렌더; XSS body 입력 → 글 상세에서 alert 미발생

### F-07: Favorite 토글 E2E
- 출처: 05#F-07
- 테스트 레벨: E2E
- 케이스: Home/Article에서 ♥ 클릭 → count+1; 재클릭 → -1; 비로그인 클릭 → 안내

### F-08: 댓글 작성·삭제 E2E
- 출처: 05#F-08
- 테스트 레벨: E2E
- 케이스: 댓글 작성 → 상단 추가; 본인 댓글 삭제 → 제거; 타인 댓글 🗑 미노출

### F-09: 보호 라우트 + 401 자동 처리 E2E
- 출처: 05#F-09, 04#R-F-26
- 테스트 레벨: E2E
- 케이스: /settings 비로그인 진입 → /login?redirect=/settings; 만료 토큰으로 보호 진입 → /login으로 자동 이동

### R-N-01: 성능 부하 E2E (k6)
- 출처: 04#R-N-01
- 테스트 레벨: E2E
- 케이스: 동시 50 사용자 / 글 1만 시드 → 글 목록 1페이지 95p < 500ms; 단일 요청 95p < 300ms

## 4. 레벨 매트릭스 (단위·통합·E2E)

각 R-/F-ID에 대해 ✅(적용) 또는 N/A(부적합)만 허용 — ❌ 금지 (ADR-0023).

| ID | 단위 | 통합 | E2E | 비고 |
|---|---|---|---|---|
| R-F-01 (회원가입) | ✅ | ✅ | ✅ | F-01 묶음 |
| R-F-02 (로그인) | ✅ | ✅ | ✅ | F-01 묶음 |
| R-F-03 (현재 사용자 R/U) | ✅ | ✅ | ✅ | F-02 묶음 |
| R-F-04 (프로필 조회) | ✅ | ✅ | ✅ | F-03 묶음 |
| R-F-05 (Follow/Unfollow) | ✅ | ✅ | ✅ | F-03 묶음 |
| R-F-06 (글 목록+필터+페이지) | ✅ | ✅ | ✅ | F-05 묶음 |
| R-F-07 (Your Feed) | ✅ | ✅ | ✅ | F-05 묶음 |
| R-F-08 (단일 글) | ✅ | ✅ | ✅ | F-06 묶음 |
| R-F-09 (글 작성) | ✅ | ✅ | ✅ | F-04 묶음 |
| R-F-10 (글 수정) | ✅ | ✅ | ✅ | F-04 묶음 |
| R-F-11 (글 삭제) | ✅ | ✅ | ✅ | F-04 묶음 |
| R-F-12 (Favorite) | ✅ | ✅ | ✅ | F-07 묶음 |
| R-F-13 (댓글 목록) | ✅ | ✅ | ✅ | F-08 묶음 |
| R-F-14 (댓글 작성) | ✅ | ✅ | ✅ | F-08 묶음 |
| R-F-15 (댓글 삭제) | ✅ | ✅ | ✅ | F-08 묶음 |
| R-F-16 (인기 태그) | ✅ | ✅ | ✅ | F-05 묶음 (사이드바 검증) |
| R-F-17 (슬러그) | ✅ | ✅ | N/A | 내부 정책, UI 노출 없음 |
| R-F-18 (마크다운 sanitize) | ✅ | ✅ | ✅ | XSS 페이로드 8종 |
| R-F-19 (Home 페이지) | ✅ | ✅ | ✅ | F-05 묶음 |
| R-F-20 (Auth 페이지) | ✅ | ✅ | ✅ | F-01 묶음 |
| R-F-21 (Settings 페이지) | ✅ | ✅ | ✅ | F-02 묶음 |
| R-F-22 (Editor 페이지) | ✅ | ✅ | ✅ | F-04 묶음 |
| R-F-23 (Article 페이지) | ✅ | ✅ | ✅ | F-06 묶음 |
| R-F-24 (Profile 페이지) | ✅ | ✅ | ✅ | F-03 묶음 |
| R-F-25 (헤더) | ✅ | ✅ | ✅ | F-09 묶음 |
| R-F-26 (보호 라우트) | ✅ | ✅ | ✅ | F-09 묶음 |
| R-F-27 (JWT 저장/헤더) | ✅ | ✅ | ✅ | F-09 묶음 |
| R-N-01 (성능) | N/A | ✅ | ✅ | k6 부하 |
| R-N-02 (JWT+BCrypt) | ✅ | ✅ | ✅ | 보안 P0 |
| R-N-03 (XSS) | ✅ | ✅ | ✅ | F-06 묶음 |
| R-N-04 (권한 거부) | ✅ | ✅ | ✅ | 타인 자원 수정 |
| R-N-05 (응답 형식) | N/A | ✅ | N/A | Bruno contract |
| R-N-06 (3 profile 부팅) | N/A | ✅ | N/A | CI matrix |
| R-N-07 (페이지 경계) | ✅ | ✅ | N/A | API 응답만 |
| R-N-08 (traceId 로깅) | N/A | ✅ | N/A | logback 검증 |
| F-01 (인증) | ✅ | ✅ | ✅ | |
| F-02 (내 정보) | ✅ | ✅ | ✅ | |
| F-03 (프로필+팔로우) | ✅ | ✅ | ✅ | |
| F-04 (글 CUD) | ✅ | ✅ | ✅ | |
| F-05 (Home/Feeds) | ✅ | ✅ | ✅ | |
| F-06 (글 상세+마크다운) | ✅ | ✅ | ✅ | |
| F-07 (Favorite) | ✅ | ✅ | ✅ | |
| F-08 (댓글) | ✅ | ✅ | ✅ | |
| F-09 (헤더+보호) | ✅ | ✅ | ✅ | |
