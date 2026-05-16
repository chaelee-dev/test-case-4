---
description: Use this when the user is producing the PRD (Product Requirements Document) for a new project, needs to enumerate features (F-XX) and the MVP cut from the SRS, or needs to define per-feature test scenarios (D-06 stage 1 source) for product behavior. Triggered inside flow-new-project at Gate B after 04-srs.md.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /prd

## 목적
SRS(요구사항)를 **사용자 가치·기능 단위**로 재구성하여 **MVP 범위를 확정**하고, 기능별 사용자 흐름·UI 요구·**테스트 시나리오(D-06 1단 상류)** 를 정의한다. SRS는 *무엇을* 정의하고, PRD는 *어떻게 보여줄/팔/우선순위할* 것인가를 정의한다.

> **Schema 강제 (ADR-0010 + 0015)**: `doc_type=prd`. `scaffold-doc.sh prd docs/planning/05-prd/05-prd.md` → 작성 → `validate-doc.sh`. F-NN subsection 강제, 각 기능에 MVP Cut/우선순위/사용자 스토리/Acceptance/R-ID 매핑 BLOCK + 3축(테스트 레벨/Happy/Failure) BLOCK(ADR-0014). schema: `.claude/schemas/prd.schema.yaml`.

> 본 Command는 `/srs`(요구사항 카탈로그)·`/intention-brief`(1페이지 의도)와 **목적이 다르다**. PRD는 *기능 카탈로그 + MVP 컷*이며, 디자인·개발팀이 게이트 C 진입 시 참조하는 1차 문서다.

## 사용 시점
- 게이트 B 진행 중, `/srs` 통과 후
- `04-srs.md` 의 R-ID 카탈로그가 확정된 직후
- `/flow-new-project` Phase 5
- `05-prd.md`가 미존재이거나 `> [DRAFT]` 상태

## 입력 (필수)
| 입력 | 경로 | 사유 |
|---|---|---|
| 프로젝트 기획서 | `docs/planning/01-project-brief/01-project-brief.md` | 범위·KPI |
| 사용자 시나리오 | `docs/planning/03-user-scenarios/03-user-scenarios.md` | 사용자 흐름 |
| 요구사항 정의서 (SRS) | `docs/planning/04-srs/04-srs.md` | R-ID 매핑 (필수) |
| (참고) v5 archive | `docs/devtoolkit/PRD.md` | 이전 PRD 구조 reference |
| docs/planning/INDEX.md | `docs/planning/INDEX.md` | D-06·범위·게이트 |

입력 누락 시 `BLOCKED: 입력 부재 — <파일명>` 보고 후 회귀.

## 산출물
- `docs/planning/05-prd/05-prd.md` (단일) 또는 영역 분할 시 `05-prd/<NN-area>.md`

## 문서 구조 (필수 섹션)

```markdown
# 제품 요구사항 정의서 (PRD)

> 문서 버전 / 작성일 / 작성자 / 상태

## 0. 개요
- 본 PRD의 적용 범위와 SRS와의 관계
- 기능 ID 체계: `F-{영역}-{번호}` (예: F-AGENT-01, F-UI-03)
- MVP 범위 한 줄 정의

## 1. 사용자·페르소나
- 주요 페르소나 2~3
- 페르소나별 핵심 작업(JTBD)

## 2. 기능 카탈로그 (Functional Catalog)

### F-XXX-NN: <기능 한 줄 제목>
- **요약**: 사용자가 무엇을 할 수 있나
- **MVP 포함 여부**: ✅ MVP / ⏳ Phase 2 / 🚫 Out
- **우선순위**: P0 / P1 / P2 / P3
- **매핑 R-ID**: R-AGENT-01, R-UI-03 (SRS 추적성)
- **사용자 흐름**: 1) → 2) → 3) (간단 단계, 와이어프레임은 07로 이관)
- **UI 요구**: 화면·상태·핵심 인터랙션
- **수용 기준 (Acceptance Criteria)**: Given/When/Then
- **테스트 레벨 (MUST, ADR-0014)** — `단위` / `통합` / `E2E` 중 1개 이상
- **테스트 시나리오 (MUST, ADR-0014)** — F-ID 1개당 **3축 필수** (Happy path + Failure path + 테스트 레벨). schema BLOCK. **13 Test Design**(ADR-0031로 12→13 재할당) `02-catalog.md`의 *해당 레벨 섹션*(ADR-0036: §1 단위 / §2 통합 / §3 E2E)에 fan-in 대상. 이슈 진행 중 신규 F-ID 추가 시 `/flow-feature` P13 + `/docs-update` §9의 `check-test-catalog-sync.sh`가 누락을 WARN 보고 (ADR-0035)
  - 사용자 관점 자동 테스트(E2E·시나리오 기반): <케이스>
  - 수동 검증 항목: <단계>
  - 회귀 위험 영역: <인접 F-ID·R-ID>

(이상을 모든 MVP 기능에 반복)

## 3. 비기능·UX 요구
- 응답 속도·접근성·다국어·다크모드 등
- SRS NFR과 중복되는 항목은 SRS에 위임 + ID 인용만

## 4. MVP 범위 (Cut Line)
- ✅ 포함 / ⏳ Phase 2 / 🚫 Out
- 의사결정 근거 1줄씩

## 5. 사용자 흐름·정보 구조
- 핵심 user journey 2~5개
- 화면 인벤토리 (상세 와이어프레임은 10-lld-screen-design.md로 이관, ADR-0031)

## 6. 성공 지표 (KPI)
- 기획서 §3 KPI를 기능 단위로 분해

## 7. 의존성·외부 인터페이스
- Claude CLI / GitHub / gstack / 사내 시스템

## 8. Open questions
- ID로 관리, docs/planning/open-items.md 또는 ADR로 이관

## 9. 추적성 매트릭스 (Traceability)
| F-ID | 출처 R-ID | UC | 다음 매핑(Issue) |
|---|---|---|---|
| F-AGENT-01 | R-AGENT-01, R-AGENT-02 | UC-01 | 미할당 |

## 변경 이력
| Version | Date | Author | Change |
```

