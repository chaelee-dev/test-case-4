---
doc_type: wbs
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: operations
related:
  R-ID: [R-F-01, R-F-02, R-F-03, R-F-04, R-F-05, R-F-06, R-F-07, R-F-08, R-F-09, R-F-10, R-F-11, R-F-12, R-F-13, R-F-14, R-F-15, R-F-16, R-F-17, R-F-18, R-F-19, R-F-20, R-F-21, R-F-22, R-F-23, R-F-24, R-F-25, R-F-26, R-F-27, R-N-01, R-N-02, R-N-03, R-N-04, R-N-05, R-N-06, R-N-07, R-N-08]
  F-ID: [F-01, F-02, F-03, F-04, F-05, F-06, F-07, F-08, F-09]
  supersedes: null
---

# Conduit (RealWorld 클론) — WBS

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 4 스프린트, 32 이슈, R-ID/F-ID 100% 매핑 |

## 0. 개요

본 WBS는 04 SRS의 35 R-ID(27 R-F + 8 R-N)와 05 PRD의 9 F-ID를 4개 스프린트, 32개 이슈로 분해한다. 추정 합산 38d로 01 §6 18d 계획 대비 약 2배 — RISK-12로 명시한 일정 초과 가능성을 사전 반영하며, Sprint 5 buffer 권한을 유보한다.

분해 원칙:
- 한 이슈 = 1~3 working days (schema BLOCK)
- 한 이슈 = 1 PR (1 이슈 1 PR)
- 한 이슈는 단일 R-ID 또는 F-ID 묶음을 완결 (Sprint 종료 시 라벨 `tested` 가능)
- 의존성(Blocked-by)은 §3 그래프로 명시

## 1. 스프린트 일람

| Sprint | 기간 | 목표(Outcome) | 주요 R-ID/F-ID | 이슈 수 |
| --- | --- | --- | --- | --- |
| Sprint 1 | 2026-W22 (5d 계획 → 8d 추정) | BE Foundation — Auth·User·Profile API 7건 + 응답/에러 표준 | R-F-01~05, R-N-02·04·05·07·08, F-01·02·03 | 8 |
| Sprint 2 | 2026-W23 (5d → 12d 추정) | BE Domain — Article·Tag·Comment·Favorite·Markdown API 12건 | R-F-06~18, R-N-03, F-04·05·06·07·08 | 9 |
| Sprint 3 | 2026-W24 (5d → 12d 추정) | FE Pages — 9 페이지 + 라우팅 + JWT + 마크다운 + Auth | R-F-19~27, R-N-03, F-01~09 | 9 |
| Sprint 4 | 2026-W25 (3d → 6d 추정) | QA·Test·CI·Release — Bruno fork, Playwright E2E, k6, 3 profile CI, README | R-N-01·05·06, KPI | 6 |

## 2. 스프린트 상세

### Sprint 1 — BE Foundation

목표: BE 부트스트랩 + 응답/에러 표준 + Auth + User + Profile API 7건 + 페이지네이션 validator. 이 종료 시점에 RealWorld Bruno 슈트의 `/users/*`, `/user`, `/profiles/*` 케이스 100% PASS.

##### Issue: I-01 project-bootstrap

- 유형: chore
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 빈 backend 폴더, When `./gradlew bootRun --args='--spring.profiles.active=dev'`를 실행하면, Then PostgreSQL 컨테이너 + Flyway V0__baseline + Spring Boot가 8080 포트에서 ready 신호를 출력한다.
- Contract Before: backend 폴더 부재
- Contract After: backend/build.gradle.kts + docker-compose.yml + Dockerfile + application-{dev,stg,prod}.yml + .env.{dev,stg,prod}.example + Flyway V0__baseline.sql + ConduitApplication.java
- DoD Checklist:
  - [ ] `./gradlew clean build` PASS
  - [ ] 3 profile bootRun 각각 ready 신호 확인 (R-N-06)
  - [ ] LOCAL.md §3 명령으로 부팅 확인
  - [ ] gradle.lockfile 커밋
  - [ ] 단위 테스트 0건이지만 통합 환경 동작 확인

##### Issue: I-02 jwt-and-security-config

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given JwtService + AuthFilter 구성, When 유효 JWT로 보호 엔드포인트(임시 /api/health-auth) 호출 시, Then 200; 토큰 부재/만료/위변조 시 401 + `{errors:{token:[...]}}`.
- Contract Before: Spring Security 미구성
- Contract After: SecurityConfig + JwtService(HS256, jjwt 0.12+) + AuthFilter + PasswordEncoderConfig(BCrypt cost 12) + TraceIdFilter + logback-spring.xml(MDC traceId)
- DoD Checklist:
  - [ ] 단위 테스트: JwtServiceTest (정상/만료/위변조) PASS
  - [ ] 통합 테스트: AuthFilterIT (401 케이스 3종) PASS
  - [ ] R-N-02, R-N-08 매핑 확인
  - [ ] /cso 보안 점검 — JWT_SECRET .env 외부 주입 검증
  - [ ] Jacoco 커버리지 ≥ 80%

##### Issue: I-03 response-envelope-and-error-handling

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 임의 컨트롤러 응답 또는 임의 예외, When 직렬화/처리되면, Then 단일 `{"<resource>":{...}}`·다건 `{"<resources>":[...],"<resources>Count":N}`·에러 `{"errors":{<field>:[<msg>]}}` 형식으로 통일된다.
- Contract Before: 응답 형식 임의
- Contract After: ResponseEnvelope util + GlobalExceptionHandler + 8종 예외 매핑(Validation/InvalidCredentials/Duplicate/Unauthorized/Forbidden/NotFound/SelfFollow/Throwable)
- DoD Checklist:
  - [ ] 단위 테스트: GlobalExceptionHandlerTest 8 케이스 PASS
  - [ ] R-N-04, R-N-05 매핑 확인
  - [ ] traceId 로그 출력 검증 (R-N-08)

