# Feature Development Harness

> **Strict Harness Mode**. 본 하네스 없이 코드 작성·변경·머지 금지.

본 문서는 `agent-toolkit (DevToolKit v6)` 프로젝트의 **Phase ↔ Command ↔ Artifact** 결정 트리. 모든 Command는 본 하네스 규칙을 따르며, 위반 시 자동 BLOCKED.

---

## 0. 하네스 진입 조건

다음 발화 또는 상황에서 자동 트리거:

- "기능 만들자"
- "구현해줘"
- "설계부터"
- "전체 흐름으로"
- "하네스로 진행"
- 사용자가 `/start-feature`, `/flow-*` 명시 호출

진입 즉시 `.claude/state/flow-state.yaml` 작성.

### 0.1 모드 자동 감지

`/context-loader` 또는 `/start-feature` 첫 실행 시 다음 규칙으로 `mode`를 결정:

```
1. docs/planning/CHANGELOG.md §"Current Status" 의 게이트 C 통과 표시가 있고 + scripts/sprint-bootstrap.sh 실행 흔적
   AND  GitHub repo URL이 docs/planning/INDEX.md 또는 .git/config 에 명시
   → mode: sprint
2. 그 외
   → mode: planning
```

수동 override:
- `/start-feature --mode=sprint`
- `/start-feature --mode=planning`

mode가 결정되면 모든 후속 Command가 그 모드로 동작.

### 0.2 Mode별 작동 차이 요약

