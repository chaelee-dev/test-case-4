---
doc_type: coding-conventions
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-N-02, R-N-04, R-N-05, R-N-06, R-N-08]
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — Coding Conventions

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Java + TypeScript 양축 규약 |

## 1. 명명 규칙

| 항목 | 규칙 | 예 |
| --- | --- | --- |
| BE 패키지 | `com.conduit.<feature>.<layer>` (kebab 없음, all lowercase) | `com.conduit.article.service` |
| BE 클래스 | UpperCamelCase + suffix(Service/Controller/Repository/Entity/Dto/Cmd) | `ArticleService`, `LoginCmd`, `ArticleDto` |
| BE 메서드/필드 | lowerCamelCase | `createArticle`, `passwordHash` |
| BE 상수 | UPPER_SNAKE | `MAX_LIMIT = 100` |
| BE 테스트 | `<ClassUnderTest>Test` (단위) / `<Feature>IT` (통합) | `SlugGeneratorTest`, `ArticleCRUD_IT` |
| FE 디렉토리 | kebab-case | `src/components/article-card/` |
| FE React 컴포넌트 | UpperCamelCase | `ArticleCard.tsx`, `FavoriteButton.tsx` |
| FE 훅 | `use<...>` | `useAuth`, `useArticleList` |
| FE 변수/함수 | lowerCamelCase | `articles`, `fetchFeed` |
| FE 상수 | UPPER_SNAKE | `STORAGE_KEY_JWT` |
| FE 타입 | UpperCamelCase + suffix(Type/Dto/Schema) | `ArticleDto`, `LoginSchema` (zod) |
| 테스트 파일 | `<file>.test.ts(x)` (단위) / `<flow>.spec.ts` (E2E) | `auth-context.test.tsx`, `login.spec.ts` |
| DB 테이블 | snake_case 복수 | `articles`, `article_tags`, `favorites` |
| DB 컬럼 | snake_case | `created_at`, `password_hash` |
| 환경 변수 | UPPER_SNAKE + 스코프 prefix | `DB_URL`, `JWT_SECRET`, `VITE_API_BASE_URL` |
| Git 브랜치 | `<type>/<issue-id>-<slug>` | `feat/12-article-create` |
| 이슈 ID 표기 | `#12` (issue), `R-F-09`, `F-04` 본문 인용 | (관련 PR 본문에 포함) |

## 2. 에러 코드 PREFIX/SUFFIX

| 도메인 | PREFIX | 예 |
| --- | --- | --- |
| 인증 | `AUTH_` | `AUTH_INVALID_CREDENTIALS`, `AUTH_TOKEN_EXPIRED`, `AUTH_TOKEN_INVALID` |
| 사용자 | `USER_` | `USER_DUPLICATE_EMAIL`, `USER_DUPLICATE_USERNAME`, `USER_NOT_FOUND` |
| 프로필 | `PROFILE_` | `PROFILE_NOT_FOUND`, `PROFILE_SELF_FOLLOW` |
| 글 | `ARTICLE_` | `ARTICLE_NOT_FOUND`, `ARTICLE_FORBIDDEN`, `ARTICLE_TITLE_BLANK`, `ARTICLE_BODY_BLANK` |
| 댓글 | `COMMENT_` | `COMMENT_NOT_FOUND`, `COMMENT_FORBIDDEN`, `COMMENT_BODY_BLANK` |
| 좋아요 | `FAVORITE_` | (대부분 idempotent라 별 코드 적음) |
| 태그 | `TAG_` | (현재 미사용) |
| 페이지네이션 | `PAGE_` | `PAGE_OFFSET_NEGATIVE`, `PAGE_LIMIT_OUT_OF_RANGE` |
| 일반 | `SERVER_` | `SERVER_INTERNAL` |

- 에러 코드는 GlobalExceptionHandler 매핑 키. API 응답 `errors` 본문에는 *사용자 친화 메시지*만 노출 (캐노니컬 사양 정합). 에러 코드 자체는 logback MDC `errorCode`로만 출력.

## 3. 언어 관용구

### 3.1 Java

