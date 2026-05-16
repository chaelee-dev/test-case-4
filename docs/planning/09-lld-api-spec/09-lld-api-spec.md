---
doc_type: api-spec
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-F-01, R-F-02, R-F-03, R-F-04, R-F-05, R-F-06, R-F-07, R-F-08, R-F-09, R-F-10, R-F-11, R-F-12, R-F-13, R-F-14, R-F-15, R-F-16, R-N-05, R-N-07]
  F-ID: [F-01, F-02, F-03, F-04, F-05, F-06, F-07, F-08]
  supersedes: null
---

# Conduit (RealWorld 클론) — API Spec (LLD — 외부 인터페이스)

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 19 엔드포인트 캐노니컬 OpenAPI 2.0.0 1대1 매핑 |

## 1. 개요

- 베이스: `<host>/api`
- 인증: `Authorization: Token <jwt>` (Bearer 아님). JWT는 `M-BE-AUTH.JwtService`가 발급 (HS256, exp=now+7d).
- Content-Type: 요청/응답 모두 `application/json; charset=utf-8`
- 캐노니컬 OpenAPI: `gothinkster/realworld:specs/api/openapi.yml` v2.0.0를 fork → `specs/api/openapi.yml` 로 잠금.
- 응답 형식 (R-N-05):
  - 단일: `{ "<resource>": {...} }`
  - 다건: `{ "<resources>": [...], "<resources>Count": N }`
  - 에러: `{ "errors": { "<field|resource>": ["msg", ...] } }`

## 2. 엔드포인트 목록

| 메서드 | 경로 | 목적 | F-ID | R-ID |
|---|---|---|---|---|
| POST | /users/login | 로그인 | F-01 | R-F-02 |
| POST | /users | 회원가입 | F-01 | R-F-01 |
| GET | /user | 현재 사용자 | F-02 | R-F-03 |
| PUT | /user | 사용자 수정 | F-02 | R-F-03 |
| GET | /profiles/{username} | 프로필 조회 | F-03 | R-F-04 |
| POST | /profiles/{username}/follow | 팔로우 | F-03 | R-F-05 |
| DELETE | /profiles/{username}/follow | 언팔로우 | F-03 | R-F-05 |
| GET | /articles | 글로벌 글 목록 | F-05 | R-F-06 |
| GET | /articles/feed | Your Feed | F-05 | R-F-07 |
| POST | /articles | 글 작성 | F-04 | R-F-09 |
| GET | /articles/{slug} | 글 상세 | F-06 | R-F-08 |
| PUT | /articles/{slug} | 글 수정 | F-04 | R-F-10 |
| DELETE | /articles/{slug} | 글 삭제 | F-04 | R-F-11 |
| POST | /articles/{slug}/favorite | 좋아요 | F-07 | R-F-12 |
| DELETE | /articles/{slug}/favorite | 좋아요 취소 | F-07 | R-F-12 |
| GET | /articles/{slug}/comments | 댓글 목록 | F-08 | R-F-13 |
| POST | /articles/{slug}/comments | 댓글 작성 | F-08 | R-F-14 |
| DELETE | /articles/{slug}/comments/{id} | 댓글 삭제 | F-08 | R-F-15 |
| GET | /tags | 인기 태그 | F-05 | R-F-16 |

## 3. 엔드포인트 상세

### POST /users/login

- 인증: 불필요
- F-ID: F-01 / R-ID: R-F-02

**Request**:
```json
{ "user": { "email": "a@b.com", "password": "secret" } }
```

**Response 200**:
```json
{ "user": { "email": "a@b.com", "token": "eyJ...", "username": "alice", "bio": null, "image": null } }
```

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 401 | `{"errors":{"email or password":["is invalid"]}}` | 자격 불일치, 비등록 email |
| 422 | `{"errors":{"email":["can't be blank"]}}` | 필수 누락, 형식 위반 |

**테스트 시나리오**: 04 SRS R-F-02 Happy + Failure 인용 → 13 Test Design 02-catalog §1 단위 + §2 통합 + §3 E2E

### POST /users

- 인증: 불필요
- F-ID: F-01 / R-ID: R-F-01

**Request**:
```json
{ "user": { "username": "alice", "email": "a@b.com", "password": "secret" } }
```

