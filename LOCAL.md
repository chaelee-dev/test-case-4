# test-case-4 (Conduit / RealWorld 클론) — 로컬에서 켜기

> **목적**: 이 저장소를 처음 clone한 사람이 *이 파일 1개*만 따라 하면 dev/stg/prod 3 profile 모두 로컬에서 부팅 가능하도록 한다.
> **정본 위치**: 본 파일은 newProject 루트의 *유저 facing* 정본. 부팅 자산 *정의*의 SoT는 `docs/planning/12-scaffolding/java.md §7` (BE) + `docs/planning/12-scaffolding/react.md §7` (FE). 매 PR 동기 갱신(ADR-0037 v1.1 + ADR-0040).

---

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Spring Boot 3.4 (BE) + React 19 Vite (FE) + PostgreSQL 16 스택 적용 |

---

## 1. 사전 요구사항

- **언어/런타임**: **Java 21** (OpenJDK Temurin) + **Node.js 20 LTS+**
- **패키지 매니저**: Gradle wrapper (`./gradlew`) (BE), **pnpm 9+** (FE)
- **컨테이너**: Docker 24+, docker-compose v2 (PostgreSQL용)
- **DB**: **PostgreSQL 16** (docker-compose로 실행)
- **OS 가정**: macOS / Linux / WSL2

## 1.5 흔한 함정 — *사전* 안내

### 1.5.1 monorepo + root `.env.{profile}` cwd 미스매치

본 프로젝트는 `backend/` + `frontend/` 평면 monorepo 구조. profile env 파일은 각 패키지 폴더 안에 둠:
- `backend/.env.{dev,stg,prod}.example`
- `frontend/.env.{dev,stg,prod}.example`

**본 프로젝트 채택**: (a) **stack-native profile 설정**
- BE(Spring): `application-{profile}.yml` + `SPRING_PROFILES_ACTIVE=<profile>` 환경 변수 + `.env.{profile}`는 dotenv-style 로더 없이 셸 export로 주입 (`export $(cat .env.dev | xargs)`)
- FE(Vite): `.env.{profile}` 파일은 Vite가 `--mode <profile>`로 자동 로드 (`VITE_*` 접두만 빌드에 인라인)

### 1.5.2 ORM 최초 migration 부재

본 프로젝트는 Flyway 사용. 함정 회피:
- (1) **dev iteration**: `spring.jpa.hibernate.ddl-auto=update` (application-dev.yml) — Hibernate 자동 schema 동기
- (2) **stg/prod release**: `src/main/resources/db/migrations/V{N}__*.sql` — Flyway가 자동 적용 (Spring Boot 부팅 시)

dev에서도 Flyway가 항상 활성화돼 있으면 V1__user.sql 부재 시 빈 schema. 본 프로젝트는 dev에서 `ddl-auto=update`로 entity 우선, V1~V7는 처음부터 작성해 두어 두 흐름 동시 충족.

### 1.5.3 stg/prod 부팅용 정적 서버 가정 (SPA frontend)

FE는 SPA. stg/prod는 빌드 산출물 기반:
- 빌드: `pnpm build --mode <profile>` → `frontend/dist/`
- 실행: `pnpm preview --port <port>` (Vite 기본 preview)
- 별도 `serve`/`http-server` 설치 불필요

---

## 2. 처음 한 번 셋업 (Initial Setup)

```bash
# 1) clone
git clone <repo-url>
cd test-case-4

# 2) BE 의존성
cd backend
./gradlew dependencies
cd ..

# 3) FE 의존성
cd frontend
pnpm install
cd ..

# 4) PostgreSQL 컨테이너 (dev DB)
docker compose up -d postgres-dev

# 5) BE 환경 변수 — profile별 1벌씩
cp backend/.env.dev.example backend/.env.dev
cp backend/.env.stg.example backend/.env.stg
cp backend/.env.prod.example backend/.env.prod
# JWT_SECRET·DB_PASSWORD 등 시크릿을 실제 값으로 (각 profile 다른 값 권장)

# 6) FE 환경 변수
cp frontend/.env.dev.example frontend/.env.dev
cp frontend/.env.stg.example frontend/.env.stg
cp frontend/.env.prod.example frontend/.env.prod
# VITE_API_BASE_URL을 profile별로 조정

# 7) DB 스키마 적용 (dev profile, 최초 1회)
#    Spring Boot가 부팅 시 ddl-auto=update + Flyway V0~ 자동 적용
#    별도 명령 불필요 — 아래 8)·9) bootRun 시 첫 부팅 로그에서
#    `Flyway Community Edition ... by Redgate` + `Migrating schema "public" to version "X"` 확인

# 8) seed 데이터 (옵션, dev)
./gradlew bootRun --args='--spring.profiles.active=dev --seed=true'
# 또는 별도 V900__seed.sql 작성하면 Flyway가 자동 적용
```

