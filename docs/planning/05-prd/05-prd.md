---
doc_type: prd
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: B
related:
  R-ID: [R-F-01, R-F-02, R-F-03, R-F-04, R-F-05, R-F-06, R-F-07, R-F-08, R-F-09, R-F-10, R-F-11, R-F-12, R-F-13, R-F-14, R-F-15, R-F-16, R-F-17, R-F-18, R-F-19, R-F-20, R-F-21, R-F-22, R-F-23, R-F-24, R-F-25, R-F-26, R-F-27]
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — PRD

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — F 9개 + MVP Cut 100% 포함 |

## 1. 제품 개요

**Conduit**는 RealWorld 오픈 스펙(Medium.com 스타일 블로그 플랫폼)을 agent-toolkit이 자동 생성한 풀스택 구현체다. 외부에 공개된 OpenAPI 2.0.0 + 9개 페이지 사양을 그대로 충족해, 캐노니컬 Bruno/Postman 슈트와 Playwright E2E를 통과시키는 것이 목적이다.

본 PRD는 04 SRS의 R-F/R-N을 **사용자 가치 중심의 F-기능 단위**로 묶어 MVP Cut과 우선순위를 정의한다. 모든 F-는 v0(MVP)에 포함된다 — 캐노니컬 사양 자체가 이미 "최소 가능 블로그"이기 때문.

## 2. 사용자 가치

| 페르소나 | 핵심 가치 |
|---|---|
| **Visitor (익명)** | 가입 없이 글로벌 피드/태그/단일 글/프로필 열람 → 가입 유인 |
| **Aiden (신규 작성자)** | 회원가입 즉시 글 작성 → 자기 글이 피드에 노출되는 만족 |
| **Bora (활성 독자)** | 관심 작성자 팔로우 + 좋아요 → 개인화된 Your Feed |
| **Self-Editor (저자 본인)** | 자기 글·댓글·설정 관리, 안전한 로그아웃 |

## 3. 기능

### F-01: 사용자 인증 (회원가입 + 로그인 + JWT)

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 신규 방문자, I want to 회원가입 및 로그인하고 토큰 기반 세션을 유지하고 싶다, so that 보호된 기능(글 작성·좋아요·팔로우)을 사용할 수 있다.
- **Acceptance**:
  - Given 유효한 username/email/password, When `/register` 폼을 제출하면, Then 회원이 생성되고 JWT가 발급돼 localStorage에 저장되고 헤더가 로그인 상태로 갱신된다.
  - Given 기존 회원, When `/login` 폼을 제출하면, Then JWT 발급 + 헤더 갱신 + 홈 이동.
- **R-ID 매핑**: R-F-01 (회원가입), R-F-02 (로그인), R-F-20 (FE 인증 페이지), R-F-27 (JWT 저장·헤더 부착)
- **테스트 시나리오**:
  - Happy (정상): 정상 입력 → 토큰 저장 + 홈 이동
  - Failure (에러): 중복 email/username → 폼 상단 에러; 잘못된 비밀번호 → 401 인라인 에러; 422 누락 필드 → 인라인
- **테스트 결정**: 단위: ✅ (validator + JWT 발급), 통합: ✅ (DB + Spring Security), E2E: ✅ (브라우저 골든패스)

### F-02: 내 정보 관리 (조회/수정/로그아웃)

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 로그인 사용자, I want to 내 프로필(bio·image·email·password)을 수정하고 로그아웃하고 싶다, so that 계정을 관리할 수 있다.
- **Acceptance**:
  - Given 로그인, When `/settings` 폼에서 부분 필드를 수정하고 "Update Settings"를 누르면, Then `PUT /user`로 갱신 + 새 JWT가 저장된다.
  - Given 로그인, When "Logout"을 누르면, Then localStorage에서 토큰이 제거되고 헤더가 익명 상태로 전환된다.
- **R-ID 매핑**: R-F-03 (BE 현재 사용자), R-F-21 (FE Settings 페이지)
- **테스트 시나리오**:
  - Happy (성공): 부분 갱신 + 로그아웃 동작
  - Failure (실패): email 중복 → 폼 에러; 비로그인 진입 → `/login`으로
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### F-03: 프로필 + 팔로우/언팔로우

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 사용자, I want to 다른 사용자의 프로필을 열람하고 팔로우/언팔로우하고 싶다, so that Your Feed가 내 관심에 맞게 채워진다.
- **Acceptance**:
  - Given `/profile/:username`, When 페이지가 로드되면, Then 사용자 헤더 + Follow 버튼(타인) 또는 Edit Settings 버튼(본인) + My/Favorited 탭 + 글 리스트가 표시된다.
  - Given 로그인 + 타 사용자, When Follow 버튼 클릭, Then `POST /profiles/:username/follow` 호출되어 following=true 토글.
