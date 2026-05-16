# RFP — RealWorld / Conduit 클론

> 출처: https://realworld-docs.netlify.app/introduction/
> 캐노니컬 OpenAPI: https://github.com/gothinkster/realworld/blob/main/specs/api/openapi.yml
> 입수일: 2026-05-16 KST

## 1. 개요

RealWorld는 "todo 데모를 넘어, 진짜 앱을 어떻게 만드는지" 보여주기 위해 만들어진 오픈 스펙 프로젝트다. 동일한 사양(Conduit — Medium.com 스타일 블로그 플랫폼)을 **임의의 프론트엔드 × 임의의 백엔드 조합**으로 구현할 수 있도록 API·UI·라우팅이 표준화되어 있다. 150여 개 구현이 동일한 API 스펙을 따른다.

본 프로젝트의 목표: agent-toolkit으로 위 RealWorld 스펙을 충족하는 한 벌의 풀스택 구현체(FE + BE)를 처음부터 끝까지 만들어내는 것.

## 2. 핵심 도메인 (Conduit)

- **User**: email·username·password·bio·image·token(JWT)
- **Profile**: 다른 사용자에서 본 형태 — username·bio·image·following(bool)
- **Article**: slug·title·description·body(markdown)·tagList·createdAt·updatedAt·favorited(bool)·favoritesCount·author(Profile)
- **Comment**: id·body·createdAt·updatedAt·author(Profile)
- **Tag**: 단순 문자열 리스트

## 3. 필수 API 엔드포인트 (캐노니컬 OpenAPI 2.0.0)

서버: `<host>/api`. 인증: `Authorization: Token <JWT>`.

| Method | Path | Auth | 설명 |
|---|---|---|---|
| POST | /users/login | none | 로그인 → User+token 반환 |
| POST | /users | none | 회원가입 → User+token 반환 |
| GET | /user | required | 현재 사용자 |
| PUT | /user | required | 현재 사용자 정보 수정 |
| GET | /profiles/{username} | optional | 프로필 조회 |
| POST | /profiles/{username}/follow | required | 팔로우 |
| DELETE | /profiles/{username}/follow | required | 언팔로우 |
| GET | /articles | optional | 글로벌 피드 (tag·author·favorited 필터, offset·limit 페이지네이션) |
| GET | /articles/feed | required | 내 피드 (팔로잉 작성자만) |
| POST | /articles | required | 글 작성 |
| GET | /articles/{slug} | optional | 단일 글 조회 |
| PUT | /articles/{slug} | required | 글 수정 (저자만) |
| DELETE | /articles/{slug} | required | 글 삭제 (저자만) |
| POST | /articles/{slug}/favorite | required | 좋아요 |
| DELETE | /articles/{slug}/favorite | required | 좋아요 취소 |
| GET | /articles/{slug}/comments | optional | 댓글 목록 |
| POST | /articles/{slug}/comments | required | 댓글 작성 |
| DELETE | /articles/{slug}/comments/{id} | required | 댓글 삭제 (작성자만) |
| GET | /tags | none | 인기 태그 목록 |

### 응답 표준 형식

- 모든 단일 리소스는 `{ "<resource>": {...} }` 래핑 (예: `{ "user": {...} }`, `{ "article": {...} }`)
- 다건 articles는 `{ "articles": [...], "articlesCount": N }`
- 에러는 `{ "errors": { "<field>": ["msg1", "msg2"] } }` 422 위주, 401/403/404/409도 동일 형식

### 페이지네이션
- `offset` (≥ 0), `limit` (≥ 1, 기본 20)

## 4. 필수 프론트엔드 페이지 (Conduit 사양)

| 경로 | 화면 | 인증 |
|---|---|---|
| `/` | Home — Banner + (Your Feed | Global Feed | Tag Feed 탭) + 글 목록 + 페이지네이션 + 인기 태그 사이드바 | optional |
| `/login` | 로그인 | none |
| `/register` | 회원가입 | none |
| `/settings` | 내 정보 수정 + 로그아웃 | required |
| `/editor` | 새 글 작성 | required |
| `/editor/:slug` | 글 수정 | required (저자만) |
| `/article/:slug` | 글 상세 + 좋아요 + 팔로우 + 마크다운 렌더 + 댓글 | optional |
| `/profile/:username` | 저자의 글 목록 + 팔로우 | optional |
| `/profile/:username/favorites` | 저자가 좋아요한 글 | optional |

헤더는 인증 상태에 따라 다른 메뉴를 보여준다. JWT는 localStorage 보관.

## 5. UI 일관성 요구
- 모든 RealWorld 구현은 동일한 **Bootstrap 4 기반 Conduit 테마**를 사용 (시각적 동등성)
- 본 프로젝트는 시각 동등성보다는 *사양 준수*가 우선 — 토킷이 정해주는 스타일링 스택(12-scaffolding §8)으로 자유롭게 구현

## 6. 비기능 요구 (제안)
- JWT 기반 stateless 인증, localStorage 저장
- 평균 응답 < 300ms (단일 사용자, 로컬 dev)
- 페이지네이션은 글 목록 모두 적용
- 마크다운 렌더링 (XSS 방어)
- 슬러그는 title 기반 자동 생성 (kebab-case + uniqueness)

## 7. 인수 기준 (개략)
- 위 19개 엔드포인트 모두 OpenAPI 2.0.0 스펙대로 동작
- 9개 페이지 모두 사용자 시나리오(로그인 → 글 작성 → 좋아요 → 팔로우 → 피드)가 골든패스로 동작
- 별도 RealWorld Postman/Bruno 테스트 슈트가 통과 (참고: gothinkster/realworld `specs/api/`)
- 3 profile(dev/stg/prod) 부팅 가능 (ADR-0037 v1.1)

## 8. 비범위 (Out of Scope, 초기 가정 — 02 Feasibility에서 재검토)
- 비밀번호 리셋·이메일 인증 플로우 (캐노니컬 스펙에 없음)
- 어드민/모더레이션 콘솔
- 알림(웹·이메일)
- 검색(전문 검색)
- 이미지 업로드 (Conduit는 URL만 받음)
- 다국어
- 결제

## 9. 참고
- 데모: https://demo.realworld.build/ (frontend × backend 페어로 동작)
- 캐노니컬 OpenAPI: github.com/gothinkster/realworld/blob/main/specs/api/openapi.yml
- 캐노니컬 E2E: github.com/gothinkster/realworld/tree/main/specs/e2e