##### Issue: I-04 user-domain-and-registration

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given username/email/password, When `POST /users` 호출하면, Then 201 + `{user:{email,token,username,bio:null,image:null}}` 응답 + BCrypt 해시 저장.
- Contract Before: User 도메인 부재
- Contract After: User entity + Flyway V1__user.sql + UserRepository + UserService.register + UserController.register + dto/RegisterRequest
- DoD Checklist:
  - [ ] 단위: UserServiceTest.register (정상 + 중복 + 422) PASS
  - [ ] 통합: UserControllerIT POST /users 6 케이스 PASS
  - [ ] Bruno 케이스 `Auth > Register` PASS (R-N-05 정합)
  - [ ] R-F-01 + F-01 매핑

##### Issue: I-05 login-endpoint

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 0.5d
- Acceptance Criteria: Given DB에 일치 user, When `POST /users/login`을 email/password로 호출하면, Then 200 + `{user:{...,token}}`; 불일치 시 401.
- Contract Before: 로그인 부재
- Contract After: AuthService.login + UserController.login + LoginRequest dto
- DoD Checklist:
  - [ ] 단위: AuthServiceTest.login PASS
  - [ ] 통합: LoginIT (정상/잘못된 password/비등록 email) PASS
  - [ ] Bruno `Auth > Login` PASS
  - [ ] R-F-02 + F-01 매핑

##### Issue: I-06 current-user-endpoints

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 유효 JWT, When `GET /user` 또는 `PUT /user`(부분 필드) 호출하면, Then 200 + 갱신된 user 반환 (PUT은 새 token 발급).
- Contract Before: 현재 사용자 엔드포인트 부재
- Contract After: UserController.getCurrent / updateCurrent + UpdateUserRequest dto + UserService.update
- DoD Checklist:
  - [ ] 단위: UserServiceTest.update (부분 갱신 atomic) PASS
  - [ ] 통합: CurrentUserIT (GET 200, PUT 200, 401, 422 중복) PASS
  - [ ] Bruno `User > Get Current / Update` PASS
  - [ ] R-F-03 + F-02 매핑

##### Issue: I-07 profile-and-follow

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given username, When `GET /profiles/:username` 호출하면, Then 200 + profile(following bool). 유효 JWT로 `POST /profiles/:username/follow` / `DELETE …/follow` 호출 시 200 + profile(following=true/false), idempotent. 자기 자신 팔로우는 422.
- Contract Before: Profile/Follow 부재
- Contract After: Profile dto + Flyway V2__follow.sql + FollowRepository + ProfileService(getProfile/follow/unfollow) + ProfileController
- DoD Checklist:
  - [ ] 단위: ProfileServiceTest (idempotent + selfFollow) PASS
  - [ ] 통합: ProfileIT 6 케이스 + UNIQUE 제약 검증 PASS
  - [ ] Bruno `Profile > Get / Follow / Unfollow` PASS
  - [ ] R-F-04, R-F-05 + F-03 매핑

##### Issue: I-08 pagination-validation

- 유형: feature
- 영역: backend
- 우선순위: P1
- Estimated Effort: 0.5d
- Acceptance Criteria: Given query `offset`/`limit`, When controller가 받으면, Then offset < 0 → 422, limit > 100 → silent clamp(100), offset > 1,000,000 → 200 + 빈 결과 < 500ms.
- Contract Before: 검증 부재
- Contract After: PaginationValidator + @PageableDefault config
- DoD Checklist:
  - [ ] 단위: PaginationValidatorTest 5 케이스 PASS
  - [ ] R-N-07 매핑
  - [ ] 후속 I-12·I-13에 적용

### Sprint 2 — BE Domain (Article + Tag + Comment + Favorite + Markdown)

목표: 글·태그·댓글·좋아요·마크다운 모듈 완성. RealWorld Bruno 슈트 `/articles/*`, `/tags`, `/comments/*` 전수 PASS.

##### Issue: I-09 article-domain-and-slug

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given title, When SlugGenerator.generate(title)를 호출하면, Then kebab-case + 충돌 시 nanoid(6) suffix. Article entity + Flyway V3 마이그레이션이 적용된다.
- Contract Before: Article 도메인 부재
- Contract After: Article entity + V3__article.sql + ArticleRepository + SlugGenerator + Article dto
- DoD Checklist:
  - [ ] 단위: SlugGeneratorTest 5 케이스 PASS (R-F-17 Happy + Failure)
  - [ ] 단위: ArticleRepositoryTest CRUD PASS
  - [ ] R-F-17 매핑

##### Issue: I-10 tag-domain-and-list

- 유형: feature
- 영역: backend
- 우선순위: P1
- Estimated Effort: 1d
- Acceptance Criteria: Given Tag·ArticleTag 도메인, When `GET /tags` 호출하면, Then 200 + `{tags:[...상위 20개, 빈도 DESC]}`. upsertAll(names)이 새 태그를 idempotent하게 처리한다.
- Contract Before: Tag 부재
- Contract After: Tag entity + ArticleTag join + V4__tag.sql + V5__article_tag.sql + TagRepository + TagService(upsertAll/listPopular) + TagController
- DoD Checklist:
  - [ ] 단위: TagServiceTest (upsert idempotent) PASS
  - [ ] 통합: TagIT 정렬·상한 PASS
  - [ ] Bruno `Tags > Get` PASS
  - [ ] R-F-16 + F-05 매핑