- **R-ID 매핑**: R-F-04 (BE 프로필 조회), R-F-05 (BE 팔로우), R-F-24 (FE Profile 페이지)
- **테스트 시나리오**:
  - Happy (정상): 본인/타인 분기 + 탭 전환 + Follow 토글
  - Failure (실패): 자기 자신 팔로우 시도 → 버튼 미노출 + BE 422; 비로그인 클릭 → `/login`; 없는 username → 404 페이지
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### F-04: 글 작성·수정·삭제 (Editor)

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 로그인 사용자, I want to 글을 작성·수정·삭제하고 싶다, so that 콘텐츠를 공유하고 관리할 수 있다.
- **Acceptance**:
  - Given 로그인 + `/editor`, When title/description/body/tagList를 입력 후 "Publish Article", Then 새 글이 생성되고 `/article/:slug`로 이동한다. slug는 R-F-17 정책으로 자동 생성.
  - Given 로그인 + 본인 글 + `/editor/:slug`, When 폼 수정 후 "Update Article", Then `PUT /articles/:slug`로 갱신된다.
  - Given 본인 글 상세에서 "Delete Article" + 확인 다이얼로그, When 삭제 확정, Then `DELETE`로 글·댓글·좋아요 cascade 제거 + `/` 이동.
- **R-ID 매핑**: R-F-09 (작성), R-F-10 (수정), R-F-11 (삭제), R-F-17 (슬러그), R-F-22 (FE Editor)
- **테스트 시나리오**:
  - Happy (성공): 작성·수정·삭제 골든패스
  - Failure (에러): title/body 누락 → 422 인라인; 타인 글 PUT/DELETE 직접 호출 → 403; 비로그인 → `/login`
- **테스트 결정**: 단위: ✅ (validator + slug gen), 통합: ✅ (tag upsert + cascade), E2E: ✅

### F-05: 글 목록 (Home — Global / Your Feed / Tag) + 인기 태그

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 사용자, I want to 글로벌 피드·내 피드·태그별 피드를 페이지네이션으로 탐색하고 싶다, so that 관심 글을 빠르게 찾을 수 있다.
- **Acceptance**:
  - Given `/` 진입, When 페이지가 로드되면, Then Feed 탭(로그인 시 Your Feed + Global Feed, 비로그인 시 Global Feed) + 글 카드 20건 + 페이지네이션 + 인기 태그 사이드바가 표시된다.
  - Given 사이드바 태그 클릭, When 동작하면, Then "# tagname" 탭이 활성되고 `?tag=` 필터 글 목록이 로드된다.
- **R-ID 매핑**: R-F-06 (BE 글로벌+필터), R-F-07 (BE Your Feed), R-F-16 (BE Tags), R-F-19 (FE Home)
- **테스트 시나리오**:
  - Happy (정상): 3가지 탭 전환·페이지네이션·태그 필터 모두 동작
  - Failure (실패): API 실패 → "글을 불러올 수 없습니다" 재시도; 팔로잉 0명의 Your Feed → 빈 안내; limit > 100 → BE clamp
- **테스트 결정**: 단위: ✅ (탭 컴포넌트 state), 통합: ✅, E2E: ✅

### F-06: 글 상세 + 마크다운 안전 렌더링

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 사용자, I want to 글 본문이 마크다운으로 보기 좋게 렌더되고 XSS로부터 보호받고 싶다, so that 안전하게 콘텐츠를 소비할 수 있다.
- **Acceptance**:
  - Given `/article/:slug`, When 페이지가 로드되면, Then 메타·Follow·Favorite·sanitize된 마크다운·Edit/Delete(저자만)·댓글 폼(로그인)·댓글 리스트가 표시된다.
  - Given body에 `<script>`/`javascript:`/`on*` 핸들러가 포함, When 렌더, Then 출력에서 제거되어 alert가 발생하지 않는다.
- **R-ID 매핑**: R-F-08 (BE 단일 글), R-F-18 (마크다운 sanitize), R-F-23 (FE 상세 페이지), R-N-03 (XSS 방어)
- **테스트 시나리오**:
  - Happy (성공): 표준 마크다운 정상 렌더; 인증 상태별 버튼 분기 정확
  - Failure (방어): XSS 페이로드 무력화; 없는 slug → 404 페이지
