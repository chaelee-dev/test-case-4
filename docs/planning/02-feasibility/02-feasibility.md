---
doc_type: feasibility
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: A
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — Feasibility

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — OQ-01·02·03 기술 스택 의사결정 1차 합의 |

## 1. 시장·환경 검토

- **RealWorld 생태계**: 2017년 시작, 현재까지 활발히 유지. 캐노니컬 OpenAPI는 2.0.0(2024+), Bruno/Hurl 테스트 슈트 + Playwright E2E가 모두 메인테이너에 의해 갱신됨. 외부 표준이 안정적이라 본 구현 기간 중 사양 변동 리스크는 낮음(RB-01).
- **유사 구현**: 150+ 구현이 codebaseshow.com에 등록. 본 구현은 *시각 동등성*보다 *agent-toolkit으로 만든 풀스택 reference*라는 차별점. 즉 시장은 "토킷 + 토킷 산출물" 양쪽을 동시에 평가한다.
- **데모 인프라**: `https://demo.realworld.build/` + `https://api.realworld.build/api`가 외부 호스팅됨. 본 프로젝트는 자체 호스팅을 목표로 하되, 초기 단계에서는 데모 API를 비교 baseline으로 활용 가능.
- **법·라이선스**: RealWorld는 MIT. 본 구현도 MIT로 배포 가능.

## 2. 기술 타당성

### 2.1 백엔드 스택 (OQ-01 결정)

| 후보 | 장 | 단 | 평 |
|---|---|---|---|
| **Spring Boot 3.4 + Java 21 + Gradle + JPA + PostgreSQL** (✅ 채택) | CLAUDE.md 기본값, agent-toolkit 가장 검증된 스택, JWT(jjwt)·validation·security 성숙 | Conduit 캐노니컬 스택은 Node.js라 데모 비교 시 약간의 응답 형식 미스 가능성 (router 매핑) | dogfooding 우선 — toolkit 기본값으로 검증 |
| Node.js + Express + Prisma | 캐노니컬 데모 스택과 동일 | toolkit 기본값과 차이 → /flow-design schema 매핑 추가 작업 | 후속 변형으로 가능 |
| Go + Gin + GORM | 가벼움, 단일 바이너리 | toolkit 검증도 낮음 | 본 사이클 비채택 |

**결정**: Spring Boot 3.4 + Java 21 + Gradle + JPA + PostgreSQL 16. JWT는 `io.jsonwebtoken:jjwt-api:0.12+`. 마크다운 안전 처리는 `commonmark-java` + `jsoup`(sanitize).

### 2.2 프론트엔드 스택 (OQ-02 결정)

| 후보 | 장 | 단 | 평 |
|---|---|---|---|
| **React 19 + TypeScript + Vite + TailwindCSS** (✅ 채택) | CLAUDE.md 기본값, ADR-0038 디자인 토큰 매핑 가장 검증됨 | Conduit 캐노니컬 CSS는 Bootstrap 4 기반 — Tailwind 재구현 필요 | 시각 동등성보다 사양 준수 우선이므로 채택 |
| Conduit 캐노니컬 CSS (Bootstrap 4 + jQuery 흔적) | 시각 동등성 100% | 1990년대식, TailwindCSS와 충돌, ADR-0038 토큰 매핑 어려움 | 비채택 |
| Vue 3 / Svelte | 변형 다양성 | toolkit 검증도 낮음 | 후속 |

**결정**: React 19 + TypeScript 5+ + Vite 5 + TailwindCSS 3+. 라우팅 `react-router-dom v6`. 폼 `react-hook-form` + zod. HTTP `ky` 또는 `fetch` wrapper. 마크다운 렌더 `react-markdown` + `rehype-sanitize`. JWT는 `localStorage`.

### 2.3 DB·인프라 (OQ-03 결정)

| 후보 | 장 | 단 | 평 |
|---|---|---|---|
| **PostgreSQL 16** (✅ 채택) | 운영 검증, JSONB(tagList) 잘 됨, full-text 후속 확장 가능 | 초기 셋업 ~3분 (docker-compose) | 채택 |
| SQLite (dev) + PostgreSQL (prod) | dev 부팅 빠름 | profile별 DB 다른 운영 부담, 3 profile 동일성 약화 (ADR-0037) | 비채택 |
| H2 in-memory (dev) | 가장 가벼움 | 마이그레이션 검증 못함 | 비채택 |

**결정**: PostgreSQL 16, dev/stg/prod 모두 동일 DB. dev는 docker-compose, stg/prod는 별 인스턴스. 마이그레이션 `Flyway` (Spring Boot 기본 통합).

### 2.4 기술 리스크 — 모두 *기존 검증된 라이브러리*로 회피 가능

- **JWT 보안**: jjwt 0.12+ + HS256, 비밀키 ≥ 256bit, `.env` 강제 (CLAUDE.md §보안)
- **마크다운 XSS**: commonmark-java 렌더 + jsoup `Safelist.relaxed()` 화이트리스트 sanitize
- **슬러그 충돌**: `slugify(title) + "-" + nanoid(6)` (RB-04)
- **N+1**: JPA fetch join + EntityGraph (Articles → Author Profile, Comments → Author)
- **CORS**: dev wildcard, stg/prod origin 화이트리스트 (Spring Security)

