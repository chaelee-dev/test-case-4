---
name: issue-unblock
description: Use this skill when the user wants to bulk-process blocked issues whose blockers have been closed. Scans all open issues with `status:blocked`, parses their `Blocked-by:` declarations, and auto-releases (label swap to `status:todo`) those whose blockers are all closed. Distinct from /issue-sync Command which handles Projects v2 sync.
---

# issue-unblock — 선수 close → 의존 이슈 자동 해제

> **정합**: [`policies/github-issue.md §3`](../../../../docs/planning/policies/github-issue.md) (의존성 규칙 #3), [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md)
> **명명 결정**: ADR-0022 §2.2 — `/issue-sync` Command와 분리 (Command는 Projects v2 sync, 본 Skill은 status:blocked 해제).

## 1. 역할

`status:blocked` 라벨이 부착된 모든 이슈를 일괄 점검하여, 본문 `Blocked-by:` 선언의 *선수 이슈*가 모두 close된 이슈를 찾아 **`status:blocked` 라벨 자동 해제 + `status:todo` 복귀 + 알림 코멘트**. 정책 §3 자동화 규칙 #3의 책임 스킬.

## 2. 진입점

- 사용자 명시 호출: `/issue-unblock` 또는 자연어("블록 해제 좀", "막힌 이슈 풀어줘")
- PR 머지·이슈 close 후 *사용자가 자율적으로 호출* (자동 트리거 아님 — ADR-0022 §2.3)

> **자동 트리거 안 됨**: PR 머지 webhook 같은 GitHub-side 이벤트로 자동 호출되지 않는다. ADR-0005(코드 0줄)·D-07(Claude Code 네이티브) 정합. 자동 트리거가 필요하면 GitHub Actions 후속 ADR 도입 후.

## 3. 입력

- **범위** (선택, 기본=repo 전체): `--milestone="Sprint N"` / `--assignee=@me` / `--label="area:auth"`

## 4. 동작

```
1. 모든 status:blocked 이슈 조회:
   gh issue list --label "status:blocked" --state open --json number,body --limit 100

2. 각 이슈별 본문 'Blocked-by:' 파싱 (issue-claim과 동일 로직):
   ---
   Blocked-by: #45, #46
   ---

3. 각 블록커 상태 점검:
   gh issue view #45 --json state
   → 모두 CLOSED 인지 확인

4. 모든 블록커 close 확인된 이슈에 대해:
   gh issue edit #N \
     --remove-label "status:blocked" \
     --add-label "status:todo"
   gh issue comment #N --body "✅ 모든 선수 이슈 close 확인. 블록 해제됨 (자동, /issue-unblock)."

5. 진행 보고:
   - 점검한 status:blocked 이슈 수
   - 해제된 이슈 수 (목록)
   - 여전히 블록 상태인 이슈 수 (목록 + 미해결 블록커)
```

## 5. 출력

- 해제된 이슈 일람 (#N + 제목)
- 여전히 블록 상태인 이슈 일람 + 미해결 블록커
- 작업 로그 (코멘트·라벨 변경 내역)

## 6. 실패 케이스

| 케이스 | 동작 |
|---|---|
| status:blocked 이슈 0개 | 정상 종료 — "해제할 이슈 없음" 보고 |
| 본문에 `Blocked-by:` 선언 없는 status:blocked 이슈 | WARN — "본문 정합 깨짐" 안내 + 사용자 결정 위임 (해제 안 함) |
| 블록커 #M이 부재 (삭제됨) | WARN — 사용자 결정 위임 |
| 권한 부족 | BLOCKED — `gh auth refresh -s write:issues` 안내 |

## 7. 정합 문서

- [`policies/github-issue.md §3`](../../../../docs/planning/policies/github-issue.md) — 의존성 자동화 규칙 #3
- [`policies/github-issue.md §4`](../../../../docs/planning/policies/github-issue.md) — FSM ↔ 라벨 매핑 (BLOCKED → PENDING 전이)
- [ADR-0022 §2.2](../../../../docs/planning/adr/0022-skill-implementation.md) — `/issue-sync` Command와 분리한 명명 결정
- [ADR-0022 §2.3](../../../../docs/planning/adr/0022-skill-implementation.md) — Skill 동작 본질 (사용자 명시 호출)
- 관련 Skill: [`issue-claim`](../issue-claim/SKILL.md) — 작업 진입 시 검사 (역방향)
- 관련 Command: [`/issue-sync`](../../../commands/issue-sync.md) — Projects v2 단방향 sync (다른 책임)