- **테스트 결정**: 단위: ✅ (sanitize), 통합: ✅, E2E: ✅ (alert 미발생)

### F-07: 좋아요 (Favorite / Unfavorite)

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 로그인 사용자, I want to 글에 좋아요를 누르고 취소하고 싶다, so that 마음에 드는 콘텐츠를 표시하고 Favorited 탭에서 다시 볼 수 있다.
- **Acceptance**:
  - Given 로그인 + 글, When ♥ 버튼을 누르면, Then `POST .../favorite`로 favorited=true + count+1로 즉시 갱신된다.
  - Given 좋아요 상태, When 같은 버튼을 다시 누르면, Then `DELETE`로 count-1.
- **R-ID 매핑**: R-F-12 (BE 좋아요), R-F-06 (?favorited= 필터로 Profile Favorited 탭과 연계)
- **테스트 시나리오**:
  - Happy (정상): 토글 + count 정확성
  - Failure (실패): 비로그인 → 버튼 disabled or 로그인 안내; 없는 slug → 404
- **테스트 결정**: 단위: ✅, 통합: ✅ (favorites unique 제약), E2E: ✅

### F-08: 댓글 (목록·작성·삭제)

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 사용자, I want to 글에 대해 댓글을 보고 작성하고 내 댓글을 삭제하고 싶다, so that 글 작성자/독자와 소통할 수 있다.
- **Acceptance**:
  - Given `/article/:slug`, When 페이지 진입 시, Then 댓글 리스트(createdAt ASC)가 보이고 로그인 사용자에게는 댓글 폼이 노출된다.
  - Given 로그인, When 댓글 body 입력 후 "Post Comment", Then `POST .../comments`로 등록되고 리스트 상단에 추가된다.
  - Given 본인 댓글, When 🗑 클릭, Then `DELETE`로 제거된다.
- **R-ID 매핑**: R-F-13 (목록), R-F-14 (작성), R-F-15 (삭제)
- **테스트 시나리오**:
  - Happy (성공): 작성·삭제 모두 동작
  - Failure (에러): 빈 body → 422; 타인 댓글 삭제 직접 호출 → 403; 비로그인 작성 → `/login`
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### F-09: 헤더 네비게이션 + 보호 라우트 + 401 자동 처리

- **MVP Cut**: ✅ 포함
- **우선순위**: P0
- **사용자 스토리**: As a 사용자, I want to 헤더 메뉴와 라우트가 내 인증 상태에 맞게 동작하기를, so that 인증이 필요한 화면에서 길을 잃지 않는다.
- **Acceptance**:
  - Given 인증 상태(비로그인/로그인), When 임의 페이지의 헤더가 렌더되면, Then 그에 맞는 메뉴 4개가 노출되고 현재 라우트는 `active` 클래스가 적용된다.
  - Given 비로그인, When `/settings`, `/editor`, `/editor/:slug` 진입 시, Then `/login?redirect=원경로`로 리다이렉트된다.
  - Given 토큰 만료, When 보호 API 호출 결과 401 수신 시, Then 토큰이 자동 제거되고 auth context가 비로그인으로 전환되며 보호 라우트면 `/login`으로 강제 이동한다.
- **R-ID 매핑**: R-F-25 (헤더), R-F-26 (보호 라우트), R-F-27 (401 자동 처리)
- **테스트 시나리오**:
  - Happy (정상): 로그인 토글 시 헤더/메뉴 즉시 변경; 보호 진입 후 로그인 → redirect 따라 원경로 복귀
  - Failure (실패): 토큰 만료된 상태에서 보호 메뉴 클릭 → 401 → 로그인 페이지로
- **테스트 결정**: 단위: ✅ (auth context), 통합: ✅ (msw 401 mock), E2E: ✅

## 4. MVP Cut 요약

| F-ID | MVP | 비고 |
| --- | --- | --- |
| F-01 | ✅ 포함 | 인증은 모든 기능의 전제 — P0 |
| F-02 | ✅ 포함 | 내 정보 + 로그아웃 — 인증 사이클 닫음 |
| F-03 | ✅ 포함 | 프로필 + 팔로우 — Your Feed의 입력 |
| F-04 | ✅ 포함 | Editor — 콘텐츠 생산의 핵심 |
| F-05 | ✅ 포함 | Home + 인기 태그 — 진입 경로 |
| F-06 | ✅ 포함 | 글 상세 + 마크다운 sanitize — 보안 P0 |
| F-07 | ✅ 포함 | 좋아요 — 사용자 가치 신호 |
| F-08 | ✅ 포함 | 댓글 — 소셜 인터랙션 |
| F-09 | ✅ 포함 | 헤더·보호 라우트·401 — 인증 UX의 골격 |

