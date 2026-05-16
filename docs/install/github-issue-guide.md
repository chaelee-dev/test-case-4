# GitHub 이슈 가이드 (5분 안내)

> **독자**: 본 프로젝트에 합류한 팀원·도입자. 이슈/PR을 만들 때 무엇을 어떻게 채울지 한눈에 보는 자리.
> **정본** (전체 메커니즘·자동화·schema): [`docs/planning/policies/github-issue.md`](../planning/policies/github-issue.md). 본 가이드는 일상 사용용 요약.
> **상위 결정**: ADR-0008 (파생 이슈 컨벤션), **ADR-0021 (제목 명명 + 멀티 모듈 + Origin 약한 추적)**.

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v1.0 | 2026-05-13 | chae.lee | 초안 — ADR-0021 채택과 동시 신설. 외부 피드백 4건(이름 규칙·prefix·태그·멀티 모듈) + 파생 이슈 Origin 추적을 1~2장 사용자 친화 안내로 정리. |

---

## 1. 이슈/PR 만들 때 5분 안내

### 1.1 제목 — `<type>(<area>): <summary>`

```
feat(auth): 로그인 폼 추가
fix(billing): 결제 콜백 검증 누락 보정
docs(plan): policies/github-issue.md §1.5 보강
```

| 자리 | 값 |
|---|---|
| `<type>` | `feat` (새 기능) · `fix` (버그 수정) · `chore` (잡무·빌드) · `docs` (문서) · `test` (테스트) · `refactor` (동작 불변 리팩터) |
| `<area>` | 모듈/도메인 — `auth` · `billing` · `infra` · 등. **프로젝트별로 다름. 본 프로젝트 어휘는 [`06 Architecture`](../planning/06-architecture/06-architecture.md) §3 모듈 인벤토리 참조**. |
| `<summary>` | 한글/영문 자유, 50자 권고, 동사로 시작 권고 |

> 정규식 BLOCK: `^(feat|fix|chore|docs|test|refactor)\([a-z][a-z0-9,_-]*\): .+$`. GitHub Action이 제목을 자동 검증 — 형식 안 맞으면 PR 머지 차단.

### 1.2 본문 — 4필드 채우기

이슈 템플릿이 자동 제공:

```markdown
## Acceptance Criteria
- [ ] AC-01: …
- [ ] AC-02: …

## Contract Before / After
- Before: (현재 동작)
- After: (변경 후 동작)

## Estimated Effort
- 0.5d | 1d | 2d | 3d  (이 중 하나)

## DoD Checklist
- [ ] 코드 작성
- [ ] 테스트 통과
- [ ] PR 머지
```

### 1.3 라벨 부착 — 5가지 카테고리

이슈를 만들면 다음 라벨을 자동/수동 부착:

| 카테고리 | 예시 | 부착 시점 |
|---|---|---|
| 우선순위 | `priority:P0`·`P1`·`P2`·`P3` | 이슈 등록 시 |
| 유형 | `type:feature`·`bug`·`chore`·`docs`·`test` | 제목 `<type>`과 자동 정합 |
| 영역 | `area:auth`·`billing`·`infra`·… | 제목 `<area>`와 자동 정합 |
| 상태 | `status:todo`→`in-progress`→`in-review`→`blocked` | Phase 전이 시 자동 갱신 |
| 의존성 | `blocked-by:#N` (보조) | 본문 `Blocked-by:` 선언이 우선 |

---

## 2. 라벨 보는 법

### 2.1 GitHub UI에서

이슈 목록 → 우상단 라벨 필터:

```
is:open label:status:in-progress           # 진행 중 이슈
is:open label:priority:P0                  # 즉시 처리 필요
is:open label:area:auth                    # auth 영역
is:open label:status:blocked               # 차단된 이슈
is:open label:derived                      # 파생 이슈 (§4 참조)
```

### 2.2 gh CLI에서

```bash
gh issue list --label "status:in-progress"
gh issue list --label "priority:P0" --label "status:todo"
gh issue list --assignee @me --label "status:in-progress"
gh issue list --label "carryover:from-sprint-3"  # 직전 스프린트 carry over
```

### 2.3 상태 라벨의 의미 (자주 묻는 질문)

