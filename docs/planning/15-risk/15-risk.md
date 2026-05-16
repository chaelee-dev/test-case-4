---
doc_type: risk
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: operations
related:
  R-ID: [R-N-01, R-N-02, R-N-03, R-N-05, R-N-06]
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — Risk Register

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 12 RISK 식별, 5카테고리 (기술/일정/외부 의존/보안/운영) |

## 1. 리스크 일람

| RISK-ID | 제목 | 영향(1~5) | 가능성(1~5) | 등급 | 영향 받는 Sprint/Issue | 대응 |
| --- | --- | --- | --- | --- | --- | --- |
| RISK-01 | RealWorld 캐노니컬 OpenAPI 스펙 변동 | 3 | 1 | Low | Sprint 4 / I-27 | OpenAPI fork 잠금, semver pin |
| RISK-02 | JWT 비밀키 / .env 누출 | 5 | 2 | High | All / I-02 | settings.json PreToolUse 훅 + .gitignore + secret rotation |
| RISK-03 | 마크다운 XSS (저장된 페이로드) | 5 | 3 | High | Sprint 2,3 / I-17, I-25 | 이중 sanitize (BE + FE) + XSS 페이로드 8종 단위 테스트 |
| RISK-04 | Flyway 마이그레이션 충돌 (Multi-PR 동시) | 3 | 3 | Medium | Sprint 1,2 / I-01, I-09, I-10, I-15, I-16 | 마이그레이션 V번호 채번 lock + PR conflict 자동 BLOCK |
| RISK-05 | N+1 쿼리로 글 목록 응답 > 500ms | 4 | 3 | High | Sprint 2 / I-12 | EntityGraph + JOIN fetch, k6 nightly로 회귀 감지 |
| RISK-06 | 슬러그 충돌·race condition | 3 | 2 | Low | Sprint 2 / I-09, I-11 | DB unique 제약 + nanoid suffix + retry 1회 |
| RISK-07 | FE-BE CORS prod에서 차단 | 3 | 3 | Medium | Sprint 4 / I-30 | Spring Security CORS 화이트리스트 stg/prod 분리 + 3 profile 부팅 검증 |
| RISK-08 | dogfooding 도중 toolkit Phase BLOCK | 3 | 3 | Medium | All | ADR-XX로 즉시 기록 후 toolkit fix → 본 프로젝트 재개 |
| RISK-09 | 캐노니컬 Bruno 슈트 실패 (응답 형식 불일치) | 4 | 3 | High | Sprint 4 / I-27 | 매 BE 엔드포인트 통합 시 contract 셀프 실행 |
| RISK-10 | Playwright E2E 환경 격리 실패 (DB 상태 오염) | 3 | 4 | High | Sprint 4 / I-28 | 각 spec `@BeforeAll` 시 DB truncate + 시드, 격리된 user 토큰 |
| RISK-11 | 3 profile 부팅 비대칭 (dev만 작동) | 4 | 3 | High | All / I-30 | ADR-0037 v1.1 CI matrix BLOCK + LOCAL.md sync 강제 |
| RISK-12 | 일정 초과 — 4-5주 → 7-8주 | 3 | 4 | High | All | Sprint 5 buffer 명시, MVP Cut 재검토 권한 보유 |

등급: Low(≤4) / Medium(5~8) / High(≥9) — 영향 × 가능성.

## 2. 리스크 상세

### RISK-01: RealWorld 캐노니컬 OpenAPI 스펙 변동

- 카테고리: 외부 의존
- 설명: gothinkster/realworld의 `specs/api/openapi.yml`이 본 프로젝트 진행 중 v2.1+로 갱신될 가능성. 캐노니컬 Bruno/Playwright 슈트도 함께 갱신될 수 있음.
- 영향: 3 — contract 슈트 실패로 KPI(100% 통과) 미충족 가능
- 가능성: 1 — 메인테이너 활동 빈도 분기 ~1회
- 현재 상태: 식별
- 트리거 신호: nightly Bruno 슈트 실패 + GitHub `gothinkster/realworld` release 알림
- 완화 전략: 본 프로젝트가 import 시점의 `specs/api/openapi.yml`를 fork해 잠금. 외부 갱신은 별 PR로 review 후 import (필요 시 ADR 신설).
- 대응 이슈: I-27 (bruno-contract-suite-fork)

### RISK-02: JWT 비밀키 / .env 누출

