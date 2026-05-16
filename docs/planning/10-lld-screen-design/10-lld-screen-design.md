---
doc_type: screen-design
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-F-19, R-F-20, R-F-21, R-F-22, R-F-23, R-F-24, R-F-25, R-F-26]
  F-ID: [F-01, F-02, F-03, F-04, F-05, F-06, F-07, F-08, F-09]
  supersedes: null
---

# Conduit (RealWorld 클론) — Screen Design (LLD — UI)

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 9 화면 + 디자인 토큰 4종 BLOCK |

## 1. 화면 인벤토리

| ID | 화면명 | 진입 트리거 | F-ID 매핑 |
|---|---|---|---|
| S-01 | Home | `/` 방문 | F-05, F-09 |
| S-02 | Login | `/login` 방문 / 헤더 "Sign in" 클릭 | F-01, F-09 |
| S-03 | Register | `/register` 방문 / 헤더 "Sign up" 클릭 | F-01, F-09 |
| S-04 | Settings | `/settings` 방문 / 헤더 "Settings" 클릭 | F-02, F-09 |
| S-05 | Editor (New) | `/editor` 방문 / 헤더 "New Article" 클릭 | F-04, F-09 |
| S-06 | Editor (Edit) | `/editor/:slug` 방문 / 글 상세 "Edit Article" 클릭 | F-04, F-09 |
| S-07 | Article | `/article/:slug` 방문 / 글 카드 클릭 | F-06, F-07, F-08 |
| S-08 | Profile (My Articles) | `/profile/:username` 방문 / 헤더 username 클릭 | F-03 |
| S-09 | Profile (Favorited) | `/profile/:username/favorites` 방문 / Profile 페이지 탭 클릭 | F-03 |

## 2. 화면 상세

### S-01: Home

- 목적: 글로벌·내 피드 탐색, 인기 태그 발견
- 상태:
  - **익명**: Banner 표시, Feed 탭 = "Global Feed"만 활성, 글 카드 + 페이지네이션, 사이드바 인기 태그
  - **로그인**: Banner 표시(또는 미표시 옵션), Feed 탭 = "Your Feed"(기본 활성) + "Global Feed"
  - **태그 클릭**: "# tagname" 탭이 동적으로 추가되고 활성, 다른 탭은 비활성
  - **로딩**: 스피너
  - **에러**: ErrorList + 재시도 버튼
  - **빈 결과**: "No articles are here ... yet."
- F-ID 매핑: F-05, F-09
- 컴포넌트: Header / Banner / FeedTabs / ArticleCard × N / Pagination / PopularTagsSidebar
- 레이아웃 (데스크탑):
  ```
  ┌────────────── Header ──────────────┐
  │           Banner (#5cb85c)         │
  ├──────────────────────────────┬─────┤
  │ [Your Feed][Global Feed]     │     │
  │ ArticleCard                  │ Pop │
  │ ArticleCard                  │ Tags│
  │ ...                          │     │
  │ Pagination 1 2 3 ...         │     │
  └──────────────────────────────┴─────┘
  ```

### S-02: Login

- 목적: 기존 사용자 인증
- 상태:
  - **빈 폼**: email + password + Submit
  - **검증 에러**: 폼 상단 ErrorList (`<ul>`)
  - **로딩**: Submit 버튼 disabled + 스피너
  - **성공**: navigate('/')
- F-ID 매핑: F-01
- 컴포넌트: AuthForm(email, password) / ErrorList / SubmitButton / LinkToRegister

### S-03: Register

- 목적: 신규 회원가입
- 상태:
  - **빈 폼**: username + email + password + Submit
  - **검증 에러**: ErrorList
  - **로딩**: disabled + 스피너
  - **성공**: navigate('/')
- F-ID 매핑: F-01
- 컴포넌트: AuthForm + ErrorList + SubmitButton + LinkToLogin

### S-04: Settings

