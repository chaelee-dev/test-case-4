---
description: Use this when the user wants to add/modify/fix/redesign a feature in an existing codebase, asks to introduce new behavior or change existing behavior, reports a bug, or wants to update the visual layer. Mode (add/modify/bug/design) is auto-detected from issue labels, natural language, and codebase state. This consolidates the previous /flow-feature-add, /flow-feature-modify, /flow-bug-fix, /flow-design-change into a single entry point.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /flow-feature

> 내부 동작 정본: [`docs/planning/operations/commands/flow-feature.md`](../../docs/planning/operations/commands/flow-feature.md) — 모드 감지 결정 트리, Phase 간 데이터 흐름, ADR-0018 selective read 알고리즘, 파생 이슈 상속 규칙, BLOCKED 회귀 매트릭스, end-to-end 트레이스. 본 문서(인터페이스 정본)는 *무엇을·언제* 호출하는지에 집중하고, internals 정본이 *어떻게* 작동하는지 다룬다.

## 목적

이슈 단위 작업의 **단일 메타 명령어 진입점**. 4가지 모드(add / modify / bug / design)를 자동 감지하고 모드별 강조·강제 단계를 적용한다. 게이트 C 통과 이후(= Sprint 운영 중) 가장 빈번한 Flow.

> **2026-04-30 통합** — 기존 `/flow-feature-add`, `/flow-feature-modify`, `/flow-bug-fix`, `/flow-design-change` 4종을 본 명령어로 통합. 4종은 deprecate.

## 사용 시점

- 아키텍처(`06-architecture.md`) + HLD(`07-hld.md`) + SRS(`04-srs.md`)가 합의된 상태
- GitHub에 이슈가 생성되었거나 생성 직전
- `mode=sprint` 진입 후 이슈 단위 작업 시작

## 모드 자동 감지 (ADR-0032 — 무질문 진행)

다음 우선순위로 **자동 결정**한다. 부정 시그널이 0건 또는 1건이면 *질문 없이* 진행 (ADR-0032 §2.1·§2.2).

| # | 신호 | 판정 모드 |
|---|---|---|
| 1 | 이슈에 `type:bug` 라벨 / "안 돼", "에러", 로그 첨부 | **bug** |
| 2 | UI/시각/token/리브랜딩/다크모드 키워드 | **design** |
| 3 | 기존 동작 변경 / "바꿔", "동작 다르게" / breaking 가능성 / 기존 모듈 수정 | **modify** |
| 4 | **기본값 (위 3개 부정 시그널 0건)** — 자동 결정, *질문 금지*. `type:feature` 라벨 우선, 부재 시에도 동일하게 add로 결정 (ADR-0032) | **add** |

규칙 4의 "기본값"은 *추측*이 아닌 *결정*이다. 부정 시그널이 0건이면 add로 조용히 진행한다. 잘못된 모드가 결정될 위험은 후속 BLOCK(change-contract Before/After·debug-investigator 재현·ui-design-review)이 흡수한다.

수동 override: `/flow-feature --mode=add|modify|bug|design "..."`

## 모드별 강조·강제 단계

| 모드 | 트리거 | 강조/필수 sub-command | 산출 강제 | 핵심 원칙 |
|---|---|---|---|---|
| **add** | `type:feature` + 신규 동작 | `change-contract` 가벼움, `ux-flow-design` UI 영향 시 | `docs/features/feat-<slug>/feat-<slug>.{brief,contract,plan}.md` | 최소 침습 — 신규 디렉토리/모듈 도입은 contract에 정당화 |
| **modify** | 기존 동작 변경, breaking 가능성 | `change-contract` 무거움 (Before/After 두 컬럼), `risk-check` High 시 단계적 롤아웃, **ADR 필수** | `docs/features/mod-<slug>/mod-<slug>.contract.md`, `docs/planning/adr/NNNN-mod-<slug>.md` | deprecation 경로 + breaking change 시 Major version bump |
| **bug** | `type:bug`, 에러 로그, 결함 보고 | **`debug-investigator` 선행 (재현 필수)**, **회귀 테스트 추가 강제** | `docs/features/bug-<slug>/bug-<slug>.investigation.md`, 회귀 테스트 코드 | 추측 기반 수정 금지. Workaround만 적용 시 ADR + 후속 이슈 |
| **design** | UI/token/시각 변경 | `ux-flow-design` 필수, `ui-design-review` 필수, **`ui-design-review --consistency` 두 번 실행** (구현 전·후) | `docs/features/design-<slug>/design-<slug>.contract.md`, before/after 스크린샷 세트 | a11y 회귀 점검 강제. token 변경은 단일 PR 일괄 |

