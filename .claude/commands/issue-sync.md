---
description: Use this when the user has changed labels, milestones, or issue bodies in GitHub and needs to propagate those changes to the GitHub Projects v2 board. One-way sync — Issues/Milestone is the SoT, Projects v2 is a view-only layer (ADR-0009 Projects v2 도입 정책).
allowed-tools: Read, Bash, Glob, Grep
---

# /issue-sync

## 목적

GitHub Issues/Milestone(SoT, D-02·D-04)의 변경 내용을 GitHub Projects v2 보드(View 계층)로 단방향 동기화한다. 라벨·Milestone·이슈 본문 변경마다 Project 필드(Status/Iteration/Effort/Area/R-ID/F-ID)를 재계산.

> 본 Command는 Projects v2 도입 정책(`docs/planning/conventions/document-manifest.md`, ADR-0003 §2.6 각주, `docs/planning/policies/github-issue.md` §5.2.1)에 정합. **역방향(Project → Issues) 동기화는 금지** — 이중 정본 회피.

> **`/issue-sync` Command vs [`issue-unblock`](../skills/devtoolkit/issue-unblock/SKILL.md) Skill 구분 (ADR-0022 §2.2)**: 본 Command는 *Issues → Projects v2 단방향 sync*. Skill `issue-unblock`은 *선수 이슈 close 시 의존 이슈 `status:blocked` 자동 해제*. 두 책임은 다르며 동시 사용 가능.

## 사용 시점

- `scripts/sprint-bootstrap.sh` 실행 직후
- 라벨·Milestone 일괄 변경 후
- 이슈 본문에 `Estimated Effort`, `매핑.R-ID/F-ID` 갱신 후
- Sprint Rollover (`/wbs --update`) 후

## 입력

- (필수) GitHub repo + Project v2 number
- (필수) `gh-cli` 인증 + project 권한 (`gh auth refresh -s project,read:project`)
- (선택) 특정 Sprint 필터 — `--sprint=N`

## 산출

- Project v2 items가 Issues/Milestone과 정합
- 동기화 보고서: `docs/planning/operations/issue-sync-<YYYYMMDD>.md` (선택)

## 필드 매핑 (단방향: Issues → Project)

| Project Field | Type | Source | 갱신 트리거 |
|---|---|---|---|
| Status | single-select | `status:*` 라벨 | 라벨 변경 |
| Iteration | iteration | Milestone | Milestone 배정/변경 |
| Effort | number | 본문 `Estimated Effort` | 이슈 본문 갱신 |
| Area | single-select | `area:*` 라벨 | 라벨 변경 |
| R-ID | text | 본문 `매핑.R-ID` | 이슈 본문 갱신 |
| F-ID | text | 본문 `매핑.F-ID` | 이슈 본문 갱신 |

## 실행 단계

1. Project number + owner 확인:
   ```bash
   gh project list --owner @me  # 본인 소유
   gh project list --owner <org>  # 조직
   ```
2. Project field ID 확인 (한 번 설정 후 캐시):
   ```bash
   gh project field-list <num> --owner <owner>
   ```
3. 대상 이슈 조회:
   ```bash
   gh issue list --milestone "Sprint N" --json number,title,labels,body,milestone --limit 100
   ```
4. 각 이슈에 대해:
   - Project item ID 조회 (`gh project item-list <num> --owner <owner>`)
   - 미등록 시 추가: `gh project item-add <num> --owner <owner> --url <issue_url>`
   - 라벨·본문에서 추출한 값으로 필드 set:
     ```bash
     gh project item-edit --id <item-id> --project-id <pid> --field-id <fid> --single-select-option-id <opt>
     gh project item-edit --id <item-id> --project-id <pid> --field-id <fid> --number <effort>
     gh project item-edit --id <item-id> --project-id <pid> --field-id <fid> --text "<R-ID>"
     ```
5. 정합 검증:
   - `Status` ↔ `status:*` 라벨 일치
   - `Iteration` ↔ Milestone 일치
   - `Effort` ↔ 본문 `Estimated Effort` 일치
6. (선택) 보고서 작성

## 완료 조건

- 모든 대상 이슈가 Project에 등록되어 있음
- 6개 필드가 SoT(Issues/Milestone)와 일치
- 불일치가 있으면 `BLOCKED: 정합 실패 — issue #N field <X>` 보고

## Strict Rules

- **역방향 동기화 금지** — Project에서 라벨/Milestone을 수정하지 않는다
- **R-ID/F-ID는 04 SRS·05 PRD에 실재해야 함** — 미존재 시 BLOCKED
- **gh project 권한 부족 시** → operations/runbook.md §4.4 fallback 절차 안내

## BLOCKED 케이스

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: gh project 권한 부족` | scope 미부여 | `gh auth refresh -s project,read:project` |
| `BLOCKED: Project number 미지정` | wbs.md project: 블록 누락 | `/wbs --update`로 보강 |
| `BLOCKED: 정합 실패 — issue #N field <X>` | SoT-View 불일치 | 본 Command 재실행 또는 SoT 직접 수정 |
| `BLOCKED: R-ID 미존재 — R-XX` | 04 SRS에 없는 ID | 이슈 본문 수정 또는 SRS 보강 |

## Artifact Binding

- 입력: GitHub Issues + Milestone (SoT) + `wbs.md` §7 `project:` 블록
- 출력: GitHub Projects v2 items (View 정합)
- 페어링: `scripts/sprint-bootstrap.sh` (선행), `/wbs --update` (선행), `/docs-update` (선택 보고서 갱신)

## 트리거 매칭

- "Project 동기화", "Projects v2 갱신", "보드 동기화", "필드 재계산", "issue-sync"
