---
description: Use this when the user has finished writing code, asks for an independent review (default mode), needs to verify the implementation matches the contract, or is about to open a PR. Use --refactor mode for an optional quality pass focused on reuse/duplication/simplification before merge. This consolidates the previous /refactor-review into --refactor mode.
allowed-tools: Read, Edit, Glob, Grep, Bash
---

# /code-review

## 목적
**Generator≠Evaluator 원칙의 핵심**. `/implement` 결과를 contract / plan / acceptance와 대조하여 머지 가능 여부 판정.

> **Schema 강제 (ADR-0010)**: `doc_type=feature-code-review`. `scaffold-doc.sh feature-code-review docs/features/<slug>/<slug>.code-review.md` → 작성 → `validate-doc.sh`. Verdict(PASS/NEEDS-WORK/FAIL)·reviewer·3축 OX 표 BLOCK. schema: `.claude/schemas/feature-code-review.schema.yaml`.

> **2026-04-30 통합** — 기존 `/refactor-review`를 `--refactor` 모드로 흡수. 기본 모드는 PASS/FAIL/NEEDS-WORK 판정이고, `--refactor` 모드는 머지 전 선택적 품질 패스(재사용·중복·단순화).

## 모드 (2종)

| 모드 | 호출 | 목적 | 산출 |
|---|---|---|---|
| **기본** (default) | `/code-review` | 머지 가능 여부 판정 (PASS/FAIL/NEEDS-WORK) | `<slug>.code-review.md` (필수 점검) |
| **refactor** | `/code-review --refactor` | 선택적 품질 패스 (재사용·중복·단순화) | `<slug>.refactor-notes.md` (선택 정리만) |

> 기본 모드는 D-06 1단의 일부로 필수. `--refactor`는 머지 직전 시간 여유 있을 때 선택. gstack `simplify` 스킬과 보완.

## 사용 시점
- `/implement` 직후, PR 생성 전
- `/flow-bug-fix` Phase 6 (재현 시나리오 검증 포함)
- gstack `/review` 스킬과 보완적으로 사용

## 입력
- 변경된 코드 (`git diff main...HEAD`)
- `<slug>.contract.md`
- `<slug>.plan.md`
- `<slug>.acceptance.md`

## 산출물
- `docs/features/<slug>/<slug>.code-review.md`
  - PASS / FAIL / NEEDS-WORK
  - 항목별 코멘트 (파일:라인)
  - 후속 액션
  - **`## 발견 사항 (Found Issues) — 파생 이슈 후보`** 절 (policies/github-issue.md §5 / ADR-0008 — 3축 OX 체크박스 모두 통과 후보만)
  - **`## 같은 PR 보정 필요`** 절 (3축 OX 미통과 후보, 현 PR에서 추가 커밋으로 처리)

## 점검 항목

```
[ ] contract의 Before/After가 코드에 반영됨
[ ] plan의 Subtask가 모두 커밋됨 (누락 없음)
[ ] 단위 테스트가 plan에 매핑된 항목 모두 cover
[ ] acceptance Functional 항목이 코드에 검증 가능
[ ] 보안 룰 위반 (secret, 입력 검증, OWASP)
[ ] 코딩 컨벤션 (docs/design/code-conventions.md)
[ ] 의도하지 않은 변경 (scope creep)
[ ] 죽은 코드 / TODO / 디버그 print
[ ] 의존성 변경의 정당성
[ ] 에러 처리·로깅 일관성
```

