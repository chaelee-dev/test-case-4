---
doc_type: module-spec
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-F-01, R-F-02, R-F-03, R-F-04, R-F-05, R-F-06, R-F-07, R-F-08, R-F-09, R-F-10, R-F-11, R-F-12, R-F-13, R-F-14, R-F-15, R-F-16, R-F-17, R-F-18, R-F-19, R-F-20, R-F-21, R-F-22, R-F-23, R-F-24, R-F-25, R-F-26, R-F-27]
  F-ID: [F-01, F-02, F-03, F-04, F-05, F-06, F-07, F-08, F-09]
  supersedes: null
---

# Conduit (RealWorld 클론) — Module Spec (LLD — 모듈/통신)

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 14개 모듈 LLD, 07 HLD §1 fan-out |

## 1. 모듈 개요

본 문서는 07 HLD §1 핵심 모듈/컴포넌트 표 14개 행 각각의 LLD 본체다. 모든 모듈은 **07 HLD §1 참조**를 통해 fan-in되며, R-ID·F-ID 매핑이 다음 표로 정리된다.

| 모듈 ID | 책임 | 07 HLD §1 참조 | R-ID 매핑 | F-ID 매핑 |
|---|---|---|---|---|
| M-BE-AUTH | 회원가입·로그인·JWT·Security filter | 07 §1 M-BE-AUTH | R-F-01, R-F-02, R-N-02 | F-01 |
| M-BE-USER | User entity·CRUD·BCrypt·Settings | 07 §1 M-BE-USER | R-F-03, R-N-02 | F-01, F-02 |
| M-BE-PROFILE | Profile 조회·Follow/Unfollow | 07 §1 M-BE-PROFILE | R-F-04, R-F-05 | F-03 |
| M-BE-ARTICLE | Article CRUD·slug·필터·Feed | 07 §1 M-BE-ARTICLE | R-F-06, R-F-07, R-F-08, R-F-09, R-F-10, R-F-11, R-F-17 | F-04, F-05 |
| M-BE-FAVORITE | Favorite/Unfavorite·count | 07 §1 M-BE-FAVORITE | R-F-12 | F-07 |
| M-BE-COMMENT | Comment CRUD | 07 §1 M-BE-COMMENT | R-F-13, R-F-14, R-F-15 | F-08 |
| M-BE-TAG | Tag upsert·인기 태그 | 07 §1 M-BE-TAG | R-F-16 | F-05 |
| M-BE-MARKDOWN | 서버측 마크다운 sanitize | 07 §1 M-BE-MARKDOWN | R-F-18, R-N-03 | F-06 |
| M-BE-WEB | REST controllers·응답 wrap·에러 핸들러 | 07 §1 M-BE-WEB | R-N-04, R-N-05, R-N-07, R-N-08 | (모든 F) |
| M-FE-AUTH | 로그인/회원가입 페이지·JWT context | 07 §1 M-FE-AUTH | R-F-20, R-F-27 | F-01 |
| M-FE-PAGES | 9개 페이지 컴포넌트 | 07 §1 M-FE-PAGES | R-F-19, R-F-21, R-F-22, R-F-23, R-F-24 | F-02, F-04, F-05, F-06, F-08 |
| M-FE-COMPONENTS | Header·ArticleCard·Pagination 등 | 07 §1 M-FE-COMPONENTS | R-F-25 | F-09 |
| M-FE-API | HTTP client + 401 처리 + 헤더 부착 | 07 §1 M-FE-API | R-F-26, R-F-27 | F-09 |
| M-FE-MARKDOWN | react-markdown + rehype-sanitize 어댑터 | 07 §1 M-FE-MARKDOWN | R-F-18, R-N-03 | F-06 |

## 2. 외부 인터페이스