- 카테고리: 보안
- 설명: `.env.{dev,stg,prod}`나 `JWT_SECRET`이 git에 커밋·로그 노출·PR 본문 포함될 가능성.
- 영향: 5 — 모든 사용자 세션 위조 가능, 데이터 무결성 즉시 손상
- 가능성: 2 — toolkit hook + .gitignore로 대부분 방어, 휴먼 실수만 잔존
- 현재 상태: 모니터링
- 트리거 신호: 시크릿 스캔 도구 alert / PR review 시 평문 키 노출 발견 / 로그에 JWT 본문 출력
- 완화 전략: ① settings.json PreToolUse 훅이 .env*·*.key·*secret* Write 차단. ② .gitignore 카피 (install.sh). ③ logback masking pattern. ④ JWT_SECRET 노출 의심 시 즉시 rotate + 재로그인 강제. ⑤ /cso로 매 PR 보안 점검 (CLAUDE.md §보안 §6).
- 대응 이슈: I-02 (jwt-and-security-config)

### RISK-03: 마크다운 XSS (저장된 페이로드)

- 카테고리: 보안
- 설명: 글 body에 입력된 `<script>` 등 XSS 페이로드가 다른 사용자 브라우저에서 실행. 저장형이라 *모든 열람자*에게 즉시 영향.
- 영향: 5 — 모든 활성 사용자 영향, 자격 탈취 가능
- 가능성: 3 — 명세상 외부 마크다운 입력 허용 → 시도 빈번
- 현재 상태: 식별
- 트리거 신호: 통합/E2E 테스트 XSS 페이로드 8종 실패 / ZAP 야간 스캔 high finding
- 완화 전략: ① BE M-BE-MARKDOWN(commonmark + jsoup Safelist.relaxed) 글 저장 시 sanitize. ② FE M-FE-MARKDOWN(react-markdown + rehype-sanitize) 렌더 시 sanitize. ③ XSS 페이로드 8종 단위·E2E 테스트 (04 §S1). ④ CSP 헤더 (`default-src 'self'`) prod에 적용.
- 대응 이슈: I-17 (markdown-sanitize), I-25 (article-detail-page)

### RISK-04: Flyway 마이그레이션 충돌

- 카테고리: 기술
- 설명: 여러 PR이 동시에 진행되면 V{N}__*.sql의 N이 충돌. 한 쪽은 V8, 다른 쪽도 V8을 작성한 경우 merge 후 적용 실패.
- 영향: 3 — 부팅 차단, 회복 빠름 (rename + commit)
- 가능성: 3 — Sprint 1·2에 마이그레이션 PR 동시 발생 가능
- 현재 상태: 식별
- 트리거 신호: PR CI에서 Flyway `migration ordering violated` 에러 / fresh checkout 부팅 실패
- 완화 전략: ① 마이그레이션 V번호 채번 lock (issue별로 V번호 예약 코멘트). ② PR conflict 발생 시 *후속 PR이 자동 BLOCK*되어 rename 강제. ③ `prefix=V{이슈번호}__*.sql` 명명 컨벤션 검토 (별 ADR로 잠재 신설).
- 대응 이슈: I-01, I-09, I-10, I-15, I-16 (DDL 작성 이슈 5건)

### RISK-05: N+1 쿼리로 글 목록 응답 > 500ms

- 카테고리: 기술
- 설명: 글 목록 응답이 author Profile + favoritesCount + tagList을 lazy fetch하면 N+1 쿼리 발생. 동시 50 사용자 부하 시 응답 1초+.
- 영향: 4 — KPI R-N-01 미달 + 사용자 체감 느림
- 가능성: 3 — JPA default lazy + 미숙한 fetch 전략 시 발현
- 현재 상태: 식별
- 트리거 신호: k6 부하 시나리오 P2에서 95p > 500ms / `hibernate.show_sql=true`로 동일 쿼리 N회
- 완화 전략: ① `@EntityGraph` 또는 JOIN fetch (M-BE-ARTICLE). ② nightly k6 부하 회귀로 조기 감지. ③ 인덱스 `articles(created_at DESC)`, `articles(author_id, created_at)`, `favorites(article_id)`. ④ p6spy로 dev에서 쿼리 카운트 점검.
- 대응 이슈: I-12 (article-list-and-filter)

### RISK-06: 슬러그 충돌·race condition

- 카테고리: 기술
- 설명: 동일 title 글 2건이 거의 동시 작성 시 slug 충돌. unique 제약으로 한쪽 실패.
- 영향: 3 — 한 사용자 작성 실패 + 재시도 1회 비용
- 가능성: 2 — 동시 작성 시도 빈도 낮음 (단일 dev 환경)
- 현재 상태: 식별
- 트리거 신호: 통합 테스트 동시 작성 케이스 실패 / 운영 로그 `DuplicateKeyException slug`
- 완화 전략: ① DB unique 제약 + 충돌 catch 시 nanoid(6) suffix 자동 추가. ② retry 1회. ③ slug 생성 시 점진 nanoid (예: 4글자 → 6글자) 확장 가능.
- 대응 이슈: I-09 (article-domain-and-slug), I-11 (article-create)

