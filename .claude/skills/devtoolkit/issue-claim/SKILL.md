---
name: issue-claim
description: Use this skill when an agent or user is about to start working on a GitHub issue (entering /implement). Checks the issue body for `Blocked-by: #N` declarations, verifies all blockers are closed, and applies `status:blocked` label + rejects entry if unresolved.
---

# issue-claim — 이슈 픽업 시 선수 검사 + 자동 status:blocked

> **정합**: [`policies/github-issue.md §3`](../../../../docs/planning/policies/github-issue.md) (의존성 규칙 #1·#2), D-05 (라벨 + 본문 컨벤션), [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md)

## 1. 역할

이슈 작업 진입 직전에 본문 `Blocked-by: #N` 선언을 검사하여, **미해결 선수 이슈가 있으면 `status:blocked` 라벨 자동 부착 + 진입 거부**. 정책 §3 자동화 규칙 #1·#2의 책임 스킬.

## 2. 진입점

- `/implement` 진입 직전 (Phase 8)
- `/flow-feature` 흐름이 `status:in-progress` 전이 직전
- 사용자 명시 호출: `/issue-claim --issue=#N`

## 3. 입력

- **이슈 번호** (필수): `--issue=#N`
- **작업자** (선택): `--assignee=@me` (기본)

## 4. 동작

```
1. 이슈 본문 Read (gh issue view #N --json body)
2. 본문 상단 'Blocked-by:' 선언 파싱:
   ---
   Blocked-by: #45, #46
   ---
   → 블록커 이슈 번호 리스트 추출

3. 각 블록커 상태 점검 (gh issue view #45 --json state):
   - state == "CLOSED" → 해소
   - state == "OPEN" → 미해결

4. 모든 블록커 close 확인:
   ✅ → 정상 진입 (ADR-0029 — FSM 전이 자동화):
       gh issue edit #N \
         --add-label "status:in-progress" \
         --remove-label "status:todo" \
         --remove-label "status:blocked" \
         --add-assignee @me
       → 진입 허용
   ❌ → 자동 처리:
       gh issue edit #N --add-label "status:blocked" --remove-label "status:todo"
       gh issue comment #N --body "Waiting on $(미해결 목록 ex: #45, #46). 선수 close 후 재진입."
       → BLOCKED 결과를 호출자에게 반환 (진입 거부)
```

## 5. 출력

- 진입 허용/거부 결정 (호출자가 사용)
- 라벨 변경 로그
- 블록커 상태 표 (예: "#45 closed, #46 open")

## 6. 실패 케이스

| 케이스 | 동작 |
|---|---|
| 이슈 #N 부재 | BLOCKED — 이슈 번호 확인 요청 |
| 본문에 `Blocked-by:` 선언 없음 | 정상 — 진입 허용 (의존성 없음) |
| 블록커 #M이 부재 (삭제됨) | WARN — "Blocked-by 본문 정합 깨짐" 안내 + 사용자 결정 위임 |
| `gh` 권한 부족 | BLOCKED — 권한 보강 요청 |

## 7. 정합 문서

- [`policies/github-issue.md §3`](../../../../docs/planning/policies/github-issue.md) — 의존성 자동화 규칙 #1·#2
- [`policies/github-issue.md §4`](../../../../docs/planning/policies/github-issue.md) — FSM ↔ 라벨 매핑 (PENDING/IN_PROGRESS/BLOCKED)
- [`adr/decisions.md`](../../../../docs/planning/adr/decisions.md) — D-05 의존성 정책
- [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md) — 본 Skill 도입
- 관련 Skill: [`issue-unblock`](../issue-unblock/SKILL.md) — 선수 close 시 해제 처리 (역방향)