| 인터페이스 | 입력 | 출력 | 에러 |
|---|---|---|---|
| M-BE-AUTH.register(NewUserCmd) | username, email, password | UserToken(token, user) | DuplicateEmail/Username(409), Validation(422) |
| M-BE-AUTH.login(LoginCmd) | email, password | UserToken | InvalidCredentials(401) |
| M-BE-AUTH.verifyToken(jwt) | jwt string | UserId or empty | TokenExpired/Invalid(401) |
| M-BE-USER.getById(userId) | userId | User | NotFound(404) |
| M-BE-USER.update(userId, UpdateUserCmd) | userId, partial fields | User+newToken | DuplicateEmail(422), NotFound(404) |
| M-BE-PROFILE.getProfile(username, viewerId?) | username, optional viewer | Profile(following) | NotFound(404) |
| M-BE-PROFILE.follow(followerId, username) | follower, target | Profile(following=true) | SelfFollow(422), NotFound(404) |
| M-BE-ARTICLE.list(ListQuery, viewerId?) | tag/author/favorited, offset, limit | List<Article>, total | Validation(422) |
| M-BE-ARTICLE.feed(viewerId, offset, limit) | viewerId, paging | List<Article>, total | Unauth(401) |
| M-BE-ARTICLE.create(viewerId, NewArticleCmd) | title, description, body, tagList | Article | Validation(422), Unauth(401) |
| M-BE-ARTICLE.update(viewerId, slug, UpdateArticleCmd) | slug, partial fields | Article | Forbidden(403), NotFound(404) |
| M-BE-ARTICLE.delete(viewerId, slug) | slug | void | Forbidden(403), NotFound(404) |
| M-BE-FAVORITE.toggle(viewerId, slug, on/off) | slug, on/off | Article | Unauth(401), NotFound(404) |
| M-BE-COMMENT.list(slug) | slug | List<Comment> | NotFound(404) |
| M-BE-COMMENT.create(viewerId, slug, body) | slug, body | Comment | Validation(422), Unauth(401), NotFound(404) |
| M-BE-COMMENT.delete(viewerId, slug, id) | slug, id | void | Forbidden(403), NotFound(404) |
| M-BE-TAG.list() | (none) | List<Tag.name> | (없음) |
| M-BE-TAG.upsertAll(names) | List<String> | List<TagId> | (없음) |
| M-BE-MARKDOWN.sanitize(rawMd) | raw markdown | safe HTML | (없음, 모든 입력 안전 처리) |
| M-FE-API.request(path, init?) | path, options | Promise<Response> | 401 → 자동 로그아웃 + redirect, 그 외 throw |
| M-FE-AUTH.login(creds) | email/password | void (context setUser) | 폼 에러 객체 |
| M-FE-PAGES.* | (라우트 props) | React node | route 보호 실패 → /login |
| M-FE-MARKDOWN.render(rawMd) | raw markdown | React node | (XSS 자동 제거) |

## 3. 내부 컴포넌트

