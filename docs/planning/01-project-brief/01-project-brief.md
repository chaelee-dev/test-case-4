---
doc_type: brief
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

# Conduit (RealWorld 클론) — Project Brief

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — RealWorld 스펙 기반 Project Brief 작성 (RFP.md → /flow-init Phase 1) |

## 1. 한 줄 정의

RealWorld 표준 사양(Conduit, Medium.com 스타일 블로그 플랫폼)을 agent-toolkit이 자동 생성한 풀스택 구현체(프론트엔드 + 백엔드)로 만들어 — 외부에 공개된 OpenAPI 2.0.0 스펙·UI 사양·E2E 슈트를 그대로 통과시키는 한 벌의 참조 구현(reference implementation)을 산출한다.

## 2. 배경 / 문제 정의

**문제**: 일반적인 "todo 데모"는 프레임워크의 표면적 능력만 보여줄 뿐, 실제 운영 가능한 앱을 만드는 데 필요한 지식·관점·트레이드오프를 전달하지 못한다. agent-toolkit이 *진짜로 동작하는* 풀스택 앱을 RFP → 운영까지 자동 생성할 수 있는지 검증할 외부 기준이 필요하다.

**배경**:
- RealWorld는 동일한 사양(Conduit)을 150+ 프레임워크 조합으로 구현한 오픈 스펙으로, **외부 기준치(OpenAPI 2.0.0 + Bruno/Postman 테스트 + E2E)** 가 명확하다.
- agent-toolkit 자체의 dogfooding 시야가 부족 — 본 구현으로 4-Phase NEW_PROJECT 흐름(/flow-init → /flow-design → /flow-wbs → /flow-bootstrap → /flow-feature)을 처음부터 끝까지 한 번 더 검증한다.
- "RealWorld가 통과한다" = "API 19개 + 페이지 9개 + 캐노니컬 테스트 슈트 통과" 라는 *반증 가능한* 인수 기준이 마련된다.

## 3. 핵심 사용자 / 이해관계자

| 구분 | 누구 | 관심사 |
|---|---|---|
| **End User (Conduit 사용자)** | 블로그 글을 쓰고/읽고/좋아요·팔로우하는 일반 사용자 | 회원가입 → 글 작성 → 피드 → 좋아요·팔로우가 매끄럽게 작동 |
| **Reference 구현 도입자** | RealWorld 스펙으로 다른 스택을 학습/평가하려는 개발자 | OpenAPI 2.0.0 100% 일치, 캐노니컬 E2E 통과 |
| **agent-toolkit 도입 검토자 (1차 이해관계자)** | 본 toolkit으로 새 프로젝트를 시작하려는 팀 리더 | 토킷이 "현실적인 풀스택 앱"을 안정적으로 만드는지 확인 |
| **agent-toolkit 메인테이너** | 본 toolkit 개발자 | dogfooding으로 Phase 흐름·schema·게이트 미비점 식별 |

핵심 의사결정자 = **agent-toolkit 도입 검토자**. 본 구현이 그들의 "한 번 따라 만들어보는 표본" 역할.

## 4. 목표 (성공 정의)

| KPI | 측정 방법 | 목표값 | 달성 시점 |
| --- | --- | --- | --- |
| OpenAPI 사양 일치율 | RealWorld 캐노니컬 Bruno/Postman 슈트 통과 비율 | 100% (19/19 엔드포인트) | MVP 종료 |
| 화면 골든패스 통과 | 9개 페이지 각각 골든패스 시나리오 1건 이상 통과 (브라우저 실증, ADR-0011) | 9/9 페이지 PASS | MVP 종료 |
| AI 게이트 6축 PASS 비율 | 매 PR마다 AI 게이트(D-06 1단) 통과 | ≥ 90% (재시도 1회 이내) | 운영 시작 |
| 3 profile 부팅 | dev/stg/prod 각각 fresh checkout에서 부팅 가능 (ADR-0037 v1.1) | 3/3 PASS | 매 PR |
| toolkit Phase 완주 | /flow-init → /flow-design → /flow-wbs → /flow-bootstrap 까지 BLOCK 없이 통과 | 4/4 Phase | Phase 4 종료 |
| 캐노니컬 E2E 통과 | gothinkster/realworld `specs/e2e/` 슈트 (Playwright) 통과 | ≥ 95% 케이스 PASS | MVP+1주 |

## 5. 비목표 (Out of Scope)

다음은 본 MVP 범위에서 명시적으로 제외:

