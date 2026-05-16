# {{PROJECT_NAME}} — 로컬에서 켜기

> **목적**: 이 저장소를 처음 clone한 사람이 *이 파일 1개*만 따라 하면 dev/stg/prod 3 profile 모두 로컬에서 부팅 가능하도록 한다.
> **정본 위치**: 이 파일은 newProject 루트의 *유저 facing* 정본. 부팅 자산 *정의*의 SoT는 `docs/planning/12-scaffolding/12-scaffolding.md` §7. 두 문서는 매 PR에서 동기 갱신된다(ADR-0037 v1.1 + ADR-0040).
> **진화 규칙**: 부팅 자산(`.env.{dev,stg,prod}.example`·migrations·lockfile·setup scripts·부팅 명령)이 변경되면 본 파일도 같은 PR에서 갱신. AI 게이트 6번째 축이 동기 누락을 BLOCK한다.

---

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | {{INIT_DATE}} | {{INIT_AUTHOR}} | 초안 — install.sh가 LOCAL.template.md를 카피해 생성. 첫 채움은 12-scaffolding §7 작성 직후. |
| v0.2-template | 2026-05-16 | yongtae.cho@bespinglobal.com | template 자체 보강 (test-case-3 PR #37·#38 회귀 흡수, ADR-0040 v1.1, **stack-agnostic**): §1.5 *사전* 함정 안내 박스 신설(monorepo+root .env / ORM 최초 migration / SPA 정적 서버 3종), §2 단계 4 push vs migrate init 분기, §3.2·3.3 실제 동작 stg/prod 명령 패턴, §5.3·5.4 cwd 함정 troubleshooting. **언어 일반화** — §1.5.1 해결 패턴 (a)~(d): Java/Spring `spring.profiles.active`·Python `python-dotenv`/Pydantic·Go `godotenv`·Node `dotenv-cli` 4개 동치 + symlink fallback. §1.5.2 ORM에 Prisma·TypeORM·SQLAlchemy·JPA(Hibernate)·Flyway·Liquibase 사례 포함. §3.2·3.3·5.4 예시도 Node와 Java 양 stack 명시. |
| v0.3-template | 2026-05-16 | yongtae.cho@bespinglobal.com | §4 부팅 자산 표 분리 (ADR-0037 v1.2 정합) — "DB migrations" 단일 행 → "스키마 적용 (dev iteration)" + "DB migrations (stg/prod release)" 2행. dev iteration용은 Prisma `db push`·TypeORM `synchronize`·Hibernate `ddl-auto`·SQLAlchemy `create_all`·Alembic `upgrade head` 류, stg/prod release용은 정식 migration 파일 디렉토리(prisma/migrations·flyway·alembic/versions). 두 흐름이 다른 자산임을 LOCAL.template와 scaffolding.schema 양쪽에서 명시. lockfile·설치/seed scripts·부팅 명령 예시도 Python(poetry/uv)·Java(gradle) 사례 추가. |

---

## 1. 사전 요구사항

> 본 절은 12-scaffolding §1 디렉토리 트리 + §2 패키지 명명 규칙에서 도출.

- **언어/런타임**: {{예: Node.js 20 LTS, Python 3.12, Java 21, ...}}
- **패키지 매니저**: {{예: pnpm 9, uv, gradle wrapper, ...}}
- **컨테이너 (선택)**: {{Docker 24+, docker-compose v2, ...}}
- **DB**: {{PostgreSQL 16, MySQL 8, SQLite, ...}}
- **OS 가정**: {{macOS / Linux / WSL2}}

---

## 1.5 흔한 함정 — *사전* 안내

> 본 절은 사후 troubleshooting(§5)이 아니라 **셋업 *전*에 한 번 읽어 미리 피하는** 함정 모음. test-case-3 PR #37·#38 회귀에서 도출 — 다음 newProject에서 같은 실패를 반복하지 않게 한다.

### 1.5.1 monorepo + root `.env.{profile}` cwd 미스매치

`.env.{dev,stg,prod}`을 project root에 두는 monorepo는 다음 함정에 노출됨:
- 워크스페이스 cwd(예: `backend/` · `services/api/`)에서 실행되는 도구(ORM CLI · 런타임 환경 변수 자동로드 등)는 **root env를 자동으로 로드하지 않는다**
- 결과: `Error: Environment variable not found: DATABASE_URL` 류 에러로 부팅 실패

**해결 패턴** (스택별로 1개 선택 — 본 newProject 채택 방식을 명시):

- (a) **build tool / 런타임의 profile-aware 설정 기능 활용** (스택 native, 가장 권장)
  - Java/Spring: `application-{profile}.yml` + `SPRING_PROFILES_ACTIVE=dev` (env 파일이 아니라 profile yml로 분리하는 게 Spring native 방식, 단일 또는 root 디렉토리 모두 OK)
  - Python(Poetry/uv): `python-dotenv` + 앱 시작 시 `load_dotenv("../.env.dev")` 또는 `pydantic-settings`의 `_env_file=...`
  - Go: `godotenv.Load("../.env.dev")` 명시 호출
  - Node: 아래 (b) 패턴 사용
- (b) **dotenv-cli 래핑** (Node monorepo 한정)
  - 각 워크스페이스 스크립트를 `dotenv -e ../.env.{profile} -- ...`로 감싼다 (`devDependencies: dotenv-cli@^7.x`). 예: `"dev": "dotenv -e ../.env.dev -- tsx watch src/server.ts"`
- (c) **monorepo 도구의 env-pass 옵션** (Node 한정)
  - Turborepo `passThroughEnv` · Nx `env` · pnpm `--filter` + root 셸 export 등
- (d) **워크스페이스별 .env symlink/카피** (스택 무관)
  - 추가 동기 부담은 있지만 도구·언어 비의존

본 프로젝트 채택: `{{(a)/(b)/(c)/(d) 중 1개 또는 N/A — 단일 패키지}}`

### 1.5.2 ORM 최초 migration 부재

`prisma migrate deploy` · `flyway migrate` · `liquibase update` 등 *운영용 migration 적용 명령*은 **기존 migration 파일만 적용**한다. 최초 부팅 시 `migrations/` 폴더가 비어 있으면 DB가 빈 상태로 남아 ready 신호는 떠도 실제 동작 안 함.

**해결 패턴** (두 흐름 분리):
- (1) **dev iteration용 빠른 스키마 동기** — Prisma: `db push --skip-generate` / TypeORM: `synchronize=true` / SQLAlchemy: `Base.metadata.create_all` / JPA(Hibernate): `spring.jpa.hibernate.ddl-auto=update` 또는 `create` — migration 파일 없이 schema → DB
- (2) **정식 migration 흐름의 최초 1회** — Prisma: `migrate dev --name init` / Flyway: `V1__init.sql` 작성 후 `flyway migrate` / Liquibase: `db.changelog-master.xml` 초기 작성 후 `update` — 이후 stg/prod에서 운영 migration 명령으로 적용

본 프로젝트 채택 — dev: `{{명령}}`, stg/prod: `{{명령}}`.

### 1.5.3 stg/prod 부팅용 정적 서버 가정 (SPA frontend 한정)

> 본 함정은 frontend가 SPA(React/Vue/Svelte 등)인 경우에만 해당. **Java/Spring + Thymeleaf · Django + 템플릿 · 단일 backend** 등 SSR/MPA 구조는 N/A.

frontend가 SPA인 경우 stg/prod는 *빌드 산출물* 기반. 다음 두 함정 흔함:
- `serve` · `http-server` 같은 별도 도구는 보통 **미설치** — `npm install -g serve` 강제는 newProject 사용자 부담 + 버전 불일치 위험
- `NODE_ENV=production` 같은 inline 셋팅은 다른 env 변수(API_URL 등)를 누락시킴 — `.env.{stg,prod}`를 명시 로드 권장 (§1.5.1 해결 패턴 적용)

**해결 패턴**: 빌드 도구가 기본 제공하는 preview 모드 사용 — `vite preview --port 4173` · `next start` · `astro preview` 등. backend는 §1.5.1의 채택 패턴으로 `.env.{stg,prod}` 로드 (Node: `dotenv -e .env.prod -- node dist/server.js` / Java: `SPRING_PROFILES_ACTIVE=prod java -jar app.jar` 등).

---

## 2. 처음 한 번 셋업 (Initial Setup)

```bash
# 1) clone
git clone <repo-url>
cd <repo-name>

# 2) 의존성 설치
{{설치 명령 — 예: pnpm install}}

# 3) 환경 변수 파일 준비 — profile별로 1벌씩
cp .env.dev.example .env.dev
cp .env.stg.example .env.stg
cp .env.prod.example .env.prod
# .env.{dev,stg,prod} 안의 시크릿(JWT_SECRET·DB_PASSWORD 등)을 실제 값으로 채움
# 각 profile별로 다른 값 사용 권장

# 4) DB 스키마 적용 (dev profile, 최초 1회)
{{최초 dev 셋업 명령 — 예: pnpm prisma:push:dev    # = prisma db push --skip-generate}}
# ⚠️ 흔한 함정: 'migrate deploy'·'flyway migrate' 류는 *기존 migration 파일만* 적용.
#    최초 부팅 시 migrations/ 비어 있으면 DB 빈 상태로 남음 (§1.5.2 참조).
#    dev iteration용은 'db push' 류, 정식 migration의 최초 1회는 별 명령으로 분리 권장.
# 정식 migration 흐름 시작 (최초 1회만, 이후엔 stg/prod에서 migrate 사용):
#   {{예: pnpm migrate:init    # = prisma migrate dev --name init}}

# 5) seed 데이터 (dev profile)
{{seed 명령 — 예: pnpm seed:dev    # monorepo는 dotenv -e ../.env.dev -- 래핑됨, §1.5.1}}
```

---

## 3. Profile별 부팅 명령

> **profile 3분기 강제 (ADR-0037 v1.1)** — 매 PR에서 3 profile 모두 부팅 검증된다. 본 절의 명령이 그대로 AI 게이트 6번째 축에서 실행된다.

### 3.1 dev profile (로컬 개발)

```bash
{{dev 부팅 명령 — 예: pnpm dev:local}}
```

- 기대 출력: `{{ready 신호 — 예: :3000 listening}}`
- 환경 변수 출처: `.env.dev`
- DB: `{{dev DB 위치 — 예: localhost:5432/myapp_dev}}`
- Hot reload: {{O / X}}

### 3.2 stg profile (스테이징 — 로컬에서 stg 환경 흉내)

```bash
# 빌드 → 실행 (stg는 빌드 산출물 기반, watch 모드 없음)
{{빌드 명령 — 예: pnpm build / ./gradlew build / poetry build}}
{{stg 실행 명령 — 예: pnpm start:stg / SPRING_PROFILES_ACTIVE=stg ./gradlew bootRun}}
# 동치 (본 newProject 채택 monorepo 패턴 — §1.5.1 참조. 아래는 Node 사례 예시):
#   {{backend — 예: pnpm --filter @app/backend start:stg    # Node: dotenv -e ../.env.stg -- node dist/server.js
#                                                          # Java: SPRING_PROFILES_ACTIVE=stg java -jar build/libs/app.jar}}
#   {{frontend 정적 (SPA만) — 예: pnpm --filter @app/frontend exec vite preview --port 4173}}
```

- 기대 출력: `{{ready 신호 — 예: :3000 listening, Accepting connections at http://localhost:4173}}`
- 환경 변수 출처: `.env.stg`
- DB: `{{stg DB 위치 — 또는 'dev DB 공유' 명시}}`
- Hot reload: 보통 X (빌드 산출물 기반)
- ⚠️ 흔한 함정 (§1.5.3 참조): `serve` 같은 별 정적 서버 미설치 / `NODE_ENV=staging`만 inline 셋팅 시 다른 env 누락 → 빌드 도구 기본 preview + `dotenv -e .env.stg` 권장
- **단일 환경 운영 시**: 본 절을 "N/A — stg=prod 공유 운영"으로 표기

### 3.3 prod profile (로컬에서 prod 환경 흉내)

```bash
{{빌드 명령 — 예: pnpm build / ./gradlew build}}
{{prod 실행 명령 — 예: pnpm start:prod / SPRING_PROFILES_ACTIVE=prod java -jar build/libs/app.jar}}
# 동치 (본 newProject 채택 monorepo 패턴 — §1.5.1 참조):
#   {{backend — Node 예: pnpm --filter @app/backend start:prod    # dotenv -e ../.env.prod -- node dist/server.js
#               Java 예: SPRING_PROFILES_ACTIVE=prod java -jar build/libs/app.jar}}
#   {{frontend 정적 (SPA만) — 예: pnpm --filter @app/frontend exec vite preview --port 4173}}
```

- 기대 출력: `{{ready 신호}}`
- 환경 변수 출처: `.env.prod`
- DB: `{{prod DB 위치 — 보통 별 인스턴스 권장}}`
- Hot reload: X (빌드 산출물)
- **단일 환경 운영 시**: N/A 표기

---

## 4. 부팅 자산 (Runnability Assets)

> 본 표는 `docs/planning/12-scaffolding/12-scaffolding.md` §7과 동기. 자산이 변경되면 양쪽 모두 갱신.

| 자산 | 경로 | 변경 trigger | 갱신 책임 |
|---|---|---|---|
| 환경 변수 템플릿 | `.env.{dev,stg,prod}.example` | 새 환경 변수 추가 | 변수를 도입한 이슈 |
| 스키마 적용 (dev iteration) | `{{예: backend/package.json scripts.prisma:push:dev / hibernate ddl-auto / SQLAlchemy create_all / Alembic upgrade head}}` | dev 환경 schema 변경 (빠른 iteration) | 모델 변경 이슈 |
| DB migrations (stg/prod release) | `{{예: backend/prisma/migrations/ · flyway/migrations · alembic/versions/ · db/migrations}}` | 운영 release용 migration 파일 작성·적용 | 운영 release 이슈 |
| lockfile | `{{pnpm-lock.yaml · poetry.lock · go.sum · gradle.lockfile 등}}` | 의존성 추가/변경 | 의존성 도입 이슈 |
| 설치/seed scripts | `{{예: package.json scripts.{setup,migrate,seed:dev,seed:stg,seed:prod} / build.gradle tasks.seed* / pyproject scripts.*}}` | seed 데이터 변경 | seed 변경 이슈 |
| 부팅 명령 | 본 LOCAL.md §3 + `{{빌드 도구 manifest의 dev/start scripts}}` | 명령 변경 | 명령 변경 이슈 |
| 컨테이너 정의 (선택) | `Dockerfile`·`docker-compose.{dev,stg,prod}.yml` | infra 변경 | infra 이슈 |

---

## 5. 자주 발생하는 문제 (Troubleshooting)

> newProject 도입 후 부팅 시 발견되는 문제를 *이슈 단위*로 본 절에 누적. AI 게이트 6번째 축이 부팅 실패를 BLOCK하지만, *해결 방법*은 본 절이 정본.

### 5.1 포트 충돌 (`EADDRINUSE`)

```bash
{{포트 사용 중 프로세스 확인 명령 — 예: lsof -i :3000}}
```

### 5.2 환경 변수 누락 (`X is required`)

해당 변수가 `.env.{dev,stg,prod}.example` 3 벌 모두에 정의됐는지 확인. profile 동기 누락이 가장 흔한 패턴.

### 5.3 DB 연결 실패

- DB 컨테이너 실행 여부: `docker compose ps`
- profile별 DB URL 일치 여부: `.env.{dev,stg,prod}` 안의 `DATABASE_URL`
- 스키마 미적용 (dev): `{{예: pnpm prisma:push:dev}}` (또는 정식 흐름 `{{예: pnpm migrate:init}}` — 최초 1회)
- stg/prod 미적용: `{{예: pnpm migrate}}` (기존 migration 파일만 적용)

### 5.4 monorepo cwd에서 `DATABASE_URL not found` (또는 다른 env 누락)

> §1.5.1 함정의 사후 발현 — 한 번 막혔다면 본 절로 빠르게 진단.

증상 (스택별 사례):
```
# Node + Prisma
$ cd backend && npx prisma migrate deploy
Error: Environment variable not found: DATABASE_URL.

# Java + Spring (유사 패턴)
$ cd backend && ./gradlew bootRun
... Could not resolve placeholder 'database.url' ...

# Python + SQLAlchemy
$ cd backend && python -m alembic upgrade head
... KeyError: 'DATABASE_URL' ...
```

원인: backend cwd에서 도구를 직접 호출하면 root `.env.{profile}`이 자동 로드되지 않음. backend 자체 env 설정이 없으니 변수 누락.

해결: **워크스페이스 cwd에서 빌드 도구·ORM CLI를 직접 호출하지 말 것**. 항상 root에서 §1.5.1 채택 패턴으로 호출 — 스크립트/run 명령이 root env를 명시 로드함.
- 채택 패턴 확인: `{{본 newProject 채택 패턴 (a)/(b)/(c)/(d)와 적용 위치를 명시}}`
  - 예 (Node + dotenv-cli): `backend/package.json scripts.prisma:*` 가 `dotenv -e ../.env.{profile} --` 로 래핑됐는지
  - 예 (Java + Spring): `SPRING_PROFILES_ACTIVE` env 또는 `--spring.profiles.active=` 플래그가 설정됐는지
  - 예 (Python + Pydantic settings): `Settings(_env_file="../.env.dev")` 등으로 root env 경로 명시했는지

### 5.5 (newProject별 추가 — 발견 시점에 본 절에 누적)

---

## 6. 외부 의존 (선택)

> 외부 서비스(Auth0·Stripe·S3 등) 또는 컨테이너 의존이 있으면 본 절에 셋업 절차 명시.

- {{서비스명}}: {{셋업 절차 또는 mock 사용 방법}}

---

## 7. 본 문서 갱신 책임 (메타)

- **누가**: 부팅 자산을 변경하는 이슈의 PR 작성자(에이전트 또는 사람)
- **언제**: 같은 PR 안에서 갱신. 별 hotfix PR로 미루지 않음 (ADR-0037 §2.3)
- **검증**: AI 게이트 6번째 축이 (a) 부팅 자산 diff 여부, (b) 본 LOCAL.md 갱신 여부를 동시 확인. 한쪽만 변경 시 BLOCK
- **상위 SoT 동기**: 본 절차가 12-scaffolding §7과 다르면 `/docs-update`가 정합 검수에서 WARN. 양쪽 동기가 우선