| 모듈 | 내부 컴포넌트 | 역할 |
|---|---|---|
| M-BE-AUTH | AuthService, JwtService, PasswordEncoder, AuthFilter (Spring Security) | 위임 + 토큰 + filter 등록 |
| M-BE-USER | UserService, UserRepository (JPA), User(엔티티) | DDL via Flyway V1_user.sql |
| M-BE-PROFILE | ProfileService, FollowRepository, Follow(엔티티) | unique(follower, followee) 제약 |
| M-BE-ARTICLE | ArticleService, ArticleRepository, ArticleSpec(JPA Specification), SlugGenerator, Article(엔티티) | 필터 동적 쿼리 |
| M-BE-FAVORITE | FavoriteService, FavoriteRepository, Favorite(엔티티) | unique(user, article) |
| M-BE-COMMENT | CommentService, CommentRepository, Comment(엔티티), CommentPolicy | 작성자 권한 검사 |
| M-BE-TAG | TagService, TagRepository, Tag(엔티티), TagPopularityQuery | upsert + 인기 집계 |
| M-BE-MARKDOWN | MarkdownService(commonmark Parser/Renderer), JsoupSanitizer | Safelist.relaxed() |
| M-BE-WEB | UserController, ProfileController, ArticleController, CommentController, TagController, GlobalExceptionHandler, ResponseEnvelope | 19 endpoints 라우팅 |
| M-FE-AUTH | LoginPage, RegisterPage, AuthContext, AuthProvider | useAuth() 훅 노출 |
| M-FE-PAGES | HomePage, SettingsPage, EditorPage, ArticlePage, ProfilePage | react-router-dom 라우트 |
| M-FE-COMPONENTS | Header, ArticleCard, FavoriteButton, FollowButton, Pagination, ErrorList, TagInput, Spinner | 재사용 컴포넌트 |
| M-FE-API | apiClient(ky), interceptors(401), schemas(zod), endpoints/* (per resource) | 타입 안전 HTTP |
| M-FE-MARKDOWN | MarkdownView (react-markdown + rehype-sanitize) | 안전 렌더 컴포넌트 |

## 4. 데이터 흐름

본 §4는 07 HLD §2의 4개 흐름을 LLD 수준으로 상세화한다.

### 4.1 로그인 데이터 흐름 (LoginCmd → UserToken)

1. `M-FE-AUTH.LoginPage` `handleSubmit({email, password})` 호출
2. `M-FE-API.endpoints.users.login({email, password})` → `POST /api/users/login`
3. `M-BE-WEB.UserController.login(@RequestBody LoginRequest)` → `M-BE-AUTH.AuthService.login(LoginCmd)`
4. `UserRepository.findByEmail(email)` → user(or empty)
5. user 없음 또는 `PasswordEncoder.matches(password, user.passwordHash) == false` → throw `InvalidCredentialsException` (`M-BE-WEB.GlobalExceptionHandler` → 401)
6. 성공 → `JwtService.create(userId, exp=now+7d)` → UserToken
7. `ResponseEnvelope.user(user, token)` → `{user:{email, token, username, bio, image}}`
8. `M-FE-API` → response → `AuthContext.setUser + localStorage.setItem('conduit.jwt', token)`
9. `M-FE-AUTH.LoginPage.navigate('/')`

### 4.2 글 작성 데이터 흐름

1. `EditorPage.handleSubmit({title, description, body, tagList})` → `M-FE-API.endpoints.articles.create(...)`
2. `POST /api/articles` `Authorization: Token <jwt>` → `M-BE-AUTH.AuthFilter` → `SecurityContext` user 주입
3. `ArticleController.create(@RequestBody NewArticleRequest, @AuthenticationPrincipal user)` → `ArticleService.create(viewerId, cmd)`
4. `SlugGenerator.generate(title)` → slug → `ArticleRepository.existsBySlug(slug)` 시 nanoid(6) suffix
5. `TagService.upsertAll(tagList)` → tag rows (반환 ids)
6. `ArticleRepository.save(Article)` (article-tag join은 cascade)
7. Response `{article:{...}}` → 201
8. `EditorPage.navigate('/article/<slug>')`

### 4.3 글 상세 + 마크다운 안전 렌더 흐름

1. `ArticlePage` 마운트 → `useEffect` `M-FE-API.endpoints.articles.get(slug)`
2. `GET /api/articles/:slug` → `ArticleController.get` → `ArticleService.get(slug, viewerId?)`
3. body는 **raw markdown** 그대로 응답 (서버측 sanitize는 *글 작성/수정 시점*에 적용, 저장도 raw로)
4. `M-FE-MARKDOWN.MarkdownView body={article.body}` → `react-markdown` + `rehype-sanitize` 처리 → React tree
5. DOM에 `<script>`·`on*`·`javascript:` 미존재 보장 (R-N-03)

### 4.4 401 자동 처리 흐름

1. 임의 보호 API 호출 → 응답 401
2. `M-FE-API.interceptors.afterResponse` catch
3. localStorage.removeItem + `AuthContext.setUser(null)` + (보호 라우트면) `navigate('/login?redirect=...')`
4. 비보호 라우트면 호출자에 throw로 위임 — 페이지 자체는 유지 (inline 안내)

## 5. 상태·라이프사이클

- **JWT 만료**: 토큰 exp=now+7d. 만료 후 호출 시 401 → 401 자동 처리 흐름 (§4.4).
- **Article slug 불변성**: 수정 시 title 변경된 경우에만 slug 재생성. 외부 링크 보존을 위해 *title 변경 없으면 slug 유지* (OQ-SR-02 결정).
- **Follow 관계**: 데이터 삭제 시 즉시 반영. 캐시 없음.
- **Favorite 카운트**: `articles.favorites_count` 컬럼 + `favorites` 테이블 unique 제약. POST/DELETE 시 atomic 갱신 (PostgreSQL row-level lock).
- **Tag 라이프사이클**: upsert만. 미사용 태그 garbage collection은 비범위 (수동 정리 가능).
- **FE AuthContext**: 앱 부팅 시 localStorage 토큰 검사 → 있으면 `GET /api/user`로 검증 → 200 시 user set / 401 시 토큰 제거.

## 6. 에러 처리

| 에러 | 발생 조건 | 처리 |
|---|---|---|
| ValidationException | @Valid 실패, custom validator 실패 | 422 + `{errors:{<field>:[<msg>]}}` |
| InvalidCredentialsException | 로그인 자격 불일치 | 401 + `{errors:{"email or password":["is invalid"]}}` |
| DuplicateResourceException | username/email/slug 충돌 | 409 (회원가입) / 422 (수정) + `{errors:{<field>:["has already been taken"]}}` |
| UnauthorizedException | JWT 없음/만료/위변조 | 401 + `{errors:{token:["is missing"]}}` 또는 `["is invalid"]` |
| ForbiddenException | 타인 자원 수정/삭제 | 403 + `{errors:{resource:["forbidden"]}}` |
| NotFoundException | 자원 부재 | 404 + `{errors:{resource:["not found"]}}` |
| SelfFollowException | 자기 자신 팔로우 | 422 + `{errors:{username:["cannot follow self"]}}` |
| Throwable (기타) | 미예상 예외 | 500 + traceId 노출 + 로그 ERROR + `{errors:{server:["internal error"]}}` |
| FE: NetworkError | fetch 실패 | inline 재시도 버튼 + ErrorList |
| FE: ParseError (zod) | 응답 스키마 불일치 | 콘솔 에러 + ErrorList "잘못된 응답" + 자동 재시도 1회 |

## 7. 동시성·트랜잭션

- **글 작성 + Tag upsert**: 단일 `@Transactional` — tag upsert 실패 시 article 저장 롤백
- **글 삭제 + cascade**: `ON DELETE CASCADE` (FK) + JPA cascade — Article 삭제 → Comments·Favorites·ArticleTags 자동 제거
- **Favorite toggle 동시성**: `favorites` 테이블 unique(user_id, article_id) + insert ignore 패턴(JPA: try-catch DataIntegrityViolation, 결과는 idempotent 200)
- **Follow toggle**: 동일 패턴
- **JWT 발급은 stateless** — 서버 세션 없음
- **PostgreSQL isolation**: 기본 READ COMMITTED. count 갱신 시 트랜잭션 + row-level lock

## 8. 테스트 진입점

| 모듈 | 단위 (JUnit5 + Mockito) | 통합 (@SpringBootTest + Testcontainers) | E2E (Playwright vs 캐노니컬) |
|---|---|---|---|
| M-BE-AUTH | AuthServiceTest, JwtServiceTest | AuthControllerIT (register/login flow) | login/register flow.spec |
| M-BE-USER | UserServiceTest | UserSettingsIT | settings.spec |
| M-BE-PROFILE | ProfileServiceTest | FollowIT | follow.spec |
| M-BE-ARTICLE | SlugGeneratorTest, ArticleServiceTest | ArticleCRUD_IT, ArticleListIT | article.spec, home.spec |
| M-BE-FAVORITE | FavoriteServiceTest | FavoriteIT | favorite.spec |
| M-BE-COMMENT | CommentServiceTest | CommentIT | comment.spec |
| M-BE-TAG | TagServiceTest | TagPopularityIT | (Home 사이드바 통해) |
| M-BE-MARKDOWN | MarkdownSanitizeTest (XSS 페이로드 8종) | (N/A — 순수 컴포넌트) | xss.spec |
| M-BE-WEB | (Controller는 IT 위주) | ResponseEnvelopeIT, GlobalErrorIT | (전수 spec이 검증) |
| M-FE-AUTH | LoginPage.test, AuthContext.test (Vitest + RTL) | (MSW로 mock) | login.spec |
| M-FE-PAGES | 각 페이지 컴포넌트 test | MSW + Vitest | 9 spec 페이지 |
| M-FE-COMPONENTS | Header.test, ArticleCard.test, Pagination.test | (N/A) | (페이지 spec에 포함) |
| M-FE-API | apiClient.test, interceptors.test | MSW 401 시 자동 처리 검증 | 401 redirect.spec |
| M-FE-MARKDOWN | MarkdownView.test (XSS 8종) | (N/A) | xss-fe.spec |

각 단위·통합·E2E 테스트는 R-ID 매핑(§1 표)을 코멘트로 명시하고, 13 Test Design 02-catalog로 fan-in한다.