---

## 3. Profile별 부팅 명령

> **profile 3분기 강제 (ADR-0037 v1.1)** — 매 PR에서 3 profile 모두 부팅 검증.

### 3.1 dev profile (로컬 개발)

```bash
# Terminal 1 — PostgreSQL dev
docker compose up -d postgres-dev

# Terminal 2 — BE
cd backend
export $(cat .env.dev | xargs)
./gradlew bootRun --args='--spring.profiles.active=dev'

# Terminal 3 — FE
cd frontend
pnpm dev --mode dev
```

- 기대 출력 (BE): `Started ConduitApplication in N seconds`, `Tomcat started on port(s): 8080`
- 기대 출력 (FE): `➜ Local: http://localhost:5173/`
- 환경 변수 출처: `backend/.env.dev` + `frontend/.env.dev`
- DB: `localhost:5432/conduit_dev`
- Hot reload: BE Spring DevTools O, FE Vite HMR O

### 3.2 stg profile (스테이징 — 로컬에서 stg 환경 흉내)

```bash
# Terminal 1 — PostgreSQL stg (또는 dev DB 재사용)
docker compose up -d postgres-stg

# Terminal 2 — BE
cd backend
./gradlew bootJar
export $(cat .env.stg | xargs)
SPRING_PROFILES_ACTIVE=stg java -jar build/libs/conduit-api-0.1.0.jar

# Terminal 3 — FE (빌드 + preview)
cd frontend
pnpm build --mode stg
pnpm preview --port 5174
```

- 기대 출력 (BE): `Started ConduitApplication ...`, port 8080
- 기대 출력 (FE): `➜ Local: http://localhost:5174/`
- 환경 변수 출처: `backend/.env.stg` + `frontend/.env.stg`
- DB: `localhost:5433/conduit_stg` (docker-compose 별 컨테이너)
- Hot reload: X (빌드 산출물)

### 3.3 prod profile (로컬에서 prod 환경 흉내)

```bash
docker compose up -d postgres-prod

cd backend
./gradlew bootJar
export $(cat .env.prod | xargs)
SPRING_PROFILES_ACTIVE=prod java -jar build/libs/conduit-api-0.1.0.jar

cd frontend
pnpm build --mode prod
pnpm preview --port 5175
```

- 기대 출력 (BE): `Started ConduitApplication ...`
- 기대 출력 (FE): `➜ Local: http://localhost:5175/`
- 환경 변수 출처: `backend/.env.prod` + `frontend/.env.prod`
- DB: `localhost:5434/conduit_prod`
- Hot reload: X

---

## 4. 부팅 자산 (Runnability Assets)

> 본 표는 `docs/planning/12-scaffolding/java.md §7` (BE) + `docs/planning/12-scaffolding/react.md §7` (FE)와 동기.

| 자산 | 경로 | 변경 trigger | 갱신 책임 |
|---|---|---|---|
| 환경 변수 템플릿 (BE) | `backend/.env.{dev,stg,prod}.example` | 새 env 변수 추가 | env 추가 PR |
| 환경 변수 템플릿 (FE) | `frontend/.env.{dev,stg,prod}.example` | 새 VITE_* 추가 | env 추가 PR |
| 스키마 적용 (dev iteration) | `backend/src/main/resources/application-dev.yml` `spring.jpa.hibernate.ddl-auto=update` | Entity 추가/변경 | 모델 변경 PR |
| DB migrations (stg/prod release) | `backend/src/main/resources/db/migrations/V{N}__*.sql` (flyway) | DDL 정식 변경 | DDL PR |
| lockfile (BE) | `backend/gradle.lockfile` | dependency 변경 | dep PR |
| lockfile (FE) | `frontend/pnpm-lock.yaml` | dependency 변경 | dep PR |
| 설치/seed scripts | BE: `./gradlew dependencies` + `V900__seed.sql` (optional) / FE: `pnpm install` | seed 변경 | seed PR |
| 부팅 명령 | 본 LOCAL.md §3 + `backend/build.gradle.kts` + `frontend/package.json scripts` | 명령 변경 | LOCAL.md sync PR |
| 컨테이너 정의 | `docker-compose.yml` (postgres-{dev,stg,prod}), `backend/Dockerfile`, `frontend/Dockerfile` | infra 변경 | infra PR |