- **레코드 적극 활용**: DTO는 `public record UserDto(...)` 로. mutability 필요한 엔티티만 클래스.
- **var 사용**: 지역 변수에 한해 타입 명확할 때 사용 (`var users = repo.findAll();`)
- **Optional**: 반환만. 필드/파라미터로 사용 금지 (Effective Java).
- **null 안전**: `@NonNull` (Jakarta Validation) 어노테이션으로 명시. `Objects.requireNonNull`.
- **Stream**: 단순 변환·필터에. 복잡한 reduce는 for-loop로 가독성 우선.
- **Switch 표현식**: enum / sealed 분기에 적극 사용.
- **try-with-resources**: 모든 AutoCloseable.

### 3.2 TypeScript / React

- **함수형 컴포넌트만** — class 컴포넌트 금지.
- **훅 규칙**: 최상위에서만, 조건문 안 금지 (React 룰).
- **`any` 금지** — 명확하지 않으면 `unknown` + 좁히기.
- **as 캐스팅** 최소화 — zod 등 런타임 검증으로 대체.
- **immutable**: state 갱신은 새 객체로 (`setUser({...user, bio: '...'})`)
- **early return**: 가드 절 우선.
- **prop drilling 3단 초과 시 Context** — 4단부터 자동 BLOCK 권고.
- **side-effect는 useEffect 또는 이벤트 핸들러**.

## 4. 주석 정책

- **기본은 주석 0줄** — 잘 명명된 식별자가 우선. `// fetches user` 같은 자명한 주석 금지.
- 다음 경우에만 주석 작성:
  1. **WHY가 비자명한 경우**: 외부 사양·이슈 번호 참조 (`// RealWorld spec: Token header (Bearer 아님)`)
  2. **워크어라운드**: 라이브러리 버그 등 (`// workaround: jsoup 1.17 strips data: URLs in Safelist`)
  3. **숨은 제약**: 트랜잭션/락 순서 (`// MUST run before slug check to avoid race`)
- **TODO/FIXME**: 이슈 번호 필수 `// TODO(#42): handle empty tagList`
- **JavaDoc**: public API에만. private/internal은 작성 금지.
- **`/** ... */` JSDoc**: FE export 타입만. 일반 함수는 작성 금지.
- **변경 이력**: 파일 헤더 주석 금지 (git blame이 정본).

## 5. Lint·포맷

| 도구 | 룰셋 | 자동 강제 |
| --- | --- | --- |
| **Spotless** (BE) | `googleJavaFormat 1.22+ AOSP` + `removeUnusedImports` + `formatAnnotations` | `./gradlew spotlessCheck` (PR CI) + `spotlessApply` (로컬) |
| **Checkstyle** (BE) | Google Checks 변형 (max line 120, 4-space indent) | `./gradlew check` |
| **ErrorProne** (BE) | default + Conduit custom | `./gradlew build` |
| **Prettier** (FE) | print-width 100, tabs=2, single quotes, trailing comma | `pnpm format:check` (PR CI) + lint-staged pre-commit |
| **ESLint** (FE) | `eslint:recommended` + `@typescript-eslint/strict` + `react-hooks/recommended` + `jsx-a11y/recommended` | `pnpm lint` (CI) |
| **EditorConfig** (공통) | LF, UTF-8, 2-space (FE/Markdown), 4-space (Java) | `.editorconfig` |
| **commit-lint** (공통) | Conventional Commits (feat/fix/chore/docs/test/refactor) | `commitlint.config.js` + husky |

자동 강제 = CI에서 실패 시 PR 머지 차단. PR 제출 전 `./gradlew spotlessApply && pnpm format` 권고.

## 6. Import 정책

### 6.1 Java

순서 (`Spotless`가 자동 강제):
1. `java.*`
2. `javax.*`, `jakarta.*`
3. `org.*`
4. `com.*` (외부)
5. `com.conduit.*` (내부)
6. 정적 import (마지막)

각 그룹 사이 공백 1줄. `*` wildcard 금지 (5개 초과 시도 individual).

### 6.2 TypeScript

순서 (ESLint `import/order`가 자동 강제):
1. Node built-in
2. 외부 패키지 (`react`, `ky`, `zod`)
3. 내부 alias (`@/api`, `@/components`)
4. 상대 경로 (`./`, `../`)
5. 스타일/asset (`./styles.css`)

상대 import 깊이 3단 초과 금지 (`../../../`) — alias로 대체.

순환 의존 금지 (`eslint-plugin-import` 자동 감지).