### 2.5 타당성 종합

19개 엔드포인트 + 9개 페이지 모두 *기존 라이브러리 조합*으로 구현 가능. 신규 발명 없음. agent-toolkit 흐름을 그대로 적용했을 때 BLOCK 가능성이 가장 높은 지점은 **AI 게이트 6축 중 6번째(3 profile 부팅)** — Flyway 마이그레이션이 3 profile에서 동일하게 적용되는지 매 PR마다 확인 필요(ADR-0037).

## 3. 비용·리소스 추정

| 항목 | 추정 | 비고 |
|---|---|---|
| 인력 (단일 개발자 + agent-toolkit) | 약 22.5 영업일 (4–5주) | 01 §6 일정 표 기반 |
| 인프라 (개발) | 로컬 docker-compose, 비용 0 | PostgreSQL + 백·프론트 dev 서버 |
| 인프라 (stg/prod) | 클라우드 작은 인스턴스 ~ $20–40/월 | optional — 본 사이클은 로컬 stg/prod profile 검증만으로 충분 |
| 외부 의존 라이브러리 | 모두 OSS, 비용 0 | MIT/Apache 호환 |
| 캐노니컬 테스트 슈트 | gothinkster/realworld `specs/api/`·`specs/e2e/` 무료 사용 | 본 repo에 fork or submodule |
| toolkit dogfooding 시 ADR 추가 작성 | 평균 1–2건 예상 (~0.5–1 영업일) | RB-08 |

**총 비용**: 인력 시간 외 거의 0. 운영 인프라는 옵션.

## 4. 기대 효과

| 효과 | 어떻게 측정 |
|---|---|
| agent-toolkit 4-Phase 흐름의 실증 1건 추가 | /flow-init~/flow-bootstrap이 BLOCK 없이 진행되는지 |
| OpenAPI 2.0.0 1대1 매핑 가능 여부 확인 | 캐노니컬 Bruno/Postman 슈트 100% 통과 |
| ADR-0011 (UI 실증) + ADR-0037 (3 profile 부팅) + ADR-0038 (스타일링) 통합 검증 | 9개 페이지 골든패스 + 3 profile × 매 PR + Tailwind 적용 PASS |
| 풀스택 reference 1벌 확보 → 향후 다른 토킷 도입 검토자에게 표본 제공 | 본 repo의 README + screenshots 활용 |
| Conduit 사용자 입장의 골든패스 (회원가입 → 글 작성 → 좋아요 → 팔로우 → 피드) 동작 | 9/9 페이지 PASS (01 §4 KPI) |

## 5. 검토된 대안

| 대안 | 채택 여부 | 사유 |
|---|---|---|
| **A. Spring Boot + React + PostgreSQL (선택)** | ✅ | toolkit 기본값, 모든 게이트 schema 가장 검증됨 |
| B. Node.js + React + PostgreSQL (캐노니컬과 동등 스택) | ❌ | toolkit Java 검증도가 더 높음, 본 사이클은 dogfooding 우선 |
| C. RealWorld 캐노니컬 데모 그대로 fork만 하기 | ❌ | "toolkit으로 처음부터 만든다"는 목적 위배. RFP 정신 미충족 |
| D. 토킷 없이 손코딩으로 만들기 | ❌ | dogfooding 가치 0 |
| E. 캐노니컬 CSS(Bootstrap 4)로 시각 동등성 100% | ❌ | ADR-0038 (Tailwind/CSS-in-JS 1개 이상) 정합성 깨짐, 캐노니컬 사양 KPI(API)는 충족 가능하므로 시각 동등성은 비목표 |
| F. SQLite로 dev profile 간소화 | ❌ | ADR-0037 v1.1 3 profile 동일성 약화, dev/prod 차이 도입 |

## 6. 추천

**채택 안 A** — Spring Boot 3.4 + React 19 + PostgreSQL 16 으로 진행.

근거:
1. agent-toolkit dogfooding이 본 프로젝트의 1차 목적이며, toolkit 기본 스택이 가장 검증됨 (1·2·5 게이트 schema·ADR-0011/0037/0038 모두 매핑 완료).
2. 19개 엔드포인트 + 9개 페이지가 모두 기존 라이브러리 조합으로 구현 가능 — 신규 발명 0건.
3. Conduit 시각 동등성은 비목표(01 §5)이므로 캐노니컬 Bootstrap 4 CSS를 채택할 이유 없음. Tailwind로 ADR-0038 정합.
4. 비용: 인력 시간 외 거의 0. 운영 인프라는 옵션.
5. 리스크는 모두 기존 라이브러리·관행으로 회피 (2.4).

**Phase 2 (/flow-design)에서 결정해야 할 잔여 항목** (02 단계에서는 합의 보류):
- OQ-04 JWT 라이브러리 세부 (jjwt vs jose-jwt) — 06 Architecture
- OQ-05 마크다운 렌더 위치 (서버 vs 클라이언트) — 07 HLD
- OQ-06 캐노니컬 E2E 슈트 통합 방식 (fork vs submodule vs 외부 참조) — 09 API / 12 Test Design