| 라벨 | 의미 | 다음 단계 |
|---|---|---|
| (없음) | 이슈 생성 직후 | 마일스톤 배정 + `status:todo` |
| `status:todo` | 작업 대기 | `/implement` 진입 시 자동 → `in-progress` |
| `status:in-progress` | 작업 중 | PR open 시 자동 → `in-review` |
| `status:in-review` | PR 검토 중 | tested 라벨 + Approve → 머지 → close |
| `status:blocked` | 선수 이슈 미해결 | `Blocked-by:` 해소 시 자동 → `todo` 복귀 |
| (close) | 작업 완료 | 라벨 정리 (`tested`만 보존) |

---

## 3. 멀티 모듈 작업 시

영역이 2개 이상에 걸치는 경우:

### 3.1 영역 2개

```
fix(auth,session): 토큰 만료 시 결제 콜백 검증 누락 보정
```

라벨: `type:bug` + `area:auth` + `area:session` (복수 부착)

본문 끝에 `## Touched Areas` 표 권고 (BLOCK 아님).

### 3.2 영역 3개 이상 — `multi` + Touched Areas 표 강제

```
refactor(multi): 에러 코드 PREFIX 표준화
```

라벨: `area:multi` + 각 `area:*` 라벨 (모두 부착).

본문에 다음 표 **강제** (없으면 PR 머지 BLOCK):

```markdown
## Touched Areas

| Area | 변경 성격 | 리뷰어 |
|---|---|---|
| auth | API 시그니처 변경 | @reviewer1 |
| session | 토큰 처리 보정 | @reviewer2 |
| infra | 환경변수 추가 | @reviewer3 |
```

> 영역 3개 이상은 PR 분할 압박을 받습니다 — 거대 PR 회피 의도된 부작용. 가능하면 영역별로 PR을 나누세요.

---

## 4. 파생 이슈 (작업 중 다른 문제 발견)

이슈 작업 도중 *새로운 작업*이 발견되면 **별도 독립 이슈**로 등록합니다. 부모-자식 결합 없음 — 단, 발견 출처는 `## Origin` 블록으로 *약한 추적* (검색 가능, close 영향 없음).

### 4.1 3가지 패턴 분류

| 패턴 | 정의 | 등록 명령 |
|---|---|---|
| **A. Derived (파생)** | 부모와 관련 있으나 완전 독립 | `/flow-feature "..."` |
| **B. Blocker** | 부모가 선행 완료를 기다려야 할 작업 | `/flow-feature "..."` + `Blocked-by: #N` |
| **C. Bug** | 부모와 무관한 별개 결함 | `/flow-feature --mode=bug` |

> 분류가 모호하면 `/start-feature "..."`로 자연어 위임 — 자동 분류.

### 4.2 AI 검증 중 발견 (반자동)

`/code-review`·`/qa-test --ai`·`/risk-check` 보고서 끝에 **"## 발견 사항 (Found Issues)"** 절에 후보 자동 등록. **3축 OX**(in_scope·blocks_parent_merge·same_area 모두 False)를 통과한 후보만 등록 제안 — 사용자 승인 후 자동 등록.

3축 OX:

```
[ ] in_scope == False               (부모의 acceptance/contract에 없음)
[ ] blocks_parent_merge == False    (부모 PR 머지에 영향 없음)
[ ] same_area == False              (부모와 다른 파일·모듈·영역)
```

### 4.3 휴먼 PR 리뷰 중 발견 — **기본은 PR 변경 요청**

`gh pr review <PR_N> --request-changes --body "..."` → AI 게이트부터 재진입 → 같은 PR 추가 커밋 → 머지. **파생 이슈 신설은 scope 완전 밖일 때만** (위 3축 OX 모두 충족 시).

### 4.4 파생 이슈 본문 — `## Origin` 블록 (BLOCK)

`derived` 라벨이 부착된 이슈는 본문에 다음 블록 강제:

```markdown
## Origin

| Field | Value |
|---|---|
| Discovered-in | PR #42  (또는 Issue #15, code-review 보고서 경로) |
| Discovered-by | /code-review  (또는 /qa-test --ai, 휴먼 PR 리뷰, 자가 발견) |
| Discovered-at | 2026-05-13T14:30:00 KST |
| Pattern | A. Derived  (또는 B. Blocker, C. Bug) |
| 3-axis OX | in_scope=F / blocks_parent_merge=F / same_area=F |
```

