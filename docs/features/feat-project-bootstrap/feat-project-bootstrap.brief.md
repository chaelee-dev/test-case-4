---
doc_type: feature-brief
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

# feat-project-bootstrap — Feature Brief

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Issue #1 (I-01 project bootstrap) |

## 1. 한 줄 의도

`backend/` 폴더에 Spring Boot 3.4 + Java 21 + Gradle + Flyway + docker-compose 골격을 구축해 `./gradlew bootRun --args='--spring.profiles.active=dev'` 명령으로 3 profile 모두 ready 신호가 뜨도록 한다.

## 2. 사용자 가치

본 이슈는 *내부 인프라*다. 직접 사용자 가치는 없지만 후속 Sprint 1 모든 BE 이슈(I-02~I-08)의 *전제*다. 본 이슈 PASS 전에는 다음 이슈 진입 불가.

## 3. 현재 상태 → 변경 후 상태

| 측면 | 현재 | 변경 후 |
| --- | --- | --- |
| 디렉토리 | `backend/` 부재 | `backend/` 생성 + Spring Boot 표준 구조 |
| 빌드 도구 | 없음 | Gradle 8 + Kotlin DSL + gradle.lockfile |
| Spring Boot | 없음 | 3.4.x + Java 21 |
| DB | 없음 | docker-compose `postgres-{dev,stg,prod}` 컨테이너 3종 |
| 마이그레이션 | 없음 | Flyway V0__baseline.sql + db/migrations/ 구조 |
| Profile 분리 | 없음 | application-{dev,stg,prod}.yml + .env.{dev,stg,prod}.example |
| 부팅 검증 | 없음 | `./gradlew bootRun` ready 신호 + healthcheck endpoint |
| LOCAL.md §3 | 명령만 정의 | 실 명령 동작 확인 (3 profile 모두) |

## 4. 모드 자동 감지 결과

- mode: **add**
- 근거: type:chore 라벨 + 신규 디렉토리(`backend/`) 추가 + 기존 코드 수정 0건 + UI 영향 없음 + 부정 시그널(bug/design/modify) 0건 → ADR-0032 규칙 4 기본값 add 적용

## 5. 영향 범위

- **신규**: `backend/` 폴더 전체 (~15 파일), `docker-compose.yml` (루트), `LOCAL.md` 일부 검증 갱신
- **변경**: 없음 (기존 파일 수정 없음)
- **위험 영역**: 향후 모든 BE 이슈가 본 골격에 의존 — 본 PR이 정확해야 후속 이슈가 깔끔하게 진행

## 6. 비목표

- BE 도메인 로직 (auth/user/article/...) — 후속 이슈에서
- FE 부트스트랩 — I-18에서 별 이슈
- CI 워크플로 — I-30에서 별 이슈
- 실제 도커 이미지 publish (Dockerfile 작성만)

## 7. Open Questions

- **OQ-FB-01**: gradle wrapper distribution `bin` vs `all`? — `bin` 채택 (다운로드 작음)
- **OQ-FB-02**: Java 21 vendor — Temurin vs Corretto? — Temurin (Spring Boot 권장)
- **OQ-FB-03**: PostgreSQL healthcheck interval? — 5s × 3 retries