- 목적: 내 정보 수정 + 로그아웃
- 상태:
  - **빈 폼**: image URL · username · bio(textarea) · email · 새 password
  - **변경 후**: Update Settings 활성화
  - **로딩**: disabled + 스피너
  - **에러**: ErrorList
  - **로그아웃**: Logout 버튼 (빨강) → 토큰 제거 + navigate('/')
- F-ID 매핑: F-02
- 컴포넌트: SettingsForm + ErrorList + UpdateButton + LogoutButton

### S-05: Editor (New)

- 목적: 새 글 작성
- 상태:
  - **빈 폼**: title + description + body(textarea, markdown) + tagList(TagInput)
  - **태그 입력 중**: Enter 또는 Tab으로 칩 추가
  - **검증 에러**: ErrorList
  - **로딩**: Publish disabled + 스피너
  - **성공**: navigate('/article/:slug')
- F-ID 매핑: F-04
- 컴포넌트: ArticleForm + TagInput + ErrorList + PublishButton

### S-06: Editor (Edit)

- 목적: 본인 글 수정
- 상태:
  - **로딩 중(prefill)**: 폼 disabled + 스피너
  - **prefill 완료**: 기존 값으로 채워짐
  - **변경**: Update Article 활성화
  - **저장 중**: 스피너
  - **성공**: navigate('/article/:slug')
  - **타인 글 진입**: ErrorPage 또는 navigate('/')
- F-ID 매핑: F-04
- 컴포넌트: 동일 (mode 분기)

### S-07: Article

- 목적: 글 상세 + 마크다운 + 좋아요 + 팔로우 + 댓글
- 상태:
  - **로딩**: 스피너
  - **익명**: Follow/Favorite 버튼 비활성(or 클릭 시 로그인 안내), 댓글 폼 미노출
  - **로그인 / 비저자**: Follow/Favorite 활성, 댓글 폼 노출
  - **로그인 / 저자**: Edit/Delete 버튼 노출, 자기 댓글 🗑 표시
  - **삭제 확인**: 다이얼로그 (window.confirm)
  - **404**: NotFoundCard
- F-ID 매핑: F-06, F-07, F-08
- 컴포넌트: ArticleBanner(author·date) + FollowButton + FavoriteButton + EditDeleteActions + MarkdownView + TagPill × N + CommentForm + CommentList

### S-08: Profile (My Articles)

- 목적: 저자 헤더 + 본인이 쓴 글 목록
- 상태:
  - **로딩**
  - **본인 보기**: Edit Settings 버튼
  - **타인 보기**: Follow 버튼
  - **탭 활성 = "My Articles"**
  - **빈 결과**: "No articles are here ... yet."
- F-ID 매핑: F-03
- 컴포넌트: ProfileBanner + ProfileTabs + ArticleCard × N + Pagination

### S-09: Profile (Favorited)

S-08과 동일 구조, 탭만 "Favorited Articles" 활성. API는 `?favorited=<username>` 필터.

## 3. 디자인 시스템 / 토큰

### Color (ADR-0038 §3 BLOCK)

| 토큰 | 값 | 용도 |
|---|---|---|
| `--c-primary` | `#5cb85c` (Conduit green) | 주요 액션 버튼, 활성 탭, Banner |
| `--c-primary-hover` | `#4cae4c` | 버튼 hover |
| `--c-secondary` | `#373a3c` | 헤더 텍스트, 본문 강조 |
| `--c-neutral-bg` | `#ffffff` | 배경 |
| `--c-neutral-text` | `#373a3c` | 본문 텍스트 |
| `--c-neutral-muted` | `#aaaaaa` | 메타데이터·placeholder |
| `--c-border` | `#e5e5e5` | 카드·구분선 |
| `--c-danger` | `#b85c5c` | Delete·Unfavorite |
| `--c-success` | `#5cb85c` | 성공 알림 |
| `--c-warning` | `#f0ad4e` | 경고 |