AI 발견 시는 보고서가 자동 채움. 휴먼 발견 시는 `/start-feature`가 인터랙티브로 묻고 채움.

### 4.5 파생 이슈 검색

```bash
gh issue list --label derived                                       # 모든 파생 이슈
gh issue list --label derived --search "Discovered-in: #42"         # PR #42에서 파생
gh issue list --label derived --search "Discovered-by: /code-review"
```

부모(`Discovered-in: #42`의 #42)가 close되어도 파생 이슈는 영향 없음 — *약한 링크 본질*.

---

## 5. 예시 5개 (Copy-paste 가능)

### 5.1 단일 영역 새 기능

```
제목: feat(auth): 소셜 로그인(Google) 추가
라벨: type:feature, area:auth, priority:P2, status:todo

본문:
## Acceptance Criteria
- [ ] AC-01: Google OAuth2 flow 통과 시 세션 생성
- [ ] AC-02: 거절 시 로그인 페이지로 returnUrl 보존

## Contract Before / After
- Before: 이메일/비번 로그인만
- After: + Google OAuth 옵션

## Estimated Effort
- 2d

## DoD Checklist
- [ ] 코드 작성
- [ ] 통합 테스트 (mock OAuth)
- [ ] PR 머지
```

### 5.2 영역 2개 버그

```
제목: fix(auth,session): 토큰 만료 시 결제 콜백 검증 누락 보정
라벨: type:bug, area:auth, area:session, priority:P1

본문: (4필드 + Touched Areas 권고)
```

### 5.3 영역 3개 이상 리팩터 — multi 강제

```
제목: refactor(multi): 에러 코드 PREFIX 표준화
라벨: area:multi, area:auth, area:billing, area:infra

본문: (4필드 + Touched Areas BLOCK)

## Touched Areas
| Area | 변경 성격 | 리뷰어 |
|---|---|---|
| auth | AUTH_* PREFIX 추가 | @r1 |
| billing | BILL_* PREFIX 추가 | @r2 |
| infra | INFRA_* PREFIX 추가 | @r3 |
```

### 5.4 블록 의존 — Blocked-by

```
제목: feat(billing): Stripe 결제 위젯 임베드
라벨: type:feature, area:billing, status:blocked

본문 상단:
---
Blocked-by: #45  (Stripe API 키 등록 이슈)
---

## Acceptance Criteria
- [ ] AC-01: 결제 위젯이 카드 정보 수집·전달
…
```

### 5.5 파생 이슈 (PR #42 코드리뷰 중 발견)

```
제목: refactor(auth): 관리자 모듈 캐시 추가 (로그인 폼과 무관)
라벨: type:chore, area:auth, derived

본문:
## Origin
| Field | Value |
|---|---|
| Discovered-in | PR #42 |
| Discovered-by | /code-review |
| Discovered-at | 2026-05-13T14:30:00 KST |
| Pattern | A. Derived |
| 3-axis OX | in_scope=F / blocks_parent_merge=F / same_area=F |

## Acceptance Criteria
- [ ] AC-01: 관리자 모듈 LRU 캐시 도입
…
```

---

## 6. 더 깊이 알고 싶으면

| 주제 | 정본 |
|---|---|
| 전체 메커니즘·자동화·schema | [`docs/planning/policies/github-issue.md`](../planning/policies/github-issue.md) |
| 스프린트 사이클·D-06 게이트·재개·Rollover | [`docs/planning/policies/sprint-cycle.md`](../planning/policies/sprint-cycle.md) |
| 진행 흐름·게이트(A·B·C) | [`docs/planning/policies/flow-and-gates.md`](../planning/policies/flow-and-gates.md) |
| 파생 이슈 결정 근거 | [`docs/planning/adr/0008-derived-issue-convention.md`](../planning/adr/0008-derived-issue-convention.md) |
| 본 가이드 결정 근거 | [`docs/planning/adr/0021-issue-naming-and-origin.md`](../planning/adr/0021-issue-naming-and-origin.md) |
