# COMMANDS_REFERENCE — 명령어 상세 사용법

> **위치**: `.claude/COMMANDS_REFERENCE.md`
> **대상**: agent-toolkit (DevToolKit v6) 작업자
> **버전**: v0.2 (2026-04-30) — Step 1 Command 통합 정합 갱신 (Meta 5→2 + Sub 3종 모드 흡수)
> **선행 문서**: [USAGE_GUIDE.md](USAGE_GUIDE.md), [harness/feature-development-harness.md](harness/feature-development-harness.md)

본 문서는 17개 Command의 **상세 사용법**을 다룬다 (2026-04-30 통합 후. 7개 항목은 deprecate, 1.3·3.1·4.3·11.1에 redirect 안내). 각 Command는 다음 항목으로 구성:

- **요약**
- **언제 호출**
- **호출 예시** (CLI 또는 Claude 발화)
- **입력 / 출력**
- **모드별 동작** (planning vs sprint)
- **자주 마주치는 BLOCKED**
- **다음 Command**

---

## 0. 사전 지식

### 0.1 Mode 시스템

명령어는 두 모드 중 하나로 동작한다 (자동 감지):

| 모드 | 작업 정본 | 사용 시점 |
|---|---|---|
| `planning` | `docs/planning/` 산출 문서 | WBS 미등록 (게이트 A/B/C 통과 전) |
| `sprint` | GitHub Issue (#N) | sprint-bootstrap 후 (개발 단계) |

`/context-loader` 또는 `/start-feature` 첫 실행 시 자동 결정.
수동 override: `/start-feature --mode=sprint`

### 0.2 호출 방법

- **Claude CLI 슬래시**: `/context-loader`, `/flow-feature-add` 등
- **자연어 트리거**: "기능 만들자", "이어서" 등 (Harness 자동 진입)

### 0.3 산출물 명명 규약

| 패턴 | 예시 |
|---|---|
| 신규 프로젝트 산출 문서 (01~14 + adr/) | `docs/planning/01-project-brief/01-project-brief.md` (ADR-0015 폴더 강제) |
| 이슈/기능 단위 | `docs/features/feat-<slug>/feat-<slug>.<artifact>.md` (manifest §3.2) |
| 버그 단위 | `docs/features/bug-<slug>/bug-<slug>.<artifact>.md` |
| 디자인 변경 | `docs/features/design-<slug>/design-<slug>.<artifact>.md` |
| 수정/리팩토링 단위 | `docs/features/mod-<slug>/mod-<slug>.<artifact>.md` |
| ADR | `docs/planning/adr/NNNN-<slug>.md` |

---

# 카테고리 1 — Meta Routing

## 1.1 `/start-feature`

### 요약
**Meta Routing 게이트웨이.** 자유 입력 → Flow 분류 → 적절한 `/flow-*` 호출.

### 언제 호출
- 작업 의도가 명확하지 않을 때
- 어떤 Flow를 써야 할지 모를 때
- 첫 세션 시작

### 호출 예시
```
/start-feature 사용자 시나리오 문서를 작성하고 싶다
/start-feature #45 작업 시작
/start-feature --mode=sprint 다크모드 도입
```

### 입력
- 자연어 의도 (필수)
- (선택) `--mode=planning|sprint`
- (선택) `--issue=#N`

### 출력
- 분류 결과 1줄 보고
- `.claude/state/flow-state.yaml` 초기화
- 다음 Command 자동 호출 (또는 안내)

### 모드별 동작
| | planning | sprint |
|---|---|---|
| 분류 신호 | 산출 문서 키워드 ("brief", "scenario", "PRD") | 이슈 번호, 라벨 (`type:bug`, `type:feature`) |
| 결과 | `/flow-new-project` 또는 `/flow-feature-add` | 동일하나 이슈 컨텍스트 포함 |

### 자주 마주치는 BLOCKED
- **분류 모호**: 사용자에게 1~2개 명확화 질문
- **trigger 발화 + 동시에 명시 Command**: 명시 Command 우선

### 다음 Command
- 분류 결과의 `/flow-*`
- 또는 `/context-loader` (현재 위치 모를 때)

---

## 1.2 `/flow-new-project`

### 요약
새 프로젝트 시작. 게이트 A → B → C → WBS → Sprint 1+ 흐름.

### 언제 호출
- 빈 저장소 / PRD 부재 상태
- 본 agent-toolkit v6 같은 신규 프로젝트 부트스트랩

### 호출 예시
```
/flow-new-project 사내 표준 자율 개발 에이전트 만들기
```

### 입력
- 1줄 정의 (필수)
- (있으면) reference 자산 경로 (예: `docs/devtoolkit/PRD.md` v5 archive)

### 출력 (단계별)
```
01-project-brief.md         (게이트 A)
02-feasibility.md           (게이트 A)
03-user-scenarios.md
04-srs.md, 05-prd.md        (게이트 B)
06-architecture.md          (Architecture 본체, ADR-0031)
07-hld.md                   (HLD 본체, ADR-0031 신설)
08-lld-module-spec.md           (LLD 본체)
09-lld-api-spec.md
10-lld-screen-design.md         (BE-only 시 status: N/A 골격)
11-coding-conventions.md
12-scaffolding/<lang>.md
13-test-design/             (게이트 C, 5절 폴더, ADR-0030)
14-wbs.md
15-risk.md                  (운영)
adr/NNNN-*.md               (병행)
→ scripts/sprint-bootstrap.sh → mode=sprint 전환
```

### 모드 변화
- 시작: `mode=planning`
- WBS 등록 직후: `mode=sprint` 자동 전환

### 자주 마주치는 BLOCKED
- 게이트 A 미통과로 게이트 B 진입 시도
- WBS 미작성 상태로 sprint 모드 강제 시도

### 다음 Command
- `/product-brainstorm` (의도 모호)
- `/intention-brief` (의도 명확)

---

## 1.3 `/flow-feature` *(2026-04-30 통합)*

### 요약
**이슈 단위 작업의 단일 메타 진입점.** 4가지 모드(add/modify/bug/design) 자동 감지. 가장 빈번한 Flow.

> **2026-04-30 통합** — 기존 `/flow-feature-add`·`/flow-feature-modify`·`/flow-bug-fix`·`/flow-design-change` 4종을 본 명령어로 통합·deprecate.

### 모드 자동 감지

| 신호 | 판정 모드 |
|---|---|
| `type:bug` 라벨 / "에러", "안 돼" / 로그 첨부 | **bug** |
| UI/시각/token/리브랜딩/다크모드 키워드 | **design** |
| 기존 동작 변경 / breaking 가능성 | **modify** |
| 기본값 (위 미해당) | **add** |

수동 override: `/flow-feature --mode=add|modify|bug|design`

### 호출 예시
```
/flow-feature #12                                    # 자동 감지
/flow-feature "Sprint 1 이슈 #12 — 로그인 폼 추가"
/flow-feature --mode=bug "이슈 #34: PR 본문에 Test Plan 누락"
/flow-feature --mode=modify "이슈 #50: GitHub API rate limit 회피"
/flow-feature --mode=design "다크모드 토큰 도입"
/flow-feature "X 함수 분리"                          # 파생 이슈 (독립, ADR-0008)
```

### 모드별 강조·산출 접두

| 모드 | 강조/필수 | 산출 접두 | 핵심 원칙 |
|---|---|---|---|
| **add** | change-contract 가벼움, ux 선택 | `feat-<slug>` | 최소 침습 |
| **modify** | change-contract 무거움(Before/After), risk-check, **ADR 필수** | `mod-<slug>` | deprecation 경로 |
| **bug** | **debug-investigator 선행**, 회귀 테스트 강제 | `bug-<slug>` | 추측 기반 수정 금지 |
| **design** | ux-flow + ui-design-review + `--consistency` 두 번 | `design-<slug>` | a11y, token 단일 PR 일괄 |

### 입력
- 의도 또는 이슈 번호 (필수)
- (선택) `--mode=add|modify|bug|design`

### 출력
모든 모드 공통 (manifest §3.2 정본, slug에 모드 접두 포함):
```
docs/features/<접두>-<slug>/<접두>-<slug>.brief.md
docs/features/<접두>-<slug>/<접두>-<slug>.contract.md
docs/features/<접두>-<slug>/<접두>-<slug>.plan.md
docs/features/<접두>-<slug>/<접두>-<slug>.acceptance.md
docs/features/<접두>-<slug>/<접두>-<slug>.risk.md
+ 코드 + 테스트 + (mode=sprint) PR
+ (mode=bug) 재현·회귀 테스트
+ (mode=design) before/after 스크린샷 → docs/features/<접두>-<slug>/screenshots/
+ (mode=modify) ADR 필수 → docs/planning/adr/NNNN-*.md
```

### 모드별 동작 (planning vs sprint)
| 단계 | planning | sprint |
|---|---|---|
| 작업 단위 | 산출 문서 묶음 | Issue #N |
| Blocked-by 검사 | skip | 필수 |
| FSM 라벨 | `flow-state.gates`만 | `status:in-progress` |
| 마지막 단계 | `/docs-update`까지 | + PR + tested 라벨 게이트 |

### 자주 마주치는 BLOCKED
- 모드 자동 감지 실패 → 사용자에게 1~2개 질문
- mode=bug 재현 실패
- mode=modify breaking change + ADR 부재
- mode=design `/ui-design-review` 미통과
- `Blocked-by:` 미해소 (sprint)
- `change-contract` 누락 / `/plan-eng-review` 미통과

### 다음 Command
- `/context-loader` 먼저
- 그 다음 Phase 순서대로 (`/flow-feature` 본문 Phase Sequence 참조)

---

# 카테고리 2 — Context

## 2.1 `/context-loader`

### 요약
**Resumability 자동화.** 어디까지 했는지 한 눈에.

### 언제 호출
- 새 세션 시작 직후 (필수)
- 컨텍스트 손실 의심 시
- "이어서", "복원" 등 발화

### 호출 예시
```
/context-loader
/context-loader --issue=#42
```

### 출력 (콘솔 보고)
```
📍 현재 위치
- Mode: planning
- Phase: 게이트 A 통과 / B 진행 중
- Active Flow: flow-new-project
- Branch: dev/agent-ui

📦 산출물 상태
- ✅ docs/planning/01-project-brief/01-project-brief.md (v0.3)
- ⏳ docs/planning/03-user-scenarios/03-user-scenarios.md (없음)
- ⏳ docs/planning/04-srs/04-srs.md (없음)

🚧 누락 정보
- O-01 결정 필요
- GitHub repo URL 미확정 (sprint 모드 진입 차단)

➡️ 권고 다음 Command
- /intention-brief "사용자 시나리오 작성"
```

### 모드별 동작
| 단계 | planning | sprint |
|---|---|---|
| 진행 중 작업 식별 | 가장 최근 수정된 docs/planning 파일 | `gh issue list --label status:in-progress` |
| DoD 확인 | acceptance.md | 이슈 본문 체크리스트 |
| `gh-cli` 호출 | skip (없으면) | 필수 (실패 시 planning fallback + 경고) |

### 자주 마주치는 BLOCKED
- (없음 — 본 Command는 절대 BLOCKED 되지 않음. 정보 부족 시 그대로 보고)

### 다음 Command
- 보고서의 "권고 다음 Command" 그대로

---

# 카테고리 3 — 기획

## 3.1 `/product-brainstorm` *(2026-04-30 deprecate)*

→ **`/intention-brief --brainstorm`** 모드로 흡수. §3.2 참조.

호출 예시:
```
/intention-brief --brainstorm "자율 에이전트가 PR 머지 후 자동으로 다음 이슈 픽업하게 만들기"
```

---

## 3.2 `/intention-brief`

### 요약
의도를 **한 페이지짜리 결정**으로 응축.

### 언제 호출
- `/product-brainstorm` 직후
- 의도 명확하나 문서 없음
- `/flow-feature-add` Phase 2

### 호출 예시
```
/intention-brief 사용자 시나리오 작성
/intention-brief feat-notification "알림 기능 도입"
```

### 입력
- (있으면) brainstorm 결과
- 자연어 의도

### 출력 (Flow별 분기)
| Flow | 경로 |
|---|---|
| flow-new-project | `01-project-brief.md` |
| flow-feature-add/modify | `feat-<slug>.brief.md` |
| flow-bug-fix | `bug-<slug>.brief.md` (보조) |
| flow-design-change | `design-<slug>.brief.md` |

### 8섹션 필수
1. One-liner / 2. Problem / 3. Why now / 4. Scope / 5. Success / 6. Constraints / 7. Open questions / 8. Next

### 자주 마주치는 BLOCKED
- 8섹션 중 1개 이상 누락
- One-liner > 1줄
- Open questions에 ID 미부여

### 다음 Command
- `/change-contract` (변경 통제 시작)
- 또는 `/ux-flow-design` (UI 영향)

---

# 카테고리 4 — UX

## 4.1 `/ux-flow-design`

### 요약
사용자 흐름·화면 상태 명세.

### 언제 호출
- UI 있는 기능 구현 직전
- `/flow-design-change` Phase 2
- 복잡한 상태 머신 화면

### 호출 예시
```
/ux-flow-design feat-notification "알림 토스트 + 알림 센터"
```

### 출력
- `feat-<slug>.ux.md`
- 8섹션 (흐름도, 상태, wireframe, 데이터, 의존성, a11y, 회귀 영향)

### 자주 마주치는 BLOCKED
- 5종 상태(idle/loading/success/error/empty) 미명시
- mermaid 흐름도 검증 실패

### 다음 Command
- `/ui-design-review` (시각 검토)
- 또는 `/change-contract`

---

## 4.2 `/ui-design-review`

### 요약
**한 화면 깊게** 검토. 시각적 품질·구현 정확도.

### 언제 호출
- 화면 구현 직후, PR 직전
- `/flow-design-change` Phase 3

### 호출 예시
```
/ui-design-review feat-notification
```

### 출력
- `feat-<slug>.ui-review.md`
- PASS / FAIL / NEEDS-WORK 판정

### 점검 항목 (9개)
시각 일치 / 토큰 사용 / 5상태 / 반응형 / 색대비 / 포커스 / 한글 텍스트 / 다크모드 / 모션

### 자주 마주치는 BLOCKED
- 하드코딩된 색·폰트·spacing 발견 → 자동 FAIL
- wireframe과 구조 불일치 → FAIL

### 다음 Command
- PASS → `/qa-test`
- NEEDS-WORK 이상 → `/implement` 재진입

---

## 4.3 `/design-consistency-review` *(2026-04-30 deprecate)*

→ **`/ui-design-review --consistency`** 모드로 흡수. §4.2 참조.

호출 예시:
```
/ui-design-review --consistency --tokens-changed=primary,secondary
```

`/flow-feature --mode=design`은 두 모드를 모두 사용 — 구현 전 기본 모드, 구현 후 `--consistency` 재실행.

---

# 카테고리 5 — 변경 통제

## 5.1 `/change-contract`

### 요약
**계약 없이 변경 금지** 원칙의 핵심. 변경 전/후·이유·영향·롤백 명세.

### 언제 호출
- 모든 코드 변경의 직전 (필수)
- `/flow-feature-modify` Phase 3 (필수)

### 호출 예시
```
/change-contract feat-notification
/change-contract bug-test-plan-missing
```

### 입력
- brief (또는 이슈 본문)
- 영향 코드 위치 식별

### 출력
- `<slug>.contract.md`
- 6섹션: 의도 / Before-After / 영향 범위 / 호환성 / Rollback / 검증 방법

### 자주 마주치는 BLOCKED
- 호출자 미추적
- breaking 표시인데 migration plan 없음
- Rollback "불가" + 사용자 명시 승인 없음

### 다음 Command
- `/implementation-planner`
- 또는 `/risk-check`

---

# 카테고리 6 — 설계

## 6.1 `/implementation-planner`

### 요약
contract → **커밋 단위 실행 계획**.

### 언제 호출
- `change-contract` 직후
- 코드 작성 직전

### 호출 예시
```
/implementation-planner feat-notification
```

### 출력
- `<slug>.plan.md`
- Subtask 표 (작업/파일/테스트/시간)
- DAG 의존 그래프

### 자주 마주치는 BLOCKED
- DAG 순환
- 테스트 미매핑 Subtask
- 24시간 초과 추정 (이슈 분할 권고)

### 다음 Command
- `/plan-eng-review`

---

## 6.2 `/plan-eng-review`

### 요약
**개발 착수 전 게이트**. PASS 없이 `/implement` 진입 거부.

### 언제 호출
- `change-contract` + `plan` 작성 직후 (필수)

### 호출 예시
```
/plan-eng-review feat-notification
```

### 출력
- `<slug>.eng-review.md`
- PASS / FAIL / NEEDS-WORK
- 후속 액션 리스트

### 점검 항목 (8개)
contract 정확성 / plan 커버리지 / 테스트 plan / 코딩 컨벤션 / 보안 룰 / 의존성 해소 / Rollback / 추정 작업량

### 자주 마주치는 BLOCKED
- verdict ≠ PASS → 회귀할 Phase 안내됨
- 의존성 미해소 (sprint)

### 다음 Command
- PASS → `/acceptance-criteria`
- FAIL → `/change-contract` 또는 `/implementation-planner` 회귀

---

# 카테고리 7 — 완료 기준

## 7.1 `/acceptance-criteria`

### 요약
완료를 **검증 가능한 항목**으로 못 박기. 이슈 DoD + PR Test Plan 시드.

### 언제 호출
- 구현 직전 / 직후
- PR 본문 4블록 생성 직전

### 호출 예시
```
/acceptance-criteria feat-notification
```

### 출력
- `<slug>.acceptance.md`
- 4섹션: Functional / UX / 회귀 / Test Plan 시드 (Build/Automated/Manual/DoD)

### 자주 마주치는 BLOCKED
- 항목이 측정 불가능 (애매한 형용사)
- modify/bug-fix인데 회귀 항목 0개

### 다음 Command
- `/risk-check`
- 또는 `/implement`

---

# 카테고리 8 — 리스크

## 8.1 `/risk-check`

### 요약
**부정적 시나리오·블라스트 반경·완화책** 점검.

### 언제 호출
- contract 직후, `/implement` 직전
- modify/design-change Phase 4 (필수)
- 외부 의존 변경 시

### 호출 예시
```
/risk-check feat-notification
```

### 출력
- `<slug>.risk.md`
- 7개 카테고리 (회귀/성능/보안/비용/의존성/데이터/운영)
- 등급 (High/Med/Low)

### 자주 마주치는 BLOCKED
- secret 노출 가능성 → 즉시 STOP
- High 리스크 + 완화책 부재

### 다음 Command
- `/implement` (PASS 시)

---

# 카테고리 9 — 구현

## 9.1 `/implement`

### 요약
모든 게이트 PASS 상태에서 **코드 작성**.

### 언제 호출
- 진입 체크리스트 모두 ✅

### 호출 예시
```
/implement feat-notification
```

### 진입 전 체크 (모드별)

**전역**:
- contract / plan / acceptance / eng-review(PASS) / risk(High 완화) 모두 존재
- branch 분기됨

**mode=sprint 추가**:
- Issue가 `status:in-progress`
- Blocked-by 모두 closed
- 브랜치명 `feat/<slug>-issue-<N>`

**mode=planning**:
- 이슈/라벨 검증 skip
- docs-only 변경은 main 직접 작업도 허용

### 출력
- 코드 + 단위 테스트 + 커밋
- 빌드 통과 증거

### FSM 전이
- mode=sprint: 진입 시 `status:in-progress`, 종료 시 `status:in-review`
- mode=planning: `flow-state.current_phase` 만 갱신

### 자주 마주치는 BLOCKED
- 진입 체크리스트 미충족 → 회귀할 Phase 안내
- 단위 테스트 누락
- 코딩 컨벤션 위반
- 보안 파일 Write/Edit 시도 (settings.json 훅이 1차 차단)

### 다음 Command
- `/code-review`

---

# 카테고리 10 — 검증

## 10.1 `/code-review`

### 요약
**Generator≠Evaluator 핵심.** `/implement` 결과를 contract와 대조.

### 언제 호출
- `/implement` 직후, PR 직전
- 가능하면 별도 컨텍스트 (또는 reviewer 에이전트)

### 호출 예시
```
/code-review feat-notification
```

### 출력
- `<slug>.code-review.md`
- 10항목 체크리스트 결과

### 점검 항목
contract 반영 / plan 커버리지 / 테스트 매핑 / acceptance 검증 가능 / 보안 / 컨벤션 / scope creep / 죽은 코드 / 의존성 정당성 / 에러 처리

### 자주 마주치는 BLOCKED
- 시크릿 발견 → 즉시 STOP
- scope creep (contract에 없는 변경)
- 자기 작성 코드에 PASS 부여 시도

### 다음 Command
- `/qa-test`

---

## 10.2 `/qa-test`

### 요약
**PR Test Plan 4블록 생성** (D-06 강제).

### 언제 호출
- `/code-review` PASS 후
- PR 생성 직전

### 호출 예시
```
/qa-test feat-notification
```

### 출력
- `<slug>.qa-report.md`
- (mode=sprint) PR 자동 생성, 본문에 4블록

### 4블록
- **Build**: 빌드 명령 결과
- **Automated tests**: 자동 테스트 결과
- **Manual verification**: 사람이 검증할 항목 (체크박스)
- **DoD coverage**: acceptance ↔ diff 매핑 표

### 모드별 동작
| | planning | sprint |
|---|---|---|
| PR 생성 | skip 또는 docs-only | 필수 + Closes #N |
| 라벨 갱신 | skip | `status:in-review` |
| 머지 게이트 | 사람 검토 | CI + Approve + tested 라벨 |

### 자주 마주치는 BLOCKED
- 4블록 누락
- Build/Automated 미통과
- DoD coverage 매핑 누락 항목

### 다음 Command
- `/docs-update`
- (UI 변경 시) `/ui-design-review` + `/design-consistency-review` 먼저

---

# 카테고리 11 — 개선

## 11.1 `/refactor-review` *(2026-04-30 deprecate)*

→ **`/code-review --refactor`** 모드로 흡수. §10.x(code-review) 참조.

호출 예시:
```
/code-review --refactor feat-notification
```

큰 리팩토링은 `/flow-feature --mode=modify` 별도 진입.

---

# 카테고리 12 — 디버깅

## 12.1 `/debug-investigator`

### 요약
**조사 없이 수정 금지.** 재현 → 가설 → 검증 → 근본 원인.

### 언제 호출
- `/flow-bug-fix` Phase 1 (필수)
- 알 수 없는 동작
- 인시던트 트리아지

### 호출 예시
```
/debug-investigator #34 PR 본문에 Test Plan 누락
```

### 출력
- `bug-<slug>.investigation.md`
- 7섹션 (요약/재현/영향/가설/검증/원인/수정plan)

### 자주 마주치는 BLOCKED
- 재현 실패 → 사용자에게 정보 요청
- 가설 1개만 (confirmation bias)
- 추측 기반 fix plan

### 다음 Command
- `/change-contract` (수정 계약)
- 또는 `/risk-check`

---

# 카테고리 13 — 문서화

## 13.1 `/docs-update`

### 요약
변경 흔적을 **재개 가능한 문서**로.

### 언제 호출
- 모든 Flow 마지막 단계
- 결정 발생 직후 (ADR)
- docs/planning/CHANGELOG.md §"Current Status" 갱신 시점

### 호출 예시
```
/docs-update feat-notification
```

### 갱신 대상 (변경 성격에 따라)
| 변경 | 갱신 |
|---|---|
| 결정 발생 | ADR (필수) |
| 의미 있는 산출 | docs/planning/CHANGELOG.md §"Current Status" |
| 사용자 노출 변화 | CHANGELOG.md |
| 디자인 변경 | 디자인 시스템 changelog |
| API 변경 | 09-lld-api-spec.md |
| 운영 절차 | CLAUDE.md Addendum |

### ADR 필수 케이스
- 외부 의존성 변경 / breaking change / 아키텍처 결정 / Workaround만 적용

### 13/02-catalog 동기화 (ADR-0035, 실행 단계 §9)
이슈 진행 중 04 SRS · 05 PRD에 신규/변경 R-/F-ID가 발생했으면 본 Command 실행 단계 §9에서 자동 호출:

```
bash .claude/scripts/check-test-catalog-sync.sh
```

WARN 출력 시 누락 R-/F-ID를 `13-test-design/02-catalog.md`의 해당 레벨 섹션(§1 단위 / §2 통합 / §3 E2E — ADR-0036)에 `### R-NN`/`### F-NN` fan-in. 차단 없음(exit 0).

### 자주 마주치는 BLOCKED
- 결정이 있었는데 ADR 미작성
- docs/planning/CHANGELOG.md §"Current Status"가 현재 상태와 불일치

### 다음 Command
- (Flow 종료) DONE
- 또는 다음 이슈로 `/start-feature`

---

# 부록 A — Flow별 Command 시퀀스 표

## A.1 flow-new-project (mode=planning, 게이트 통과 후 sprint 전환)

| Step | Command | Output | 모드 |
|---|---|---|---|
| 1 | /context-loader | flow-state.yaml | planning |
| 2 | /product-brainstorm | _brainstorm/<slug>.md | planning |
| 3 | /intention-brief | 01-project-brief.md | planning |
| (게이트 A) | (사용자/팀장 컨펌) | gates.A=PASS | |
| 4 | /intention-brief × 다수 | 03, 04, 05 | planning |
| (게이트 B) | (팀 합의) | gates.B=PASS | |
| 5 | /implementation-planner --mode=architecture | 06-architecture.md | planning |
| 5a | /implementation-planner --mode=hld | 07-hld.md (ADR-0031 신설) | planning |
| 6 | /implementation-planner --mode=module | 08-lld-module-spec.md | planning |
| 7 | /implementation-planner --mode=api | 09-lld-api-spec.md | planning |
| 7a | /ux-flow-design (와이어프레임) | 10-lld-screen-design.md (BE-only 시 N/A 골격) | planning |
| 7b | /implementation-planner --mode=conventions | 11-coding-conventions.md | planning |
| 7c | /implementation-planner --mode=scaffold --lang=<x> | 12-scaffolding/<x>.md | planning |
| 7d | /implementation-planner --mode=test | 13-test-design/ (5절 폴더) | planning |
| 8 | /plan-eng-review | gates.C=PASS | planning |
| 9 | /wbs + /risk-check | 14-wbs.md, 15-risk.md | planning |
| 10 | scripts/sprint-bootstrap.sh | GitHub Milestones+Issues | **→ sprint 전환** |
| 11+ | /flow-feature-add 반복 | 코드 + PR | sprint |

## A.2 flow-feature-add (mode=sprint 가정)

| Step | Command | Output |
|---|---|---|
| 1 | /context-loader | (이슈 식별) |
| 2 | /intention-brief | feat-<slug>.brief.md |
| 3 | /ux-flow-design (UI 영향 시) | feat-<slug>.ux.md |
| 4 | /change-contract | feat-<slug>.contract.md |
| 5 | /implementation-planner | feat-<slug>.plan.md |
| 6 | /plan-eng-review | feat-<slug>.eng-review.md (PASS) |
| 7 | /acceptance-criteria | feat-<slug>.acceptance.md |
| 8 | /risk-check | feat-<slug>.risk.md |
| 9 | /implement | 코드 + 테스트 + 커밋 |
| 10 | /code-review | feat-<slug>.code-review.md (PASS) |
| 11 | /qa-test | feat-<slug>.qa-report.md + PR |
| 12 | /ui-design-review (UI 변경 시) | feat-<slug>.ui-review.md |
| 13 | /docs-update | ADR / CHANGELOG / docs/planning/CHANGELOG.md §"Current Status" |
| 14 | (사람) PR 빌드+검증+승인 | tested 라벨 → 머지 |

## A.3 flow-bug-fix

| Step | Command | Output |
|---|---|---|
| 1 | /context-loader | |
| 2 | /debug-investigator | bug-<slug>.investigation.md |
| 3 | /change-contract | |
| 4 | /risk-check | |
| 5 | /implement (회귀 테스트 필수) | |
| 6 | /code-review | |
| 7 | /qa-test | |
| 8 | /docs-update (필요 시 ADR) | |
| 9 | (사람) PR 머지 | |

## A.4 flow-feature-modify

(flow-feature-add와 동일 + ADR 필수 + 회귀 항목 명시 강조)

## A.5 flow-design-change

| Step | Command | Output |
|---|---|---|
| 1 | /context-loader | |
| 2 | /ux-flow-design (필수) | before/after |
| 3 | /ui-design-review (필수) | |
| 4 | /design-consistency-review (필수) | 매트릭스 |
| 5 | /change-contract | token 변경 매트릭스 |
| 6 | /risk-check (시각 회귀 포함) | |
| 7 | /implementation-planner | |
| 8 | /plan-eng-review | |
| 9 | /acceptance-criteria | |
| 10 | /implement | |
| 11 | /code-review | |
| 12 | /qa-test (스냅샷·반응형) | |
| 13 | /design-consistency-review (재실행) | |
| 14 | /docs-update | 디자인 changelog |

---

# 부록 B — 자주 마주치는 BLOCKED 상황 통합 표

| 메시지 | 원인 | 해결 |
|---|---|---|
| `BLOCKED: change-contract 부재` | 코드 수정 시도 시 contract 없음 | `/change-contract` 먼저 |
| `BLOCKED: eng-review verdict=FAIL` | 검토 미통과 | contract/plan 재작성 |
| `BLOCKED: Blocked-by 미해소 #N` (sprint) | 선수 이슈 진행 중 | #N 완료 대기 또는 우선순위 조정 |
| `BLOCKED: 단위 테스트 누락` | 테스트 없이 머지 시도 | plan에 매핑된 테스트 추가 |
| `BLOCKED: tested 라벨 부재` (sprint) | 사람의 검증 미완 | 본인이 빌드+검증 후 라벨 부착 |
| `BLOCKED: 시크릿 의심 노출` | secret 노출 가능성 | 즉시 STOP, /cso 점검, 코드/로그 정리 |
| `BLOCKED: 게이트 A 미통과` (planning) | 팀장 컨펌 없이 다음 단계 진입 | 컨펌 후 진행 |
| `BLOCKED: 산출물 누락` | Phase의 Output 파일 없음 | 해당 Phase 먼저 완료 |
| `BLOCKED: 재현 실패` (bug-fix) | 결함 재현 안 됨 | 사용자에게 추가 정보 요청 |
| `BLOCKED: gh-cli 미설정` (sprint) | GitHub repo·인증 안 됨 | mode=planning fallback 또는 gh auth login |
| `BLOCKED: 보안 파일 Write 시도` | .env*, *.key 등 | 작업 중단, 경로 재검토 |
| `BLOCKED: scope creep` | contract에 없는 변경 발견 | contract 갱신 또는 변경 되돌림 |

---

# 부록 C — gstack 스킬과의 페어링

| Phase | 본 Command | 보완 gstack 스킬 |
|---|---|---|
| 설계 게이트 | `/plan-eng-review` | `/plan-eng-review`(gstack) — 동명, 절차 보완 |
| 코드 리뷰 | `/code-review` | `/review` |
| QA | `/qa-test` | `/qa`, `/qa-only` |
| 리스크 점검 | `/risk-check` | `/cso` (보안 전문) |
| 디버깅 | `/debug-investigator` | `/investigate` |
| 디자인 리뷰 | `/ui-design-review` | `/design-review`, `/design-consultation` |
| 배포 | (별도) | `/ship`, `/land-and-deploy`, `/canary` |
| (전반) | — | `/careful` 상시 활성 (CLAUDE.md 필수 규칙 8) |

병행 호출 권장. 본 Command는 흐름 통제, gstack은 절차 깊이.

---

# 부록 D — 빠른 참조

```
새 세션              → /context-loader
모호한 의도          → /start-feature "<자연어>"
새 프로젝트          → /flow-new-project "<1줄 정의>"
기능 추가 (sprint)   → /flow-feature-add #<N> "<의도>"
기능 추가 (planning) → /flow-feature-add --no-issue "<의도>"
기능 변경            → /flow-feature-modify "<대상> <의도>"
버그                 → /flow-bug-fix "<재현/이슈>"
디자인               → /flow-design-change "<의도>"
재개                 → /context-loader
```

---

# 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1 | 2026-04-29 | 이채 | 초안 작성. mode=planning/sprint 분리 적용 |