primary·secondary·neutral 모두 정의됨.

### Typography

| 토큰 | 값 | 용도 |
|---|---|---|
| `--font-family-base` | `"source sans pro", sans-serif` | 본문 |
| `--font-family-mono` | `ui-monospace, monospace` | 코드·markdown code |
| `--font-size-xs` | `0.75rem` (12px) | 메타 |
| `--font-size-sm` | `0.875rem` (14px) | 보조 |
| `--font-size-base` | `1rem` (16px) | 본문 |
| `--font-size-lg` | `1.25rem` (20px) | 부제 |
| `--font-size-xl` | `2rem` (32px) | 페이지 헤딩 |
| `--font-size-2xl` | `2.75rem` (44px) | Banner 헤딩 |

scale 6단 (xs ~ 2xl).

### Spacing

| 토큰 | 값 | 용도 |
|---|---|---|
| `--space-1` | `0.25rem` (4px) | 미세 |
| `--space-2` | `0.5rem` (8px) | tight |
| `--space-3` | `0.75rem` (12px) | small |
| `--space-4` | `1rem` (16px) | base |
| `--space-6` | `1.5rem` (24px) | medium |
| `--space-8` | `2rem` (32px) | large |
| `--space-12` | `3rem` (48px) | section |

scale 7단.

### Component primitives

| 컴포넌트 | variants | 상태 |
|---|---|---|
| **Button** | primary·outline-primary·outline-secondary·danger·sm·lg | default·hover·active·disabled·loading |
| **Input** | text·email·password·textarea | default·focus·error·disabled |
| **Card** | article·comment·profile-banner | (정적) |
| **Tag pill** | default·active | default·hover |
| **Tabs** | feed·profile | active·inactive |
| **ErrorList** | (단일 변형) | (정적) |
| **Pagination** | (단일) | active page·disabled |

7종 ≥ 3 충족.

**12-scaffolding §8 매핑**: 위 4종 토큰은 모두 TailwindCSS `tailwind.config.ts` `theme.extend.colors|fontSize|spacing` + `@layer components`로 매핑된다. 자세한 매핑 표는 `12-scaffolding/react.md §8`.

## 4. 접근성

- **키보드 네비게이션**: 모든 버튼/링크/입력은 Tab 순회 가능. Editor 태그 입력은 Enter/Tab/comma 모두 칩 추가.
- **콘트라스트**: WCAG AA (4.5:1) — primary green on white 4.7:1 (OK), neutral muted #aaa는 메타에만 사용 (3:1 가능)
- **ARIA**: Header 메뉴 `<nav aria-label="primary">`, FavoriteButton `aria-pressed`, FollowButton `aria-pressed`, Pagination `<nav aria-label="pagination">`
- **포커스 표시**: `:focus-visible` outline (Tailwind default 활용)
- **이미지**: 모든 `<img>`에 alt (avatar는 username)
- **에러 전달**: ErrorList는 `role="alert"` 또는 `aria-live="polite"`
- **마크다운 출력 alt/lang**: react-markdown 기본 처리 + sanitize 후 검증

## 5. Open Questions

- **OQ-SD-01**: Banner를 로그인 사용자에게도 매번 보여줄지, dismiss 가능하게 할지? — 캐노니컬 매번 표시. 본 구현도 매번.
- **OQ-SD-02**: Profile 페이지에서 "Edit Settings" → `/settings` 이동 시 reload vs SPA navigate — SPA navigate 채택.
- **OQ-SD-03**: 다크 모드 지원 여부 — 본 사이클 비범위. 토큰 구조가 향후 확장 가능하게 CSS variable + Tailwind theme 분리.
- **OQ-SD-04**: 모바일 햄버거 메뉴 — 캐노니컬 미사용. 본 구현은 모바일에서 헤더 가로 스크롤 허용.