##### Issue: I-11 article-create

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 유효 JWT + title/description/body/tagList, When `POST /articles` 호출하면, Then 201 + article(slug 자동) + tagList upsert 후 ArticleTag join 저장.
- Contract Before: 글 작성 부재
- Contract After: ArticleService.create + ArticleController.create + NewArticleRequest dto + Transactional 적용
- DoD Checklist:
  - [ ] 단위: ArticleServiceTest.create PASS (slug + tag upsert)
  - [ ] 통합: ArticleCreateIT 정상 + 동일 title 2건 PASS
  - [ ] Bruno `Articles > Create` PASS
  - [ ] R-F-09 + F-04 매핑

##### Issue: I-12 article-list-and-filter

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given `?tag=`/`?author=`/`?favorited=` + `limit`/`offset`, When `GET /articles` 호출하면, Then 200 + `{articles:[...createdAt DESC],articlesCount:N}` 필터 정확.
- Contract Before: 글 목록 부재
- Contract After: ArticleSpec(JPA Specification) + ArticleService.list + ArticleController.list + EntityGraph(author fetch join)
- DoD Checklist:
  - [ ] 단위: ArticleSpecTest 4 필터 PASS
  - [ ] 통합: ArticleListIT 정렬·페이지네이션·필터·N+1 카운트 PASS
  - [ ] Bruno `Articles > List` PASS
  - [ ] R-F-06 + F-05 매핑
  - [ ] RISK-05 N+1 회피 검증 (쿼리 카운트 assertion)

##### Issue: I-13 article-feed

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 유효 JWT, When `GET /articles/feed?limit&offset` 호출하면, Then 200 + 팔로잉 작성자 글만 createdAt DESC 반환. 비로그인 → 401.
- Contract Before: 부재
- Contract After: ArticleService.feed + ArticleController.feed + JOIN follow
- DoD Checklist:
  - [ ] 통합: FeedIT (팔로잉 0/N/401) PASS
  - [ ] Bruno `Articles > Feed` PASS
  - [ ] R-F-07 + F-05 매핑

##### Issue: I-14 article-detail-update-delete

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given slug, When `GET /articles/:slug` 호출하면 200 + article; 유효 JWT + 본인 글로 PUT/DELETE 호출 시 200/204; 타인 글은 403.
- Contract Before: 단일 글 부재
- Contract After: ArticleController.get/update/delete + ArticlePolicy.canEdit + ArticleService.update(title 변경 시 slug 재생성)/delete(cascade)
- DoD Checklist:
  - [ ] 단위: ArticlePolicyTest + UpdateTest (title 변경 / 미변경 slug 보존) PASS
  - [ ] 통합: ArticleDetailIT (GET/PUT/DELETE + 403 + cascade) PASS
  - [ ] Bruno `Articles > Get/Update/Delete` PASS
  - [ ] R-F-08, R-F-10, R-F-11, R-N-04 + F-04, F-06 매핑

##### Issue: I-15 favorite

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 유효 JWT, When `POST /articles/:slug/favorite` 또는 `DELETE …/favorite` 호출하면, Then 200 + article(favorited toggle + count ±1), idempotent.
- Contract Before: 좋아요 부재
- Contract After: Favorite entity + V7__favorite.sql + FavoriteRepository(UNIQUE) + FavoriteService.toggle + 추가 컨트롤러 매핑
- DoD Checklist:
  - [ ] 통합: FavoriteIT (idempotent + count 정확성 + race) PASS
  - [ ] Bruno `Favorites > Create/Delete` PASS
  - [ ] R-F-12 + F-07 매핑

##### Issue: I-16 comment

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given slug, When `GET .../comments` 호출하면 200 + `{comments:[...]}`; JWT + body로 POST하면 200 + `{comment:{...}}`; 본인 댓글 DELETE → 200, 타인 댓글 → 403.
- Contract Before: 댓글 부재
- Contract After: Comment entity + V6__comment.sql + CommentRepository + CommentService(list/create/delete) + CommentPolicy + CommentController
- DoD Checklist:
  - [ ] 단위: CommentServiceTest + CommentPolicyTest PASS
  - [ ] 통합: CommentIT (list 0/N, create, delete 본인/타인) PASS
  - [ ] Bruno `Comments > List/Create/Delete` PASS
  - [ ] R-F-13, R-F-14, R-F-15 + F-08 매핑

##### Issue: I-17 markdown-sanitize

- 유형: feature
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 임의 마크다운, When MarkdownService.sanitize(body)를 호출하면, Then `<script>`/`<iframe>`/`on*`/`javascript:`/`data:`가 제거된 안전 HTML이 반환된다.
- Contract Before: 마크다운 sanitize 부재
- Contract After: MarkdownService (commonmark Parser/Renderer + jsoup Safelist.relaxed) + 8종 XSS 페이로드 단위 테스트
- DoD Checklist:
  - [ ] 단위: MarkdownSanitizeTest 8 페이로드 + 정상 마크다운 PASS
  - [ ] R-F-18, R-N-03 + F-06 매핑
  - [ ] RISK-03 단계적 롤아웃 Step 1 통과

### Sprint 3 — FE Pages

목표: 9 페이지 + 라우팅 + JWT + 마크다운 + Auth. 종료 시 캐노니컬 Conduit Frontend 전체 사양 충족.

##### Issue: I-18 frontend-bootstrap

