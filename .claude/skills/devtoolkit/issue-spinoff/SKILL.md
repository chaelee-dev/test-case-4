---
name: issue-spinoff
description: Use this skill when an AI validation report (/code-review, /qa-test --ai, /risk-check) contains a "## 발견 사항 (Found Issues)" section with candidate items that passed 3-axis OX checks. Auto-creates derived GitHub issues with the `derived` label and `## Origin` block populated from the report context.
---

# issue-spinoff — 파생 이슈 자동 등록

> **정합**: [ADR-0008](../../../../docs/planning/adr/0008-derived-issue-convention.md) (파생 이슈 컨벤션), [ADR-0021](../../../../docs/planning/adr/0021-issue-naming-and-origin.md) (Origin 약한 추적), [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md) (Skill 실구현), [`policies/github-issue.md §5`](../../../../docs/planning/policies/github-issue.md)

## 1. 역할

AI 검증 보고서(`/code-review`, `/qa-test --ai`, `/risk-check`)의 **"## 발견 사항 (Found Issues) — 파생 이슈 후보"** 절을 파싱하여, 3축 OX 모두 통과한 후보를 별도 GitHub Issue로 자동 등록한다. 등록 시 **`derived` 라벨 부착**과 **`## Origin` 블록 자동 채움**으로 파생 출처를 *약한 추적*(검색 가능 메타, 부모 close 영향 없음)한다.

## 2. 진입점

다음 Command가 보고서를 산출한 직후 호출:

| 호출자 | 보고서 경로 | Discovered-by 값 |
|---|---|---|
| `/code-review` | `docs/features/<slug>/<slug>.code-review.md` | `/code-review` |
| `/qa-test --ai` | `docs/features/<slug>/<slug>.ai-qa-report.md` | `/qa-test --ai` |
| `/risk-check` | `docs/features/<slug>/<slug>.risk.md` | `/risk-check` |
| `/start-feature` (휴먼 PR 리뷰 위임) | (자연어) | `휴먼 PR 리뷰` |

사용자 명시 호출도 가능: `/<host-command>` 실행 후 발견 사항이 있으면 본 Skill이 description 매칭으로 트리거.

## 3. 입력

- **보고서 경로** (필수): "## 발견 사항" 절 파싱 대상
- **부모 컨텍스트** (선택): PR 번호 또는 이슈 번호. 미지정 시 보고서에서 추출
- **승인 모드** (기본=interactive): `interactive` (후보별 사용자 승인) / `bulk` (3축 OX 통과 후보 일괄 등록)

## 4. 동작

```
1. 보고서 파일 Read
2. "## 발견 사항 (Found Issues) — 파생 이슈 후보" 절 추출
3. 각 후보별로:
   a. 3축 OX 체크박스 평가
      - [✅] in_scope == False
      - [✅] blocks_parent_merge == False
      - [✅] same_area == False
   b. 3축 모두 ✅ → A. Derived 분류 → 등록 후보
      Q2 ❌ → B. Blocker 분류 → 등록 후보 (Blocked-by 부착)
      무관 결함 → C. Bug 분류 → 등록 후보 (`/flow-feature --mode=bug` 권장)
      Q1·Q3만 ❌ → 같은 PR 보정 (Skill 등록 대상 아님)
4. 사용자 승인 (interactive 모드)
5. 승인된 후보별로 gh issue create 호출:

   gh issue create \
     --title "<type>(<area>): <summary>" \   # ADR-0021 정규식 강제
     --label "derived,type:*,area:*,priority:P*,status:todo" \
     --body "$(cat <<EOF
   ## Origin
   | Field | Value |
   |---|---|
   | Discovered-in | <부모 PR/Issue 또는 보고서 경로> |
   | Discovered-by | <호출자 Command> |
   | Discovered-at | $(date -d "+9 hours" +"%Y-%m-%dT%H:%M:%S KST") |
   | Pattern | A. Derived (or B. Blocker, C. Bug) |
   | 3-axis OX | in_scope=F / blocks_parent_merge=F / same_area=F |

   ## Acceptance Criteria
   - [ ] AC-01: <보고서 발췌>

   ## Contract Before / After
   - Before: <현재 상태>
   - After: <변경 후>

   ## Estimated Effort
   - 1d   # 보고서 컨텍스트 기반 추정 (기본 1d)

   ## DoD Checklist
   - [ ] 코드 작성
   - [ ] 테스트 통과
   - [ ] PR 머지
   EOF
   )"

6. B. Blocker 패턴이면 본문에 'Blocked-by: #<부모>' 추가
7. 부모 이슈/PR에 코멘트 자동 부착: "파생 이슈 #<신규> 등록됨 (Origin: <Skill 이름>)"
```

## 5. 출력

- 신규 GitHub Issue 생성 (URL + 번호)
- 부모 이슈/PR에 등록 알림 코멘트
- 작업 보고: 등록된 후보 수, 거부된 후보 수, BLOCKED 후보 수

## 6. 실패 케이스

| 케이스 | 동작 |
|---|---|
| 보고서 파일 부재 | BLOCKED — 사용자에게 보고서 경로 확인 요청 |
| "## 발견 사항" 절 없음 | 정상 종료 — 등록할 후보 없음 |
| 후보 3축 OX 모두 ❌ | 해당 후보는 건너뜀 (Skill이 등록 안 함, "같은 PR 보정" 통보) |
| 제목 정규식 위반 (ADR-0021) | BLOCKED — 사용자에게 제목 수정 요청 후 재시도 |
| `gh issue create` 실패 (권한·네트워크) | BLOCKED — 보고서에 실패 사유 + 수동 등록 가이드 출력 |

## 7. 정합 문서

- [`policies/github-issue.md §5`](../../../../docs/planning/policies/github-issue.md) — 파생 이슈 3가지 패턴(A/B/C) + 3축 OX
- [`policies/github-issue.md §5.6`](../../../../docs/planning/policies/github-issue.md) — Origin 블록 약한 추적
- [ADR-0008](../../../../docs/planning/adr/0008-derived-issue-convention.md) — 부모-자식 강한 결합 폐기
- [ADR-0021](../../../../docs/planning/adr/0021-issue-naming-and-origin.md) — 제목 명명 + Origin
- [ADR-0022](../../../../docs/planning/adr/0022-skill-implementation.md) — 본 Skill 도입 결정
