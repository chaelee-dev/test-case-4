---
doc_type: srs
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: B
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — SRS

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — R-F 27건 + R-N 8건. 캐노니컬 OpenAPI 2.0.0 1대1 매핑 |

## 1. 범위 / 가정

**범위**:
- 19개 백엔드 엔드포인트(캐노니컬 OpenAPI 2.0.0)
- 9개 프론트엔드 페이지(Home/Login/Register/Settings/Editor/Editor:slug/Article/Profile/Profile:favorites)
- JWT 기반 stateless 인증(localStorage)
- PostgreSQL 16 + Flyway 마이그레이션
- 3 profile(dev/stg/prod) 부팅 (ADR-0037 v1.1)

**가정**:
- Spring Boot 3.4 + Java 21 (BE), React 19 + Vite + Tailwind (FE) — 02 Feasibility §6 결정
- 단일 인스턴스 (멀티 노드·로드밸런서 없음)
- 데이터 마이그레이션 source 없음 (그린필드)
- 영어 1언어
- 이미지는 URL 문자열만 (업로드 없음)

**비범위**: 01 §5 참조.

## 2. 기능 요구사항

### R-F-01: 회원가입 (POST /users)

- **우선순위**: P0
- **트레이스**: UC-02
- **Acceptance**:
  - Given 유효한 username/email/password를 입력했을 때, When `POST /users`를 호출하면, Then 201 + `{user: {email, token, username, bio:null, image:null}}` 응답이 반환되고 DB에 사용자가 1건 생성된다.
- **테스트 시나리오**:
  - Happy path (정상): 유효 입력 → 201 + token 반환 + BCrypt 해시 저장
  - Failure path (실패): 동일 username 존재 → 422 + `{errors:{username:["has already been taken"]}}`; password < 8자 → 422 + 필드 에러; 형식 위반 email → 422
- **테스트 결정**: 단위: ✅ (validator + BCrypt 해시), 통합: ✅ (DB + JWT 발급), E2E: ✅ (FE 회원가입 폼)

### R-F-02: 로그인 (POST /users/login)

- **우선순위**: P0
- **트레이스**: UC-03
- **Acceptance**:
  - Given DB에 일치하는 사용자가 있을 때, When email/password로 `POST /users/login` 호출하면, Then 200 + `{user: {..., token}}` 응답한다.
- **테스트 시나리오**:
  - Happy: 일치 자격 → 200 + 새 JWT
  - Failure (실패): 잘못된 password → 401 + `{errors:{"email or password":["is invalid"]}}`; 비등록 email → 401 (정보 누출 방지로 동일 메시지); 누락 → 422
- **테스트 결정**: 단위: ✅ (PasswordEncoder 매치), 통합: ✅, E2E: ✅

### R-F-03: 현재 사용자 조회·수정 (GET/PUT /user)

- **우선순위**: P0
- **트레이스**: UC-11
- **Acceptance**:
  - Given 유효 JWT, When `GET /user` 호출하면, Then 200 + 현재 사용자 정보 반환.
  - Given 유효 JWT + 부분 필드(email/password/username/bio/image 중 1개 이상), When `PUT /user` 호출하면, Then 200 + 갱신된 사용자 + 새 JWT.
- **테스트 시나리오**:
  - Happy (성공): 토큰 OK → 200, 부분 갱신 OK
  - Failure (에러): 토큰 부재/만료/위변조 → 401; email 중복 → 422; 모든 필드 누락 PUT → 422
- **테스트 결정**: 단위: ✅, 통합: ✅ (DB atomic update), E2E: ✅ (Settings 페이지)

### R-F-04: 프로필 조회 (GET /profiles/:username)

- **우선순위**: P0
- **트레이스**: UC-05, UC-07
- **Acceptance**:
  - Given 존재하는 username, When `GET /profiles/:username` 호출하면, Then 200 + `{profile: {username, bio, image, following}}`. 토큰 없으면 following=false 고정.
- **테스트 시나리오**:
  - Happy (정상): 존재 사용자 → 200; 비로그인 → following=false
  - Failure (실패): 없는 username → 404 + `{errors:{resource:["not found"]}}`
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-05: 팔로우·언팔로우 (POST/DELETE /profiles/:username/follow)