- 유형: chore
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 빈 frontend 폴더, When `pnpm dev --mode dev`를 실행하면, Then Vite가 :5173에서 ready 신호 + TailwindCSS 적용된 빈 페이지가 렌더된다.
- Contract Before: frontend 폴더 부재
- Contract After: package.json + pnpm-lock.yaml + vite.config.ts + tsconfig.json + tailwind.config.ts + tokens.css(10§3) + index.html + main.tsx + App.tsx + .env.{dev,stg,prod}.example
- DoD Checklist:
  - [ ] 3 profile build/preview PASS (R-N-06)
  - [ ] tokens.css → tailwind.config.ts 매핑 검증
  - [ ] ESLint + Prettier + EditorConfig 통과
  - [ ] LOCAL.md §3 명령 검증

##### Issue: I-19 api-client-and-401

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given M-FE-API.apiClient, When 임의 API 호출에 토큰이 있으면, Then `Authorization: Token <jwt>` 자동 부착. 401 응답 시 토큰 자동 제거 + auth context 초기화 + 보호 라우트에서만 navigate('/login?redirect=...').
- Contract Before: HTTP 클라이언트 부재
- Contract After: lib/api/client.ts(ky) + interceptors + endpoints/{users,profiles,articles,comments,tags}.ts + lib/api/schemas.ts (zod)
- DoD Checklist:
  - [ ] 단위: apiClient.test (헤더 부착 + 401 인터셉터) PASS
  - [ ] 통합: MSW로 401 시나리오 검증 PASS
  - [ ] R-F-27 + F-09 매핑

##### Issue: I-20 auth-context-and-pages

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given `/login` 또는 `/register`, When 폼 제출하면, Then API 호출 + 성공 시 localStorage.setItem + auth context 갱신 + navigate('/'); 422 에러 시 폼 상단 ErrorList.
- Contract Before: 인증 페이지 부재
- Contract After: lib/auth/{AuthContext,storage}.tsx + pages/login + pages/register + ErrorList 컴포넌트
- DoD Checklist:
  - [ ] 단위: LoginPage.test + RegisterPage.test PASS
  - [ ] R-F-20 + F-01 매핑

##### Issue: I-21 header-and-protected-routes

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given auth 상태(비로그인/로그인), When Header가 렌더되면, Then 그에 맞는 메뉴 4개 + active class 적용. 비로그인 사용자가 `/settings`·`/editor`·`/editor/:slug`에 진입하면 `/login?redirect=...`로 자동 이동.
- Contract Before: 헤더/라우팅 부재
- Contract After: components/header + routes/router.tsx + routes/ProtectedRoute.tsx
- DoD Checklist:
  - [ ] 단위: Header.test (인증 상태별 메뉴) + ProtectedRoute.test PASS
  - [ ] R-F-25, R-F-26 + F-09 매핑

##### Issue: I-22 settings-page

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given 로그인 + `/settings`, When 부분 필드 변경 후 "Update Settings"를 누르면, Then `PUT /user`로 갱신 + 새 token 저장 + 헤더 즉시 갱신. "Logout" 클릭 시 토큰 제거 + 익명 헤더.
- Contract Before: Settings 페이지 부재
- Contract After: pages/settings + SettingsForm 컴포넌트 + zod 스키마
- DoD Checklist:
  - [ ] 단위: SettingsPage.test (Update + Logout) PASS
  - [ ] R-F-21 + F-02 매핑

##### Issue: I-23 home-page

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given `/` 진입, When 페이지 로드되면, Then Banner + Feed 탭(인증 상태별) + 글 카드 20건 + 페이지네이션 + 인기 태그 사이드바가 표시된다. 태그 클릭 시 "# tagname" 탭 동적 추가.
- Contract Before: Home 페이지 부재
- Contract After: pages/home + FeedTabs + ArticleCard + Pagination + PopularTagsSidebar 컴포넌트
- DoD Checklist:
  - [ ] 단위: HomePage.test + ArticleCard.test + Pagination.test PASS
  - [ ] R-F-19 + F-05 매핑

##### Issue: I-24 editor-page

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given 로그인 + `/editor` 또는 `/editor/:slug`, When 폼 입력 후 Publish/Update, Then 새 글 작성 또는 본인 글 수정 후 `/article/:slug` 이동. 태그 입력은 Enter/Tab/comma로 칩 추가.
- Contract Before: Editor 페이지 부재
- Contract After: pages/editor + ArticleForm + TagInput 컴포넌트
- DoD Checklist:
  - [ ] 단위: EditorPage.test + TagInput.test PASS
  - [ ] R-F-22 + F-04 매핑

##### Issue: I-25 article-detail-page

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given `/article/:slug`, When 페이지 로드되면, Then 메타 + Follow + Favorite + sanitize된 마크다운 + Edit/Delete(저자만) + 댓글 폼(로그인 시) + 댓글 리스트가 표시된다. XSS 페이로드 입력 글에서 alert 미발생.
- Contract Before: Article 페이지 부재
- Contract After: pages/article + MarkdownView(rehype-sanitize) + FollowButton + FavoriteButton + CommentForm + CommentList 컴포넌트
- DoD Checklist:
  - [ ] 단위: ArticlePage.test + MarkdownView.test (XSS 8종) PASS
  - [ ] R-F-23, R-N-03 + F-06, F-07, F-08 매핑

##### Issue: I-26 profile-page