## Pre-P0 — 컨텍스트 위생 (사전 작업)

본 Command 호출 직전, 채팅 세션이 다른 작업으로 누적된 상태라면 작업 컨텍스트를 정리한다.

```
[자동 안내] UserPromptSubmit hook (.claude/scripts/check-context-weight.sh)
  └─ /flow-* 입력 감지 + 트랜스크립트 ≥ 500줄 시 system-reminder 주입
     (차단 없음 — 권고만)

[수동 절차]
  1. 직전 작업 마무리/저장 상태 확인
  2. /compact  (Claude Code 네이티브 — 대화 압축으로 컨텍스트 토큰 절감)
  3. /flow-feature "<의도>" 재호출
```

**적용 시점**: 다음 중 하나
- `mode=sprint` 진입 후 *연속 이슈 작업*
- 대화가 길어진 후 *첫 이슈*
- 직전 다른 Flow(`/flow-init`·`/flow-design` 등) 완료 후 이어서 작업

새 Claude 세션에서 시작하면 본 단계 자동 충족 (트랜스크립트 짧음).

> 임계값(500줄·~10k 토큰)·정책 정본: [`docs/planning/operations/commands/flow-feature.md`](../../docs/planning/operations/commands/flow-feature.md) §"Pre-P0 컨텍스트 위생"

## Phase Sequence

```
P0  /context-loader              (영향 파일 식별·세션 복원, 모든 모드)
P1  /intention-brief             (의도 1줄 → brief, 모든 모드)
    + --brainstorm 옵션          (의도 모호 시)
P2  /ux-flow-design              (mode=design 필수 / mode=add UI 영향 시)
P3a /debug-investigator          (mode=bug 전용, 재현 필수)
P3  /change-contract             (모든 모드 필수, mode=modify에서 Before/After 강조,
                                  §0 Referenced-IDs BLOCK — ADR-0018)
P4  /implementation-planner      (구현 plan, contract §0 기반 selective read — ADR-0018,
                                  모든 모드)
P5  /plan-eng-review             (PASS 게이트, 모든 모드)
P6  /acceptance-criteria         (DoD, 모든 모드)
P7  /risk-check                  (모든 모드, mode=modify에서 High 등급 강제 검토)
P8  /implement                   (진입 시 git checkout -b <mode>/<slug>-issue-<N> 자동 분기,
                                  진입 시 issue-claim Skill 호출 — Blocked-by 검사 + status:blocked 자동 부착(ADR-0022),
                                  코드 + 단위 테스트, Subtask당 1커밋(메시지에 #N), 자가 push 금지.
                                  mode=bug는 회귀 테스트 추가 강제)
P9  /code-review                 (Generator≠Evaluator. mode=modify는 변경 전/후 diff 중심)
    + --refactor 옵션            (리팩토링 중심 검토 시)
P10 /qa-test --ai                (D-06 1단, AI 게이트. PASS 직후 git push -u + gh pr create
                                  --title "<type>(<area>): <summary>"  (ADR-0021 정규식, BLOCK)
                                  --base main --body <Test Plan + Closes #N + Touched Areas(3+영역 시)
                                  + Flow Mode + Mode Decision Trace(ADR-0032)>)
P11 (자동) PR open               (status:in-progress → status:in-review 자동 전이)
P12 /ui-design-review            (mode=design·add UI 영향 필수)
    + --consistency 옵션         (mode=design 강제, 구현 후 재실행)
P13 /docs-update                 (모든 모드. mode=modify는 ADR 필수.
                                  04·05 신규/변경 R-/F-ID 시 13/02-catalog 동기화 — ADR-0035.
                                  13/02-catalog 갱신 시 ADR-0036 레벨별 섹션(§1 단위 / §2 통합 / §3 E2E)에 fan-in,
                                  ADR-0034 sub-file 본문 BLOCK 통과 필요)
P14 /qa-test --human             (D-06 2단, 휴먼 게이트, 사람 재현)
P15 (사람) Approve + 머지        (이슈 close, 모든 모드)
```