---

## 5. 자주 발생하는 문제 (Troubleshooting)

### 5.1 포트 충돌 (`EADDRINUSE`)

```bash
lsof -i :8080  # BE
lsof -i :5173  # FE dev
lsof -i :5432  # PostgreSQL
```

### 5.2 환경 변수 누락 (`Could not resolve placeholder 'database.url'`)

해당 변수가 `backend/.env.{dev,stg,prod}.example` 3 벌 모두에 정의됐는지 확인. profile 동기 누락이 가장 흔한 패턴 (ADR-0037 v1.1).

### 5.3 DB 연결 실패

- PostgreSQL 컨테이너 실행 여부: `docker compose ps`
- profile별 DB URL 일치 여부: `backend/.env.{dev,stg,prod}` 안의 `DB_URL`
- 스키마 미적용 (dev): Spring Boot 부팅 로그에서 `Hibernate: create table ...` 또는 `Flyway ... Migrating schema "public" to version "X"` 확인. 둘 다 없으면 `spring.jpa.hibernate.ddl-auto`와 `spring.flyway.enabled` 설정 점검
- stg/prod 미적용: Flyway 자동 적용. 부팅 시 `Flyway Community Edition X.Y.Z by Redgate` + `Migrating schema "public" to version "X"` 로그 확인

### 5.4 monorepo cwd에서 `Could not resolve placeholder 'database.url'`

증상:
```
$ cd backend && ./gradlew bootRun
... Could not resolve placeholder 'database.url' ...
```

원인: backend cwd에서 직접 호출하면 `.env.dev`이 자동 로드되지 않음.

해결: 본 프로젝트 채택 (a) — Spring Boot 부팅 전 `export $(cat .env.dev | xargs)` 또는 IDE Run Configuration의 "Environment variables" 필드에 `.env.dev` 내용 채움. `--spring.profiles.active=<profile>`도 함께 지정.

### 5.5 Flyway 검증 실패 — `Validate failed: Detected applied migration not resolved locally`

원인: 이전 PR에서 작성한 V{N}__*.sql 파일을 누군가 삭제·이동했거나, 운영 DB에 적용된 migration 파일이 로컬에 없음.

해결:
1. 누락 파일 복원 (`git log -- 'src/main/resources/db/migrations/'`)
2. 그래도 불일치면 dev DB drop 후 재생성 (`docker compose down -v && docker compose up -d postgres-dev`)
3. stg/prod는 절대 drop 금지 — 별 hotfix PR로 누락 파일 회복

---

## 6. 외부 의존 (선택)

- **외부 의존**: **없음** (이미지 호스팅·이메일·OAuth 모두 비범위, 02 Feasibility §2.5 참조)
- **캐노니컬 RealWorld 슈트**: `specs/api/openapi.yml` + `specs/api/bruno/` (CI fork). 외부 호출 아님 — 본 BE를 대상으로 실행됨.

---

## 7. 본 문서 갱신 책임 (메타)

- **누가**: 부팅 자산을 변경하는 이슈의 PR 작성자
- **언제**: 같은 PR 안에서 갱신. 별 hotfix PR로 미루지 않음 (ADR-0037 §2.3)
- **검증**: AI 게이트 6번째 축이 부팅 자산 diff 여부 + 본 LOCAL.md 갱신 여부를 동시 확인. 한쪽만 변경 시 BLOCK
- **상위 SoT 동기**: 본 절차가 `docs/planning/12-scaffolding/java.md §7` + `react.md §7`과 다르면 `/docs-update` 검수에서 WARN