- 유형: feature
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given `/profile/:username` 또는 `/profile/:username/favorites`, When 페이지 로드되면, Then 사용자 헤더 + Follow/Edit-Settings 버튼 분기 + My/Favorited 탭 + 글 카드 + 페이지네이션이 표시된다.
- Contract Before: Profile 페이지 부재
- Contract After: pages/profile + ProfileBanner + ProfileTabs 컴포넌트
- DoD Checklist:
  - [ ] 단위: ProfilePage.test PASS
  - [ ] R-F-24 + F-03 매핑

### Sprint 4 — QA/Test/CI/Release

목표: 캐노니컬 슈트 통과 + 3 profile CI + 성능 + Release. KPI 6개 모두 충족.

##### Issue: I-27 bruno-contract-suite-fork

- 유형: test
- 영역: backend
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given gothinkster/realworld `specs/api/bruno/`를 fork한 후, When CI에서 `bru run specs/api/bruno`를 실행하면, Then 19 엔드포인트 모두 PASS 100%.
- Contract Before: contract test 부재
- Contract After: specs/api/bruno/ fork + bruno CLI 설치 + GitHub Actions step + 결과 artifact
- DoD Checklist:
  - [ ] 19 endpoint Bruno 케이스 PASS
  - [ ] CI 통합 (PR + nightly)
  - [ ] R-N-05 매핑 + RISK-01 잠금

##### Issue: I-28 playwright-e2e-fork