- **우선순위**: P0
- **트레이스**: UC-07
- **Acceptance**:
  - Given 유효 JWT + 타 사용자, When `POST /profiles/:username/follow`, Then 200 + profile(following=true). 동일 사용자가 이미 팔로잉 중이어도 idempotent(200).
  - Given 팔로잉 중, When `DELETE …/follow`, Then 200 + profile(following=false). 안 팔로잉 상태에서 DELETE도 idempotent.
- **테스트 시나리오**:
  - Happy (성공): 팔로우/언팔로우 → 토글, follower count 증감
  - Failure (에러): 자기 자신 팔로우 → 422; 비로그인 → 401; 없는 사용자 → 404
- **테스트 결정**: 단위: ✅ (DomainService), 통합: ✅ (follow 테이블 unique 제약), E2E: ✅

### R-F-06: 글로벌 글 목록 + 필터·페이지네이션 (GET /articles)

- **우선순위**: P0
- **트레이스**: UC-01, UC-10
- **Acceptance**:
  - Given DB에 글 N건, When `GET /articles?limit=20&offset=0`, Then 200 + `{articles:[...20건 또는 N건], articlesCount: N}`. createdAt DESC 정렬.
  - Given `?tag=foo` / `?author=bob` / `?favorited=alice` 각각, When 호출하면, Then 해당 조건 매칭 글만 반환.
- **테스트 시나리오**:
  - Happy (정상): 정렬·페이지네이션·필터 각각 동작
  - Failure (에러): limit > 100 → 422 or 100으로 clamp; offset 음수 → 422; 없는 tag → 빈 배열 + count 0 (404 아님)
- **테스트 결정**: 단위: ✅ (Specification/Criteria query), 통합: ✅ (DB + index 활용), E2E: ✅ (Home Global Feed)

### R-F-07: Your Feed (GET /articles/feed)

- **우선순위**: P0
- **트레이스**: UC-12
- **Acceptance**:
  - Given 유효 JWT + 사용자 X가 팔로잉 중인 작성자 집합 F, When `GET /articles/feed?limit&offset`, Then 200 + F가 쓴 글만 createdAt DESC로 반환.
- **테스트 시나리오**:
  - Happy (성공): 팔로잉 작성자 글만 노출 + 페이지네이션
  - Failure (실패): 비로그인 → 401; 팔로잉 0명 → 200 + 빈 배열 + count 0
- **테스트 결정**: 단위: ✅, 통합: ✅ (JOIN follow + article), E2E: ✅

### R-F-08: 단일 글 조회 (GET /articles/:slug)

- **우선순위**: P0
- **트레이스**: UC-05
- **Acceptance**:
  - Given 존재하는 slug, When `GET /articles/:slug`, Then 200 + article. JWT 있으면 favorited·author.following이 사용자 기준 boolean. 없으면 둘 다 false.
- **테스트 시나리오**:
  - Happy (정상): 존재 → 200; 비로그인 → favorited/following=false
  - Failure (실패): 없는 slug → 404
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-09: 글 작성 (POST /articles)

- **우선순위**: P0
- **트레이스**: UC-04
- **Acceptance**:
  - Given 유효 JWT + title/description/body + tagList(optional), When `POST /articles`, Then 201 + article(slug 자동 생성, author=현재 사용자). 새 태그는 tag 테이블에 upsert.
- **테스트 시나리오**:
  - Happy (성공): 정상 입력 → 201, body는 raw markdown으로 저장(렌더는 클라이언트/응답 시 sanitize 결과는 R-F-18에서)
  - Failure (에러): title/description/body 누락 → 422; 비로그인 → 401
- **테스트 결정**: 단위: ✅ (validator + slug gen), 통합: ✅ (article + tag upsert), E2E: ✅ (Editor 페이지)

### R-F-10: 글 수정 (PUT /articles/:slug)

- **우선순위**: P0
- **트레이스**: UC-09
- **Acceptance**:
  - Given 유효 JWT + 본인 글 + 부분 필드, When `PUT /articles/:slug`, Then 200 + 갱신된 article. title 변경 시 slug 재생성.
- **테스트 시나리오**:
  - Happy (정상): 본인 글 title 변경 → 200 + new slug
  - Failure (에러): 타인 글 → 403; 비로그인 → 401; 없는 slug → 404; 모든 필드 누락 → 422
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-11: 글 삭제 (DELETE /articles/:slug)