1. **비밀번호 리셋·이메일 인증** — 캐노니컬 RealWorld 스펙에 없음. 추후 별 feature로.
2. **이미지 업로드(파일)** — Conduit은 이미지를 URL 문자열로만 받음. 멀티파트 업로드·CDN 연동 없음.
3. **어드민/모더레이션 콘솔** — 일반 사용자만.
4. **알림(웹·이메일·푸시)** — 캐노니컬에 없음.
5. **검색** — `/articles` 필터(tag/author/favorited)만 지원, 전문 검색·자동완성 없음.
6. **다국어 (i18n)** — 영어 1언어 (캐노니컬 사양).
7. **결제·구독·광고** — 비상업 데모.
8. **모바일 네이티브 앱** — 본 프로젝트는 웹 풀스택만. mobile-specs는 후속.
9. **OAuth 소셜 로그인** — JWT only.
10. **WebSocket·실시간** — 댓글·좋아요 카운트는 페이지 리로드 시점에 반영.

## 6. 일정 (대략)

| 구간 | 기간 (영업일) | 산출 게이트 |
|---|---|---|
| Phase 1 — /flow-init (본 문서) | 1d | 01·02·03·04·05 (Gate A·B) |
| Phase 2 — /flow-design | 2d | 06·07·08·09·10·11·12·13 (Gate C) |
| Phase 3 — /flow-wbs | 1d | 14·15 |
| Phase 4 — /flow-bootstrap | 0.5d | GitHub 이슈·마일스톤 등록 |
| Sprint 1 (BE 인증·User·Profile) | 5d | F-XX 이슈 묶음 |
| Sprint 2 (BE Articles·Tags·Comments·Favorites) | 5d | |
| Sprint 3 (FE 페이지 + JWT) | 5d | |
| Sprint 4 (E2E·QA·성능·운영 준비) | 3d | tested 라벨 + 운영 검증 |
| **총 합산 (영업일)** | **약 22.5d (4-5주)** | |

본 일정은 추정. /flow-wbs에서 R-ID/F-ID 기반으로 재산정한다.

## 7. 리스크 (초기 식별)

| ID | 리스크 | 영향 | 초기 완화 |
|---|---|---|---|
| RB-01 | RealWorld 스펙 변동(2.0.0 → ?) | 낮음 — 외부 스펙이 안정적 | OpenAPI 파일을 본 repo에 캐싱 (specs/api/openapi.yml fork) |
| RB-02 | JWT secret 노출 | 보안 | .env 강제, settings.json PreToolUse 훅으로 차단 (CLAUDE.md §보안) |
| RB-03 | 마크다운 XSS | 보안 | sanitize 라이브러리 강제, F-ID 측정 |
| RB-04 | 슬러그 충돌 (동일 title 다수) | 데이터 무결성 | suffix(-2,-3,...) 또는 nanoid 보강 — 04 SRS R-ID에서 명시 |
| RB-05 | 페이지네이션 대량 데이터 시 성능 | 성능 | limit 상한(예: 100), index on (createdAt DESC) |
| RB-06 | FE/BE 통신 CORS | 운영 | dev profile에서 wildcard, stg/prod에서 origin 화이트리스트 |
| RB-07 | 캐노니컬 E2E 환경 차이로 일부 케이스 실패 | 측정 KPI | KPI를 95%로 설정 (4번 표) — 100% 추구는 별 이슈로 |
| RB-08 | dogfooding 도중 toolkit BLOCK 발생 | 일정 | BLOCK 즉시 ADR-XX로 기록, toolkit 보완 후 본 프로젝트 재개 |

## 8. Open Questions

- **OQ-01**: 백엔드 스택 — Spring Boot 3.4 (CLAUDE.md 기본값) vs Node.js/Express vs Go? 02 Feasibility에서 결정.
- **OQ-02**: 프론트엔드 스택 — React 19 (CLAUDE.md 기본값) 유지 vs Conduit 캐노니컬 스택? 02 Feasibility에서 결정.
- **OQ-03**: DB — PostgreSQL vs SQLite(개발 단순화)? 02 Feasibility에서.
- **OQ-04**: JWT 라이브러리 선택 (jjwt vs jose vs ...). 06 Architecture에서.
- **OQ-05**: 마크다운 렌더링 — 서버 렌더 vs 클라이언트 렌더? 07 HLD에서.
- **OQ-06**: 캐노니컬 E2E 슈트(Playwright)를 본 repo에 fork 할지, submodule할지 외부 참조만 할지? 09 API / 12 Test Design에서.