## 규칙 (강제)

1. **기존 구조 분석 필수** — `/context-loader`로 영향 파일 식별 전 코드 변경 금지
2. **모드 시그널 동시 충돌 시 BLOCKED (ADR-0032)** — 다음 *부정 시그널 동시 발생* 케이스만 BLOCK:
   - `type:bug` 라벨 + UI/design 키워드 (bug vs design)
   - `type:bug` 라벨 + "기능 추가" 자연어 (bug vs add 위장)
   - 라벨 부재 + 자연어에서 모드 결정 키워드 2개 이상 충돌

   부정 시그널이 없거나 1개만 있으면 자동 결정 — *사용자 질문 금지*. 규칙 4 기본값(=add) 발동.
3. **mode=bug**: `debug-investigator` 재현 단계 통과 없이 P3 진입 금지
4. **mode=modify**: `risk-check` 결과 High면 단계적 롤아웃 plan 강제, breaking change 시 ADR 필수
5. **mode=design**: `ui-design-review` 통과 없이 `/implement` 금지. token 변경은 단일 PR 일괄
6. **이슈 ID 의존성 검사** — `Blocked-by:` 미해소 시 진입 거부 (policies/github-issue.md §3, mode=sprint 한정)

## 입력

- 의도 1줄 (자연어, 필수)
- GitHub Issue 번호 (`mode=sprint`에서 필수, `--issue=#N` 또는 인자로)
- (선택) `--mode=add|modify|bug|design` — 자동 감지 override

## 호출 예시

**자동 감지**:
```
/flow-feature #12
/flow-feature "Sprint 1 이슈 #12 — 로그인 폼 추가"
   ↓ (type:feature 라벨 + 신규 동작 → mode=add)
```

**수동 모드 지정**:
```
/flow-feature --mode=bug "이슈 #34: PR 본문에 Test Plan 누락"
/flow-feature --mode=modify "이슈 #50: GitHub API rate limit 회피 전략 변경"
/flow-feature --mode=design "다크모드 토큰 도입"
```

**파생 이슈 등록 (policies/github-issue.md §5 / ADR-0008)**:
```
/flow-feature "X 함수 분리"                       ← 독립 신규 이슈 (부모 추적 링크 없음)
/flow-feature --mode=bug "..."                    ← 별개 결함
```

> 파생 이슈는 부모와 추적 링크를 두지 않는다. 추적이 필요하면 본문 코멘트에 자유 서술(예: "PR #42 리뷰 중 발견").

> **파생 이슈도 동일 정책 적용** — 새 이슈는 별도 GitHub Issue이므로 본 sequence(P0~P15)와 동일한 git/브랜치/커밋/푸시/PR/lifecycle 정책이 그대로 적용된다. 별도 분기(`<mode>/<slug>-issue-<N+m>`) + 별도 PR + 자체 머지·close. 부모 PR과 같은 브랜치에 끼워넣지 않는다.

**분류 모호 시**:
```
/start-feature "..."
   ↓ (Meta Routing 게이트웨이가 분류 → /flow-feature 또는 /flow-new-project로 위임)
```

## 모드별 동작

| 항목 | mode=planning | mode=sprint |
|---|---|---|
| 작업 단위 | `feat-<slug>` 산출 문서 묶음 | GitHub Issue #N |
| 이슈 번호 | N/A (불필요) | **필수** (`--issue=#N`) |
| Blocked-by 검사 | skip | 필수 |
| 산출물 위치 | `docs/features/<mode-prefix-slug>/<mode-prefix-slug>.*.md` (manifest §3.2 정본) | 동일 + 이슈에 코멘트로 링크 |
| FSM 라벨 | `flow-state.gates`만 갱신 | `status:in-progress` 자동 부여 |
| 종료 시 | `/docs-update`까지 | + PR 생성 + D-06 머지 게이트 |

## 산출물 (모드별 명명 규약)

**정본 경로**: `docs/features/<slug>/<slug>.<type>.md` (document-manifest §3.2). slug는 mode 접두를 포함한다 (`.claude/schemas/feature-*.schema.yaml`의 `filename_pattern` 정합).

