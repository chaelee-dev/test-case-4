---
doc_type: hld
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

# Conduit (RealWorld 클론) — High-Level Design (HLD)

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 14개 모듈 분해 + 데이터 흐름 + 비기능 대응 |

## 1. 핵심 모듈 / 컴포넌트

| 모듈 | 책임 | 의존 | 08에서 상세 |
| --- | --- | --- | --- |
| **M-BE-AUTH** | 회원가입·로그인·JWT 발급/검증, Security filter | M-BE-USER, M-BE-CONFIG | 08 §M-BE-AUTH |
| **M-BE-USER** | User entity·CRUD·BCrypt 해시·Settings 갱신 | M-BE-DB | 08 §M-BE-USER |
| **M-BE-PROFILE** | Profile 조회·Follow/Unfollow, following 계산 | M-BE-USER, M-BE-DB | 08 §M-BE-PROFILE |
| **M-BE-ARTICLE** | Article CRUD·slug 생성·필터·페이지네이션·Your Feed | M-BE-USER, M-BE-TAG, M-BE-DB | 08 §M-BE-ARTICLE |
| **M-BE-FAVORITE** | Favorite/Unfavorite, count 갱신 | M-BE-ARTICLE, M-BE-DB | 08 §M-BE-FAVORITE |
| **M-BE-COMMENT** | Comment CRUD, 작성자 권한 검사 | M-BE-ARTICLE, M-BE-USER | 08 §M-BE-COMMENT |
| **M-BE-TAG** | Tag upsert·인기 태그 집계 | M-BE-DB | 08 §M-BE-TAG |
| **M-BE-MARKDOWN** | (검증용) commonmark 렌더 + jsoup sanitize | (외부 라이브러리) | 08 §M-BE-MARKDOWN |
| **M-BE-WEB** | REST controllers, 응답 wrapping, GlobalExceptionHandler | 모든 도메인 모듈 | 08 §M-BE-WEB |
| **M-FE-AUTH** | 로그인·회원가입 페이지·JWT context | M-FE-API | 08 §M-FE-AUTH |
| **M-FE-PAGES** | 9개 페이지(Home/Login/Register/Settings/Editor/Article/Profile) | M-FE-AUTH, M-FE-API, M-FE-COMPONENTS | 08 §M-FE-PAGES |
| **M-FE-COMPONENTS** | 공통 컴포넌트(Header, ArticleCard, FavoriteButton, FollowButton, Pagination) | M-FE-AUTH | 08 §M-FE-COMPONENTS |
| **M-FE-API** | HTTP 클라이언트(ky 래퍼) + 401 자동 처리 + JWT 헤더 부착 | M-FE-AUTH | 08 §M-FE-API |
| **M-FE-MARKDOWN** | react-markdown + rehype-sanitize 어댑터 | (외부 라이브러리) | 08 §M-FE-MARKDOWN |

총 14개 모듈 (BE 9 + FE 5). 모든 모듈은 08 LLD Module Spec에서 fan-out으로 상세화 (ADR-0031).

## 2. 모듈 간 데이터 흐름

### 2.1 로그인 → JWT 발급 흐름

```
[Browser /login]
   │ POST /api/users/login {user:{email, password}}
   ▼
[M-FE-AUTH 페이지] ── [M-FE-API 클라이언트] ──HTTPS──▶ [M-BE-WEB Controller]
                                                              │
                                                              ▼
                                                       [M-BE-AUTH Service]
                                                              │ PasswordEncoder.match
                                                              ▼
                                                       [M-BE-USER Repository] → PostgreSQL
                                                              │
                                                              ▼
                                                       [M-BE-AUTH JwtService.create()]
                                                              │
                                                              ▼
                                                       Response {user:{..., token}}
   ▼
[M-FE-API] → localStorage.setItem('conduit.jwt', token)
   │
   ▼
[M-FE-AUTH context] → 헤더 즉시 갱신 (M-FE-COMPONENTS Header re-render)
```

### 2.2 글 작성 → 슬러그 생성 → Tag upsert 흐름