## 실행 단계
1. 입력 4종 모두 읽기
2. `git diff` 분석
3. 체크리스트 적용 (특히 scope creep 체크)
4. 위반 → 파일:라인 + 권장 수정
5. 판정 (PASS만 PR 생성 허가)
6. **발견 사항 등록 제안 (policies/github-issue.md §5 / ADR-0008)** — 검토 중 인식된 신규 작업 후보를 3축 OX 체크박스로 분류:

   ```
   각 후보별로:
   - [ ] in_scope == False           Q1. 부모 acceptance/contract Before·After에 명시 X (No → 체크)
   - [ ] blocks_parent_merge == False Q2. 본 작업 없이 부모 PR 머지 가능 (Yes → 체크)
   - [ ] same_area == False           Q3. 부모와 다른 파일·모듈·영역 (Yes → 체크)
   ```

   > [분량] 축은 폐기 — WBS 단계 이슈 템플릿 4필드(Acceptance / Contract / Effort / DoD)로 사전 보장. 판정 로직 상세는 policies/github-issue.md §5.3 표 참조.

   **3개 모두 ✅ → "## 발견 사항 (Found Issues) — 파생 이슈 후보"**: A. Derived 분류 + 권장 Command (`/flow-feature "..."`, `--parent` 없음) + 3축 OX 결과 + 근거(파일:라인) 포함. **Origin 5필드 자동 첨부 (ADR-0021 §2.4)** — Discovered-in=현재 PR/이슈, Discovered-by=`/code-review`, Discovered-at=KST 현재 시각, Pattern=A.Derived, 3-axis OX 결과. 사용자 승인 시 [`issue-spinoff`](../skills/devtoolkit/issue-spinoff/SKILL.md) Skill이 호출되어 `derived` 라벨 + Origin 본문 자동 생성 (ADR-0022).

   **Q2 ❌ → C/B 패턴 Blocker 별도 이슈** 후보로 별도 표시 (`Blocked-by: #N` 본문 부착 권장)

   **Q1·Q3만 ❌ (Q2 ✅) → "## 같은 PR 보정 필요"**: 현 PR에서 추가 커밋으로 처리. 별도 이슈 등록 안 함.

   **무관한 결함 → C. Bug** (`/flow-feature --mode=bug "..."`)

   자동 등록은 사용자 승인 후 `issue-spinoff` 스킬이 처리. 모든 파생 이슈는 독립 — 부모 추적 링크 없음.

## 완료 조건
- 판정 명시
- FAIL 0개
- NEEDS-WORK는 PR 본문에 코멘트로 남기되 pre-merge에서 해소

## Strict Rules
- **Generator(=`/implement` 수행자)와 동일 컨텍스트 금지** — 가능하면 별도 에이전트(reviewer)로 수행
- **자기 작성 코드 PASS 자동 부여 금지**
- **시크릿 발견 시 즉시 STOP** + 사용자 보고 (CLAUDE.md 보안 룰)

## Artifact Binding
- 입력: 코드, contract, plan, acceptance
- 출력: → `/qa-test`, PR 생성

---

## `--refactor` 모드 상세

머지 전 **선택적 품질 패스**. 동작은 정상이지만 (1) 재사용 기회 (2) 중복 제거 (3) 단순화를 점검.

### 사용 시점
- 기본 `/code-review` PASS 후
- 머지 직전 + 시간 여유 있을 때 (선택)
- 큰 이슈를 작업한 후

### 입력
- 변경된 코드
- 인접 코드 (Grep으로 유사 패턴 탐색)

### 산출물
- `docs/features/<slug>/<slug>.refactor-notes.md` (있으면)
- 코드 변경 (작은 정리만)

### 점검 항목
```
[ ] 신규 함수가 기존 유틸의 재구현 아님
[ ] 3+ 회 반복되는 로직이 추출되었는가 (3-strikes 원칙은 신중)
[ ] 명명이 의도를 드러내는가 (함수명 = 동사+명사)
[ ] 불필요한 추상화는 없는가 (premature abstraction 회피)
[ ] 죽은 코드 / 미사용 import / TODO 흔적
[ ] 테스트 또한 단순한가 (over-mocked 회피)
```

### 실행 단계
1. 변경 영역 + 인접 코드 그루핑
2. 위 체크리스트 적용
3. 명백한 개선만 적용 (큰 리팩토링은 별도 이슈로)
4. 변경 시: contract 갱신 필요 여부 판정 → 필요 시 BLOCKED

### 완료 조건
- 식별된 개선 적용 완료 또는 별도 이슈로 백로그 등록
- 단위 테스트 100% 유지

### Strict Rules
- **scope creep 금지** — 본 모드는 작은 정리에만 (큰 리팩토링은 `/flow-feature --mode=modify` 별도 진입)
- **3 line이 premature abstraction을 정당화하지 않는다** — 의심스러우면 보류
- **"works but feels off" → 일단 머지 후 별도 이슈** 권장 (D-06 게이트가 자연 정지점)
