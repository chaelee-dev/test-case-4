---
name: issue-pick
description: Use this skill when the user asks "what's next" / "다음 이슈 줘" / "어떤 이슈부터 할까" — auto-selects the next workable issue from the current sprint, excluding blocked ones, sorted by priority and dependency order.
---

# issue-pick — 작업 가능한 다음 이슈 자동 선정

> **정합**: [`policies/github-issue.md §3`](../../../../docs/planning/policies/github-issue.md) (의존성 규칙 #4), [`policies/sprint-cycle.md §1`](../../../../docs/planning/policies/sprint-cycle.md), [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md)

## 1. 역할

현재 스프린트(또는 사용자 지정 마일스톤)에서 **작업 가능한 이슈를 자동 선정**하여 1~3개 후보를 추천한다. 블록 이슈 제외, 우선순위(`priority:P0~P3`)·의존성 순서로 정렬. 정책 §3 자동화 규칙 #4의 책임 스킬.

## 2. 진입점

- 사용자 자연어: "다음 이슈 줘", "어떤 이슈부터 할까", "작업 픽업", "what's next"
- `/start-feature` 또는 `/context-loader` 흐름에서 "현재 작업 중인 이슈 없음" 판정 후 자동 호출
- 사용자 명시 호출: `/issue-pick` 또는 `/issue-pick --milestone="Sprint 1"`

## 3. 입력

- **범위 필터** (선택):
  - `--milestone="Sprint N"` (기본=현재 active 마일스톤)
  - `--assignee=@me` 또는 `unassigned` (기본=후자 우선)
  - `--area=auth` 등 라벨 필터
- **개수** (선택, 기본=3): 추천 후보 수

## 4. 동작

```
1. 후보 이슈 조회:
   gh issue list \
     --milestone "$MILESTONE" \
     --state open \
     --json number,title,labels,body,assignees \
     --limit 50

2. 필터링:
   a. status:blocked 제외 (규칙 #4 정합)
   b. status:in-review 제외 (이미 PR 대기 중)
   c. status:in-progress 제외 (이미 진행 중)
   d. 본문 'Blocked-by:' 선언이 있고 블록커가 미해결인 이슈 제외 (보조 검사)

3. 정렬:
   1순위: priority:P0 > P1 > P2 > P3 (라벨 기준)
   2순위: status:todo > 라벨 없음 (status:todo 우선)
   3순위: Estimated Effort 짧은 순 (0.5d > 1d > 2d > 3d) — 빠른 승리
   4순위: 이슈 번호 오름차순 (등록 순서)

4. 상위 N개 추천 (기본 3개) — 사용자에게 표 출력:
   | # | Title | Priority | Area | Effort | 비고 |
   |---|---|---|---|---|---|
   | #42 | feat(auth): 로그인 폼 | P1 | auth | 2d | 추천 1순위 |
   | #45 | fix(billing): 결제 콜백 | P2 | billing | 0.5d | quick win |
   | #50 | docs(plan): WBS 갱신 | P3 | docs | 0.5d | 잡무 묶기 |

5. 사용자 선택 시 후속 안내:
   "선택된 이슈 #42 → /flow-feature --issue=42 로 진입 가능. 또는 /implement #42."
```

## 5. 출력

- 추천 후보 표 (1~3개)
- 각 후보의 1줄 사유 (왜 추천했는지)
- 후속 Command 안내 (`/flow-feature --issue=#N`)

## 6. 실패 케이스

| 케이스 | 동작 |
|---|---|
| 활성 마일스톤 없음 | BLOCKED — "Sprint N 시작 필요. /flow-bootstrap 또는 sprint-bootstrap.sh 실행 안내" |
| 모든 이슈가 blocked | WARN — "모든 이슈 블록 상태. /issue-unblock 호출 권장" + 블록커 일람 출력 |
| 후보 0개 (모두 close) | 정상 — "현재 스프린트 완료. /retro + /flow-sprint-rollover (O-02 수동) 진행" |
| 권한 부족 | BLOCKED — `gh auth` 안내 |

## 7. 정합 문서

- [`policies/github-issue.md §3`](../../../../docs/planning/policies/github-issue.md) — 의존성 자동화 규칙 #4
- [`policies/github-issue.md §2`](../../../../docs/planning/policies/github-issue.md) — 우선순위 라벨 (priority:P0~P3)
- [`policies/sprint-cycle.md §4`](../../../../docs/planning/policies/sprint-cycle.md) — Sprint Rollover
- [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md) — 본 Skill 도입
- 관련 Skill: [`issue-claim`](../issue-claim/SKILL.md) — 픽업 후 진입 시 호출 (보조 검사)
