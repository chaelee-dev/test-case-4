---
description: Use this when the user is about to land a non-trivial change, asks "what could go wrong", needs to evaluate blast radius before merge, or is about to ship something that touches shared infrastructure.
allowed-tools: Read, Write, Glob, Grep, Bash
---

# /risk-check

## 목적
변경 전 **부정적 시나리오·블라스트 반경·완화책**을 점검. `15-risk/15-risk.md` (1수준 산출 15, ADR-0031로 재할당)에 누적된다.

> **Schema 강제 (ADR-0010)**: mode=planning은 `doc_type=risk`(1수준 15), mode=sprint(FEATURE)는 `doc_type=feature-risk`. 각각 `scaffold-doc.sh <doc_type> <output>` → 작성 → `validate-doc.sh`. RISK-NN subsection·카테고리 enum·완화 전략 BLOCK. schema: `.claude/schemas/{risk,feature-risk}.schema.yaml`.

## 사용 시점
- `change-contract` 직후, `/implement` 직전
- `/flow-feature-modify`·`/flow-design-change` Phase 4 (필수)
- 외부 의존(Claude 구독, GitHub API, gh-cli) 변경 시

## 입력
- `<slug>.contract.md`
- (있으면) policies/flow-and-gates.md §3 (기획서 리스크 표)

## 산출물
- `docs/features/<slug>/<slug>.risk.md`
  - 식별된 위험·완화책·잔존 리스크·Rollback trigger
  - **`## 발견 사항 (Found Issues) — 파생 이슈 후보`** 절 (policies/github-issue.md §5 / ADR-0008 — 3축 OX 체크박스 모두 통과 후보만)
  - **`## 같은 PR 보정 필요`** 절 (3축 OX 미통과 후보 — 같은 PR 추가 커밋으로 처리)
- (변경 누적) `docs/planning/15-risk/15-risk.md`

## 위험 카테고리

| 카테고리 | 예시 |
|---|---|
| 회귀 | 기존 동작 손상 |
| 성능 | 지연·메모리·DB 부하 |
| 보안 | secret 노출, 권한 우회 (CLAUDE.md 규칙) |
| 비용 | Claude 토큰·API 호출량 폭주 |
| 의존성 | Claude 구독·GitHub API rate limit·gh-cli 버전 |
| 데이터 | 마이그레이션·영속성 |
| 운영 | 모니터링·알림 사각지대 |

## 문서 구조

```markdown
# Risk Check — <slug>

## 1. 식별된 위험
| ID | 카테고리 | 시나리오 | 영향(L/M/H) | 가능성(L/M/H) | 등급 |
|---|---|---|---|---|---|
| R-1 | 회귀 | ... | M | H | High |

## 2. 완화책
| Risk ID | 완화 | 검증 방법 |

## 3. 잔존 리스크
- 사용자 명시 승인이 필요한 항목

## 4. Rollback trigger
- 어떤 신호가 보이면 즉시 rollback?
```

## 실행 단계
1. contract 읽기 + 영향 범위 파악
2. 7개 카테고리 각각 1줄 체크
3. 등급(High/Med/Low) 판정
4. High 리스크 → 완화책 필수
5. policies/flow-and-gates.md §3과 충돌 검사 → 해당 행 갱신 권고
6. **발견 사항 분류 (policies/github-issue.md §5 / ADR-0008)** — 리스크 점검 중 인식된 후속 작업 후보를 3축 OX 체크박스로 분류:

   ```
   각 후보별로:
   - [ ] in_scope == False           Q1. 부모 acceptance/contract 미명시 (No → 체크)
   - [ ] blocks_parent_merge == False Q2. 본 작업 없이 부모 PR 머지 가능 (Yes → 체크)
   - [ ] same_area == False           Q3. 부모와 다른 파일·모듈·영역 (Yes → 체크)
   ```

   > [분량] 축은 폐기 — WBS 단계 이슈 템플릿 4필드로 사전 보장. 판정 로직 상세는 policies/github-issue.md §5.3 표 참조.

   - **3개 모두 ✅ → "## 발견 사항 — 파생 이슈 후보"**: 잔존 리스크 완화 후속 이슈, 모니터링·알림 신설, 데이터 마이그레이션 분리 등을 A. Derived로 분류 + 권장 Command (`/flow-feature "..."`) + 3축 OX 결과 + 근거(리스크 ID 매핑). **Origin 5필드 자동 첨부 (ADR-0021 §2.4)** — Discovered-by=`/risk-check`. 사용자 승인 시 [`issue-spinoff`](../skills/devtoolkit/issue-spinoff/SKILL.md) Skill이 호출되어 `derived` 라벨 + Origin 본문 자동 생성 (ADR-0022).
   - **Q2 ❌ → B. Blocker** 별도 이슈 (`Blocked-by: #N`)
   - **Q1·Q3만 ❌ (Q2 ✅) → "## 같은 PR 보정 필요"**: 현 PR에서 mitigation으로 직접 처리
   - **무관한 결함 → C. Bug** (`/flow-feature --mode=bug "..."`)

   `issue-spinoff` 스킬이 사용자 승인 후 자동 등록. 모든 파생 이슈는 독립 — 부모 추적 링크 없음.

## 완료 조건
- 모든 카테고리 점검 완료
- High 리스크 모두 완화책 존재
- 잔존 리스크 명시 (있으면 승인 요청)

## Strict Rules
- **secret 노출 가능성 발견 시 즉시 STOP** (CLAUDE.md 보안 룰)
- High 리스크 + 완화책 부재 시 진행 거부
