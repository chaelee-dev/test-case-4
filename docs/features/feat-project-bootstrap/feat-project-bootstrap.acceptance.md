---
doc_type: feature-acceptance
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

# feat-project-bootstrap — Acceptance Criteria

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Issue #1 DoD |

## 1. 인수 기준 (Given/When/Then)

### AC-01: Gradle 빌드 PASS

- Given: 본 PR 머지 후 fresh checkout
- When: `cd backend && ./gradlew clean build --refresh-dependencies` 실행
- Then: BUILD SUCCESSFUL + ConduitApplicationTest > contextLoads() PASS + build/libs/conduit-api-0.1.0.jar 생성
- 측정 방법: 자동 테스트 (PR CI 또는 로컬)
- R-ID: R-N-06

### AC-02: dev profile 부팅 + 헬스체크

- Given: PostgreSQL dev 컨테이너 실행 중 + `.env.dev` 채워짐
- When: `./gradlew bootRun --args='--spring.profiles.active=dev'` 실행 후 30s 대기
- Then: 로그에 `Started ConduitApplication in N seconds` + `curl http://localhost:8080/api/health`가 200 + `{"status":"ok"}` 반환
- 측정 방법: 자동 테스트 (smoke 통합)
- R-ID: R-N-06

### AC-03: stg profile 부팅

- Given: PostgreSQL stg 컨테이너 실행 + `.env.stg` 채워짐
- When: `./gradlew bootJar && SPRING_PROFILES_ACTIVE=stg java -jar build/libs/conduit-api-0.1.0.jar` 실행 후 30s 대기
- Then: 로그에 ready 신호 + `/api/health` 200
- 측정 방법: 수동 확인 (I-30에서 CI matrix 자동화 예정)
- R-ID: R-N-06

### AC-04: prod profile 부팅

- Given: PostgreSQL prod 컨테이너 실행 + `.env.prod` 채워짐
- When: 동일 (SPRING_PROFILES_ACTIVE=prod)
- Then: ready + 헬스체크 200
- 측정 방법: 수동 확인 (I-30에서 자동화 예정)
- R-ID: R-N-06

### AC-05: gradle.lockfile 재현성

- Given: 본 PR의 backend/gradle.lockfile
- When: 다른 환경에서 `./gradlew dependencies --write-locks` 재실행
- Then: gradle.lockfile diff 0줄 (재현성 확인)
- 측정 방법: 자동 테스트 (CI에서 `git diff --exit-code backend/gradle.lockfile` 검증)
- R-ID: R-N-06

### AC-06: LOCAL.md §3 명령 동작

- Given: 본 PR 머지 후 fresh checkout + 본 README + LOCAL.md만 따라 함
- When: LOCAL.md §3.1 dev 부팅 명령을 순서대로 실행
- Then: 30분 이내 ready 신호 확인 (사용자 경험 검증)
- 측정 방법: 수동 확인 (이슈 close 시점 1회)
- R-ID: R-N-06

## 2. Definition of Done (D-06)

- [ ] AC-01 (gradle build) PASS — `./gradlew clean build`
- [ ] AC-02 (dev profile) PASS — bootRun + health 200
- [ ] AC-03 (stg profile) PASS — 수동 검증
- [ ] AC-04 (prod profile) PASS — 수동 검증
- [ ] AC-05 (lockfile 재현성) PASS — CI git diff 0
- [ ] AC-06 (LOCAL.md §3 명령) PASS — 사용자 입장 1회 reproducing
- [ ] 단위/통합/E2E 테스트 결정 명시 (ADR-0023): 단위 N/A, 통합 ✅ (ConduitApplicationTest), E2E N/A
- [ ] CI green (lint + format + build + test)
- [ ] PR 본문에 Test Plan 4블록 + `Closes #1`
- [ ] `tested` 라벨 부착 (D-06 2단 휴먼 게이트, AC-06 확인 후)
- [ ] reviewer 1+ Approve
- [ ] /docs-update: 12-scaffolding/java.md §1·§7 갱신 (실 파일 추가로 인한 동기 — 본 PR이 §1·§7과 정합)
- [ ] LOCAL.md sync 검증 (check-local-md-sync.sh 통과 또는 WARN 사유 명시)
- [ ] CHANGELOG.md §"Current Status"에 Issue #1 close 기록

## 3. 비기능 인수

- 부팅 시간: dev profile 30s 이내 ready (단일 사용자 로컬 dev DB)
- 메모리: bootRun 시 -Xmx 512MB 이하 (Spring Boot default OK)
- 빌드 시간: clean build 90s 이내 (fresh checkout)

## 4. 회귀 인수

- 본 이슈는 신규 골격. 기존 회귀 대상 없음
- 다만 후속 이슈 진입 가능 상태 확인:
  - I-02 jwt-and-security-config: 본 PR 머지 직후 진입 가능
  - I-09 article-domain-and-slug: I-02 머지 후 진입 가능
