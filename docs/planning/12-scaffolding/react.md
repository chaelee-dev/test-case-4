---
doc_type: scaffolding
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-F-18, R-F-19, R-F-20, R-F-21, R-F-22, R-F-23, R-F-24, R-F-25, R-F-26, R-F-27, R-N-03]
  F-ID: []
  supersedes: null
---

# Conduit Frontend (React/Vite) — Scaffolding

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — FE 디렉토리·FSD·3 profile·TailwindCSS 토큰 매핑 |

## 1. 디렉토리 트리

```
frontend/
├── package.json
├── pnpm-lock.yaml
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.ts
├── postcss.config.js
├── .env.dev.example
├── .env.stg.example
├── .env.prod.example
├── Dockerfile
├── index.html
├── public/
├── src/
│   ├── main.tsx                   # entrypoint — import './styles/index.css'
│   ├── App.tsx                    # 라우터 + 전역 Provider
│   ├── styles/
│   │   ├── index.css              # @tailwind base/components/utilities + tokens
│   │   └── tokens.css             # CSS variables (10 §3 매핑 정본)
│   ├── lib/
│   │   ├── api/
│   │   │   ├── client.ts          # ky 인스턴스 + 401 인터셉터
│   │   │   ├── schemas.ts         # zod
│   │   │   └── endpoints/
│   │   │       ├── users.ts
│   │   │       ├── profiles.ts
│   │   │       ├── articles.ts
│   │   │       ├── comments.ts
│   │   │       └── tags.ts
│   │   ├── auth/
│   │   │   ├── AuthContext.tsx
│   │   │   ├── useAuth.ts
│   │   │   └── storage.ts
│   │   └── markdown/
│   │       └── MarkdownView.tsx
│   ├── components/                # M-FE-COMPONENTS
│   │   ├── header/
│   │   ├── article-card/
│   │   ├── favorite-button/
│   │   ├── follow-button/
│   │   ├── pagination/
│   │   ├── error-list/
│   │   ├── tag-input/
│   │   └── spinner/
│   ├── pages/                     # M-FE-PAGES
│   │   ├── home/
│   │   ├── login/
│   │   ├── register/
│   │   ├── settings/
│   │   ├── editor/
│   │   ├── article/
│   │   └── profile/
│   ├── routes/
│   │   ├── router.tsx
│   │   └── ProtectedRoute.tsx     # 보호 라우트 (R-F-26)
│   └── test/
│       ├── setup.ts
│       └── msw/
│           ├── handlers.ts
│           └── server.ts
├── tests/e2e/                     # Playwright (or fork 캐노니컬)
│   ├── playwright.config.ts
│   └── specs/
└── specs/api/openapi.yml          # symlink → backend/specs/api/openapi.yml
```

## 2. 패키지 명명 규칙

- 디렉토리: kebab-case (`article-card`, `favorite-button`)
- React 컴포넌트 파일: UpperCamelCase (`ArticleCard.tsx`)
- 훅: `use<...>.ts` (`useAuth.ts`)
- 테스트: `<file>.test.tsx` (단위/통합) / `<flow>.spec.ts` (E2E Playwright)
- 일반 모듈: lowerCamelCase (`storage.ts`, `slugify.ts`)
- alias: `@/*` → `src/*` (tsconfig.json `paths`)
- export: 디폴트 X — named export 강제 (tree-shaking + grep 친화)

## 3. 디자인 패턴 결정

- **선택 패턴**: **FSD (Feature-Sliced Design) 변형** + Atomic 요소
- **이유**: 9 페이지·14 모듈을 *layer × slice* 매트릭스로 정리. layer = `pages / components / lib(api·auth·markdown) / routes`. slice = 도메인(article·user·profile·comment·tag). FSD의 단방향 의존(pages → components → lib)으로 순환 import 자동 차단. Atomic은 components 내부 분류(atoms 없이 molecules·organisms만 활용).

추가 패턴:
- **Context + Hook (Auth)**: `<AuthProvider>` + `useAuth()` — Redux 미사용 (규모 과잉).
- **데이터 페치**: 페이지 컴포넌트 `useEffect` + 자체 state. React Query는 본 규모에 과잉이라 비채택 (단, MSW 사용은 유지).
- **검증**: zod 스키마 (`@/lib/api/schemas`) + react-hook-form resolver.
- **에러 경계**: 페이지 단위 `<ErrorBoundary>` + fallback `<ErrorPage>`.

## 4. 모듈 경계 (08-lld-module-spec와 fan-out)

| 08 모듈 ID | 폴더 | 진입점 | 외부 노출 |
|---|---|---|---|
| M-FE-AUTH | `src/lib/auth/` + `src/pages/login`, `src/pages/register` | `<AuthProvider>`, `useAuth()` | 전역 hook |
| M-FE-PAGES | `src/pages/` (9 폴더) | router에서 lazy import | 라우트 진입점 |
| M-FE-COMPONENTS | `src/components/` (8 폴더) | export <ComponentName> | 모든 페이지에서 import |
| M-FE-API | `src/lib/api/` | `apiClient`, `endpoints.*` | 페이지에서 호출 |
| M-FE-MARKDOWN | `src/lib/markdown/` | `<MarkdownView>` | Article 페이지 / 미리보기 |

