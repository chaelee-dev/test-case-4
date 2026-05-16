---
description: Use this when the user is producing the SRS (Software Requirements Specification) for a new project, needs to enumerate requirement IDs (R-XX) with priorities and dependencies, or needs to derive upstream test scenarios per requirement (D-06 stage 1 source). Triggered inside flow-new-project at Gate B after 03-user-scenarios.md.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /srs

## 목적
프로젝트의 **요구사항을 ID 단위로 카탈로그화**하고, 각 요구사항에 **테스트 시나리오를 함께 도출**(D-06 1단의 상류 도출)한다. 이후 모든 Phase의 추적 단위(traceability anchor)가 된다.

> **Schema 강제 (ADR-0010 + 0015)**: `doc_type=srs`. `bash .claude/scripts/scaffold-doc.sh srs docs/planning/04-srs/04-srs.md` → 작성 → `bash .claude/scripts/validate-doc.sh docs/planning/04-srs/04-srs.md`. R-F-NN/R-N-NN subsection 강제, 각 요구사항에 우선순위/Acceptance(Given/When/Then) BLOCK + 3축(테스트 레벨/Happy/Failure) BLOCK(ADR-0014). schema: `.claude/schemas/srs.schema.yaml`.

> 본 Command는 `/intention-brief`(1페이지 의도)·`/change-contract`(코드 변경 contract)와 **목적이 다르다**. SRS는 *요구사항 ID 카탈로그*이며 코드 변경이 아닌 제품 정의 단계다.

## 사용 시점
- 게이트 A 통과 후 (`01-project-brief.md` 컨펌됨)
- `03-user-scenarios.md`가 작성된 직후
- `/flow-new-project` Phase 4 (게이트 B)
- `04-srs.md`가 미존재이거나 `> [DRAFT]` 상태

## 입력 (필수)
| 입력 | 경로 | 사유 |
|---|---|---|
| 프로젝트 기획서 | `docs/planning/01-project-brief/01-project-brief.md` | 범위·목적 |
| 사용자 시나리오 | `docs/planning/03-user-scenarios/03-user-scenarios.md` | 행위자·use case |
| (참고) v5 archive | `docs/devtoolkit/PRD.md` | 요구사항 추출 reference |
| docs/planning/INDEX.md | `docs/planning/INDEX.md` | D-06·범위·게이트 |

입력 누락 시 `BLOCKED: 입력 부재 — <파일명>` 보고 후 회귀.

## 산출물
- `docs/planning/04-srs/04-srs.md` (단일) 또는 도메인 분할 시 `04-srs/<NN-domain>.md`

## 문서 구조 (필수 섹션)

```markdown
# 요구사항 정의서 (SRS)

> 문서 버전 / 작성일 / 작성자 / 상태

## 0. 개요
- 본 SRS의 범위 (브리프 §4 In-scope에 1:1 매핑)
- 요구사항 ID 체계: `R-{영역}-{번호}` (예: R-AGENT-01, R-UI-03)

## 1. 행위자 (Actors)
- 사용자, 에이전트, 외부 시스템 등

## 2. 기능 요구사항 (Functional Requirements)

### R-XXX-NN: <한 줄 제목>
- **설명**: 무엇을 해야 하는가
- **우선순위**: P0 / P1 / P2 / P3
- **선행 요구사항**: R-AAA-MM, R-BBB-OO (없으면 "없음")
- **수용 기준 (Acceptance Criteria)**: Given/When/Then 또는 체크리스트
- **테스트 레벨 (MUST, ADR-0014)** — `단위` / `통합` / `E2E` 중 1개 이상
- **테스트 시나리오 (MUST, ADR-0014)** — schema BLOCK 강제. **13 Test Design**(ADR-0031로 12→13 재할당) `02-catalog.md`의 *해당 레벨 섹션*(ADR-0036: §1 단위 / §2 통합 / §3 E2E)에 fan-in 대상. 이슈 진행 중 신규 R-ID 추가 시 `/flow-feature` P13 + `/docs-update` §9의 `check-test-catalog-sync.sh`가 누락을 WARN 보고 (ADR-0035). **3축 필수**:
  - **Happy path** (정상/성공/happy): Given/When/Then 정상 흐름 1건 이상
  - **Failure path** (실패/에러/거부/예외): Given/When/Then 실패·예외 흐름 1건 이상
  - 회귀 위험 영역: <인접 R-ID>

(이상을 모든 요구사항에 반복)

## 3. 비기능 요구사항 (Non-Functional Requirements, NFR)

### NFR-N-01: 성능
### NFR-N-02: 보안 (CLAUDE.md 보안 룰 준수 강제)
### NFR-N-03: 가용성·재개성 (policies/sprint-cycle.md §3 수동 재개 절차 호환)
### NFR-N-04: 관측성 (로그·비용·세션 영속화)
### NFR-N-05: 운영 환경 (로컬 단일 사용자 우선 — D 결정 기록)

## 4. 제외 항목 (Out-of-scope)
- 브리프 §4.2 Out-of-scope의 기술적 재확인

## 5. 의존성·외부 인터페이스
- Claude CLI / GitHub / gstack / 사내 시스템

## 6. Open questions
- ID로 관리, docs/planning/open-items.md 또는 ADR로 이관

## 7. 추적성 매트릭스 (Traceability)
| R-ID | 출처(Brief §, Use case) | 다음 매핑(PRD F-ID, Issue) |
|---|---|---|
| R-AGENT-01 | Brief §5 F1 / UC-01 | F-01 / Issue 미할당 |

## 변경 이력
| Version | Date | Author | Change |
```

