---
doc_type: scaffolding
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-N-02, R-N-04, R-N-05, R-N-06, R-N-07, R-N-08]
  F-ID: []
  supersedes: null
---

# Conduit Backend (Java/Spring Boot) — Scaffolding

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — BE 디렉토리·DDD layered·3 profile·부팅 자산 |

## 1. 디렉토리 트리

```
backend/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle/
├── gradlew, gradlew.bat
├── gradle.lockfile
├── docker-compose.yml          # 루트(공유)에서 import 또는 본 폴더
├── Dockerfile
├── .env.dev.example
├── .env.stg.example
├── .env.prod.example
├── src/
│   ├── main/
│   │   ├── java/com/conduit/
│   │   │   ├── ConduitApplication.java
│   │   │   ├── auth/
│   │   │   │   ├── AuthService.java
│   │   │   │   ├── JwtService.java
│   │   │   │   ├── AuthFilter.java
│   │   │   │   └── PasswordEncoderConfig.java
│   │   │   ├── user/
│   │   │   │   ├── User.java
│   │   │   │   ├── UserRepository.java
│   │   │   │   ├── UserService.java
│   │   │   │   └── dto/
│   │   │   ├── profile/
│   │   │   ├── article/
│   │   │   │   ├── Article.java
│   │   │   │   ├── ArticleRepository.java
│   │   │   │   ├── ArticleService.java
│   │   │   │   ├── SlugGenerator.java
│   │   │   │   └── ArticleSpec.java
│   │   │   ├── favorite/
│   │   │   ├── comment/
│   │   │   ├── tag/
│   │   │   ├── markdown/
│   │   │   ├── web/
│   │   │   │   ├── UserController.java
│   │   │   │   ├── ProfileController.java
│   │   │   │   ├── ArticleController.java
│   │   │   │   ├── CommentController.java
│   │   │   │   ├── TagController.java
│   │   │   │   ├── GlobalExceptionHandler.java
│   │   │   │   ├── ResponseEnvelope.java
│   │   │   │   └── TraceIdFilter.java
│   │   │   └── config/
│   │   │       ├── SecurityConfig.java
│   │   │       ├── JpaConfig.java
│   │   │       └── CorsConfig.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-stg.yml
│   │       ├── application-prod.yml
│   │       ├── logback-spring.xml
│   │       └── db/migration/
│   │           ├── V1__user.sql
│   │           ├── V2__profile_follow.sql
│   │           ├── V3__article.sql
│   │           ├── V4__tag.sql
│   │           ├── V5__article_tag.sql
│   │           ├── V6__comment.sql
│   │           └── V7__favorite.sql
│   └── test/
│       ├── java/com/conduit/...        # 단위 + 통합
│       └── resources/
└── specs/api/openapi.yml               # fork(잠금)
```

## 2. 패키지 명명 규칙

- 루트: `com.conduit.<feature>.<layer>`
- feature: `auth`, `user`, `profile`, `article`, `favorite`, `comment`, `tag`, `markdown`, `web`, `config`
- layer: 명시적 X — 한 feature 안에 service/repository/entity/dto 평면 배치. 도메인 = 1 feature.
- 클래스: UpperCamelCase + suffix(`Service`, `Repository`, `Controller`, `Dto`, `Cmd`)
- 테스트: 단위 `<X>Test` (단위 = service/util), 통합 `<X>IT` (통합 = controller + DB)

## 3. 디자인 패턴 결정

- **선택 패턴**: **Layered + 경량 DDD (feature-package)**
- **이유**: 14개 모듈 중 BE 9개가 도메인 분명(auth/user/profile/article/...). 각 feature 안 service/repo/entity 평면 배치로 import 충돌 최소화. 도메인 간 horizontal coupling은 `*Service` 경계로만 (다른 feature의 Repository 직접 import 금지). 풀-DDD(aggregate root, value object 등)은 본 규모에서 과잉이라 *경량* 채택. Spring Boot 관용도 정합.

추가 패턴:
- **Specification (JPA)**: ArticleSpec으로 동적 필터 (tag·author·favorited).
- **Filter chain**: TraceIdFilter → AuthFilter → SecurityFilterChain → Controller.
- **Policy**: ArticlePolicy.canEdit, CommentPolicy.canDelete (도메인 권한).
- **Anti-corruption**: M-BE-MARKDOWN (commonmark/jsoup) 결과만 도메인 service에 전달.

## 4. 모듈 경계 (08-lld-module-spec와 fan-out)

