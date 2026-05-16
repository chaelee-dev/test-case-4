---
description: Use this when the user types a generic intent without specifying which flow, asks "let's build something", needs the harness to pick the right Meta Command, or is about to begin work but hasn't classified the request type yet.
allowed-tools: Read, Glob, Grep, Bash
---

# /start-feature

## 목적
**Meta Routing 게이트웨이**. 사용자의 자유 입력을 받아 NEW_PROJECT / FEATURE_ADD / FEATURE_MODIFY / BUG_FIX / DESIGN_CHANGE 중 하나로 분류하고 적절한 `/flow-*` 커맨드로 위임한다.

## 사용 시점
- 사용자가 의도만 던졌을 때 ("기능 만들자", "이거 좀 고쳐줘")
- 어떤 Flow가 적합한지 모를 때
- Harness 강제 모드 진입 전 첫 단계
- "다음 이슈 줘" / "어떤 이슈부터 할까" — [`issue-pick`](../skills/devtoolkit/issue-pick/SKILL.md) Skill 위임 (ADR-0022)

## 분류 규칙

| 신호 | 분류 |
|---|---|
| 빈 저장소 / PRD 부재 / "처음부터" | **NEW_PROJECT** → `/flow-new-project` |
| `type:feature` 라벨 + 신규 동작 / "추가" | **FEATURE (mode=add)** → `/flow-feature` |
| 기존 동작 변경 / "바꿔" / "동작 다르게" / breaking | **FEATURE (mode=modify)** → `/flow-feature --mode=modify` |
| `type:bug` 라벨 / "안 돼" / "에러" / 로그 첨부 | **FEATURE (mode=bug)** → `/flow-feature --mode=bug` |
| UI/시각/token / "리브랜딩" / "예쁘게" | **FEATURE (mode=design)** → `/flow-feature --mode=design` |
| **검증 중 발견** / "PR 보다가 발견" / "리뷰 중 인지" / "관련 작업 별도" | **DERIVED / BLOCKER / BUG** (policies/github-issue.md §5 / ADR-0008) → 3가지 패턴 분류 후 `/flow-*` 위임 (모두 독립 이슈) |

분류가 모호하면 **사용자에게 질문하여 분류 강제**. 추측 금지.

### 파생 이슈 분류 (policies/github-issue.md §5 / ADR-0008 흡수)

휴먼이 신규 이슈를 발견한 경우 본 Command가 등록 진입점 역할을 한다(별도 `/found-issue` 또는 `/spinoff` Command 신설하지 않음). 단, **PR 검토 중 발견은 PR 재작업이 기본**이며 별도 이슈 등록은 예외 케이스에만 사용한다(팀장 피드백, policies/github-issue.md §5.3 수동 절차).

#### 우선순위 1 — PR 검토 중 발견은 **PR 변경 요청**이 기본

발견 컨텍스트가 P14-qa-human / P15-human-merge(PR 검토 중)이면 본 Command 호출 전에 다음을 먼저 시도:

```bash
gh pr review <PR_N> --request-changes --body "발견 사항: <설명> (파일:라인 + 재현 절차)"
```

→ 에이전트가 변경 요청을 받고 P10-qa-ai부터 재진입 → 같은 PR에 추가 커밋 → 머지로 완결.

#### 우선순위 2 — 파생 이슈 등록 (예외, scope 완전 밖)

PR 검토 중 발견이라도 **policies/github-issue.md §5.3 3축 OX 체크박스를 모두 충족**하면(scope 완전 밖) 별도 이슈 등록이 정합. 본 Command가 자연어를 받아 분류:

| 사용자 표현 신호 | 분류 (policies/github-issue.md §5.2) | 위임 | 부모 추적 링크 |
|---|---|---|---|
| "#N 작업 중 Y도 좋겠다는 인사이트" / "독립 작업" / "현 PR scope 밖" / "관련 있으나 별도 작업" | **A. Derived (파생)** | `/flow-feature "..."` (필요 시 carryover 라벨) | ❌ 없음 (완전 독립) |
| "#N 진행하려면 Z 인프라 선행" / "선행 차단" | **B. Blocker** | `/flow-feature` 또는 `/flow-feature --mode=modify` + 본문 `Blocked-by: #N` | `Blocked-by: #N` |
| "#N 작업 중 무관한 결함 발견" / "별개 버그" | **C. Bug** | `/flow-feature --mode=bug "..."` | ❌ 없음 |

> **모든 파생 이슈는 독립**. 부모와의 추적 링크(`Parent`/`Children`/`sub-of:#N` 라벨)는 ADR-0008 결정으로 폐기. 추적이 필요하면 본문 코멘트에 자유 서술(예: "PR #42 리뷰 중 발견").

자연어가 모호하면 위 표 기준으로 사용자에게 1~2개 질문해 패턴 확정. 추측 금지.

#### 호출 예시

**기본 (PR 변경 요청 우선)**:
```
사용자: "PR #42 리뷰 중 src/auth.ts에서 race condition 발견"
   ↓
Command 응답: "PR #42 자체의 결함으로 보입니다. PR 변경 요청을 권장합니다:
   gh pr review 42 --request-changes --body '...'
   에이전트가 같은 PR에 fix 커밋을 추가합니다.
   별도 이슈로 분리하실 거면 '/start-feature ... (현 PR scope 밖)' 명시해주세요."
```

**예외 (scope 완전 밖, A. Derived)**:
```
/start-feature "PR #42 리뷰 중 발견: 다크모드 토큰 시스템 도입 (현 PR scope 완전 밖, 다음 스프린트 후보)"
   ↓ (A. Derived로 분류)
/flow-feature "다크모드 토큰 시스템 도입"   (carryover:from-sprint-N 라벨, 부모 추적 링크 없음)
```

## 입력
- 자연어 의도 (필수)
- (선택) 이슈 번호 / 파일 경로 / 에러 로그

## 산출물
- 분류 결과 + 선택된 Flow 명시
- `.claude/state/flow-state.yaml` 초기화 (active_flow, current_phase=`Phase 0`)

## 실행 단계
1. 사용자 입력 파싱
2. 키워드 + 컨텍스트(GitHub 라벨, git status, 파일 변경 여부) 결합 분석
3. 분류 결정 → 사용자에게 1줄로 보고
4. 모호하면 명확화 질문 (1~2개)
5. **파생 이슈로 결정된 경우 (DERIVED / BLOCKER / BUG)** — Origin 5필드를 인터랙티브로 수집 (ADR-0021 §2.4):
   - Discovered-in (PR #N / Issue #N / 보고서 경로)
   - Discovered-by (`/code-review` / `/qa-test --ai` / 휴먼 PR 리뷰 / 자가 발견)
   - Discovered-at (KST 자동 생성)
   - Pattern (A. Derived / B. Blocker / C. Bug)
   - 3-axis OX (Pattern A·B는 모두 F 강제, C는 무관)
6. 결정된 `/flow-*` 호출 — 파생이면 `--origin='<5필드 yaml>'`로 본문 자동 채움 + `derived` 라벨 자동 부착

## 완료 조건
- 분류 결정 완료
- `flow-state.yaml`의 `active_flow` 필드 작성
- 다음 Command (`/flow-*` 또는 `/context-loader`) 안내

## 트리거 매칭
"기능 만들자", "구현해줘", "설계부터", "전체 흐름으로", "하네스로 진행", "어떻게 할까", "PR 보다가 발견", "리뷰 중 발견", "이슈 #N 자식", "#N 작업 중 발견"
