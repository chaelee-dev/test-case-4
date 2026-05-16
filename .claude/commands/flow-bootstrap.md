---
description: Phase 4/4 of NEW_PROJECT — git commit + PR + sprint-bootstrap (GitHub external write). Use this after /flow-wbs and human review of 13·14. Transitions toolkit from mode=planning to mode=sprint. After this, switch to /flow-feature for issue-by-issue work.
allowed-tools: Read, Bash, Glob, Grep
---

# /flow-bootstrap

## 목적

NEW_PROJECT **Phase 4/4** — **외부 쓰기** 단계. git 커밋·푸시·PR + sprint-bootstrap dry-run·실 실행. GitHub Milestones + Issues + Labels + Projects v2 items 일괄 등록. 본 메타 완료 후 툴킷이 **mode=planning → mode=sprint** 전환.

> **ADR-0016 §2.1**: 4단계 분리의 마지막. *외부 시스템 쓰기*가 일어나는 유일한 단계라 사용자 명시 호출 + dry-run 한 번 더 확인이 안전망.

## 사용 시점

- `/flow-wbs` 완료 + 사용자 WBS 검수 OK
- 14-wbs/14-wbs.md §7 sprint-bootstrap YAML 작성 완료
- 15-risk·14-wbs 모두 v0.1+ DRAFT 또는 v1.0+ Accepted

## 산출

**파일 산출 (1수준 폴더 외)**:
- 신규 git 브랜치 `chore/planning-bootstrap-<YYYYMMDD>` (현 브랜치 main/master일 때)
- 신규 git 커밋 (docs/planning/* + adr/* + docs/planning/INDEX.md 등 부속)
- 신규 PR (base=main, head=신규 브랜치) — *docs-only PR*

**외부 쓰기 (GitHub)**:
- Milestones (Sprint 1..N)
- Issues (이슈 8필드 채워서 등록)
- Labels (FSM 5종 + priority 4종 + type 5종 + area 6종 = 20종)
- Projects v2 items (단방향 sync, ADR-0009)

## Phase Sequence (내부 자동 호출)

```
0. (자동) /context-loader 입력 검증
   - 14-wbs·15-risk 폴더 존재?
   - 13 §7 sprint-bootstrap YAML 작성 완료?
   - 아니면 BLOCKED: "/flow-wbs 미통과"

─── git 커밋 + Planning PR ────────────────
1. (자동) 현재 브랜치 확인
   if [현재 = main/master]; then
     git checkout -b chore/planning-bootstrap-<YYYYMMDD>
   else
     그대로 사용 (분기 skip, 예: dev/* 브랜치)
   fi
2. (자동) git add docs/planning/ docs/planning/adr/ + 부속 변경
3. (자동) git commit -m "docs(plan): /flow-new-project 산출 일괄 (01~15 + adr/) — 게이트 A·B·C 통과 + WBS"
4. (자동) git push -u origin <브랜치>
5. (자동) gh pr create --base main --head <브랜치>
   - 본문: 산출 문서 목록 + 게이트 A·B·C 컨펌 기록 + 다음 단계 안내
   - Test Plan 4블록: N/A (docs-only PR)

─── sprint-bootstrap dry-run ──────────────
6. (자동) bash scripts/sprint-bootstrap.sh --dry-run
   - 출력: Milestones + Issues 미리보기 + Labels 20종 + Projects v2 item 매핑
   - 표시 위치: stderr
   - 외부 쓰기 0 (시뮬레이션만)

─── 휴먼 게이트 (마지막 컨펌) ──────────────
▶ 사용자: dry-run 결과 검토. OK면 실 실행 승인 입력
   - 등록 예정 Sprint 수 / Issue 수가 14-wbs/14-wbs.md와 일치하는가
   - 라벨 20종이 의도와 맞는가
   - Projects v2 item 매핑이 단방향 sync(ADR-0009)와 정합한가

─── 실 등록 (승인 후) ─────────────────────
7. (승인 후, 자동) bash scripts/sprint-bootstrap.sh
   → GitHub 실 쓰기. 멱등 보장 (재실행 시 기존 항목 skip)
8. (자동) 툴킷 모드 전환: planning → sprint
   - .claude/state/flow-state.yaml 갱신 (mode: sprint, current_sprint: 1)

─── 완료 안내 ──────────────────────────
✅ NEW_PROJECT 4단계 완료. Sprint 1 진입 가능.
다음 단계: /flow-feature #<이슈번호> 또는 자연어 "이슈 #N 작업"
```

## 입력

- `docs/planning/14-wbs/14-wbs.md` §7 YAML (필수)
- `docs/planning/15-risk/15-risk.md`
- (선택) `gh` CLI 인증 상태 — 미인증 시 `gh auth login` 안내

## 완료 조건

- [ ] git 브랜치 + 커밋 + push 정상
- [ ] PR open 상태 (base=main)
- [ ] sprint-bootstrap dry-run 결과 사용자 승인
- [ ] sprint-bootstrap 실 실행 완료 (exit 0)
- [ ] GitHub Milestones·Issues·Labels·Projects v2 items 모두 등록 확인 (`gh issue list --milestone "Sprint 1"`)
- [ ] flow-state.yaml `mode: sprint`로 전환

## 다음 메타

```
mode=sprint 전환 완료
   ▼
/flow-feature #<이슈번호>      (또는 자연어 "이슈 #N 작업")
   → Sprint 1+ 이슈 단위 반복
```

## BLOCKED 케이스

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: /flow-wbs 미통과` | 13·14 부재 | `/flow-wbs` 먼저 |
| `BLOCKED: gh CLI 미인증` | `gh auth status` 실패 | `gh auth login` 후 재실행 |
| `BLOCKED: sprint-bootstrap YAML 부재` | 13 §7 미작성 | `/wbs` 재실행으로 YAML 자동 채움 |
| `BLOCKED: dry-run 결과 사용자 거부` | 등록 항목 불일치 | `/flow-wbs` 회귀 후 재진입 |
| `BLOCKED: 브랜치 push 실패` | 원격 접근 권한 | 권한 확인 또는 수동 push |
| `BLOCKED: sprint-bootstrap exit ≠ 0` | gh API 오류 등 | 에러 메시지 확인 + 부분 등록 상태 점검 |

## Strict Rules

- **dry-run 후 사용자 승인 없이 실 실행 금지** — 외부 쓰기는 *되돌리기 비용 큼*. 본 메타의 핵심 안전망
- **본 메타 자체가 PR을 머지하지 않음** — Planning PR 머지는 사람이 GitHub 웹에서 별도 결정 (docs-only)
- **`--force` 옵션 없음** — sprint-bootstrap 멱등 보장에 의존. 재실행 안전

## Artifact Binding

- 입력: `/flow-wbs` 산출 (13 §7 YAML 특히)
- 출력: GitHub 외부 + flow-state mode=sprint 전환 → `/flow-feature`의 입력 환경 조성

## 트리거 매칭

- "GitHub 등록", "sprint-bootstrap 실행", "/flow-bootstrap", "Sprint 1 시작 준비"
- 자연어: "이제 깃허브에 등록", "이슈 다 만들자", "외부 쓰기 시작"
