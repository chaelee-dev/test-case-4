---
description: Use this when the user resumes work after a break, asks "where were we", needs to recover state from a closed session, or is about to start a new flow and must establish current phase, active issue, and artifact status.
allowed-tools: Read, Glob, Grep, Bash
---

# /context-loader

> 사람이 읽는 정본 운영 절차는 [`docs/planning/operations/runbook.md`](../../docs/planning/operations/runbook.md). 본 Command는 그 절차의 자동화이다.

## 목적
**Resumability 보장**. policies/sprint-cycle.md §3 (수동 재개 5단계)를 자동화하여 "현재 어디까지 진행됐는가"를 한 번에 파악한다.

## 사용 시점
- 새 세션 시작 직후
- `/start-feature` 직후
- 다른 Flow 진행 중 컨텍스트 손실 의심 시
- 사용자가 "이어서", "복원", "지금 어디" 등 발화

## 입력
- (선택) 이슈 번호 — 없으면 `gh issue list --label "status:in-progress" --assignee @me`
- 작업 디렉토리 (필수, 기본 `c:\work\agent-toolkit`)

## 산출물
- 현재 상태 보고서 (인메모리)
- `.claude/state/flow-state.yaml` 갱신
- 사용자에게 다음 Command 권고 1개

## 실행 단계 (policies/sprint-cycle.md §3.2 자동화)

```
1. docs/planning/INDEX.md / CLAUDE.md 읽기 (header 부분만)
2. 모드 자동 감지 (Harness §0.1):
   - docs/planning/CHANGELOG.md §"Current Status" 게이트 C 통과 표시 + sprint-bootstrap 흔적 + GitHub repo URL → mode=sprint
   - 그 외 → mode=planning
3. docs/planning/ 하위 산출 문서 인벤토리 (어디까지 작성됐는가)
4. git status / git log -3 / git branch --show-current
5. (mode=sprint 일 때만) GitHub 동기화:
   a. gh issue list --label "status:in-progress" --assignee @me  → 진행 중 이슈
   b. gh issue view <N>  → DoD 체크리스트 + 최근 코멘트
   c. gh pr list --state open --author @me  → 오픈 PR
   gh-cli 미설치 또는 인증 실패 → 경고 출력 후 mode=planning 으로 fallback
6. 종합 → flow-state.yaml 작성:
   - mode
   - current_phase
   - active_flow
   - last_command
   - artifacts: {경로: 존재 여부}
   - missing_inputs: [리스트]
   - last_session: {issue_number, flow, area_hint, closed_phase, closed_at}
7. **컨텍스트 위생 휴리스틱**: last_session vs 새 명령 인자 비교 → 필요 시 `/clear` 또는 `/compact` 권장 (자동 실행 X)
8. 다음 Command 1개 권고 (Harness 규칙 + 현재 mode 기반)
```

## 모드별 동작 차이

| 단계 | planning 모드 | sprint 모드 |
|---|---|---|
| 진행 중 작업 식별 | `docs/planning/` 가장 최근 수정 문서 | `gh issue list --label status:in-progress` |
| DoD 확인 | `<slug>.acceptance.md` | 이슈 본문 체크리스트 |
| 권고 다음 Command | 게이트 미통과 → `/intention-brief` 등 문서 작성 | 이슈 Phase에 따라 `/implement` 등 |

## 컨텍스트 위생 휴리스틱 (docs/planning/open-items.md O-01 부분 구현)

`/flow-feature #N` 등으로 새 작업에 진입할 때, 이전 세션 컨텍스트가 남아 있으면 **권장만 출력하고 사용자에게 선택권을 준다**. 자동 `/clear`·`/compact` 실행은 하지 않는다 — 디버깅 중 잠깐 다른 이슈를 본 케이스 등에서 의도치 않은 컨텍스트 소실 위험이 있고, compaction은 LLM 호출 비용도 발생한다.

### 판정 입력
- `flow-state.yaml.last_session` (직전 세션 정보)
- 사용자가 부른 새 명령의 인자 (예: `/flow-feature #15`의 #15)
- (mode=sprint) 두 이슈의 라벨·Parent·파일 영역 hint

### 판정 룰

| 상황 | 권장 |
|---|---|
| `last_session` 비어 있음 (새 세션 또는 첫 진입) | 그대로 진입 |
| 같은 #N 재진입 (REJECTED 회귀, BLOCKED 해소, P10-qa-ai 회귀 등) | 그대로 진입 — 컨텍스트 유지 가치 ⬆ |
| 다른 #N · 같은 영역 (Parent 동일 / 라벨 동일 / `area_hint` 겹침) | `/compact` 권장 — 부분 재사용 가치 |
| 다른 #N · 다른 영역 | `/clear` 권장 — 재사용 가치 ⬇ |
| 다른 Flow (NEW_PROJECT ↔ FEATURE 전환) | `/clear` 권장 — 재사용 가치 ⬇⬇ |

### 출력 포맷 (`📍 현재 위치` 머리말 위에 우선 출력)

```
🧹 컨텍스트 위생 점검
- 이전: #12 "auth refresh token 갱신" (P11-pr-open, billing 영역 외 / 2시간 전)
- 새 작업: #15 "billing invoice 생성"
- 판정: 다른 영역 — /clear 권장

선택:
  [c] /clear 후 본 명령 재호출 (권장)
  [m] /compact 후 진행
  [k] 컨텍스트 유지 (의도적 재사용 시)
  [a] 중단
```

판정이 "그대로 진입"이면 본 절 출력은 생략하고 곧장 `📍 현재 위치` 보고로 진행한다.

### Strict Rules
- **자동 실행 금지** — 본 휴리스틱은 *권유*만 한다. 사용자 단답으로 통제
- **단답 무응답이면 [k] 유지로 처리** — 안전한 디폴트 (clear는 되돌릴 수 없음)
- **`/clear` 직후에는 본 명령 재호출 안내** — clear가 컨텍스트를 비우므로 사용자가 같은 명령을 새 컨텍스트에서 다시 부르도록

## 보고 포맷 (사용자에게 출력)

```
📍 현재 위치
- Mode: <planning | sprint>
- Phase: <게이트 A/B/C 또는 Sprint N의 Phase>
- Active Flow: <flow 이름 or 없음>
- Active Issue: #<N> "<제목>"   (mode=sprint만)
- Branch: <branch>

📦 산출물 상태
- ✅ docs/planning/01-project-brief/01-project-brief.md (v0.3)
- ✅ docs/planning/INDEX.md (v0.5)
- ⏳ docs/planning/03-user-scenarios/03-user-scenarios.md (없음)
- ⏳ docs/planning/04-srs/04-srs.md (없음)

🚧 누락 정보
- O-01 결정 필요
- GitHub repo URL 미확정 (sprint 모드 진입 차단)

➡️ 권고 다음 Command
- /intention-brief "사용자 시나리오 작성"   ← mode=planning 예시
```

## 완료 조건
- `flow-state.yaml` 작성 완료
- 사용자가 즉시 다음 단계로 진입 가능

## 트리거 매칭
"이어서", "복원", "지금 어디", "어디까지", "resume", "context"
