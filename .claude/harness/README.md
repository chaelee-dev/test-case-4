# Harness 시스템 — README

> **위치**: `.claude/harness/`
> **본 디렉토리**: 흐름 통제 정의 (Phase 결정 트리)
> **본 README**: 인덱스·운영 가이드

---

## 1. Harness란

**일관된 작업 흐름을 강제하는 결정 트리**. Claude Code의 자유도 높은 자율성을 *목표 일관성·검증 가능성·재개 가능성*에 맞춰 통제한다.

docs/planning/INDEX.md (D-06 PR 게이트 + §5.6 수동 재개)와 CLAUDE.md (FSM·보안·Generator≠Evaluator)를 코드 수준에서 강제하는 레이어.

---

## 2. 디렉토리 구성

```
.claude/harness/
├── README.md                          # 본 문서
└── feature-development-harness.md     # 메인 결정 트리
```

향후 추가 가능 (변경 시 본 README 갱신):

- `incident-response-harness.md` — 프로덕션 사고 대응 전용
- `release-harness.md` — 릴리즈·배포 전용

---

## 3. 사용 방법

### 자동 진입 (권장)

다음 발화 시 자동 적용:

```
"기능 만들자", "구현해줘", "설계부터", "전체 흐름으로", "하네스로 진행"
```

또는 다음 Command를 명시 호출:

```
/start-feature <자연어 의도>
/flow-feature-add #<이슈 번호>
/flow-bug-fix #<이슈 번호>
```

### 수동 단계 호출

각 Phase의 Command를 직접 호출 가능. 단, **블로킹 조건 위반 시 자동 BLOCKED**.

```
/context-loader
/intention-brief "..."
/change-contract
/implementation-planner
/plan-eng-review
/implement
/code-review
/qa-test
/docs-update
```

---

## 4. State 파일

런타임 상태는 `.claude/state/flow-state.yaml`에 영속화. 자세한 schema는 `feature-development-harness.md` Section 1 참조.

- `.gitignore`에 추가 권장 (개인 작업 컨텍스트)
- 팀 공유 진실은 `docs/planning/CHANGELOG.md §"Current Status" 현재 진행 상황`이 정본

---

## 5. 다른 시스템과의 관계

| 시스템 | 관계 |
|---|---|
| `docs/planning/INDEX.md` | 단일 진실의 원천 — 본 하네스는 PLAN의 게이트·FSM·D-06을 코드화 |
| `CLAUDE.md` | 보안·FSM·Generator≠Evaluator 룰 — 본 하네스가 Phase별로 강제 |
| `.claude/agents/` (v5 계승) | 본 하네스의 **Evaluator** 역할이 reviewer 에이전트로 위임됨 |
| `.claude/skills/gstack/` | `/review`, `/qa`, `/cso`, `/investigate` 등을 본 하네스가 적절한 Phase에서 호출 |
| `.claude/skills/devtoolkit/` | `/scaffold`, `/sprint`, `/task-sync`는 policies/sprint-cycle.md §1 자동화와 보완 |
| GitHub (D-02 SoT) | FSM ↔ Label 매핑(policies/github-issue.md §3)을 하네스가 자동 갱신 |

---

## 6. 변경 절차

본 하네스는 **개발 진행의 룰북**이다. 변경 시:

1. `/change-contract` 작성 (메타!)
2. ADR 작성 — `docs/planning/adr/NNNN-harness-change-*.md`
3. 팀 합의 (policies/flow-and-gates.md §2 게이트 B에 준함)
4. docs/planning/CHANGELOG.md §"Current Status", §12에 반영
5. 본 README 인덱스 갱신

---

## 7. 한계 (알려진)

- **무인 자동 재개 미지원** — O-01 결정 보류 (docs/planning/open-items.md)
- **PR 머지 이후 자동화 없음** — D-06 게이트는 사람 책임
- **여러 이슈 동시 작업 미지원** — flow-state.yaml은 single-issue 전제
- **외부 시스템 변경 미반영** — Claude 구독 정책·gh-cli 버전 변경 시 본 하네스 검증 필요

---

## 8. 빠른 참조

```
새 세션 → /context-loader
모호한 의도 → /start-feature
새 프로젝트 → /flow-new-project
기능 추가 → /flow-feature-add
기능 변경 → /flow-feature-modify
버그 → /flow-bug-fix
디자인 → /flow-design-change
```