**Response 201**: `{ "user": { ... } }` (login 동일 형식)

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 409 | `{"errors":{"username":["has already been taken"]}}` | 중복 username/email |
| 422 | `{"errors":{"password":["is too short (minimum is 8 characters)"]}}` | 길이/형식 위반 |

**테스트 시나리오**: 04 R-F-01 Happy + Failure → 단위 + 통합 + E2E

### GET /user

- 인증: 필수
- F-ID: F-02 / R-ID: R-F-03

**Request**: (body 없음, 헤더만)

**Response 200**: `{ "user": { ... } }` (현재 사용자)

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 401 | `{"errors":{"token":["is missing"]}}` | 토큰 부재/만료/위변조 |

**테스트 시나리오**: 04 R-F-03 Happy + Failure → 통합 + E2E (Settings 페이지)

### PUT /user

- 인증: 필수
- F-ID: F-02 / R-ID: R-F-03

**Request** (모든 필드 optional, 최소 1개 필수):
```json
{ "user": { "email": "...", "username": "...", "password": "...", "bio": "...", "image": "..." } }
```

**Response 200**: `{ "user": { ..., "token": "<새 jwt>" } }`

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 401 | `{"errors":{"token":["is invalid"]}}` | 토큰 |
| 422 | `{"errors":{"email":["has already been taken"]}}` | 중복 또는 모든 필드 누락 |

**테스트 시나리오**: 04 R-F-03 Happy + Failure → 통합 + E2E

### GET /profiles/{username}

- 인증: 선택 (없으면 following=false)
- F-ID: F-03 / R-ID: R-F-04

**Request**: path 파라미터 username

**Response 200**:
```json
{ "profile": { "username": "alice", "bio": "...", "image": "...", "following": true } }
```

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 404 | `{"errors":{"resource":["not found"]}}` | 없는 username |

**테스트 시나리오**: 04 R-F-04 → 단위 + 통합 + E2E

### POST /profiles/{username}/follow

- 인증: 필수
- F-ID: F-03 / R-ID: R-F-05

**Request**: body 없음

**Response 200**: `{ "profile": { ..., "following": true } }` (idempotent)

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 401 | `{"errors":{"token":["is invalid"]}}` | 토큰 |
| 404 | `{"errors":{"resource":["not found"]}}` | 없는 username |
| 422 | `{"errors":{"username":["cannot follow self"]}}` | 자기 자신 |

**테스트 시나리오**: 04 R-F-05 → 단위 + 통합 + E2E

### DELETE /profiles/{username}/follow

동일 패턴, 응답 following=false. idempotent.

| 상태 | 본문 |
|---|---|
| 200 | `{"profile":{..., "following":false}}` |
| 401/404 | 동일 |

**테스트 시나리오**: 04 R-F-05 → 단위 + 통합 + E2E

### GET /articles

- 인증: 선택 (없으면 favorited/following 모두 false)
- F-ID: F-05 / R-ID: R-F-06

**Request**: query `tag`, `author`, `favorited`, `limit` (default 20, max 100), `offset` (default 0)

**Response 200**:
```json
{ "articles": [{...}, ...], "articlesCount": 145 }
```

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 422 | `{"errors":{"limit":["must be between 1 and 100"]}}` | offset/limit 경계 위반 |

**테스트 시나리오**: 04 R-F-06 Happy(필터 + 정렬 + 페이지네이션) + Failure(경계) → 단위 + 통합 + E2E

### GET /articles/feed

- 인증: 필수
- F-ID: F-05 / R-ID: R-F-07

**Request**: query `limit`, `offset`

**Response 200**: `{ "articles": [...], "articlesCount": N }`

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 401 | `{"errors":{"token":["is invalid"]}}` | 토큰 |

**테스트 시나리오**: 04 R-F-07 → 통합 + E2E

### POST /articles

- 인증: 필수
- F-ID: F-04 / R-ID: R-F-09

**Request**:
```json
{ "article": { "title": "...", "description": "...", "body": "...", "tagList": ["foo", "bar"] } }
```

**Response 201**: `{ "article": { "slug": "...", ..., "author": { ... } } }`

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 401 | `{"errors":{"token":["is invalid"]}}` | 토큰 |
| 422 | `{"errors":{"title":["can't be blank"]}}` | 필수 누락 |

**테스트 시나리오**: 04 R-F-09 + R-F-17(slug 정책) → 단위 + 통합 + E2E

### GET /articles/{slug}

- 인증: 선택
- F-ID: F-06 / R-ID: R-F-08