```
[Editor] ── M-FE-API ──▶ [M-BE-WEB POST /articles] ── (JWT filter) ──▶
                                                                       │
                                                                       ▼
                                                              [M-BE-ARTICLE Service]
                                                                       │
                                                              ├── slugify(title) → 충돌 시 nanoid(6) suffix
                                                              ├── M-BE-TAG.upsertAll(tagList)
                                                              ├── repository.save(Article)
                                                                       ▼
                                                              Response {article:{...}}
```

### 2.3 글 상세 + 마크다운 안전 렌더 흐름

```
[Article 페이지 /article/:slug]
   │ GET /api/articles/:slug
   ▼
[M-FE-API] ──▶ [M-BE-WEB GET /articles/:slug] ──▶ [M-BE-ARTICLE Service]
                                                          ▼
                                              Response {article:{body: "raw md"}}
   ▼
[M-FE-PAGES Article] ──▶ [M-FE-MARKDOWN] ──react-markdown + rehype-sanitize──▶ React tree
   ▼
[브라우저 DOM]: <script>·on*·javascript: 제거된 안전 HTML
```

### 2.4 401 자동 처리 흐름

```
[보호 API 호출] ──▶ Response 401
   │
   ▼
[M-FE-API 인터셉터]:
   1) localStorage.removeItem('conduit.jwt')
   2) auth context.setUser(null)
   3) 현재 라우트가 보호 라우트면 → navigate('/login?redirect=<현경로>')
   4) 비보호 라우트면 → inline 안내만 (페이지 유지)
```

## 3. 비기능 대응

| 비기능 R-ID | 대응 전략 | 상세 |
| --- | --- | --- |
| R-N-01 (응답 < 300ms 95p, 50명 동시 < 500ms) | DB 인덱스 + JPA fetch join + EntityGraph | `articles(created_at DESC)`, `articles(author_id, created_at)`, `tags(name)` 인덱스. List 응답은 author JOIN 미리 fetch |
| R-N-02 (JWT + 패스워드 보안) | Spring Security + jjwt + BCrypt | HS256 + 256bit 비밀키(.env 주입), BCrypt cost 12, 토큰 만료 7일, refresh 없음 |
| R-N-03 (마크다운 XSS 방어) | 서버 검증 sanitize + 클라이언트 렌더 sanitize 이중화 | M-BE-MARKDOWN(commonmark + jsoup `Safelist.relaxed()`) + M-FE-MARKDOWN(`rehype-sanitize` defaultSchema) |
| R-N-04 (권한 거부 403) | Method-level @PreAuthorize + 도메인 정책 클래스 | ArticlePolicy.canEdit(user, article), CommentPolicy.canDelete(user, comment) |
| R-N-05 (응답 형식 일관성) | Jackson 커스텀 wrapper + GlobalExceptionHandler | 단일/다건/에러 직렬화 표준화, `application/json` 강제, RealWorld Bruno 슈트로 contract 검증 |
| R-N-06 (3 profile 부팅) | docker-compose 단일 정의 + `.env.{dev,stg,prod}.example` | ADR-0037 v1.1. Flyway 마이그레이션 3 profile 동일 적용 |
| R-N-07 (페이지네이션 경계) | controller-level validator | offset ≥ 0, limit clamp(1~100), offset > 1M은 200 + 빈 결과 |
| R-N-08 (감사 로깅 + traceId) | Spring `OncePerRequestFilter` + MDC traceId | logback-spring.xml JSON pattern, 요청당 1줄 stdout |

## 4. 외부 인터페이스 윤곽

- **REST API**: 19 endpoints, `<host>/api/...`, 캐노니컬 OpenAPI 2.0.0 100% 일치 — 09 LLD API Spec 정본
- **JWT 헤더**: `Authorization: Token <jwt>` (Bearer 아님)
- **CORS**: dev `*`, stg/prod allowed origins 화이트리스트 (Spring Security `CorsConfigurationSource`)
- **FE storage**: localStorage key `conduit.jwt`
- **외부 시스템 의존**: 없음 (이미지·이메일·IdP·CDN 모두 비범위)