import 방향: `pages` → `components` → `lib`. 역방향 금지 (ESLint `import/no-restricted-paths`).

## 5. 빌드·실행

```bash
# 의존 설치
pnpm install

# 타입 체크
pnpm tsc --noEmit

# Lint + Format
pnpm lint && pnpm format:check

# 단위 + 통합 테스트 (Vitest + MSW + RTL)
pnpm test

# E2E (Playwright)
pnpm e2e

# 로컬 부팅 (dev profile)
cp .env.dev.example .env.dev
pnpm dev --mode dev          # → http://localhost:5173

# 로컬 부팅 (stg profile, 빌드 + preview 또는 stg API 연결)
cp .env.stg.example .env.stg
pnpm build --mode stg && pnpm preview --port 5174

# 로컬 부팅 (prod profile)
cp .env.prod.example .env.prod
pnpm build --mode prod && pnpm preview --port 5175

# 프로덕션 정적 자산 빌드
pnpm build --mode prod        # → dist/
```

ready 신호: Vite ` ➜ Local: http://localhost:5173/` 메시지 + 200 응답.

## 6. 환경 변수 / 설정 분리

| 키 | dev | stg | prod | 노출 위치 |
| --- | --- | --- | --- | --- |
| `VITE_API_BASE_URL` | `http://localhost:8080/api` | `https://stg.example.com/api` | `https://app.example.com/api` | `.env.{profile}` (Vite는 VITE_* 접두만 빌드에 인라인) |
| `VITE_APP_NAME` | `Conduit (dev)` | `Conduit (stg)` | `Conduit` | `.env.{profile}` |
| `VITE_DEMO_MODE` | `false` | `false` | `false` | `.env.{profile}` |
| `NODE_ENV` | `development` | `production` | `production` | Vite 자동 |

> 비밀(secret) FE 노출 금지 — VITE_* 는 모두 클라이언트 번들에 인라인되어 누구나 봄. 비밀이 필요한 호출은 BE 프록시로.

## 7. 부팅 자산 (Runnability Assets)

| 자산 | 경로 (profile별) | 변경 trigger 이슈 유형 | 갱신 책임 |
| --- | --- | --- | --- |
| 환경 변수 템플릿 | `.env.dev.example`, `.env.stg.example`, `.env.prod.example` | `VITE_*` 키 추가/변경 (config 이슈) | FE 담당 |
| 스키마 적용 (dev iteration) | N/A (FE는 DB 직접 사용 안 함) | N/A | N/A |
| DB migrations (stg/prod release) | N/A (DB는 backend 패키지의 db/migrations) | N/A | N/A |
| lockfile | `pnpm-lock.yaml` | dependency 변경 (`pnpm add/upgrade`) | FE 담당 |
| 설치/seed scripts | `pnpm install` (frozen) | `pnpm` 메이저 변경 | FE 담당 |
| 부팅 명령 | dev: `pnpm dev --mode dev` / stg: `pnpm build --mode stg && pnpm preview --port 5174` / prod: `pnpm build --mode prod && pnpm preview --port 5175` | 빌드 옵션 변경 시 LOCAL.md 동기 | FE 담당 + LOCAL.md 담당 |
| LOCAL.md | `<repo>/LOCAL.md` (newProject 루트 가이드) | 부팅 자산 변경 시 매 PR 동기 (ADR-0040) | 자산 변경 PR 작성자 |

## 8. 스타일링 솔루션

- **솔루션**: **TailwindCSS 3.4+** (with CSS variables for design tokens)
- **이유**: ADR-0038 + 02 Feasibility §2.2 결정. utility-first + JIT으로 번들 작음. 캐노니컬 Bootstrap 4 시각 동등성보다 *디자인 토큰 명확성* 우선.
- **의존성** (frontend/package.json devDependencies):
  ```json
  {
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0",
    "@tailwindcss/typography": "^0.5.10",
    "@tailwindcss/forms": "^0.5.7"
  }
  ```
- **entrypoint 적용**: `src/main.tsx`에서 `import './styles/index.css'`. `index.css` 본문:
  ```css
  @import './tokens.css';
  @tailwind base;
  @tailwind components;
  @tailwind utilities;
  ```
- **디자인 토큰 매핑** (10 §3 → tailwind.config.ts):

| 10 §3 토큰 | TailwindCSS 위치 |
|---|---|
| Color `--c-primary` ~ `--c-warning` | `theme.extend.colors.primary/secondary/neutral/danger/success/warning` (CSS variable 참조) |
| Typography `--font-family-*` | `theme.extend.fontFamily.{base,mono}` |
| Typography scale `--font-size-*` | `theme.extend.fontSize.{xs,sm,base,lg,xl,2xl}` |
| Spacing `--space-*` | `theme.extend.spacing.{1,2,3,4,6,8,12}` (Tailwind 기본 + 추가) |
| Component primitives (Button/Input/Card/Tag/Tabs/ErrorList/Pagination) | `@layer components { .btn-primary {...} .input {...} ... }` in `index.css` |

CSS variables(`tokens.css`)은 다크 모드 향후 확장을 대비한 추상화. 본 사이클은 라이트만.