### RISK-07: FE-BE CORS prod 차단

- 카테고리: 운영
- 설명: prod profile에서 CORS allowed origins가 잘못 설정돼 FE → BE 호출 모두 차단.
- 영향: 3 — prod 부팅 검증 실패, 사용자 0건 영향 (배포 전 발견 시)
- 가능성: 3 — profile 동기 누락 빈번 (RB-07 회귀)
- 현재 상태: 식별
- 트리거 신호: 3 profile 부팅 CI matrix prod 실패 / E2E spec preflight OPTIONS 차단
- 완화 전략: ① `application-prod.yml`의 `cors.allowed-origins` 환경 변수 주입 + 3 profile 부팅 CI에서 헬스체크 GET /api/health (CORS 적용) 검증. ② LOCAL.md §3.3 prod 부팅 명령에서 `CORS_ALLOWED_ORIGINS` 명시.
- 대응 이슈: I-30 (3-profile-ci-matrix)

### RISK-08: dogfooding toolkit Phase BLOCK

- 카테고리: 일정
- 설명: 본 프로젝트 진행 중 agent-toolkit의 schema/scaffold/validate 스크립트가 의도치 않게 BLOCK 발생. fix 후 진행 재개 필요.
- 영향: 3 — 1~2일 지연
- 가능성: 3 — dogfooding 정의상 발견되는 빈도
- 현재 상태: 모니터링
- 트리거 신호: validate-doc.sh BLOCK / scaffold-doc.sh 골격 누락 / install.sh 실패
- 완화 전략: ① BLOCK 발생 즉시 ADR-XX로 기록(공통 ADR 디렉토리 0017~0040 패턴). ② toolkit fix를 *다른 워크트리*에서 진행 후 본 프로젝트로 sync. ③ 일정 §6에 1일 buffer 사전 반영 (RISK-12 연계).
- 대응 이슈: (별 이슈 없음 — toolkit repo 자체에서 처리)

### RISK-09: 캐노니컬 Bruno 슈트 실패

- 카테고리: 외부 의존
- 설명: 본 BE 응답이 RealWorld 캐노니컬 Bruno 슈트의 assertion(JSON 키 이름, status code, 형식)과 불일치.
- 영향: 4 — KPI(100% 통과) 미달, 데모 신뢰성 손상
- 가능성: 3 — wrap·field naming 미스 흔함
- 현재 상태: 식별
- 트리거 신호: PR CI Bruno 슈트 실패 / 응답 JSON에 unexpected 키
- 완화 전략: ① M-BE-WEB ResponseEnvelope 표준화 + Jackson `@JsonInclude(NON_NULL)`. ② Sprint 1~3 매 endpoint 통합 시점에 Bruno 셀프 실행 (Sprint 4 일괄 발견 회피). ③ 캐노니컬 sample 응답을 09 API Spec §3에 인용 (이미 적용).
- 대응 이슈: I-27 (bruno-contract-suite-fork) + Sprint 1~3 모든 BE 이슈에 DoD로 "Bruno 슈트 통과 1건 추가"

### RISK-10: Playwright E2E 환경 격리 실패

- 카테고리: 기술
- 설명: E2E spec 간 DB 상태 공유로 flaky test 발생. 한 spec이 다른 spec의 user/article을 수정.
- 영향: 3 — CI 신뢰도 손상, 재시도 빈번
- 가능성: 4 — DB 격리 미설계 시 자주 발현
- 현재 상태: 식별
- 트리거 신호: 동일 spec이 단독 실행은 PASS, 전수에선 FAIL / Playwright trace에 다른 spec의 데이터 흔적
- 완화 전략: ① 각 spec `beforeAll`에서 DB truncate (test profile) + 시드 명시. ② Playwright worker 1개로 시작 (병렬 0), 격리 검증 후 점진 확대. ③ 각 spec이 unique username/email 사용 (faker + UUID).
- 대응 이슈: I-28 (playwright-e2e-fork)

### RISK-11: 3 profile 부팅 비대칭

- 카테고리: 운영
- 설명: dev는 부팅되나 stg/prod profile 부팅 검증 누락 (RB-08 회귀, ADR-0037 동기 부재).
- 영향: 4 — AI 게이트 6번째 축 BLOCK, PR 진행 정체
- 가능성: 3 — Spring profile 분기·env 동기 누락 흔함
- 현재 상태: 식별
- 트리거 신호: AI 게이트 6 BLOCK / fresh checkout 부팅 stg/prod 실패 / LOCAL.md §3 명령 outdated
- 완화 전략: ① ADR-0037 v1.1 CI matrix BLOCK (3 profile 헬스체크 200 강제). ② LOCAL.md sync 강제 (ADR-0040). ③ 12-scaffolding §7 부팅 자산 표 PR 동기 갱신.
- 대응 이슈: I-30 (3-profile-ci-matrix)