| 항목 | mode=planning | mode=sprint |
|---|---|---|
| 작업 정본 | `docs/planning/` 산출 문서 | GitHub Issue (#N) |
| `gh-cli` 사용 | 옵셔널 (없으면 skip) | 필수 |
| 의존성 표현 | 문서 내 "Open questions / Blocked" 섹션 | 이슈 본문 `Blocked-by: #N` |
| FSM 상태 | 게이트 A/B/C (`flow-state.gates`) | GitHub 라벨 (`status:*`) |
| PR | 생성하지 않거나 docs-only PR | 이슈 단위 PR + D-06 머지 게이트 |
| 진행 단위 | 산출 문서 1개 = 작업 1개 | Issue 1개 = 작업 1개 (1~3 working days) |
| `tested` 라벨 | N/A | 머지 게이트 (policies/sprint-cycle.md §2) |
| `Closes #N` | N/A | PR 본문 자동 삽입 |

---

## 1. 상태(State) 정의

```yaml
# .claude/state/flow-state.yaml
schema_version: 1
session_id: <claude session id>

# 작업 정본 모드 (Pre-WBS = 문서 정본, Post-WBS = GitHub 이슈 정본)
mode: planning | sprint
# - planning: WBS·GitHub Milestone 미등록 단계.
#   * 작업 단위 = docs/planning/ 산출물
#   * gh-cli 호출은 옵셔널 (없으면 skip)
#   * `Blocked-by`, status 라벨 등은 적용 안 함
# - sprint: scripts/sprint-bootstrap.sh 실행 후, 이슈 단위 작업 단계
#   * 작업 단위 = GitHub Issue (#N)
#   * gh-cli 필수
#   * FSM ↔ Label 매핑·Blocked-by·tested 라벨 모두 적용

issue: { number: <N>, title: "...", url: "..." }   # mode=sprint에서만 의미

active_flow: <flow-new-project | flow-feature (mode=add|modify|bug|design)>
current_phase: <Phase 식별자 (예: P3-change-contract)>
last_command: </command-name>
last_command_at: <ISO 8601>

artifacts:
  brief:        { path: "...", exists: true|false, version: "v0.X" }
  contract:     { path: "...", exists: ..., ... }
  plan:         { path: "...", ... }
  acceptance:   { path: "...", ... }
  ux:           { path: "...", ... }
  risk:         { path: "...", ... }
  eng_review:   { path: "...", verdict: PASS|FAIL|null }
  code_review:  { path: "...", verdict: PASS|FAIL|null }
  ai_qa_report:    { path: "...", verdict: PASS|FAIL|null }   # D-06 1단 (PR 생성 전제)
  human_qa:        { tested_label: true|false }                # D-06 2단 (머지 전제)

last_session:                                                   # 컨텍스트 위생 휴리스틱 (docs/planning/open-items.md O-01 부분 구현)
  issue_number: <N>|null                                        # 직전 진입한 이슈 (mode=sprint만 의미)
  flow: <flow-feature(mode) | flow-new-project>|null
  area_hint: <"<slug>" 또는 "<도메인>">|null                    # 영역 비교용 힌트 (라벨·파일 영역에서 추출)
  closed_phase: <Phase 식별자>|null                              # 마지막으로 머문 Phase
  closed_at: <ISO 8601>|null

missing_inputs:
  - <블로커 ID>
  - "GitHub repo URL 미확정"

blocked_by_issues: [<#N>, <#M>]   # GitHub Blocked-by:
gates:
  A: PASS | PENDING | FAIL    # 팀장 컨펌 (NEW_PROJECT)
  B: PASS | PENDING | FAIL    # 팀 합의
  C: PASS | PENDING | FAIL    # 개발팀 검토
```

---

## 2. Phase 정의 (Flow별)

### 2.1 flow-feature (가장 빈번, 모드: add/modify/bug/design 자동 감지)

> **2026-04-30 통합** — 기존 `flow-feature-add`·`flow-feature-modify`·`flow-bug-fix`·`flow-design-change` 4종을 `flow-feature`로 통합. 아래 Phase 표는 4모드 공통 흐름 + §2.2~§2.4의 모드별 강조·강제 차이 분리.

| current_phase | command | input (artifacts) | output | next_phase | blocking_conditions | rollback |
|---|---|---|---|---|---|---|
| P0-context | /context-loader | (없음) | flow-state.yaml | P1-brief | active issue 식별 실패 | (없음) |
| P1-brief | /intention-brief | (이슈 본문) | brief.md | P3-contract | brief 8섹션 미완 | P0 회귀 |
| P2-ux | /ux-flow-design | brief | ux.md | P3-contract | UI 영향 없으면 skip | (없음) |
| P3-contract | /change-contract | brief, ux | contract.md | P4-plan | 호출자 미추적 | P1/P2 회귀 |
| P4-plan | /implementation-planner | contract | plan.md | P5-eng-review | DAG 순환 / 테스트 미매핑 | P3 회귀 |
| P5-eng-review | /plan-eng-review | contract, plan | eng-review (PASS) | P6-acceptance | verdict ≠ PASS | P3/P4 회귀 |
| P6-acceptance | /acceptance-criteria | contract, plan, ux | acceptance.md | P7-risk | 항목 측정 불가 | P5 회귀 |
| P7-risk | /risk-check | contract | risk.md | P8-implement | High 리스크 미완화 | P6 회귀 |
| P8-implement | /implement | 모든 산출물 | 코드+테스트+커밋 | P9-code-review | 빌드 실패·테스트 실패 | P4 회귀 |
| P9-code-review | /code-review | 코드, contract, plan, acceptance | code-review (PASS) | P10-qa-ai | verdict ≠ PASS | P8 회귀 |
| P10-qa-ai | /qa-test --ai | acceptance, 코드, 상류 시나리오 | ai-qa-report.md + Test Plan 4블록 (**AI 게이트 — PR 생성 전제**) | P11-pr-open | AI 테스트 실패 / 4블록 누락 / Build 실패 / 시크릿 노출 | P8/P9 회귀 |
| P11-pr-open | (자동) branch + PR 생성 | ai-qa-report, Test Plan | PR open + status:in-review | P12-ui-review (UI 변경 시) or P13-docs | AI 게이트 미통과 | P10-qa-ai 회귀 |
| P12-ui-review | /ui-design-review (+ `--consistency` 옵션, mode=design 필수) | ux, PR | ui-review.md | P13-docs | FAIL 항목 존재 | P8 회귀 |
| P13-docs | /docs-update | PR | ADR / docs/planning/CHANGELOG.md §"Current Status" 갱신 | P14-qa-human | (없음) | (없음) |
| P14-qa-human | (사람) /qa-test --human 가이드, 로컬 빌드 + Test Plan 재현 | PR | `tested` 라벨 (**휴먼 게이트 1단**) | P15-human-merge | tested 라벨 부재 | 코멘트로 변경 요청 → P8/P9 회귀 |
| P15-human-merge | (사람) Approve + 머지 | PR | 머지 + 이슈 close (**휴먼 게이트 2단**) | DONE | Approve 부재 / CI red | 코멘트로 변경 요청 → P8/P9 회귀 |

### 2.2 flow-feature mode=modify (모드별 차이)

P0 → P1 → (P2 UI 영향 시) → **P3-contract (필수, Before/After 무거움)** → **P7-risk (필수, High 등급 시 단계적 롤아웃)** → P4 → P5 → P6 → P8 → P9 → **P10-qa-ai (AI 게이트)** → P11-pr-open → P12-ui-review → P13-docs (**ADR 필수**) → **P14-qa-human (휴먼 게이트 1단)** → **P15-human-merge (휴먼 게이트 2단)**.

### 2.3 flow-feature mode=bug (모드별 차이)

P0 → **P-investigate (`/debug-investigator`, 재현 필수)** → P3-contract → P7-risk → P8-implement (**회귀 테스트 필수**) → P9 → **P10-qa-ai (AI 게이트, 회귀 시나리오 포함)** → P11-pr-open → P13-docs → **P14-qa-human** → **P15-human-merge**.

### 2.4 flow-feature mode=design (모드별 차이)

P0 → P1 → **P2-ux (필수)** → **P-ui-review (`/ui-design-review`)** → **P-consistency (`/ui-design-review --consistency`)** → P3 → P7 → P4 → P5 → P6 → P8 → P9 → **P10-qa-ai (AI 게이트)** → P11-pr-open → **P-consistency 재실행 (`/ui-design-review --consistency`)** → P13-docs → **P14-qa-human** → **P15-human-merge**.

### 2.5 flow-new-project

게이트 A → 게이트 B → 게이트 C 순. 각 게이트 통과 후에만 다음 단계.

| 게이트 | Phase | Output | 판정자 |
|---|---|---|---|
| A | /intention-brief --brainstorm (선택) → /intention-brief | `01-project-brief.md` | 팀장 |
| B | /intention-brief × 다수 | `03-user-scenarios.md`, `04-srs.md`, `05-prd.md` | 팀 전체 |
| C | /implementation-planner + /plan-eng-review | `06-architecture.md`, `07-hld.md`(ADR-0031), `08-lld-module-spec.md`, `09-lld-api-spec.md`, `10-lld-screen-design.md`(BE-only는 N/A 골격), `11-coding-conventions.md`, `12-scaffolding/<lang>.md`, `13-test-design/`(5절 폴더) | 개발팀 |
| D (운영) | scripts/sprint-bootstrap.sh | GitHub Milestone + Issues | 자동 |

---

## 3. blocking_conditions

### 3.1 모드 무관 (전역)

다음 조건은 모드에 관계없이 즉시 `BLOCKED`:

1. Meta Command 없이 시작 시도
2. `change-contract` 없이 코드 변경 시도
3. `acceptance-criteria` 없이 PR 생성 시도
4. 단위 테스트 없이 `P9-code-review` 진입 시도
5. `/plan-eng-review` PASS 없이 `/implement` 진입 시도
6. 보안 파일(`.env*`, `*.key`, `*secret*`) Write/Edit 시도 (settings.json 훅이 1차 차단)
7. 시크릿 노출 (코드/로그/커밋 메시지) 발견
8. **AI 테스트 게이트(P10-qa-ai) 미통과 상태에서 PR 생성 시도 (D-06 1단)**
9. **산출 문서가 schema 검증 BLOCK 위반 (ADR-0010)** — `.claude/scripts/validate-doc.sh <output>` exit=2. doc_type별 schema는 `.claude/schemas/<doc_type>.schema.yaml`. 위반 항목(필수 섹션·표 컬럼·subsection 패턴·ID 정규식·frontmatter)을 정정 후 재검증 통과해야 다음 Phase 진입.

### 3.2 mode=sprint 전용

다음은 `mode: sprint`에서만 강제. `mode: planning`에선 skip.

10. GitHub `Blocked-by:` 미해소 이슈 작업 시도
11. `tested` 라벨 부재 상태에서 머지 시도 (D-06 2단 — P14-qa-human 미완)
12. 이슈 번호 없이 `/implement` 진입 (sprint 모드는 이슈 단위 작업이 원칙)

### 3.3 mode=planning 전용

다음은 `mode: planning`에서만 강제.

13. policies/flow-and-gates.md §2 게이트(A/B/C) 통과 없이 다음 Phase 진입
14. 결정 발생 시 ADR 작성 누락 (policies/flow-and-gates.md §3.3)

### 3.4 비블로킹 Phase 격리 정책 (보류)

본 하네스에는 현재 비블로킹 Phase가 없다 (P10b-learning은 [ADR-0009](../../docs/planning/adr/0009-deprecate-learning-layer.md)로 제거). 향후 비블로킹 Phase 후보 발생 시 ADR-0007 §2.6의 4조건을 모두 충족해야 함:

1. 출력이 코드·테스트·머지 대상에 영향 없음
2. 실패가 사용자 안전·보안·정합성에 영향 없음
3. 명시적 timeout 설정
4. 실패 흔적이 PR/로그에 남음 (audit 가능)

이외의 Phase는 §3.1 BLOCKED 강제 룰을 유지한다.

---

## 4. rollback 규칙

- **로컬 회귀**: 이전 Phase로 돌아가서 산출물 보강 후 재진입
- **이슈 단위 rollback**: PR 변경 요청 → `/implement` 재진입
- **PR 머지 후 rollback**: revert PR + `/flow-feature --mode=modify`로 복구 (D-06 게이트 통과)
- **데이터 영속성 변경 rollback 불가** 시: `/risk-check`에서 사전 식별 + 사용자 명시 승인 필수

---

## 5. State 전이 자동 갱신

각 Command 완료 시 `.claude/state/flow-state.yaml`을 자동 갱신:

```python
# 의사코드
flow_state.last_command = current_command
flow_state.last_command_at = now()
flow_state.artifacts[output_key].exists = file_exists(output_path)
if all_required_artifacts_present(next_phase):
    flow_state.current_phase = next_phase
else:
    flow_state.current_phase = "BLOCKED:" + next_phase
    flow_state.missing_inputs += missing_artifacts(next_phase)
```

---

## 6. Resumability (policies/sprint-cycle.md §3 자동화)

새 세션에서 `/context-loader`만 호출하면:
1. flow-state.yaml 읽기
2. 산출물 실존 검증
3. GitHub 상태 sync
4. 컨텍스트 위생 휴리스틱 — `last_session` vs 새 명령 인자 비교 → `/clear`·`/compact` 권장 출력 (자동 실행 X)
5. 다음 Command 1개 권고

flow-state.yaml은 `.gitignore` 권장 (개인 작업 컨텍스트). docs/planning/CHANGELOG.md §"Current Status"가 팀 공유용 진실의 원천.

### 6.1 컨텍스트 위생 휴리스틱 (docs/planning/open-items.md O-01 부분 구현)

본 toolkit은 단일 Claude Code 세션 안에서 다수의 이슈·Flow를 순차 진행하는 흐름이 일반적이다. 이전 작업 컨텍스트가 새 작업과 무관하면 모델 응답 품질·비용·가독성이 모두 저하되므로, `/context-loader` 진입 시점에 **권장만 출력**한다 (자동 실행 금지 — 의도치 않은 컨텍스트 소실 위험과 compaction 비용 통제).

| 상황 | 권장 |
|---|---|
| `last_session` 비어 있음 | 그대로 진입 |
| 같은 #N 재진입 (REJECTED/BLOCKED 회귀 등) | 그대로 진입 |
| 다른 #N · 같은 영역 (Parent·라벨·`area_hint` 겹침) | `/compact` |
| 다른 #N · 다른 영역 | `/clear` |
| 다른 Flow (NEW_PROJECT ↔ FEATURE) | `/clear` |

상세 룰·출력 포맷·Strict Rules는 [`.claude/commands/context-loader.md`](../commands/context-loader.md) 의 "컨텍스트 위생 휴리스틱" 절. 본 휴리스틱은 supervisor 모델(O-01 본격 구현)이 도입되기 전까지의 가벼운 부분 구현이다.

---

## 7. Generator ≠ Evaluator

다음 Command 쌍은 **별도 컨텍스트(가능하면 별도 에이전트)**로 수행:

| Generator | Evaluator |
|---|---|
| /implementation-planner | /plan-eng-review |
| /implement | /code-review |
| /implement | /qa-test |
| /ux-flow-design | /ui-design-review |
| / 화면 구현 | /ui-design-review --consistency |
기존 `.claude/agents/` 의 `developer` ↔ `reviewer` 분리 정책 계승.

---

## 8. 실패 처리

- 모든 BLOCKED는 **사유 + 회귀할 Phase + 누락 입력 리스트**를 기록
- 사용자에게 1줄 보고 + 조치 옵션 제시
- 임의로 BLOCKED를 우회하지 않음 (`/freeze` 등 gstack 스킬과 호환)

---

## 9. 주의 — 자동화의 한계

- 본 하네스는 PR 생성까지의 자동 흐름(AI 게이트 포함)만 보장. **PR 이후 사람의 빌드·재현 테스트·Approve·머지(D-06 2단 — 휴먼 게이트)는 자동화 대상이 아님**
- 무인 야간 자동 진행은 **O-01 (docs/planning/open-items.md)** 결정 보류 상태 — 현재는 수동 재개 절차로 운영
