---
doc_type: feature-plan
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: feature
related:
  R-ID: [R-N-06]
  F-ID: []
  supersedes: null
---

# feat-project-bootstrap — Implementation Plan

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Issue #1 commit DAG |

## 1. 커밋 시퀀스 (DAG)

| # | 커밋 | 영향 파일 | 테스트 추가 | 회귀 위험 |
|---|---|---|---|---|
| C1 | chore(backend): scaffold gradle + spring boot bootstrap | backend/build.gradle.kts, settings.gradle.kts, gradle/wrapper/*, gradlew, gradlew.bat | gradle build syntax | 낮음 (신규 추가) |
| C2 | chore(backend): add application yml + 3 profile configs | backend/src/main/resources/application{,-dev,-stg,-prod}.yml | (해당없음 — config) | 낮음 |
| C3 | chore(backend): add ConduitApplication + health controller | backend/src/main/java/com/conduit/ConduitApplication.java, backend/src/main/java/com/conduit/web/HealthController.java | ConduitApplicationTest (smoke) | 낮음 |
| C4 | chore(backend): add flyway baseline + logback | backend/src/main/resources/db/migrations/V0__baseline.sql, backend/src/main/resources/logback-spring.xml | (Flyway 통합 검증은 I-04에서) | 낮음 |
| C5 | chore(backend): add Dockerfile + env templates | backend/Dockerfile, backend/.dockerignore, backend/.env.{dev,stg,prod}.example | (Dockerfile은 빌드 아닌 lint) | 낮음 |
| C6 | chore(infra): add docker-compose with 3 postgres containers | docker-compose.yml (루트) | (compose validate) | 낮음 |
| C7 | chore(backend): generate gradle.lockfile | backend/gradle.lockfile | (재현성 lockfile) | 낮음 |

총 7 커밋. 모두 chore(backend) 또는 chore(infra). 각 커밋 메시지 끝에 `#1` 명시 (sprint-bootstrap이 PR 본문 Closes #1 처리).

## 2. 의존성 그래프

```
C1 (gradle skeleton)
   │
   ▼
C2 (application yml × 4)
   │
   ▼
C3 (ConduitApplication + Health)
   │
   ├──▶ C4 (Flyway baseline + logback)
   │       │
   │       ▼
   │     C5 (Dockerfile + env templates)  ← parallel OK
   │
   └──▶ C6 (docker-compose)  ← parallel after C2+C3
              │
              ▼
            C7 (gradle.lockfile, depends on all preceding)
```

C1 → C2 → C3 직선. C4/C5/C6 부분 병렬. C7 마지막 (모든 dependency 확정 후 generation).

## 3. 테스트 매핑

| 커밋 | 테스트 추가 위치 | 시나리오 |
|---|---|---|
| C1 | (해당없음) | `./gradlew build --dry-run`만 sanity check |
| C2 | (해당없음) | yml 문법 검증은 Spring Boot 부팅 시 검증 |
| C3 | backend/src/test/java/com/conduit/ConduitApplicationTest.java | Spring context loads + GET /api/health 200 + body 검증 |
| C4 | (Flyway 통합 테스트는 I-04에서) | C4는 placeholder만, V1+ 통합은 후속 이슈 |
| C5 | (Dockerfile lint, hadolint 옵션) | 본 사이클 미적용 |
| C6 | (compose syntax는 `docker compose config` 검증) | DoD에서 수동 검증 |
| C7 | (해당없음 — generated artifact) | gradle.lockfile diff는 PR review 시 점검 |

총 1개 테스트 클래스 `ConduitApplicationTest` 추가. ADR-0023 결정: 단위 `N/A` (smoke 통합으로 충분), 통합 `✅`, E2E `N/A` (헬스체크만)

## 4. 빌드·실행 검증 단계

```bash
# 단계 1 — Gradle 빌드 sanity
cd backend
./gradlew clean build --refresh-dependencies
# 기대: BUILD SUCCESSFUL + ConduitApplicationTest PASS

# 단계 2 — 단위/smoke 테스트 명시 실행
./gradlew test
# 기대: ConduitApplicationTest > contextLoads() PASS

# 단계 3 — docker-compose 검증
cd ..
docker compose config
# 기대: 3개 postgres-{dev,stg,prod} 서비스 YAML 파싱 통과
docker compose up -d postgres-dev
docker compose ps
# 기대: postgres-dev healthy

# 단계 4 — dev profile 부팅 (수동 검증)
cd backend
cp .env.dev.example .env.dev
export $(cat .env.dev | xargs)
./gradlew bootRun --args='--spring.profiles.active=dev' &
sleep 30
curl -sf http://localhost:8080/api/health | jq .
# 기대: {"status":"ok"} 응답 + 로그에 "Started ConduitApplication"

# 단계 5 — stg/prod profile 동일 검증 (반복)
cp .env.stg.example .env.stg
docker compose up -d postgres-stg
./gradlew bootRun --args='--spring.profiles.active=stg' &
# (헬스체크 200 + ready 로그 확인)

cp .env.prod.example .env.prod
docker compose up -d postgres-prod
SPRING_PROFILES_ACTIVE=prod java -jar build/libs/conduit-api-0.1.0.jar &
# (헬스체크 200 + ready 로그 확인)
```

CI 통과 = 단계 1 + 단계 2 (단계 3~5는 본 사이클은 수동 검증, I-30에서 CI matrix 자동화).

## 5. 점진 합의 / 결정 발생 항목

- ADR 작성 필요: no — 기존 12-scaffolding §1~§7 결정사항을 실 파일로 *반영*하는 작업. 새로운 결정 없음
- 결정 보류 (후속 이슈에서):
  - Spring Boot 정확 버전 pin (3.4.0 vs 3.4.x latest): 3.4.5 채택 (안정 minor)
  - Java release target: 21 (LTS) — 06 Architecture §Stack Decision 그대로
  - Flyway baseline은 "버전 마커"만 — V1__user.sql은 I-04에서 작성