### RISK-12: 일정 초과

- 카테고리: 일정
- 설명: 01 §6 4-5주 추정이 낙관적. 실제 issue 추정 합산 38d (Sprint 1: 8d, Sprint 2: 12d, Sprint 3: 12d, Sprint 4: 6d) 대비 18d 계획 → ~2배.
- 영향: 3 — 마감 지연, KPI 일부 미달
- 가능성: 4 — 추정 합산이 일정을 이미 초과
- 현재 상태: 식별
- 트리거 신호: Sprint 종료 시점 burn-down 50% 미만 / `tested` 라벨 없는 이슈 누적
- 완화 전략: ① 14 WBS §6에서 솔직히 명시: 실제 6-7주 예상. ② Sprint 종료마다 회고 + MVP Cut 재검토 권한. ③ 우선순위 P1·P2 이슈는 Sprint 5(buffer)로 이연 가능. ④ 일정 압박 시 RealWorld 캐노니컬 Playwright spec 통과율 95% → 90%로 조정 검토.
- 대응 이슈: (전체 일정 관리 — sprint-bootstrap 후 milestone date로 추적)

## 3. High 리스크 단계적 롤아웃

High 등급(영향×가능성 ≥ 9) 리스크는 다음 단계로 롤아웃:

### High RISK-02 (JWT 누출)
- **Step 1 (Sprint 1, I-02 직후)**: settings.json PreToolUse 훅 + .gitignore 검증 (existing). 평문 키 git history 스캔.
- **Step 2 (Sprint 4)**: prod profile에서 JWT_SECRET를 secrets manager(예: HashiCorp Vault / AWS Secrets Manager)에서 주입하는 흐름 검토 (옵션).
- **Rollback Trigger**: 누출 의심 시 즉시 JWT_SECRET rotate → 모든 사용자 재로그인 강제 (DB users 토큰 캐시 없음, JWT stateless라 rotate만으로 충분).

### High RISK-03 (마크다운 XSS)
- **Step 1 (Sprint 2, I-17)**: BE sanitize 단위 테스트 8종 페이로드 PASS.
- **Step 2 (Sprint 3, I-25)**: FE sanitize + Playwright 브라우저 alert 미발생 검증.
- **Step 3 (Sprint 4, nightly)**: OWASP ZAP baseline scan 통과.
- **Rollback Trigger**: 발견 시 즉시 hotfix PR(article-detail에 plain text 임시 표시) + 단위 테스트 보강.

### High RISK-05 (N+1 성능)
- **Step 1 (Sprint 2, I-12 직후)**: 단위 + 통합 테스트로 쿼리 카운트 assertion (`@AutoConfigureTestEntityManager`).
- **Step 2 (Sprint 4, nightly)**: k6 P2 시나리오 50 동시 / 글 1만 시드로 95p < 500ms 검증.
- **Rollback Trigger**: 95p > 500ms 발견 시 EntityGraph 도입 hotfix + 인덱스 추가.

### High RISK-09 (Bruno 슈트 실패)
- **Step 1 (Sprint 1~3 매 BE endpoint 이슈 DoD)**: 해당 endpoint Bruno 케이스 셀프 PASS.
- **Step 2 (Sprint 4, I-27)**: 전수 Bruno 슈트 fork + CI 매 PR 실행.
- **Rollback Trigger**: 통과율 < 100%면 응답 형식 hotfix.

### High RISK-10 (E2E 격리)
- **Step 1 (Sprint 4, I-28 시작)**: Playwright worker 1개 + spec별 DB truncate 검증.
- **Step 2 (격리 PASS 후)**: worker 점진 2 → 4 확대.
- **Rollback Trigger**: flaky 감지 시 worker 1로 회귀 + 격리 보강.

### High RISK-11 (3 profile 부팅)
- **Step 1 (Sprint 1, I-01)**: `.env.{dev,stg,prod}.example` 3 종 작성 + LOCAL.md §3 3 profile 명령 명시.
- **Step 2 (Sprint 4, I-30)**: CI matrix dev/stg/prod 헬스체크 200 BLOCK 강제.
- **Rollback Trigger**: 한 profile 실패 시 LOCAL.md sync PR로 즉시 회복.

### High RISK-12 (일정 초과)
- **Step 1**: Sprint 1 종료 burn-down 확인. 50% 미만이면 RISK-12 발생 상태로 전이.
- **Step 2**: Sprint 3까지 진행 후 Sprint 5 buffer 필요 여부 결정.
- **Rollback Trigger**: Sprint 4 종료 시점에 미완료 P0 이슈 5건+ → MVP Cut 재검토 (01 §5와 합의 후 일부 F를 v0.1.x로 이연).
