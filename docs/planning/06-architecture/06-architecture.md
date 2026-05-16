---
doc_type: architecture
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: C
related:
  R-ID: [R-N-01, R-N-02, R-N-03, R-N-04, R-N-05, R-N-06, R-N-07, R-N-08]
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — System Architecture

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — Stack Decision + 컨테이너 구조 |

## Stack Decision

| 항목 | 결정 | 근거 |
| --- | --- | --- |
| 언어 (BE) | **Java 21** | CLAUDE.md 기본값, 02 Feasibility §2.1 채택. Spring Boot 3.4 LTS 안정성 |
| 언어 (FE) | **TypeScript 5+** | React 19 정합, 타입 안정 |
| 프레임워크 (BE) | **Spring Boot 3.4** + Spring Security + Spring Data JPA | toolkit 검증도 1위, JWT(jjwt)·validation·security 성숙 |
| 프레임워크 (FE) | **React 19 + Vite 5** + react-router-dom v6 | CLAUDE.md 기본값, ADR-0038 디자인 토큰 매핑 검증 |
| 빌드 (BE) | Gradle 8 (Kotlin DSL) | Spring Boot 표준 |
| 빌드 (FE) | Vite 5 | pnpm 9, fast HMR |
| DB | **PostgreSQL 16** | 02 Feasibility §2.3, 3 profile 동일 |
| 마이그레이션 | **Flyway 10+** | Spring Boot 기본 통합, 버전 관리 명확 |
| 인증 | **JWT (HS256)** via `io.jsonwebtoken:jjwt-api:0.12.6+` | 02 §2.4 |
| 마크다운 (BE 검증용) | `org.commonmark:commonmark` + `org.jsoup:jsoup` (sanitize) | 02 §2.4 |
| 마크다운 (FE 렌더) | `react-markdown` + `rehype-sanitize` | 02 §2.4 |
| 스타일링 (FE) | **TailwindCSS 3+** | ADR-0038, 디자인 토큰 매핑 |
| HTTP 클라이언트 (FE) | `ky` (fetch wrapper) | Axios 대비 경량, fetch 호환 |
| 폼 (FE) | `react-hook-form` + `zod` | 타입 안전 검증 |
| 패키저 (FE) | **pnpm 9+** | 디스크 효율, lockfile 결정성 |
| 컨테이너 (dev) | `docker-compose` | PostgreSQL + 옵션 |
| 컨테이너 (prod) | Dockerfile per service | stg/prod 동일 이미지 |
| Java JRE | OpenJDK 21 Temurin | Spring Boot 3.4 권장 |
| Node | **20 LTS+** | Vite 5 최소 |

> 12 Scaffolding은 본 §Stack Decision의 "언어" 행을 파싱해 `12-scaffolding/<lang>.md` 파일 분리 정본 (foldering-rules §3). 본 프로젝트는 `java.md` (BE) + `react.md` (FE) 2개.

## 1. 시스템 컨텍스트

```
                ┌────────────────────────────────────┐
                │            End User                │
                │  (브라우저: Visitor / Aiden / Bora)│
                └──────────────┬─────────────────────┘
                               │ HTTPS (dev: HTTP)
                               │
                ┌──────────────▼─────────────────────┐
                │     Conduit Frontend (SPA)         │
                │     React 19 + Vite + Tailwind     │
                │     localStorage: conduit.jwt      │
                └──────────────┬─────────────────────┘
                               │ JSON over HTTPS
                               │ Authorization: Token <jwt>
                               │
                ┌──────────────▼─────────────────────┐
                │    Conduit Backend API             │
                │    Spring Boot 3.4 / Java 21       │
                │    /api/* (19 endpoints)           │
                └──────────────┬─────────────────────┘
                               │ JDBC
                               │
                ┌──────────────▼─────────────────────┐
                │    PostgreSQL 16                   │
                │    Flyway 마이그레이션 적용         │
                └────────────────────────────────────┘

  Out of band:
    - 캐노니컬 Bruno/Postman 슈트 (CI) → Backend API
    - 캐노니컬 Playwright E2E (CI) → Frontend SPA → Backend API
```

**경계**:
- 사용자 ↔ Frontend: HTTPS (stg/prod), HTTP (dev)
- Frontend ↔ Backend: same-origin (prod via reverse proxy) 또는 CORS allowed origins (stg/prod) 또는 `*` (dev)
- Backend ↔ DB: VPC 내 (prod), 로컬 docker network (dev/stg)
- 외부 의존: 없음 (이미지 호스팅·이메일·OAuth 모두 비범위)

## 2. 컨테이너 구조

dev profile (`docker-compose.yml`):

```
┌─ docker-compose ──────────────────────────────────┐
│                                                   │
│  ┌─────────────┐    ┌─────────────┐               │
│  │ frontend    │    │ backend     │               │
│  │ Vite dev    │────│ Spring Boot │               │
│  │ :5173       │    │ :8080       │               │
│  └──────┬──────┘    └──────┬──────┘               │
│         │ ws (HMR)         │                      │
│  ┌──────┴──────┐    ┌──────▼──────┐               │
│  │  Browser    │    │ postgres:16 │               │
│  │  localhost  │    │ :5432       │               │
│  └─────────────┘    └─────────────┘               │
└───────────────────────────────────────────────────┘
```

stg/prod profile:
- frontend: 빌드 결과(`dist/`)를 nginx 또는 정적 호스팅
- backend: `java -jar conduit-api-*.jar --spring.profiles.active=stg|prod`
- postgres: 별 인스턴스 (managed RDS 등 가능)
- 단일 host에서 docker compose 또는 k8s — 본 프로젝트는 docker-compose 한 벌만 정의, k8s는 비범위

3개 컨테이너 모두 동일 도커 네트워크. dev/stg/prod 모두 동일 컨테이너 구성으로 ADR-0037 v1.1 3 profile 정합 보장.

## 3. 외부 시스템 / 경계

- **없음** (캐노니컬 RealWorld는 self-contained)
- 캐노니컬 demo API(`https://api.realworld.show/api`)는 *비교 baseline*으로만 사용하며 본 시스템이 의존하지 않음
- 캐노니컬 테스트 슈트(Bruno/Playwright)는 CI에서 우리 backend·frontend를 대상으로 실행 — 외부 *판정자*이지 *의존*은 아님
- 비기능 R-ID(R-N-01~08) 모두 본 시스템 내부에서 해결 (외부 IdP·CDN 없음)