- **우선순위**: P0
- **트레이스**: UC-09
- **Acceptance**:
  - Given 유효 JWT + 본인 글, When `DELETE /articles/:slug`, Then 204/200 + DB에서 article·comments·favorites cascade 제거.
- **테스트 시나리오**:
  - Happy (성공): 본인 글 → 200/204; 연관 댓글·좋아요 cascade
  - Failure (실패): 타인 글 → 403; 비로그인 → 401; 없는 slug → 404
- **테스트 결정**: 단위: ✅, 통합: ✅ (cascade 검증), E2E: ✅

### R-F-12: 좋아요·좋아요취소 (POST/DELETE /articles/:slug/favorite)

- **우선순위**: P0
- **트레이스**: UC-06
- **Acceptance**:
  - Given 유효 JWT, When `POST /articles/:slug/favorite`, Then 200 + article(favorited=true, favoritesCount+1). 이미 좋아요 상태면 idempotent.
  - Given 좋아요 상태, When `DELETE …/favorite`, Then 200 + article(favorited=false, favoritesCount-1). 비좋아요에서 DELETE도 idempotent.
- **테스트 시나리오**:
  - Happy (성공): 토글 + count 정확성
  - Failure (에러): 비로그인 → 401; 없는 slug → 404
- **테스트 결정**: 단위: ✅, 통합: ✅ (favorites unique 제약), E2E: ✅

### R-F-13: 댓글 목록 (GET /articles/:slug/comments)

- **우선순위**: P0
- **트레이스**: UC-08
- **Acceptance**:
  - Given 존재하는 slug, When `GET /articles/:slug/comments`, Then 200 + `{comments:[...]}` createdAt ASC.
- **테스트 시나리오**:
  - Happy (정상): 댓글 0건 → 빈 배열 + 200; N건 → N건 반환
  - Failure (실패): 없는 slug → 404
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-14: 댓글 작성 (POST /articles/:slug/comments)

- **우선순위**: P0
- **트레이스**: UC-08
- **Acceptance**:
  - Given 유효 JWT + body, When `POST /articles/:slug/comments`, Then 200 + `{comment: {id, body, author, createdAt, updatedAt}}`.
- **테스트 시나리오**:
  - Happy (성공): 정상 → 200
  - Failure (에러): 빈 body → 422; 비로그인 → 401; 없는 slug → 404
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-15: 댓글 삭제 (DELETE /articles/:slug/comments/:id)

- **우선순위**: P0
- **트레이스**: UC-08
- **Acceptance**:
  - Given 유효 JWT + 본인 댓글, When `DELETE …/comments/:id`, Then 200/204 + DB에서 제거.
- **테스트 시나리오**:
  - Happy (성공): 본인 댓글 → 200
  - Failure (실패): 타인 댓글 → 403; 비로그인 → 401; 없는 id → 404
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-16: 인기 태그 (GET /tags)

- **우선순위**: P1
- **트레이스**: UC-01 (사이드바)
- **Acceptance**:
  - Given DB에 태그 N개, When `GET /tags`, Then 200 + `{tags:[...N개 또는 상위 20개, 사용 빈도 DESC]}`.
- **테스트 시나리오**:
  - Happy (정상): 정렬·상한 정확
  - Failure (에러): 태그 0건 → 빈 배열 + 200
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅ (Home 사이드바)

### R-F-17: 슬러그 자동 생성 정책

- **우선순위**: P0
- **트레이스**: RB-04, UC-04, UC-09
- **Acceptance**:
  - Given title, When 새 글 생성 또는 title 변경, Then slug = kebab-case(title) + (충돌 시) "-" + nanoid(6).
- **테스트 시나리오**:
  - Happy (정상): "Hello World" → "hello-world"; 동일 title 2건 → "hello-world", "hello-world-a1b2c3"
  - Failure (에러): 특수문자 only title (예: "!!!") → fallback "untitled-" + nanoid(6)
- **테스트 결정**: 단위: ✅ (순수 함수), 통합: ✅ (DB unique 제약), E2E: N/A (백엔드 내부 정책)

### R-F-18: 마크다운 안전 렌더링

