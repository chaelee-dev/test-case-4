# USAGE_GUIDE — agent-toolkit 사용 안내

> **대상**: agent-toolkit (DevToolKit v6) 작업자
> **전제**: docs/planning/INDEX.md, CLAUDE.md, `.claude/harness/feature-development-harness.md` 숙지
> **버전**: v0.8.2 (2026-05-04) — 사람이 읽기 쉽게 재구성. 정보 보존, 구조·압축만 변경

---

## 0. 한 눈에 보기 (30초)

```
1. cd c:\work\agent-toolkit  (Claude 메모리 격리)
2. /context-loader            → 현재 위치 + mode 자동 감지
3. /flow-new-project "<RFP>"  또는  /flow-feature #N
4. 자동 진행 — 사용자는 게이트 컨펌(A·B·C)만 입력
5. (sprint) PR ─ AI 게이트 통과 → 휴먼 게이트(tested 라벨) → 머지
```

> **산출 문서는 schema 강제 (ADR-0010)**: 모든 문서(28종)는 `.claude/schemas/<doc_type>.schema.yaml` 정본에 따라 형식이 강제된다. 같은 RFP 입력 → 같은 형식 출력 보장. 작성 흐름은 §6.2 참조.

---

## 1. 모드 시스템

| 모드 | 작업 정본 | 사용 시점 | 주요 차이 |
|---|---|---|---|
| `planning` | `docs/planning/` 산출 문서 | WBS·GitHub Milestone 미등록 단계 (= 현재) | gh-cli 옵셔널, 게이트 A/B/C 강제 |
| `sprint` | GitHub Issue (#N) | sprint-bootstrap 후 (Sprint 1+) | gh-cli 필수, 라벨/PR/D-06 게이트 강제 |

**현재 시점은 `mode=planning`**. docs/planning/CHANGELOG.md §"Current Status"의 다음 작업이 `/flow-new-project "<RFP>"` 호출 단계며, 게이트 C 통과 후 `sprint-bootstrap.sh` 실행 시점에 자동 전환된다.

수동 override: `/start-feature --mode=sprint <의도>` 또는 `--mode=planning`.

---

## 2. 라이프사이클 5단계

```
[1] 분석·설계 ─→ [2] 부트스트랩 ─→ [3] 이슈 작업 ──→ [4] 머지·close
                                          ↑                  │
                                          └──[5] 사이클 ←────┘
                                             (Sprint Rollover)
```

| 단계 | 모드 | 진입 명령어 | 결과 |
|---|---|---|---|
| **1. 분석·설계** | planning | `/flow-new-project "<RFP\|PRD\|자연어>"` | 산출 01·03·04·05·06·07·08·12·13·14·15 자동 일괄, 게이트 A·B·C 통과 |
| **2. 부트스트랩** | planning → sprint | (단계 1에서 자동) `/risk-check` → `/wbs` → `sprint-bootstrap.sh` | Milestone+Issues+Labels 등록, Sprint 1 active |
| **3. 이슈 작업** | sprint | `/flow-feature #N` (모드 자동 감지) | PR open + `status:in-review` 라벨 (AI 게이트 통과) |
| **4. 머지·close** | sprint | `gh pr ...` (휴먼 게이트, 사람 책임) | tested 라벨 + Approve + CI green → 머지 → 이슈 close |
| **5. 사이클** | sprint | gstack `/retro` + `/wbs --update` + `sprint-bootstrap.sh --sprint=N+1` | Sprint N→N+1 갱신 (살아있는 WBS) |

> 단계 3↔4를 스프린트 내 이슈 수만큼 반복. Sprint 종료 시 단계 5로 진입해 다음 스프린트 준비.

---

## 3. 단계별 가이드

### 3.1 단계 1 — 분석·설계

**진입**: `/flow-new-project "<RFP|PRD|자연어>"`

**자동 일괄 작성** (ADR-0004) — 사용자 컨펌 5회 = RFP 입력 1 + 게이트 A·B·C 컨펌 3 + sprint-bootstrap 실 실행 승인 1:

```
─── 게이트 A (팀장 컨펌) ───
  /intention-brief             → 01-project-brief.md (+ 02 선택)
▶ 사용자: y/n 컨펌

─── 게이트 B (팀 합의) ────
  /ux-flow-design (또는 /intention-brief)  → 03-user-scenarios.md
  /srs                                       → 04-srs.md (R-ID + 검증 시나리오 MUST)
  /prd                                       → 05-prd.md (F-ID + MVP Cut)
▶ 사용자: y/n 컨펌

─── 게이트 C (개발팀 검토) ───
  /implementation-planner --mode=hld         → 06 (HLD ≤ 3장)
                          --mode=conventions → 12 (≤ 3장)
                          --mode=scaffold    → 13/<lang> (언어당 ≤ 3장)
  /ux-flow-design (와이어프레임)              → 07
  /implementation-planner --mode=api         → 08 (API 단위 ≤ 1장)
                          --mode=module      → 14 (LLD ≤ 5장)
                          --mode=test        → 15 (≤ 5장)
  ADR (병행, 결정 발생 시)                    → docs/planning/adr/NNNN-*.md
  /plan-eng-review                           → 검토 보고서
▶ 사용자: y/n 컨펌
```

**핵심 원칙 (v0.7.8 강화)**: SRS/PRD에 **R-ID/F-ID별 검증 시나리오 MUST** — schema BLOCK 강제. 단계 3·4의 D-06 게이트가 12 Test Design fan-in 카탈로그를 정본 인용. 시나리오 4단계 흐름은 [INDEX.md §3.1](../docs/planning/INDEX.md) 참조.

### 3.2 단계 2 — 부트스트랩

**자동** (단계 1 후반에서 진행):

```
/risk-check                              → 15-risk.md
/wbs (신규 작성 모드)                     → 14-wbs.md
─── 자동 ──────────────────────────────
git checkout -b chore/planning-bootstrap-<YYYYMMDD>  (현 브랜치 main/master일 때만)
git commit + git push -u origin <브랜치>  (단일 커밋, docs/planning/* 일괄)
gh pr create                              → Planning PR open
─── 자동 dry-run ─────────────────────
bash scripts/sprint-bootstrap.sh --dry-run → 미리보기 (라벨 19종 + Milestone + Issues + Projects v2)
▶ 사용자: 실 실행 승인 (5번째 컨펌)
─── 승인 후 자동 ─────────────────────
bash scripts/sprint-bootstrap.sh         → GitHub 실 등록
                                            (이 시점 이후 mode=sprint)
```

> `sprint-bootstrap.sh`는 v1.0.0 구현 완료. dry-run으로 미리보기 후 사용자 승인 시에만 실제 GitHub 쓰기 진입 — 부분 복구가 비싼 side-effect라 명시 게이트 1회.

### 3.3 단계 3 — 이슈 작업 (AI 게이트로 PR 생성까지)

**진입**: `/flow-feature #N` (또는 자연어 + `--mode=add|modify|bug|design`)

**내부 흐름**:
```
/intention-brief → /change-contract → /implementation-planner
   → /plan-eng-review (PASS 필수)
   → /acceptance-criteria → /risk-check
   → /implement (코드+단위 테스트)
   → /code-review (PASS 필수)
   → /qa-test --ai (D-06 1단)
   → PR 자동 생성 + status:in-review
```

**AI 게이트 미통과**: BLOCKED. `/implement` 또는 `/code-review` 회귀.

### 3.4 단계 4 — 머지·이슈 close (D-06 휴먼 게이트)

```
gh pr checkout <N>
[로컬 빌드 + Test Plan Manual verification 단계별 ✅]
gh pr edit <N> --add-label tested
gh pr review <N> --approve         # 동료 승인
gh pr merge <N> --squash           # PR 본문 Closes #N → 이슈 자동 close
/docs-update                        # ADR / CHANGELOG / docs/planning/CHANGELOG.md §"Current Status" 갱신
```

**변경 요청 시**: `gh pr review <N> --request-changes` → AI 게이트(`/qa-test --ai`)부터 재진입.

### 3.5 단계 5 — Sprint Rollover

```
gstack /retro                            → docs/planning/retro/sprint-N.md
/wbs --update                             → 14-wbs.md §2 Sprint (N+1) 갱신
                                           (이전 Sprint N 본문 보존, ✅ closed 표식만 추가)
scripts/sprint-bootstrap.sh --sprint=N+1  → Sprint (N+1) Milestone+Issues 추가 등록
(수동) Milestone N close + carryover 이슈 라벨/Milestone 이동
```

---

## 4. Phase ↔ 산출물 매핑

### 4.1 NEW_PROJECT (게이트 A → B → C → 운영)

| 게이트 | Command | 산출 |
|---|---|---|
| A | `/intention-brief --brainstorm`(선택) → `/intention-brief` | 01 (+ 02 선택) |
| B | `/ux-flow-design` 또는 `/intention-brief` | 03 |
| B | **`/srs`** | 04 (R-ID + 검증 시나리오 MUST, ≤ 5장) |
| B | **`/prd`** | 05 (F-ID + MVP Cut + 검증 시나리오 MUST, ≤ 5장) |
| C | `/implementation-planner --mode=architecture` | 06-architecture.md (Architecture 본체, ADR-0031) |
| C | `/implementation-planner --mode=hld` | 07-hld.md (HLD 본체, ADR-0031 신설) |
| C | `/implementation-planner --mode=module` | 08-lld-module-spec.md (LLD 모듈 내부 본체) |
| C | `/implementation-planner --mode=api` | 09-lld-api-spec.md (LLD 외부 인터페이스) |
| C | `/ux-flow-design` (와이어프레임) | 10-lld-screen-design.md (LLD UI, BE-only는 N/A 골격) |
| C | `/implementation-planner --mode=conventions` | 11-coding-conventions.md |
| C | `/implementation-planner --mode=scaffold --lang=<lang>` | 12-scaffolding/&lt;lang&gt;.md |
| C | `/implementation-planner --mode=test` | 13-test-design/ (5절 폴더, 04·05 fan-in) |
| C | (병행) 직접 작성 | adr/NNNN-*.md |
| C | `/plan-eng-review` | 검토 보고서 |
| 운영 | `/risk-check` | 15-risk.md |
| 운영 | **`/wbs`** (신규) → `sprint-bootstrap.sh` | 14-wbs.md → GitHub 등록 |
| 사이클 | gstack `/retro`, **`/wbs --update`** | retro/sprint-N.md, 10 갱신 |

> **`/srs`·`/prd`·`/wbs`** 는 NEW_PROJECT 전용. `/flow-new-project`가 자동 호출. 단독 호출도 가능 (예: SRS만 갱신).
>
> **분량 초과 시**: 도메인/영역 단위 폴더 + INDEX.md 분할 (LLM 컨텍스트 압축 회피).

### 4.2 FEATURE (이슈 단위 반복, 모드 자동 감지)

`/flow-feature` 한 진입점에서 모드별로 강조 차이. 산출 파일 접두:
- `mode=add` → `feat-<slug>.*.md`
- `mode=modify` → `mod-<slug>.*.md` (+ ADR 필수)
- `mode=bug` → `bug-<slug>.*.md` (+ 회귀 테스트 강제)
- `mode=design` → `design-<slug>.*.md` (+ before/after 스크린샷)

| Phase | Command | 출력 (예: mode=add) |
|---|---|---|
| Brief | `/intention-brief` (`--brainstorm` 옵션) | `feat-<slug>.brief.md` |
| UX (조건부) | `/ux-flow-design` (mode=design 필수) | `feat-<slug>.ux.md` |
| Investigate (조건부) | `/debug-investigator` (mode=bug 전용) | `bug-<slug>.investigation.md` |
| Contract | `/change-contract` | `feat-<slug>.contract.md` |
| Plan | `/implementation-planner` | `feat-<slug>.plan.md` |
| Eng Review | `/plan-eng-review` | `feat-<slug>.eng-review.md` |
| Acceptance | `/acceptance-criteria` | `feat-<slug>.acceptance.md` |
| Risk | `/risk-check` | `feat-<slug>.risk.md` |
| Implement | `/implement` | (코드+커밋) |
| Code Review | `/code-review` (`--refactor` 옵션) | `feat-<slug>.code-review.md` |
| **AI 게이트** | `/qa-test --ai` | `feat-<slug>.ai-qa-report.md` → PR 자동 생성 |
| UI Review (조건부) | `/ui-design-review` (`--consistency` 옵션) | `feat-<slug>.ui-review.md` |
| Docs | `/docs-update` | ADR / docs/planning/CHANGELOG.md §"Current Status" |
| **휴먼 게이트** | `/qa-test --human` 가이드 | tested 라벨 |
| 머지 | (사람) Approve + 머지 | 이슈 close |

---

## 5. D-06 게이트 (2단)

```
[개발 완료]
   ▼
┌──────────────────────────────────────┐
│  AI 게이트 (자동, qa-test --ai)       │
│   ✓ AI 자동 테스트 통과               │
│   ✓ AI 코드 리뷰 PASS                 │
│   ✓ Test Plan 4블록 첨부              │
│   ✓ 시크릿·보안 스캔 통과             │
│   → 통과 시 PR 자동 생성              │
└──────────────────────────────────────┘
   ▼
┌──────────────────────────────────────┐
│  휴먼 게이트 (branch protection 강제) │
│   ✓ 자동 CI 통과                      │
│   ✓ Approve 리뷰 ≥ 1                  │
│   ✓ tested 라벨 (본인 로컬 재현)      │
│   → 머지 → 이슈 close                 │
└──────────────────────────────────────┘
```

**Test Plan 4블록** (PR 본문 강제, `.github/pull_request_template.md`):
- **Build** — 빌드 명령 체크리스트
- **Automated tests** — 자동 테스트 명령 + AI 게이트 결과
- **Manual verification** — 휴먼 게이트가 단계별 ✅
- **DoD coverage** — 이슈 DoD ↔ PR diff 매핑

---

## 6. FSM ↔ GitHub Label 매핑

| FSM | Label | 트리거 |
|---|---|---|
| CREATED | (라벨 없음) | 이슈 생성 직후 |
| PENDING | `status:todo` | 마일스톤 배정 |
| IN_PROGRESS | `status:in-progress` | `/implement` 진입 시 |
| IN_REVIEW | `status:in-review` | PR open |
| DONE | (이슈 close) | PR 머지 |
| BLOCKED | `status:blocked` | Blocked-by 미해소 |
| REJECTED | `status:in-progress` 회귀 + 코멘트 | 변경 요청 |

### 6.1 GitHub Projects v2 매핑 (View 계층, ADR-0009)

D-02 SoT는 Issues+Milestone. Projects v2는 단방향 View 계층. 정본은 `docs/planning/policies/github-issue.md` §5.2.1 참조. 자동화는 `scripts/sprint-bootstrap.sh` (일괄 등록) + `/issue-sync` (점진 동기화).

### 6.2 산출 문서 schema 강제 흐름 (ADR-0010)

모든 산출 문서(28종)는 `.claude/schemas/<doc_type>.schema.yaml`이 형식 정본. **같은 RFP 입력 → 같은 형식 출력 보장**.

```bash
# 1. schema에서 빈 골격 생성
bash .claude/scripts/scaffold-doc.sh <doc_type> <output_path>

# 2. 사용자/LLM이 placeholder를 실제 값으로 채움 (frontmatter author/date, title, 각 섹션 TODO)

# 3. schema 검증
bash .claude/scripts/validate-doc.sh <output_path>
# exit=0  : OK (BLOCK 위반 0)
# exit=2  : BLOCK 위반 (BLOCKED 룰 §3.1 #9 — /plan-eng-review 차단)

# 4. (선택) 13/02-catalog cross-ref 동기화 검사 (ADR-0035)
#    04 SRS·05 PRD의 R-/F-ID 갯수 vs 13/02-catalog의 ### R-/### F- subsection 갯수 비교.
#    누락 ID 발견 시 stderr WARN(차단 없음). /flow-feature P13 + /docs-update §9에서 자동 호출.
bash .claude/scripts/check-test-catalog-sync.sh [--planning-dir=docs/planning]
```

**doc_type 28종**: NEW_PROJECT 13(`brief`/`feasibility`/`user-scenarios`/`srs`/`prd`/`architecture`/`screen-design`/`api-spec`/`adr`/`coding-conventions`/`scaffolding`/`module-spec`/`test-design`) + FEATURE 11(`feature-brief`/`feature-ux`/`feature-investigation`/`feature-contract`/`feature-plan`/`feature-eng-review`/`feature-acceptance`/`feature-risk`/`feature-code-review`/`feature-ai-qa`/`feature-ui-review`) + 운영 4(`wbs`/`risk`/`runbook`/`retro`).

**schema가 강제하는 것**: 필수 섹션 + 순서, 표 컬럼, subsection 패턴(예: `### R-F-NN`), ID 정규식(R-/F-/UC-/RISK-/AC-), frontmatter 7필드 enum/pattern.

**schema가 강제하지 않는 것**: 산출 분량(행 수·페이지). 산출 문서(01~15·`docs/features/*`·`retro/`)는 RFP/맥락에 따라 자유. **운영 문서만** `.claude/scripts/check-line-count.sh`가 300줄 WARN-only로 별도 가드.

상세 정책은 [`docs/planning/conventions/document-manifest.md`](../docs/planning/conventions/document-manifest.md).

---

## 7. 자주 마주칠 BLOCKED

### 전역
- `change-contract 부재` — `/change-contract` 먼저
- `eng-review verdict=FAIL` — contract/plan 재작성
- `단위 테스트 누락` — plan 매핑 후 추가
- `AI 테스트 게이트 미통과` — 실패 테스트 수정 후 `/qa-test --ai` 재실행
- `시크릿 의심 노출` — STOP, `/cso` 점검
- `BLOCK [<doc_type>] ...` — schema 검증 위반 (ADR-0010). 위반 항목 정정 후 `bash .claude/scripts/validate-doc.sh <path>` 재실행
- `yq 미설치` — schema 스크립트 동작 불가 → `brew install yq` / `apt install yq` (RUNBOOK §4)

### planning만
- `게이트 X 미통과` — 외부 결재 후 진행
- `결정 발생 + ADR 누락` — `docs/planning/adr/NNNN-*.md` 작성
- `정식 산출 덮어쓰기 차단 — <path> v1.x` — `--force-regenerate` 또는 ADR (Idempotency)
- `분량 권고 초과 — <path> N장` — 폴더 분할 후 재실행

### sprint만
- `Blocked-by 미해소 #N` — 선수 이슈 대기 또는 우선순위 조정
- `tested 라벨 부재` — 본인 빌드+재현 후 `gh pr edit <N> --add-label tested`
- `gh-cli 미설정` — `gh auth login`
- `이슈 템플릿 필드 누락 — <필드명>` — Acceptance Criteria / Contract Before·After / Estimated Effort / DoD Checklist 중 누락 항목 채운 후 재진입 (ADR-0008)

> 더 많은 케이스는 [COMMANDS_REFERENCE.md 부록 B](COMMANDS_REFERENCE.md) 참조

---

## 8. 파생 이슈(Derived) 운영 (이슈 작업 중 새 작업 발견)

policies/github-issue.md §5 / ADR-0008 정합. 발견 지점에 따라 처리 다름. **부모-자식 결합 폐기** — 모든 신규 이슈는 독립.

### 8.1 발견 지점

| 발견 | 처리 |
|---|---|
| AI 검증 (P9 코드리뷰 / P10 QA / P7 Risk) | 보고서 "## 발견 사항" 절 → 3축 OX 체크박스 모두 통과만 파생 이슈 후보 |
| 휴먼 PR 검토 | **PR 변경 요청 기본** (`gh pr review --request-changes`) → 같은 PR 추가 커밋 → 머지 |
| 휴먼 PR 검토 (예외) | scope 완전 밖일 때만 `/start-feature`로 A. Derived 등록 |
| 자가 발견 (구현 중) | 3축 OX 충족 시 `/flow-feature` 직접 호출 (독립 이슈, `--parent` 없음) |

### 8.2 3축 OX 체크박스

파생 이슈 등록 제안은 3축이 모두 ✅일 때만 허용:

```
[ ] in_scope == False           — 부모 acceptance/contract Before·After에 명시 X
[ ] blocks_parent_merge == False — 본 작업 없이 부모 PR 머지 가능
[ ] same_area == False           — 부모와 다른 파일·모듈·영역
```

| 결과 | 처리 |
|---|---|
| 3개 모두 ✅ | A. Derived 신설 (`/flow-feature "..."`) |
| Q2 ❌ | B. Blocker (`Blocked-by: #N` 본문) |
| Q1·Q3만 ❌ (Q2 ✅) | 같은 PR 보정 (이슈 신설 금지) |
| 무관한 결함 | C. Bug (`/flow-feature --mode=bug`) |

> [분량] 축은 폐기 — WBS 단계 이슈 템플릿 4필드(Acceptance / Contract / Effort / DoD)로 사전 보장. 판정 로직 상세는 policies/github-issue.md §5.3 참조.

### 8.3 3가지 패턴

| 패턴 | 정의 | 컨벤션 | Command |
|---|---|---|---|
| **A. Derived (파생)** | 부모와 관련은 있으나 완전 독립 | (별도 이슈, 부모 추적 링크 없음) | `/flow-feature "..."` |
| **B. Blocker** | 선행 필요 | `Blocked-by: #N` | `/flow-feature` |
| **C. Bug** | 무관한 별개 결함 | `type:bug` | `/flow-feature --mode=bug` |

> **부모-자식 추적 링크 없음** — `Parent`/`Children`/`sub-of:#N` 라벨 모두 폐기. 추적 필요 시 본문 코멘트에 자유 서술(예: "PR #42 리뷰 중 발견").

---

## 9. 자주 묻는 질문

| 질문 | 답 |
|---|---|
| /flow-feature·/flow-new-project 없이 바로 코드 작성? | Harness가 차단 (change-contract 부재 BLOCKED) |
| 백엔드 이슈도 /ux-flow-design 필수? | 아니요. UI 영향 시만 |
| 작은 오타 수정도 contract 필요? | 1줄 typo는 chore로 면제. 사용자 노출 텍스트는 contract 필요 |
| ADR은 언제 필수? | 외부 의존성 변경 / breaking change / 아키텍처 결정 / Workaround만 적용 bug-fix |
| 무인 야간 자동 진행? | 미지원 (docs/planning/open-items.md O-01 보류). 수동 재개 절차 |
| /flow-new-project 재호출 시 기존 산출은? | DRAFT 마커 있으면 묻기(`[k]eep / [r]egen / [m]erge`), 정식 v1.0+은 BLOCKED. 일괄 옵션 `--keep-existing` / `--force-regenerate` |
| flow-state.yaml 손상되면? | `/context-loader` 재실행 — docs/planning/INDEX.md + GitHub + git status로 재구성 |

---

## 10. 운영 팁

- **Generator ≠ Evaluator** — `/implement` 후 `/code-review`는 가능하면 새 컨텍스트 또는 reviewer 에이전트로
- **gstack 병행** — `/review`·`/qa`·`/cso`·`/investigate`는 본 하네스 검증 단계에서 함께 활용
- **docs/planning/CHANGELOG.md §"Current Status" 갱신을 잊지 말 것** — `/docs-update`가 수행, 사용자가 마지막 확인
- **시크릿 출력 절대 금지** — CLAUDE.md 보안 룰 1순위
- **모호하면 BLOCKED** — 추측 진행이 더 큰 비용

---

## 11. 새 세션 시작 프롬프트

```
나는 agent-toolkit 프로젝트 작업을 이어서 진행하려 한다.
프로젝트 루트의 docs/planning/INDEX.md, CLAUDE.md, .claude/USAGE_GUIDE.md를 읽고,
/context-loader 를 실행해서 현재 위치를 파악해줘.
그 다음 권고된 Command를 실행해서 작업을 이어가자.
```

---

## 12. 더 자세한 사용법

| 목적 | 문서 |
|---|---|
| Command 17종 항목별 상세 (입출력·BLOCKED·다음 Command) | [COMMANDS_REFERENCE.md](COMMANDS_REFERENCE.md) |
| 결정 근거·검토 대안 | [docs/planning/adr/](../docs/planning/adr/) — ADR-0001~0010 |
| 산출 schema 정본 + 28종 일람 | [docs/planning/conventions/document-manifest.md](../docs/planning/conventions/document-manifest.md) (ADR-0010) |
| 분할 순번·INDEX.md | [docs/planning/conventions/file-numbering.md](../docs/planning/conventions/file-numbering.md) |
| 폴더링 6단계 | [docs/planning/conventions/foldering-rules.md](../docs/planning/conventions/foldering-rules.md) |
| 세션 시작·재개·종료 RUNBOOK | [docs/planning/operations/runbook.md](../docs/planning/operations/runbook.md) |
| 운영 모델 (스프린트·이슈·D-06·Projects v2) | [docs/planning/policies/github-issue.md](../docs/planning/policies/github-issue.md) |
| 진행 흐름·게이트·Resumability·Tech Direction | [docs/planning/policies/flow-and-gates.md](../docs/planning/policies/flow-and-gates.md) |
| 산출 카탈로그·자동화 매트릭스 | [docs/planning/conventions/deliverables.md](../docs/planning/conventions/deliverables.md) |
| harness 강제 룰 (BLOCKED 14항목) | [.claude/harness/feature-development-harness.md](harness/feature-development-harness.md) |

---

## 변경 이력

| Version | Date | Change |
|---|---|---|
| 0.9.0 | 2026-05-07 | **schema-level 산출 강제 + Projects v2 + Learning 격리 + 신규 명세 4종** (ADR-0009·0010). (1) §0에 schema 강제 1줄, §6.1 Projects v2 매핑, §6.2 schema 작성 흐름(scaffold→작성→validate) 신설. (2) §7 BLOCKED에 schema 위반·yq 미설치 추가. (3) §3.3 흐름 + §4.2 Phase 표에서 Learning Note 제거(ADR-0009). (4) §12 링크 표에 conventions/operations 4개 문서 추가. |
| 0.8.3 | 2026-05-06 | **§8 Sub-issue 운영 → 파생 이슈(Derived) 운영으로 전환** (ADR-0008, supersedes ADR-0002). (1) §7 BLOCKED 케이스에서 `부모 close 차단 — Children #N 미완` / `깊이 ≤ 2 강제` 두 행 삭제, `이슈 템플릿 필드 누락 — <필드명>` 신규 추가. (2) §8 4축 AND 기준(`[범위]`/`[분량≥30분]`/`[의존성]`/`[영역]`) → **3축 OX 체크박스**(`in_scope=False` / `blocks_parent_merge=False` / `same_area=False`)로 재작성, AI·사람 모두 즉시 가독. (3) §8 4가지 패턴(A. Sub-task / B. Spin-off / C. Blocker / D. Bug) → **3가지 패턴**(A. Derived / B. Blocker / C. Bug). (4) `--parent=#N` 자가 발견 호출 → `/flow-feature` 직접 호출(독립 이슈)로 변경. (5) 부모-자식 추적 링크 폐기 명시(`Parent`/`Children`/`sub-of:#N` 라벨 모두 폐기). [분량] 게이트는 WBS 단계 이슈 템플릿 4필드(Acceptance / Contract / Effort / DoD)로 사전 보장. 결정 변경 = ADR-0002 supersede. |
| 0.8.2 | 2026-05-04 | **사람이 읽기 쉽게 재구성**. 480 → ~330줄. 정보 보존, 구조·압축만 변경. (1) 라이프사이클 5단계 표를 메인에 단순화 — 기존 큰 §2.0 표를 §2 단일 표로 통합. (2) 단계별 가이드(§3)에 자동 일괄 작성 흐름 다이어그램 명시. (3) Sub-issue 운영(§8) 별도 절로 분리 — 발견 지점·4축 기준·4가지 패턴을 한곳에. (4) D-06 게이트(§5) 박스 다이어그램으로 시각화. (5) BLOCKED·FAQ·운영 팁을 하단 레퍼런스로 모음. (6) 외부 문서 링크 표(§12) 신설 — PLAN 분리 파일·ADR·harness 한눈에. 결정 변경 없음. |
| 0.8.1 | 2026-05-04 | 산출 4건 신설(12·13·14·15) + RFP→4종 자동화 + Idempotency (ADR-0003·0004, PLAN v0.7.1 동기화) |
| 0.8.0 | 2026-04-30 | Step 1 Command 통합 — Meta 5→2(`/flow-feature`) + Sub 3종 모드 흡수. Command 23→17 |
| 0.7.x | 2026-04-30 | Sub-issue 운영 §2.6 신설·보강 (4축 기준·휴먼 PR 재작업 기본) |
| 0.6 | 2026-04-29 | §2 라이프사이클 5단계 신설 |
| 0.5 | 2026-04-30 | Sprint Rollover 반영 |
| 0.4 | 2026-04-29 | NEW_PROJECT 신규 Command(`/srs`·`/prd`·`/wbs`) |
| 0.3 | 2026-04-29 | D-06 2단 게이트 |
| 0.2 | 2026-04-29 | mode=planning/sprint 도입 |
| 0.1 | 2026-04-29 | 초안 |