## 실행 단계
1. 입력 5개 모두 Read. 누락 시 BLOCKED.
2. SRS R-ID를 **사용자 가치 단위**로 재묶음 → 기능 후보 추출.
3. 페르소나 2~3 정의 → JTBD 1줄씩.
4. 기능 후보에 ID 부여(`F-{영역}-{번호}`), 우선순위·MVP 포함 여부 결정.
5. 각 F-ID에 사용자 흐름·UI 요구·수용 기준·**3축 검증 시나리오 (MUST, ADR-0014)** 작성: 테스트 레벨(단위/통합/E2E) + Happy path + Failure path. **schema BLOCK 강제**이므로 누락 시 `validate-doc.sh` 차단. **13 Test Design** `02-catalog.md`의 해당 레벨 섹션(ADR-0036)이 fan-in 대상 — 이슈 단위 누락은 ADR-0035의 `check-test-catalog-sync.sh`가 WARN.
6. MVP Cut Line 명시. 제외 항목은 사유 1줄.
7. 추적성 매트릭스가 SRS R-ID를 100% 커버하는지 검증 (커버 누락 시 BLOCKED).
8. docs/planning/open-items.md / SRS Open questions와 충돌 검사.
9. 저장. docs/planning/CHANGELOG.md §"Current Status" 갱신은 `/docs-update`가 담당.

## 완료 조건
- 모든 MVP 기능에 우선순위·매핑 R-ID·수용 기준 채워짐
- **80% 이상의 MVP 기능에 테스트 시나리오 직접 작성됨** (나머지는 fallback 마커 허용)
- MVP Cut Line 명시 + 제외 사유 1줄
- 추적성 매트릭스가 SRS R-ID를 100% 커버
- 팀 리뷰 통과(게이트 B 2차 조건)

## Strict Rules
- 1결정-1파일 ADR 발생 시 즉시 `docs/planning/adr/NNNN-*.md` 작성 (policies/flow-and-gates.md §3.3)
- 시크릿·내부망 URL 본문 삽입 금지 (CLAUDE.md 보안 룰)
- SRS R-ID에 매핑되지 않은 기능 등장 시 BLOCKED → SRS로 회귀하여 R-ID 추가

## BLOCKED 케이스
| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: 입력 부재 — 04-srs.md` | SRS 미작성 | `/srs` 회귀 |
| `BLOCKED: 미매핑 기능 — F-XX` | SRS R-ID 매핑 없음 | SRS에 R-ID 추가 또는 기능 제거 |
| `BLOCKED: SRS 커버리지 < 100%` | R-ID가 어떤 F-ID에도 안 잡힘 | 누락 R-ID에 F-ID 신설 또는 명시적 Out 표기 |
| `BLOCKED: MVP Cut Line 부재` | Phase 2/Out 분류 누락 | §4 작성 후 재진입 |
| `BLOCKED: 테스트 시나리오 0건` | 상류 도출 부재 | 최소 1개 F-ID에 시나리오 작성 후 재진입 |

## Artifact Binding
- 입력: `01-project-brief.md`, `03-user-scenarios.md`, `04-srs.md`, `docs/planning/INDEX.md`
- 출력: → `/ux-flow-design`(07 입력), `/implementation-planner`(06·08 입력), `/wbs`(이슈 분해 시 입력)
- 페어링:
  - 게이트 B 검토: 팀 리뷰 미팅
  - 게이트 C 진입 전 검토: `/plan-eng-review`
  - 결정 발생 시: ADR 직접 작성

## 트리거 매칭
"PRD 작성", "기능 카탈로그", "MVP 정의", "F-ID", "05-prd.md"
