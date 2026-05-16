---
doc_type: feature-contract
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

# feat-project-bootstrap — Change Contract

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Issue #1 |

## 0. 참조 정본 ID (Referenced-IDs)

| 종류 | 정본 위치 | 영향 ID |
| --- | --- | --- |
| R-ID (요구) | docs/planning/04-srs/04-srs.md | R-N-06 (3 profile 부팅) |
| F-ID (기능) | docs/planning/05-prd/05-prd.md | (none) — 인프라 골격, 직접 매핑 F 없음 |
| 영향 모듈 | docs/planning/07-hld/07-hld.md §1, docs/planning/08-lld-module-spec/08-lld-module-spec.md §1 | (전제) — 모든 BE 모듈 M-BE-*의 부트스트랩 인프라 |
| 영향 엔드포인트 | docs/planning/09-lld-api-spec/09-lld-api-spec.md | (none, 단 `/api/health` 헬스체크 endpoint 1건 신설) |
| 적용 컨벤션 절 | docs/planning/11-coding-conventions/11-coding-conventions.md, docs/planning/12-scaffolding/java.md | 11 §1·§3·§5 + 12-scaffolding/java.md §1·§5·§6·§7 전체 |

## 1. 변경 의도

agent-toolkit dogfooding의 Sprint 1 첫 이슈로서, RealWorld/Conduit 백엔드 골격을 토킷 컨벤션과 정합하게 구축한다. 본 골격은 후속 8개 Sprint 1 BE 이슈(I-02~I-08)와 9개 Sprint 2 BE 이슈(I-09~I-17), 그리고 Sprint 4 인프라 이슈(I-30, I-31)의 *전제*다.

## 2. Before / After

| 항목 | Before | After |
| --- | --- | --- |
| `backend/` 폴더 | 부재 | 존재 + Spring Boot 표준 구조 |
| `backend/build.gradle.kts` | 부재 | Spring Boot 3.4 + Java 21 + Flyway + 의존성 |
| `backend/settings.gradle.kts` | 부재 | rootProject.name = "conduit-api" |
| `backend/gradle.lockfile` | 부재 | lockfile 생성 (재현성) |
| `backend/src/main/java/com/conduit/ConduitApplication.java` | 부재 | @SpringBootApplication 진입점 |
| `backend/src/main/java/com/conduit/web/HealthController.java` | 부재 | GET /api/health → 200 + {"status":"ok"} |
| `backend/src/main/resources/application.yml` | 부재 | 공통 + spring.profiles.active=dev (기본) |
| `backend/src/main/resources/application-{dev,stg,prod}.yml` | 부재 | profile별 DB URL · CORS · log level |
| `backend/src/main/resources/db/migrations/V0__baseline.sql` | 부재 | 빈 baseline (`-- placeholder`) |
| `backend/src/main/resources/logback-spring.xml` | 부재 | JSON pattern + MDC traceId placeholder |
| `backend/.env.{dev,stg,prod}.example` | 부재 | DB_URL·DB_USER·DB_PASSWORD·JWT_SECRET 등 키 |
| `backend/Dockerfile` | 부재 | multi-stage (Gradle build → JRE runtime) |
| `docker-compose.yml` (루트) | 부재 | postgres-{dev,stg,prod} 컨테이너 3종 + 헬스체크 |
| `LOCAL.md` §3 | 명령만 명시 | 실 명령 동작 검증 (DoD에서) |

## 3. 호출자·의존자 (Call Sites)

| 위치 | 영향 | 조치 |
| --- | --- | --- |
| 후속 이슈 I-02 (jwt-and-security-config) | 본 골격에 SecurityConfig·JwtService 추가 의존 | 본 PR 머지 후 진입 가능 |
| 후속 이슈 I-03 (response-envelope-and-error-handling) | 본 골격에 GlobalExceptionHandler 추가 의존 | 본 PR 머지 후 진입 가능 |
| Sprint 1~4 모든 BE 이슈 | 동일 — 본 골격 위에 빌드 | 본 PR 머지 후 |
| Sprint 4 I-30 (3-profile-ci-matrix) | 본 PR의 application-{dev,stg,prod}.yml + docker-compose 사용 | I-30 시 application 파일 그대로 활용 |
| `docs/planning/12-scaffolding/java.md` | §1 디렉토리 트리·§5 빌드·§7 부팅 자산 표가 본 PR 결과를 가정 | 본 PR로 *문서 → 실 파일* 동기 (gap 해소) |
| `LOCAL.md` §3 부팅 명령 | 본 PR이 LOCAL.md 명령 실행 가능 상태로 만드는 *첫* 이슈 | LOCAL.md 갱신 없음 (이미 일반화돼 있음). DoD에서 명령 실행 검증만 |

## 4. Backward Compatibility

- Breaking: no — 신규 디렉토리만 추가. 기존 파일 수정 0건
- 마이그레이션 필요: no — 새 프로젝트라 사용자/데이터 없음. Flyway V0__baseline.sql은 placeholder만

## 5. Rollback 전략

- revert 가능: yes — git revert로 `backend/` 폴더 + `docker-compose.yml` 전체 제거 가능
- rollback 절차: 
  1. `git revert <merge-commit>` 또는 `git revert <merge-commit> -m 1`
  2. `docker compose down -v` (postgres 볼륨 제거 — 데이터 손상 위험 없음, dev/stg/prod 모두 빈 DB)
  3. 후속 이슈 I-02~ 진입 차단 상태로 회귀
- 데이터 손상 위험: 없음 — 본 이슈 머지 시점에 사용자 데이터·실 데이터 없음. Flyway V0는 placeholder 뿐. 향후 V1__user.sql 도입(I-02·I-04) 후의 rollback은 별 절차 필요.

## 6. 비목표

- 도메인 코드 (auth/article/...): I-02~I-17에서
- FE 부트스트랩: I-18에서
- CI 워크플로: I-30에서
- 운영 배포 (k8s manifest, secret manager 연동): 본 사이클 비범위