| 08 모듈 ID | java 패키지 | 진입점 | 외부 노출 |
|---|---|---|---|
| M-BE-AUTH | `com.conduit.auth` | AuthFilter, JwtService, AuthService | login/register API + filter |
| M-BE-USER | `com.conduit.user` | UserService, UserRepository | (다른 service만 호출, 외부 API는 web을 통해) |
| M-BE-PROFILE | `com.conduit.profile` | ProfileService | /profiles/* |
| M-BE-ARTICLE | `com.conduit.article` | ArticleService, SlugGenerator | /articles/*, /articles/feed |
| M-BE-FAVORITE | `com.conduit.favorite` | FavoriteService | /articles/:slug/favorite |
| M-BE-COMMENT | `com.conduit.comment` | CommentService | /articles/:slug/comments/* |
| M-BE-TAG | `com.conduit.tag` | TagService | /tags |
| M-BE-MARKDOWN | `com.conduit.markdown` | MarkdownService | (article·comment에서 호출) |
| M-BE-WEB | `com.conduit.web` | 모든 *Controller, GlobalExceptionHandler, ResponseEnvelope, TraceIdFilter | 19 endpoints |

## 5. 빌드·실행

```bash
# 의존 설치
./gradlew dependencies

# 빌드
./gradlew clean build

# 테스트
./gradlew test                                          # 단위 + 통합 (Testcontainers)

# 로컬 부팅 (dev profile)
cp .env.dev.example .env.dev
export $(cat .env.dev | xargs)
./gradlew bootRun --args='--spring.profiles.active=dev'

# 로컬 부팅 (stg profile, 외부 DB 가정)
cp .env.stg.example .env.stg && vim .env.stg
export $(cat .env.stg | xargs)
./gradlew bootRun --args='--spring.profiles.active=stg'

# 로컬 부팅 (prod profile, 외부 DB 가정)
cp .env.prod.example .env.prod && vim .env.prod
export $(cat .env.prod | xargs)
./gradlew bootRun --args='--spring.profiles.active=prod'

# Docker (dev)
docker compose --profile dev up --build

# JAR 빌드
./gradlew bootJar
java -jar build/libs/conduit-api-0.1.0.jar --spring.profiles.active=prod
```

ready 신호: `Started ConduitApplication in N seconds` + 8080 포트 LISTEN.

## 6. 환경 변수 / 설정 분리

| 키 | dev | stg | prod | 노출 위치 |
| --- | --- | --- | --- | --- |
| `SPRING_PROFILES_ACTIVE` | `dev` | `stg` | `prod` | shell |
| `DB_URL` | `jdbc:postgresql://localhost:5432/conduit_dev` | `jdbc:postgresql://stg-db:5432/conduit_stg` | `jdbc:postgresql://prod-db:5432/conduit_prod` | application-{profile}.yml |
| `DB_USER` | `conduit` | `conduit_stg` | `conduit_prod` | .env.{profile} |
| `DB_PASSWORD` | `conduit` (dev only) | (secret manager 또는 .env.stg) | (secret manager) | .env.{profile} (커밋 금지) |
| `JWT_SECRET` | `dev_only_change_me_64_bytes_min_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | (secret) | (secret) | .env.{profile} (커밋 금지) |
| `JWT_EXPIRATION_HOURS` | `168` (7d) | `168` | `168` | application-{profile}.yml |
| `CORS_ALLOWED_ORIGINS` | `*` | `https://stg.example.com` | `https://app.example.com` | application-{profile}.yml |
| `LOG_LEVEL_ROOT` | `INFO` | `INFO` | `WARN` | logback-spring.xml |
| `LOG_LEVEL_CONDUIT` | `DEBUG` | `INFO` | `INFO` | logback-spring.xml |
| `SERVER_PORT` | `8080` | `8080` | `8080` | application.yml |

> 단일 환경 운영(stg=prod 공유) 비고: 본 프로젝트는 3 profile 독립 운영. stg/prod가 동일 인프라일 경우 CORS_ALLOWED_ORIGINS만 동기 + `.env.stg = .env.prod` symlink 가능 (현재 미적용).

## 7. 부팅 자산 (Runnability Assets)

| 자산 | 경로 (profile별) | 변경 trigger 이슈 유형 | 갱신 책임 |
| --- | --- | --- | --- |
| 환경 변수 템플릿 | `.env.dev.example`, `.env.stg.example`, `.env.prod.example` | env 키 추가/삭제 (config 이슈) | BE 담당 |
| 스키마 적용 (dev iteration) | `spring.jpa.hibernate.ddl-auto=update` (application-dev.yml) — Hibernate 자동 동기 | Entity 추가/변경 (모델 이슈) | BE 담당 |
| DB migrations (stg/prod release) | `src/main/resources/db/migrations/V{N}__*.sql` (flyway) | DDL 정식 변경 (release 이슈) | BE 담당 + 리뷰 |
| lockfile | `gradle.lockfile` | dependency 추가/upgrade | BE 담당 |
| 설치/seed scripts | `./gradlew dependencies` + `db/seed/V900__seed.sql` (optional, dev only) | 시드 데이터 변경 | BE 담당 |
| 부팅 명령 | dev: `./gradlew bootRun --args='--spring.profiles.active=dev'` / stg: `--spring.profiles.active=stg` / prod: `java -jar ... --spring.profiles.active=prod` | 명령 변경 시 LOCAL.md 동기 갱신 | BE 담당 + LOCAL.md 담당 |
| LOCAL.md | `<repo>/LOCAL.md` (newProject 루트 가이드) | 부팅 자산 변경 시 매 PR 동기 (ADR-0040) | 자산 변경 PR 작성자 |

ADR-0037 v1.1 + v1.2: dev `ddl-auto=update`로 빠른 iteration, stg/prod는 Flyway로 정식 migration. 두 흐름 분리.

## 8. 스타일링 솔루션

- **솔루션**: **N/A** (Backend-only — 스타일 시트 없음)
- **이유**: 본 패키지는 Java/Spring Boot REST API. UI/뷰 렌더 없음. 스타일링은 `12-scaffolding/react.md §8`에서 TailwindCSS 정본.
- **의존성**: N/A
- **entrypoint 적용**: N/A
- **디자인 토큰 매핑**: N/A — 10 Screen Design §3 토큰은 FE에서만 매핑.