**Request**: path slug

**Response 200**: `{ "article": { ... } }`

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 404 | `{"errors":{"resource":["not found"]}}` | 없는 slug |

**테스트 시나리오**: 04 R-F-08 → 단위 + 통합 + E2E

### PUT /articles/{slug}

- 인증: 필수
- F-ID: F-04 / R-ID: R-F-10

**Request**: 부분 필드, 최소 1개 필수
```json
{ "article": { "title": "new title?", "description": "?", "body": "?", "tagList": ["?"] } }
```

**Response 200**: `{ "article": { ... } }` (title 변경 시 slug 재생성)

**Response 4xx/5xx**:

| 상태 | 본문 예시 | 발생 조건 |
|---|---|---|
| 401 | token | |
| 403 | `{"errors":{"article":["forbidden"]}}` | 타인 글 |
| 404 | resource not found | 없는 slug |
| 422 | 모든 필드 누락 | |

**테스트 시나리오**: 04 R-F-10 → 통합 + E2E

### DELETE /articles/{slug}

- 인증: 필수
- F-ID: F-04 / R-ID: R-F-11

**Request**: body 없음

**Response 200/204**: 본문 없음 또는 빈 객체

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 401 | token | |
| 403 | article forbidden | 타인 글 |
| 404 | resource not found | |

**테스트 시나리오**: 04 R-F-11 + cascade → 통합 + E2E

### POST /articles/{slug}/favorite

- 인증: 필수
- F-ID: F-07 / R-ID: R-F-12

**Request**: body 없음

**Response 200**: `{ "article": { ..., "favorited": true, "favoritesCount": <new> } }` (idempotent)

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 401 | token | |
| 404 | resource not found | 없는 slug |

**테스트 시나리오**: 04 R-F-12 → 단위 + 통합 + E2E

### DELETE /articles/{slug}/favorite

동일 패턴. 응답 favorited=false, count-1. idempotent.

**테스트 시나리오**: 04 R-F-12 → 단위 + 통합 + E2E

### GET /articles/{slug}/comments

- 인증: 선택
- F-ID: F-08 / R-ID: R-F-13

**Request**: path slug

**Response 200**: `{ "comments": [...] }` (배열 0건도 200)

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 404 | resource not found | 없는 slug |

**테스트 시나리오**: 04 R-F-13 → 통합 + E2E

### POST /articles/{slug}/comments

- 인증: 필수
- F-ID: F-08 / R-ID: R-F-14

**Request**:
```json
{ "comment": { "body": "..." } }
```

**Response 200**: `{ "comment": { "id": 7, "body": "...", "createdAt": "...", "updatedAt": "...", "author": { ... } } }`

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 401 | token | |
| 404 | resource not found | 없는 slug |
| 422 | body blank | |

**테스트 시나리오**: 04 R-F-14 → 단위 + 통합 + E2E

### DELETE /articles/{slug}/comments/{id}

- 인증: 필수
- F-ID: F-08 / R-ID: R-F-15

**Request**: body 없음

**Response 200/204**

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 401 | token | |
| 403 | comment forbidden | 타인 댓글 |
| 404 | resource not found | 없는 id/slug |

**테스트 시나리오**: 04 R-F-15 → 통합 + E2E

### GET /tags

- 인증: 불필요
- F-ID: F-05 / R-ID: R-F-16

**Request**: 없음

**Response 200**:
```json
{ "tags": ["javascript", "react", "..."] }
```

상위 20개 사용 빈도 DESC (OQ-P-01 결정). 0건이면 빈 배열.

**Response 4xx/5xx**:

| 상태 | 본문 | 발생 조건 |
|---|---|---|
| 5xx | server error | DB 장애 시 |

**테스트 시나리오**: 04 R-F-16 → 단위 + 통합 + E2E (Home 사이드바)

## 4. Webhook / 콜백

- **없음** — 본 시스템은 webhook 발행/수신 모두 비범위.

## 5. Rate Limit / Quota

- **본 사이클 비범위**. 캐노니컬 사양에 명시 없음, 본 구현도 미적용.
- 향후 확장 시 Spring Cloud Gateway 또는 Bucket4j로 IP·user 단위 제한 검토 — 별 feature.
- 단, **R-N-07** 페이지네이션 경계는 적용 (offset/limit 한도): limit > 100 silent clamp, offset > 1,000,000 안전 빈 결과.