- **우선순위**: P0
- **트레이스**: UC-05, RB-03, NF-S-03
- **Acceptance**:
  - Given 마크다운 body 입력, When 글이 렌더될 때, Then `<script>`·`<iframe>`·`on*` 이벤트 핸들러·`javascript:` URL이 모두 제거된 안전 HTML이 출력된다.
- **테스트 시나리오**:
  - Happy (성공): "**bold**" → `<strong>bold</strong>`; 표준 마크다운 모두 정상 렌더
  - Failure (실패→방어): `<script>alert(1)</script>` 입력 → 출력에서 제거, alert 미발생; `[x](javascript:alert(1))` → href 제거 또는 무효화
- **테스트 결정**: 단위: ✅ (sanitize 함수), 통합: ✅ (글 조회 응답), E2E: ✅ (브라우저에서 alert 미발생 확인)

### R-F-19: Home 페이지 (FE)

- **우선순위**: P0
- **트레이스**: UC-01, UC-10, UC-12
- **Acceptance**:
  - Given `/` 진입, When 페이지 로드되면, Then Banner + Feed 탭(Your Feed [로그인 시만] / Global Feed / # tagname [태그 클릭 시 동적 추가]) + 글 카드 리스트(20건) + 페이지네이션 + 인기 태그 사이드바가 표시된다.
- **테스트 시나리오**:
  - Happy (정상): 로그인 → Your Feed 기본 활성; 비로그인 → Global Feed; 태그 클릭 → Tag Feed 추가 + 활성
  - Failure (에러): API 실패 → "글을 불러올 수 없습니다" + 재시도 버튼
- **테스트 결정**: 단위: ✅ (탭 컴포넌트 state), 통합: ✅ (API mock + 렌더), E2E: ✅ (브라우저 골든패스)

### R-F-20: 인증 페이지 (FE — /login, /register)

- **우선순위**: P0
- **트레이스**: UC-02, UC-03
- **Acceptance**:
  - Given `/login` 또는 `/register`, When 폼 제출하면, Then API 호출 + 성공 시 토큰 저장 + `/`로 이동 + 헤더 갱신. 실패 시 폼 상단에 에러 리스트 출력.
- **테스트 시나리오**:
  - Happy (성공): 정상 입력 → 토큰 저장 + 헤더 변경
  - Failure (실패): 422 에러 응답 → `errors` 객체를 폼 상단에 리스트로 표시 (각 필드별 첫 메시지 표기)
- **테스트 결정**: 단위: ✅ (zod 스키마 + 에러 매핑), 통합: ✅ (API mock), E2E: ✅

### R-F-21: Settings 페이지 (FE — /settings)

- **우선순위**: P0
- **트레이스**: UC-11
- **Acceptance**:
  - Given 로그인 + `/settings`, When 필드 변경 후 "Update Settings", Then `PUT /user` 호출 + 새 토큰 저장 + 헤더 username·avatar 갱신.
  - Given 같은 페이지, When "Logout" 클릭, Then localStorage 토큰 제거 + `/`로 이동 + 익명 헤더.
- **테스트 시나리오**:
  - Happy (정상): 부분 갱신 + Logout 동작
  - Failure (에러): email 중복 → 폼 상단 에러; 비로그인 진입 → `/login`으로 리다이렉트
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-22: Editor 페이지 (FE — /editor, /editor/:slug)

- **우선순위**: P0
- **트레이스**: UC-04, UC-09
- **Acceptance**:
  - Given 로그인 + `/editor` (new), When 폼 입력 후 "Publish Article", Then `POST /articles` → 성공 시 `/article/:slug`로 이동.
  - Given 로그인 + `/editor/:slug` (edit) + 본인 글, When 폼 prefill 후 "Update", Then `PUT /articles/:slug` → 이동.
- **테스트 시나리오**:
  - Happy (성공): new + edit 모두 성공
  - Failure (실패): 비로그인 → `/login`; 타인 글 edit 직접 진입 → "Forbidden" 또는 홈으로
- **테스트 결정**: 단위: ✅ (tag 입력 키보드 핸들러), 통합: ✅, E2E: ✅

### R-F-23: Article 상세 페이지 (FE — /article/:slug)

- **우선순위**: P0
- **트레이스**: UC-05, UC-06, UC-07, UC-08
- **Acceptance**:
  - Given `/article/:slug`, When 페이지 로드, Then 글 메타(저자·날짜) + Follow 버튼 + Favorite 버튼 + 마크다운 본문(sanitized) + Edit/Delete(저자만) + 댓글 폼(로그인 시) + 댓글 리스트가 표시.
- **테스트 시나리오**:
  - Happy (정상): 비로그인 → Follow/Favorite/댓글폼 비활성/숨김; 로그인 → 활성; 저자 → Edit/Delete 보임
  - Failure (에러): 404 글 → "Article not found" + 홈 링크
- **테스트 결정**: 단위: ✅ (인증 상태별 분기), 통합: ✅, E2E: ✅

### R-F-24: Profile 페이지 (FE — /profile/:username, /profile/:username/favorites)

- **우선순위**: P0
- **트레이스**: UC-07, UC-10
- **Acceptance**:
  - Given `/profile/:username`, When 로드, Then 사용자 헤더(image·username·bio) + Follow 버튼(타인 한정) / Edit Settings 버튼(본인 한정) + 탭 "My Articles" / "Favorited Articles" + 글 카드 + 페이지네이션.
- **테스트 시나리오**:
  - Happy (성공): 본인/타인 분기 정확; 탭 전환 → URL 변경 + 글 목록 갱신
  - Failure (실패): 없는 username → "Profile not found"
- **테스트 결정**: 단위: ✅, 통합: ✅, E2E: ✅

### R-F-25: 헤더 네비게이션 (FE)

- **우선순위**: P0
- **트레이스**: UC-02, UC-03, UC-11, 모든 페이지
- **Acceptance**:
  - Given 인증 상태가 로그인/비로그인 두 가지 중 하나일 때, When 헤더가 렌더링되면, Then 비로그인은 [Home, Sign in, Sign up], 로그인은 [Home, New Article, Settings, @username]을 보이며 현재 라우트 메뉴에 `active` 클래스가 적용된다.
- **테스트 시나리오**:
  - Happy (정상): 로그인 토글 시 헤더 즉시 변경
  - Failure (에러): 토큰 만료 후 보호 메뉴 클릭 → `/login`으로 + 헤더가 비로그인 상태로 정정
- **테스트 결정**: 단위: ✅ (auth context), 통합: ✅, E2E: ✅

### R-F-26: 보호 라우트 (FE)

- **우선순위**: P0
- **트레이스**: UC-11, UC-04, UC-09
- **Acceptance**:
  - Given 비로그인 상태, When `/settings`, `/editor`, `/editor/:slug` 중 하나에 진입하면, Then `/login`으로 리다이렉트하고 원래 경로를 `?redirect=` 쿼리로 보존한다.
- **테스트 시나리오**:
  - Happy (성공): 로그인 후 `?redirect`를 따라 원경로 복귀
  - Failure (실패): 토큰 만료 상태 진입 → 401 응답 후 자동 로그아웃 + 로그인 페이지로
- **테스트 결정**: 단위: ✅ (라우트 가드), 통합: ✅, E2E: ✅

### R-F-27: JWT 저장 & API 클라이언트 (FE)

- **우선순위**: P0
- **트레이스**: 모든 보호 API
- **Acceptance**:
  - Given 로그인 성공 응답, When 토큰 저장 단계 진입, Then localStorage key `conduit.jwt`에 저장한다.
  - Given 모든 API 요청, When 호출 직전, Then 토큰이 있으면 `Authorization: Token <jwt>` 헤더 자동 부착.
- **테스트 시나리오**:
  - Happy (정상): 토큰 저장·삭제 후 헤더 부착 여부 정확
  - Failure (에러): 응답 401 수신 시 토큰 자동 제거 + auth context 비로그인으로 전환 + 보호 라우트 강제 이탈
- **테스트 결정**: 단위: ✅ (HTTP wrapper), 통합: ✅ (msw mock), E2E: ✅

## 3. 비기능 요구사항

### R-N-01: 응답 성능

- **우선순위**: P1
- **트레이스**: NF-S-01, NF-S-02
- **Acceptance**:
  - Given 단일 사용자 + 로컬 dev, When 모든 API를 호출하면, Then 95p < 300ms.
  - Given 글 1만 건 + 동시 50 사용자, When 글 목록 1페이지 요청, Then < 500ms.
- **테스트 시나리오**:
  - Happy (성공): 부하 도구(k6 or Gatling)로 통과
  - Failure (실패): 인덱스 누락 → 1초 이상 → BLOCK
- **테스트 결정**: 단위: N/A, 통합: ✅ (k6 부하), E2E: N/A

### R-N-02: 인증 보안 (JWT + 패스워드)

- **우선순위**: P0
- **트레이스**: NF-S-04, RB-02
- **Acceptance**:
  - Given 보호 엔드포인트, When JWT 없음/만료/위변조 토큰으로 호출, Then 401.
  - Given 회원가입, When password 저장, Then BCrypt(cost ≥ 10) 해시로만 저장 (평문 저장 금지).
  - Given JWT 발급, When 비밀키 사용, Then 256bit 이상 + `.env` 외부 주입.
- **테스트 시나리오**:
  - Happy (정상): 정상 토큰 → 200
  - Failure (실패): 토큰 변조·만료·서명 불일치 모두 401, 평문 DB 저장 확인 시 즉시 BLOCK
- **테스트 결정**: 단위: ✅ (JWT verify), 통합: ✅ (security filter), E2E: ✅

### R-N-03: XSS 방어 (마크다운)

- **우선순위**: P0
- **트레이스**: NF-S-03, R-F-18, RB-03
- **Acceptance**:
  - Given 임의 마크다운 입력, When 글 조회/렌더, Then `<script>`/`on*`/`javascript:`이 출력에서 제거된다.
- **테스트 시나리오**:
  - Happy (성공): 일반 마크다운 정상
  - Failure (방어): XSS 페이로드 모두 무력화
- **테스트 결정**: 단위: ✅ (sanitize 함수), 통합: ✅, E2E: ✅ (브라우저 alert 미발생)

### R-N-04: 권한 검사 (Authorization)

- **우선순위**: P0
- **트레이스**: NF-S-05
- **Acceptance**:
  - Given 인증된 사용자, When 자기 소유가 아닌 글 또는 댓글에 대해 PUT/DELETE를 호출하면, Then 403 응답으로 거부한다.
- **테스트 시나리오**:
  - Happy (성공): 본인 자원 → 200
  - Failure (거부): 타인 자원 → 403 + `{errors:{resource:["forbidden"]}}`
- **테스트 결정**: 단위: ✅ (정책 함수), 통합: ✅, E2E: ✅

### R-N-05: 응답 형식 일관성

- **우선순위**: P0
- **트레이스**: 모든 R-F
- **Acceptance**:
  - Given 임의의 API 응답, When 응답이 직렬화되면, Then 단일 리소스는 `{"<resource>": {...}}` 래핑, 다건은 `{"<resources>": [...], "<resources>Count": N}`, 에러는 `{"errors": {"<field>": ["msg"]}}` 형식을 따른다.
- **테스트 시나리오**:
  - Happy (정상): RealWorld Bruno 슈트 통과
  - Failure (실패): 한 엔드포인트라도 wrap 안 함 → BLOCK
- **테스트 결정**: 단위: N/A, 통합: ✅ (응답 스키마 contract test), E2E: N/A

### R-N-06: 3 profile 부팅 (ADR-0037 v1.1)

- **우선순위**: P0
- **트레이스**: NF-S-08, ADR-0037
- **Acceptance**:
  - Given fresh checkout + `.env.{dev,stg,prod}.example`, When 12-scaffolding §5 부팅 명령을 profile별로 실행, Then 각각 ready 신호 + 에러 0건. LOCAL.md 절차로 누구나 재현 가능 (ADR-0040).
- **테스트 시나리오**:
  - Happy (성공): 3/3 profile ready
  - Failure (에러): 한 profile만 부팅 실패 → AI 게이트 6번째 축 미충족 → PR BLOCK
- **테스트 결정**: 단위: N/A, 통합: ✅ (CI matrix), E2E: N/A

### R-N-07: 페이지네이션 경계

- **우선순위**: P1
- **트레이스**: NF-S-07
- **Acceptance**:
  - Given offset/limit 쿼리, When offset < 0 또는 limit < 1 또는 limit > 100, Then 422 또는 안전한 default로 clamp.
  - Given offset = 1,000,000 (대량), When 호출, Then 결과는 빈 배열이지만 서버 OOM·5초 이상 응답 금지.
- **테스트 시나리오**:
  - Happy (정상): 정상 범위 → 200
  - Failure (실패): 음수·과대 limit → 422; 과대 offset → 빈 결과 < 500ms
- **테스트 결정**: 단위: ✅ (validator), 통합: ✅, E2E: N/A

### R-N-08: 감사 로깅 + 상관 ID

- **우선순위**: P2
- **트레이스**: (운영 가시성)
- **Acceptance**:
  - Given 모든 요청, When 처리 완료 시, Then `[traceId] METHOD path status duration_ms userId?` 형식의 로그 1줄이 stdout으로 출력된다.
- **테스트 시나리오**:
  - Happy (정상): 로그 한 줄이 정해진 키 6개 포함
  - Failure (에러): traceId 누락 → BLOCK (관측성 위반)
- **테스트 결정**: 단위: N/A, 통합: ✅ (logback config + test 로그 캡처), E2E: N/A

## 4. 인터페이스 요구사항

### 4.1 외부 API (BE)

- 베이스 URL: `<host>/api`
- 인증 헤더: `Authorization: Token <jwt>` (Bearer 아님 — 캐노니컬 사양)
- 모든 요청/응답: `application/json; charset=utf-8`
- 페이지네이션: `limit` (default 20, max 100), `offset` (default 0, ≥ 0)
- 에러: `{ "errors": { "<field|resource>": ["msg", ...] } }`, status 401/403/404/409/422

### 4.2 FE ↔ BE 통신

- CORS: dev `*`; stg/prod allowed origins 화이트리스트 (Spring Security)
- JWT 저장: localStorage key `conduit.jwt`
- 401 자동 처리: 응답 수신 시 토큰 제거 + auth context 초기화 + 보호 라우트 이탈

### 4.3 OS·런타임

- BE: Java 21, Spring Boot 3.4, Gradle 8, PostgreSQL 16
- FE: Node 20+, Vite 5, React 19, TailwindCSS 3+
- 컨테이너: docker-compose (dev), Dockerfile per service (stg/prod)

### 4.4 외부 의존

- 없음 (이미지·이메일·OAuth 모두 비범위)

## 5. 도메인 모델

```
User (id PK, username UNIQUE, email UNIQUE, password_hash, bio, image, created_at, updated_at)
  │
  ├──< Follow (follower_id FK, followee_id FK, created_at) — UNIQUE(follower_id, followee_id), 자기 자신 금지
  │
  └──< Article (id PK, slug UNIQUE, title, description, body, author_id FK, created_at, updated_at)
         │
         ├──< Comment (id PK, article_id FK, author_id FK, body, created_at, updated_at)
         │
         ├──< Favorite (user_id FK, article_id FK, created_at) — UNIQUE(user_id, article_id)
         │
         └──< ArticleTag (article_id FK, tag_id FK) — UNIQUE pair

Tag (id PK, name UNIQUE)
```

- 모든 FK는 cascade DELETE on parent (Article 삭제 → Comment/Favorite/ArticleTag cascade) — R-F-11 보장
- created_at/updated_at은 DB 기본값 + `@PrePersist`/`@PreUpdate` (JPA)
- slug는 unique 인덱스 + R-F-17 정책으로 충돌 시 nanoid suffix

## 6. Open Questions

- **OQ-SR-01**: limit clamp(>100)을 422로 거부할지 silent clamp할지? — 캐노니컬 사양 미명시. 본 구현은 silent clamp(100) + 응답 헤더에 실제 적용된 limit 노출 검토 (07 HLD에서 결정)
- **OQ-SR-02**: 글 수정 시 slug 재생성을 *항상* 할지, *title 변경 시에만* 할지? — 외부 링크 보존을 위해 *title 변경 시에만* (R-F-10) 채택. 12 Test Design에서 케이스 명시
- **OQ-SR-03**: 댓글에도 마크다운 렌더 적용할지? — 캐노니컬은 plain text. 본 구현 plain text 채택 → R-F-18은 article body에만 적용
- **OQ-SR-04**: 만료된 JWT의 만료 시간 — 캐노니컬 미명시. 본 구현 7일 default + refresh 없음 (만료 시 재로그인)