- 유형: test
- 영역: frontend
- 우선순위: P0
- Estimated Effort: 2d
- Acceptance Criteria: Given Playwright 슈트, When CI에서 9 spec(auth/settings/profile/editor/home/article/favorite/comment/protected-route)을 실행하면, Then ≥ 95% PASS.
- Contract Before: E2E 부재
- Contract After: tests/e2e/playwright.config.ts + specs/* 9개 + DB truncate 전략 + faker
- DoD Checklist:
  - [ ] 9 spec ≥ 95% PASS
  - [ ] CI 통합 (PR 핵심 spec + nightly 전수)
  - [ ] R-N-03 XSS spec 포함
  - [ ] RISK-10 격리 검증

##### Issue: I-29 performance-k6-scenarios

- 유형: test
- 영역: backend
- 우선순위: P1
- Estimated Effort: 1d
- Acceptance Criteria: Given k6 P1/P2/P3 시나리오, When nightly CI 실행 시, Then P1 95p < 300ms, P2 50 동시 / 글 1만 95p < 500ms, P3 offset=1M < 500ms.
- Contract Before: 성능 테스트 부재
- Contract After: tests/performance/k6/*.js + seed 시나리오 + nightly cron
- DoD Checklist:
  - [ ] P1·P2·P3 모두 PASS
  - [ ] Grafana trend 대시보드 (또는 summary.json artifact)
  - [ ] R-N-01 매핑 + RISK-05 회귀 감지

##### Issue: I-30 3-profile-ci-matrix

- 유형: chore
- 영역: infra
- 우선순위: P0
- Estimated Effort: 1d
- Acceptance Criteria: Given GitHub Actions matrix {profile: [dev,stg,prod]}, When 매 PR마다 실행되면, Then 각 profile에서 fresh checkout → 부팅 → 헬스체크 GET /api/health 200을 확인하고, 1개라도 실패 시 PR BLOCK.
- Contract Before: 3 profile CI 부재
- Contract After: `.github/workflows/3profile-boot.yml` + healthcheck endpoint + LOCAL.md sync 검증 step
- DoD Checklist:
  - [ ] dev/stg/prod 3개 job 모두 PASS
  - [ ] LOCAL.md sync 검증 통과 (ADR-0040)
  - [ ] R-N-06 매핑 + RISK-07, RISK-11 잠금

##### Issue: I-31 coverage-gate-and-jacoco

- 유형: chore
- 영역: backend
- 우선순위: P1
- Estimated Effort: 0.5d
- Acceptance Criteria: Given Jacoco + Vitest c8 설정, When 매 PR CI 실행 시, Then 라인 ≥ 85% + 브랜치 ≥ 80%; 미달 시 BLOCK.
- Contract Before: 커버리지 게이트 부재
- Contract After: build.gradle.kts jacocoTestCoverageVerification + vitest.config.ts coverage threshold + CI step
- DoD Checklist:
  - [ ] BE 라인 ≥ 85%
  - [ ] FE 라인 ≥ 85%
  - [ ] 13-test-design 01-strategy §3 정합

##### Issue: I-32 readme-and-release-v1.0

- 유형: docs
- 영역: docs
- 우선순위: P1
- Estimated Effort: 0.5d
- Acceptance Criteria: Given Sprint 4 완료, When v1.0.0 release를 발행하면, Then README + screenshots + CHANGELOG + Bruno 통과 badge + Playwright 통과 badge + Release notes가 GitHub에 게시된다.
- Contract Before: README placeholder
- Contract After: README.md(스크린샷 + 부팅 안내 + KPI 표) + CHANGELOG.md + release-notes v1.0.0
- DoD Checklist:
  - [ ] README 스크린샷 9 페이지 모두 포함
  - [ ] KPI 6개 달성 확인 표 첨부
  - [ ] tagged release v1.0.0

## 3. 의존성 그래프

```
Sprint 1 (BE Foundation):
  I-01 ──┬──▶ I-02 ──▶ I-03 ──▶ I-04 ──▶ I-05 ──▶ I-06
         │                       │                  │
         │                       ▼                  ▼
         │                     I-07 ─────────────▶ I-08
         │                                         │
Sprint 2 (BE Domain):                              │
  I-09 (depends on I-01, I-02) ────────────────────┤
    ├──▶ I-10                                      │
    ├──▶ I-11 (depends on I-09, I-10)              │
    ├──▶ I-12 (depends on I-09, I-08, I-10)        │
    ├──▶ I-13 (depends on I-09, I-07)              │
    ├──▶ I-14 (depends on I-11)                    │
    ├──▶ I-15 (depends on I-09, I-12)              │
    ├──▶ I-16 (depends on I-09)                    │
    └──▶ I-17 (depends on I-09)                    │
                                                   │
Sprint 3 (FE):                                     │
  I-18 ──▶ I-19 (depends on Sprint 1·2 BE 부분 API) ▶ I-20 ──▶ I-21
                                                              │
            ├──▶ I-22 (depends on I-19, I-20, I-21)           │
            ├──▶ I-23 (depends on I-19, I-21)                 │
            ├──▶ I-24 (depends on I-19, I-21)                 │
            ├──▶ I-25 (depends on I-19, I-21, I-17)           │
            └──▶ I-26 (depends on I-19, I-21)                 │
                                                              │
Sprint 4 (QA/Ops):                                            │
  I-27 (depends on Sprint 1·2 모든 BE 이슈)                    │
  I-28 (depends on Sprint 3 모든 FE 이슈)                      │
  I-29 (depends on Sprint 2 BE 이슈 + 시드)                    │
  I-30 (depends on Sprint 1·3 부팅 자산 안정화)                │
  I-31 (depends on Sprint 1~3 모든 이슈, parallel OK)          │
  I-32 (depends on I-27, I-28, I-29, I-30, I-31)               │
```

**순환 의존 없음** — DAG. Sprint 간 의존은 forward only.

## 4. 추적성 매트릭스

| R-ID | F-ID | Sprint | Issue Slug |
| --- | --- | --- | --- |
| R-F-01 | F-01 | 1 | I-04 user-domain-and-registration |
| R-F-02 | F-01 | 1 | I-05 login-endpoint |
| R-F-03 | F-02 | 1 | I-06 current-user-endpoints |
| R-F-04 | F-03 | 1 | I-07 profile-and-follow |
| R-F-05 | F-03 | 1 | I-07 profile-and-follow |
| R-F-06 | F-05 | 2 | I-12 article-list-and-filter |
| R-F-07 | F-05 | 2 | I-13 article-feed |
| R-F-08 | F-06 | 2 | I-14 article-detail-update-delete |
| R-F-09 | F-04 | 2 | I-11 article-create |
| R-F-10 | F-04 | 2 | I-14 article-detail-update-delete |
| R-F-11 | F-04 | 2 | I-14 article-detail-update-delete |
| R-F-12 | F-07 | 2 | I-15 favorite |
| R-F-13 | F-08 | 2 | I-16 comment |
| R-F-14 | F-08 | 2 | I-16 comment |
| R-F-15 | F-08 | 2 | I-16 comment |
| R-F-16 | F-05 | 2 | I-10 tag-domain-and-list |
| R-F-17 | F-04 | 2 | I-09 article-domain-and-slug |
| R-F-18 | F-06 | 2 | I-17 markdown-sanitize |
| R-F-19 | F-05 | 3 | I-23 home-page |
| R-F-20 | F-01 | 3 | I-20 auth-context-and-pages |
| R-F-21 | F-02 | 3 | I-22 settings-page |
| R-F-22 | F-04 | 3 | I-24 editor-page |
| R-F-23 | F-06 | 3 | I-25 article-detail-page |
| R-F-24 | F-03 | 3 | I-26 profile-page |
| R-F-25 | F-09 | 3 | I-21 header-and-protected-routes |
| R-F-26 | F-09 | 3 | I-21 header-and-protected-routes |
| R-F-27 | F-09 | 3 | I-19 api-client-and-401 |
| R-N-01 | (전반) | 4 | I-29 performance-k6-scenarios |
| R-N-02 | F-01 | 1 | I-02 jwt-and-security-config |
| R-N-03 | F-06 | 2,3 | I-17 markdown-sanitize, I-25 article-detail-page |
| R-N-04 | (전반) | 1,2 | I-03 response-envelope-and-error-handling, I-14 article-detail-update-delete |
| R-N-05 | (전반) | 1,4 | I-03 response-envelope-and-error-handling, I-27 bruno-contract-suite-fork |
| R-N-06 | (전반) | 1,3,4 | I-01 project-bootstrap, I-18 frontend-bootstrap, I-30 3-profile-ci-matrix |
| R-N-07 | F-05 | 1 | I-08 pagination-validation |
| R-N-08 | (전반) | 1 | I-02 jwt-and-security-config |

**커버리지 확인**: 35 R-ID (27 R-F + 8 R-N) 모두 1개 이상 이슈에 매핑. 9 F-ID 모두 매핑. **100% 커버**.

## 5. 리스크 매핑

| 15-risk Risk-ID | 영향 받는 Sprint/Issue | 대응 이슈 |
| --- | --- | --- |
| RISK-01 | 4 / I-27 | I-27 bruno-contract-suite-fork |
| RISK-02 | All / I-02 | I-02 jwt-and-security-config |
| RISK-03 | 2,3 / I-17, I-25 | I-17 markdown-sanitize + I-25 article-detail-page |
| RISK-04 | 1,2 / I-01, I-09, I-10, I-15, I-16 | (절차) 마이그레이션 V번호 채번 lock |
| RISK-05 | 2 / I-12 | I-12 article-list-and-filter + I-29 performance-k6-scenarios |
| RISK-06 | 2 / I-09, I-11 | I-09 article-domain-and-slug |
| RISK-07 | 4 / I-30 | I-30 3-profile-ci-matrix |
| RISK-08 | All | (별 이슈 없음 — toolkit repo 자체에서 처리) |
| RISK-09 | 4 / I-27 + Sprint 1~3 BE DoD | I-27 + 모든 BE 이슈 DoD에 Bruno 통과 1건 추가 |
| RISK-10 | 4 / I-28 | I-28 playwright-e2e-fork |
| RISK-11 | All / I-30 | I-30 3-profile-ci-matrix + I-01·I-18 부팅 자산 |
| RISK-12 | All | (절차) Sprint 5 buffer 권한 보유, MVP Cut 재검토 |

## 6. 일정

| Sprint | 계획 (영업일) | 추정 합산 | 시작 → 종료 (가정) |
|---|---|---|---|
| Sprint 1 | 5d | 8d | 2026-W22 (2026-05-25 → 06-05) |
| Sprint 2 | 5d | 12d | 2026-W23~24 (2026-06-08 → 06-26) |
| Sprint 3 | 5d | 12d | 2026-W25~26 (2026-06-29 → 07-17) |
| Sprint 4 | 3d | 6d | 2026-W27 (2026-07-20 → 07-31) |
| **총** | **18d** | **38d** | 약 9 영업주 (~7 calendar week 가정) |

01 §6의 18d 계획 대비 추정 38d로 ~2배. RISK-12 발생 가능성을 명시한다. Sprint 5(2026-W28) buffer는 다음 경우에만 활성화:
- Sprint 4 종료 시점에 P0 이슈 잔여 > 5건
- 캐노니컬 Bruno/Playwright 통과율 < 95%
- 3 profile 부팅 1개 실패

## 7. sprint-bootstrap 입력

```yaml
project:
  name: test-case-4
  description: "Conduit (RealWorld 클론) — agent-toolkit dogfooding 풀스택 reference 구현"
  visibility: private
  default_branch: main
  topics:
    - realworld
    - conduit
    - dogfooding
    - agent-toolkit

labels:
  status:
    - { name: "status:todo", color: "ededed" }
    - { name: "status:in-progress", color: "0e8a16" }
    - { name: "status:in-review", color: "fbca04" }
    - { name: "status:blocked", color: "b60205" }
  type:
    - { name: "type:feature", color: "1d76db" }
    - { name: "type:bug", color: "d93f0b" }
    - { name: "type:chore", color: "c5def5" }
    - { name: "type:docs", color: "5319e7" }
    - { name: "type:test", color: "0075ca" }
  scope:
    - { name: "scope:backend", color: "8B4513" }
    - { name: "scope:frontend", color: "61dafb" }
    - { name: "scope:infra", color: "555555" }
    - { name: "scope:docs", color: "808080" }
  priority:
    - { name: "P0", color: "b60205" }
    - { name: "P1", color: "d93f0b" }
    - { name: "P2", color: "fbca04" }
    - { name: "P3", color: "c5def5" }
  gate:
    - { name: "tested", color: "0e8a16" }

sprints:
  - name: "Sprint 1 — BE Foundation"
    milestone: "Sprint 1"
    due_on: 2026-06-05
    description: "Auth·User·Profile API 7건 + 응답/에러 표준 + 페이지네이션 validator"
    issues:
      - slug: "I-01-project-bootstrap"
        title: "chore(backend): I-01 project bootstrap"
        labels: ["type:chore", "area:backend", "priority:P0", "status:todo"]
        body_file: "docs/planning/14-wbs/14-wbs.md#issue-i-01-project-bootstrap"
        effort: "1d"
      - slug: "I-02-jwt-and-security-config"
        title: "feat(backend): I-02 jwt and security config"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-01-project-bootstrap"]
      - slug: "I-03-response-envelope-and-error-handling"
        title: "feat(backend): I-03 response envelope and error handling"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-02-jwt-and-security-config"]
      - slug: "I-04-user-domain-and-registration"
        title: "feat(backend): I-04 user domain and registration"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-03-response-envelope-and-error-handling"]
      - slug: "I-05-login-endpoint"
        title: "feat(backend): I-05 login endpoint"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "0.5d"
        blocked_by: ["I-04-user-domain-and-registration"]
      - slug: "I-06-current-user-endpoints"
        title: "feat(backend): I-06 current user endpoints"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-05-login-endpoint"]
      - slug: "I-07-profile-and-follow"
        title: "feat(backend): I-07 profile and follow"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-04-user-domain-and-registration"]
      - slug: "I-08-pagination-validation"
        title: "feat(backend): I-08 pagination validation"
        labels: ["type:feature", "area:backend", "priority:P1", "status:todo"]
        effort: "0.5d"
        blocked_by: ["I-03-response-envelope-and-error-handling"]

  - name: "Sprint 2 — BE Domain"
    milestone: "Sprint 2"
    due_on: 2026-06-26
    description: "Article·Tag·Comment·Favorite·Markdown API 9건"
    issues:
      - slug: "I-09-article-domain-and-slug"
        title: "feat(backend): I-09 article domain and slug"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-02-jwt-and-security-config"]
      - slug: "I-10-tag-domain-and-list"
        title: "feat(backend): I-10 tag domain and list"
        labels: ["type:feature", "area:backend", "priority:P1", "status:todo"]
        effort: "1d"
        blocked_by: ["I-09-article-domain-and-slug"]
      - slug: "I-11-article-create"
        title: "feat(backend): I-11 article create"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-09-article-domain-and-slug", "I-10-tag-domain-and-list"]
      - slug: "I-12-article-list-and-filter"
        title: "feat(backend): I-12 article list and filter"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-09-article-domain-and-slug", "I-08-pagination-validation"]
      - slug: "I-13-article-feed"
        title: "feat(backend): I-13 article feed"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-09-article-domain-and-slug", "I-07-profile-and-follow"]
      - slug: "I-14-article-detail-update-delete"
        title: "feat(backend): I-14 article detail update delete"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-11-article-create"]
      - slug: "I-15-favorite"
        title: "feat(backend): I-15 favorite"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-09-article-domain-and-slug", "I-12-article-list-and-filter"]
      - slug: "I-16-comment"
        title: "feat(backend): I-16 comment"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-09-article-domain-and-slug"]
      - slug: "I-17-markdown-sanitize"
        title: "feat(backend): I-17 markdown sanitize"
        labels: ["type:feature", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-09-article-domain-and-slug"]

  - name: "Sprint 3 — FE Pages"
    milestone: "Sprint 3"
    due_on: 2026-07-17
    description: "9 페이지 + JWT + 마크다운 + Header/Routes"
    issues:
      - slug: "I-18-frontend-bootstrap"
        title: "chore(frontend): I-18 frontend bootstrap"
        labels: ["type:chore", "area:frontend", "priority:P0", "status:todo"]
        effort: "1d"
      - slug: "I-19-api-client-and-401"
        title: "feat(frontend): I-19 api client and 401"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-18-frontend-bootstrap"]
      - slug: "I-20-auth-context-and-pages"
        title: "feat(frontend): I-20 auth context and pages"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-19-api-client-and-401"]
      - slug: "I-21-header-and-protected-routes"
        title: "feat(frontend): I-21 header and protected routes"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-20-auth-context-and-pages"]
      - slug: "I-22-settings-page"
        title: "feat(frontend): I-22 settings page"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-21-header-and-protected-routes"]
      - slug: "I-23-home-page"
        title: "feat(frontend): I-23 home page"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-21-header-and-protected-routes"]
      - slug: "I-24-editor-page"
        title: "feat(frontend): I-24 editor page"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-21-header-and-protected-routes"]
      - slug: "I-25-article-detail-page"
        title: "feat(frontend): I-25 article detail page"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-21-header-and-protected-routes", "I-17-markdown-sanitize"]
      - slug: "I-26-profile-page"
        title: "feat(frontend): I-26 profile page"
        labels: ["type:feature", "area:frontend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-21-header-and-protected-routes"]

  - name: "Sprint 4 — QA/Test/CI/Release"
    milestone: "Sprint 4"
    due_on: 2026-07-31
    description: "Bruno + Playwright + k6 + 3 profile CI + Release v1.0"
    issues:
      - slug: "I-27-bruno-contract-suite-fork"
        title: "test(backend): I-27 bruno contract suite fork"
        labels: ["type:test", "area:backend", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-16-comment", "I-15-favorite", "I-14-article-detail-update-delete"]
      - slug: "I-28-playwright-e2e-fork"
        title: "test(frontend): I-28 playwright e2e fork"
        labels: ["type:test", "area:frontend", "priority:P0", "status:todo"]
        effort: "2d"
        blocked_by: ["I-26-profile-page", "I-25-article-detail-page"]
      - slug: "I-29-performance-k6-scenarios"
        title: "test(backend): I-29 performance k6 scenarios"
        labels: ["type:test", "area:backend", "priority:P1", "status:todo"]
        effort: "1d"
        blocked_by: ["I-16-comment"]
      - slug: "I-30-3-profile-ci-matrix"
        title: "chore(infra): I-30 3-profile ci matrix"
        labels: ["type:chore", "area:infra", "priority:P0", "status:todo"]
        effort: "1d"
        blocked_by: ["I-18-frontend-bootstrap", "I-01-project-bootstrap"]
      - slug: "I-31-coverage-gate-and-jacoco"
        title: "chore(backend): I-31 coverage gate and jacoco"
        labels: ["type:chore", "area:backend", "priority:P1", "status:todo"]
        effort: "0.5d"
      - slug: "I-32-readme-and-release-v1.0"
        title: "docs(docs): I-32 readme and release v1.0"
        labels: ["type:docs", "area:docs", "priority:P1", "status:todo"]
        effort: "0.5d"
        blocked_by:
          - "I-27-bruno-contract-suite-fork"
          - "I-28-playwright-e2e-fork"
          - "I-29-performance-k6-scenarios"
          - "I-30-3-profile-ci-matrix"
          - "I-31-coverage-gate-and-jacoco"
```

## 8. Open Questions

- **OQ-W-01**: Sprint 1·2 사이에 BE 이슈가 FE 이슈와 부분 병렬 가능한지? — 본 계획은 직렬. FE가 BE의 mock(MSW)에 의지하면 Sprint 2 후반부터 FE 시작 가능. /flow-bootstrap 후 결정.
- **OQ-W-02**: I-27 Bruno fork 또는 submodule? — fork(snapshot 잠금) 채택. submodule은 외부 변경 자동 추적이라 RISK-01 회피 어려움. 변경 사항 import 시 별 PR.
- **OQ-W-03**: I-28 Playwright 캐노니컬 9 spec을 1:1 fork할지, 본 프로젝트 사양에 맞춰 새로 작성할지? — fork 우선 + 차이 발견 시 별 ADR로 수정. 시각 차이(Bootstrap vs Tailwind)로 selector 변경 필요할 수 있음.
- **OQ-W-04**: Sprint 5 buffer를 사전 milestone으로 만들지 vs 발생 시 신설할지? — 사전 milestone 없이 RISK-12 발생 시 신설. sprint-bootstrap에는 미포함.