| 모드 | slug 접두 | 예시 폴더·파일 |
|---|---|---|
| add | `feat-` | `docs/features/feat-login-form/feat-login-form.{brief,contract,plan}.md` |
| modify | `mod-` | `docs/features/mod-rate-limit/mod-rate-limit.contract.md` + `docs/planning/adr/0007-mod-rate-limit.md` |
| bug | `bug-` | `docs/features/bug-test-plan-missing/bug-test-plan-missing.investigation.md` |
| design | `design-` | `docs/features/design-dark-mode/design-dark-mode.contract.md` + `screenshots/` |

## 완료 조건

- AI 게이트(D-06 1단) 통과 → push + PR 자동 생성 (본문 `Closes #N` 강제)
- PR `tested` 라벨 부착 + Approve ≥ 1 + CI green → 머지 (D-06 2단)
- 머지 → 이슈 자동 close (`Closes #N`) + `status:*` 라벨 정리 (issue-sync 책임)
- 이슈 close → DoD 모든 체크박스 ✅
- 모드별 추가 조건:
  - **add**: contract의 변경 요약 + plan의 모든 subtask가 PR diff에 매핑
  - **modify**: 기존 시나리오 100% 통과 + 신규 시나리오 통과 + ADR 작성
  - **bug**: 재현 시나리오로 결함 ❌ (재현 안 됨) 확인 + 회귀 테스트 추가
  - **design**: `ui-design-review --consistency` 두 번 모두 PASS + 시각 회귀 0건 + a11y 통과

## BLOCKED 케이스

| 메시지 | 원인 | 모드 | 조치 |
|---|---|---|---|
| `BLOCKED: 모드 시그널 동시 충돌` | 부정 시그널 2개 이상 충돌 (ADR-0032) | 전역 | `--mode=` 명시. 단일 시그널 또는 시그널 0건은 자동 결정으로 진행 — BLOCK 안 됨 |
| `BLOCKED: change-contract 부재` | 코드 수정 직전 contract 없음 | 전역 | `/change-contract` 먼저 |
| `BLOCKED: §0 Referenced-IDs 누락` | contract.md schema validate FAIL (ADR-0018) | 전역 | `scaffold-doc.sh feature-contract` 재실행 + §0 5행 채움. (none)도 명시 |
| `BLOCKED: 재현 실패 (mode=bug)` | debug-investigator 재현 단계 미통과 | bug | 사용자에게 추가 정보 요청 |
| `BLOCKED: ui-design-review FAIL (mode=design)` | UI 검토 미통과 | design | UX·UI 보강 후 재진입 |
| `BLOCKED: ADR 누락 (mode=modify)` | breaking change인데 ADR 없음 | modify | ADR 작성 후 진행 |
| `BLOCKED: AI 테스트 게이트 미통과` | D-06 1단 — PR 생성 차단 | 전역 | 실패 테스트 수정 후 `/qa-test --ai` 재실행 |
| `BLOCKED: tested 라벨 부재` | D-06 2단 | sprint | 사람 빌드+재현 테스트 후 라벨 부착 |
| `BLOCKED: Blocked-by 미해소 #N` | 선수 이슈 진행 중 | sprint | #N 완료 대기 |

## Artifact Binding

- 입력: GitHub Issue 또는 자연어 의도, 모드 자동 감지/지정
- 출력: → `/qa-test --ai`로 PR 생성, → `/docs-update`로 ADR/CHANGELOG/docs/planning/CHANGELOG.md §"Current Status" 갱신
- 페어링:
  - 검증: `/code-review` (Generator≠Evaluator), `/qa-test --ai`/`--human`, `/risk-check`
  - 디버깅: `/debug-investigator` (mode=bug 전용)
  - UI: `/ux-flow-design`, `/ui-design-review` (`--consistency` 옵션 포함)
  - 검토: gstack `/review`, `/qa`, `/cso`, `/investigate` 병행

## 트리거 매칭

- "기능 추가", "새 기능", "feature add" → mode=add
- "기능 수정", "변경", "refactor", "rework", "동작 바꿔" → mode=modify
- "버그", "안 돼", "에러", "고장", "fix", "결함" → mode=bug
- "디자인 변경", "리브랜딩", "UI 개편", "다크모드", "token" → mode=design
- 일반 진입: "기능 만들자", "구현해줘", "이슈 #N 작업"