## 실행 단계
1. 입력 4개 모두 Read. 누락 시 BLOCKED.
2. Brief §4 In-scope 항목을 **요구사항 후보**로 1차 분해.
3. Use case별로 후보를 다시 정렬 → 중복 제거 → ID 부여 (`R-{영역}-{번호}`).
4. 각 R-ID에 **우선순위·선행 요구사항·수용 기준** 작성.
5. 각 R-ID에 **3축 검증 시나리오 (MUST, ADR-0014)** 작성: (a) 테스트 레벨(단위/통합/E2E 중 1개 이상), (b) Happy path Given/When/Then 1건 이상, (c) Failure path Given/When/Then 1건 이상. **schema BLOCK 강제**이므로 누락 시 `validate-doc.sh` 차단. **13 Test Design** `02-catalog.md`의 해당 레벨 섹션(ADR-0036)이 fan-in 대상 — 이슈 단위 누락은 ADR-0035의 `check-test-catalog-sync.sh`가 WARN.
6. NFR 5개 카테고리 초안.
7. 추적성 매트릭스 작성 (Brief·Use case·PRD/Issue 매핑 컬럼).
8. docs/planning/open-items.md Open Items와 충돌 검사 → 새 Open question에 O-XX ID 부여.
9. 저장 → docs/planning/CHANGELOG.md §"Current Status" 진행 상황 갱신은 `/docs-update`가 담당.

## 완료 조건
- 모든 R-ID에 우선순위·선행 요구사항·수용 기준 채워짐
- **80% 이상의 R-ID에 테스트 시나리오 직접 작성됨** (나머지는 fallback 마커 허용)
- NFR 5개 카테고리 초안 존재
- 추적성 매트릭스가 Brief In-scope를 100% 커버
- 팀 리뷰 통과(게이트 B 1차 조건)

## Strict Rules
- 1결정-1파일 ADR 발생 시 즉시 `docs/planning/adr/NNNN-*.md` 작성 (policies/flow-and-gates.md §3.3)
- 시크릿·내부망 URL 본문 삽입 금지 (CLAUDE.md 보안 룰)
- 우선순위 P0 항목은 의존성 차단 시 **즉시 Open question으로 이관**, 임의 조정 금지

## BLOCKED 케이스
| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: 입력 부재 — 03-user-scenarios.md` | use case 없음 | `/flow-new-project` Phase 3 회귀 |
| `BLOCKED: Brief In-scope 미커버` | 추적성 매트릭스 빈칸 | 누락 R-ID 추가 또는 Brief 수정 |
| `BLOCKED: P0 의존성 순환` | 선행 요구사항 순환 | DAG 검증 후 분해 또는 ADR로 결정 |
| `BLOCKED: 테스트 시나리오 0건` | 상류 도출 부재 | 최소 1개 R-ID에 시나리오 작성 후 재진입 (전부 fallback은 금지) |

## Artifact Binding
- 입력: `01-project-brief.md`, `03-user-scenarios.md`, `docs/planning/INDEX.md`
- 출력: → `/prd` (필수), `/implementation-planner`(아키텍처 호출 시 입력), `/wbs`(이슈 분해 시 입력)
- 페어링:
  - 게이트 B 검토: `/plan-eng-review` 또는 팀 리뷰 미팅
  - 결정 발생 시: ADR 직접 작성 (Command화는 차후)

## 트리거 매칭
"SRS 작성", "요구사항 정의", "R-ID 카탈로그", "요구사항 분해", "04-srs.md"