**Out of Scope (포함되지 않은 F)** — 01 §5 참조: 비밀번호 리셋, 이메일 인증, 이미지 업로드, 어드민, 알림, 검색, 다국어, 결제, 모바일 네이티브, OAuth, WebSocket.

캐노니컬 RealWorld 사양 자체가 이미 "MVP가 곧 전체"인 구조라 v0에 9개 F 모두 포함. 추후 확장은 별 feature(`/flow-feature`)로 진행.

## 5. UX 원칙 / 화면 구성 큰 그림

- **9개 페이지**: Home, Login, Register, Settings, Editor(new), Editor(edit), Article, Profile(My), Profile(Favorited). 03 §2 사용자 여정 참조.
- **인증 상태 의존 UI**: 헤더·Feed 탭·Favorite/Follow 버튼·Editor/Settings 접근은 모두 인증 상태로 분기.
- **에러 표시 표준**:
  - 폼 422: 폼 상단에 `<ul>` 리스트 (각 필드별 첫 메시지)
  - API 실패(5xx/네트워크): 페이지 내 inline 경고 + 재시도 버튼
  - 404: 전용 "Not Found" 카드 + 홈 링크
- **스타일**: Tailwind 3+. 캐노니컬 Bootstrap 4 CSS는 차용하지 않고 ADR-0038 디자인 토큰(Color·Typography·Spacing·Component primitives 4종)으로 재구현 — 시각 동등성은 비목표, 사양 준수가 우선 (01 §5, 02 §2.2).
- **반응형**: 데스크탑 우선. 모바일은 1열 + 카드 풀폭. 캐노니컬 Bootstrap breakpoint(sm/md/lg/xl)와 Tailwind 기본을 매핑.

## 6. 의존성 / 외부 시스템

### 6.1 본 프로젝트 내부
- 백엔드: Spring Boot 3.4, Java 21, Gradle 8, PostgreSQL 16, Flyway, jjwt, commonmark-java, jsoup
- 프론트엔드: React 19, Vite 5, TailwindCSS 3+, react-router-dom v6, react-hook-form + zod, ky/fetch wrapper, react-markdown + rehype-sanitize
- 데브옵스: docker-compose (dev DB + BE + FE 3 컨테이너)

### 6.2 외부 (참조만, 통합 안 함)
- **RealWorld 캐노니컬 OpenAPI**: `github.com/gothinkster/realworld/blob/main/specs/api/openapi.yml` — 본 repo `specs/api/openapi.yml`에 fork 복사 (사양 잠금)
- **RealWorld Bruno/Postman 슈트**: 동일 repo `specs/api/bruno/` — 본 repo에 fork (CI에서 실행)
- **RealWorld Playwright E2E**: 동일 repo `specs/e2e/` — fork 또는 submodule (OQ-06, 12 Test Design에서 결정)

### 6.3 비의존
- 결제, 이메일, OAuth IdP, 이미지 호스팅, 검색 엔진, 알림 푸시 — 모두 비범위 (01 §5)

## 7. Open Questions

- **OQ-P-01**: F-05 인기 태그 사이드바의 상위 N — 캐노니컬 미명시. 본 구현 상위 20개(사용 빈도 DESC) 채택 → 06 Architecture에서 인덱스 결정.
- **OQ-P-02**: F-04 글 삭제 시 confirmation UX — 다이얼로그(JS confirm)로 충분한지, 전용 모달이 필요한지 — 10 Screen Design에서 결정.
- **OQ-P-03**: F-09 401 자동 처리 시 비보호 라우트에서는 강제 이동 없이 inline 안내만 보일지? — 본 구현은 후자 채택(`/`, `/article/...` 등 비보호 라우트에선 토큰만 정리, 페이지 이탈 없음).
- **OQ-P-04**: F-06 마크다운 렌더 위치 — 서버 SSR vs 클라이언트 렌더. 본 구현은 클라이언트 렌더 + sanitize 라이브러리(`rehype-sanitize`) 채택 → SEO 우선순위 낮음, 07 HLD에서 확정.
