---
description: Use this when the user is about to ship a screen and needs a visual quality check on a single screen (default mode), OR when the user needs a system-wide design consistency check across multiple screens after a token/system change (use --consistency). The default mode reviews one screen deeply. The --consistency mode compares many screens. This consolidates the previous /design-consistency-review into --consistency mode.
allowed-tools: Read, Write, Glob, Grep, Bash
---

# /ui-design-review

## 목적
시각적 결과물의 **품질·일관성·구현 정확도**를 점검. UX 단계의 `/ux-flow-design` 와 짝이며, 코드 머지 전 게이트.

> **Schema 강제 (ADR-0010)**: `doc_type=feature-ui-review`. `scaffold-doc.sh feature-ui-review docs/features/<slug>/<slug>.ui-review.md` → 작성 → `validate-doc.sh`. Verdict·mode(default/--consistency)·화면별 목적 부합/상태 표출 BLOCK. schema: `.claude/schemas/feature-ui-review.schema.yaml`.

> **2026-04-30 통합** — 기존 `/design-consistency-review`를 `--consistency` 모드로 흡수. 단일 화면 깊은 검토는 기본 모드, 시스템 단위 일관성 점검은 `--consistency` 모드.

## 모드 (2종)

| 모드 | 호출 | 목적 | 산출 |
|---|---|---|---|
| **기본** (default) | `/ui-design-review` | **한 화면 깊이** 검토 (wireframe 대비, token 사용, 5종 상태, 반응형, a11y) | `docs/features/<slug>/<slug>.ui-review.md` |
| **consistency** | `/ui-design-review --consistency` | **여러 화면 비교** (system-wide, 디자인 시스템 / token 변경 후) | `docs/planning/design-consistency-<date>.md` (매트릭스, 시스템 차원 산출 — feature-bound 아님) |

> `flow-feature --mode=design`은 두 모드를 모두 사용 — 구현 전 기본 모드, 구현 후 `--consistency` 모드 재실행.

## 사용 시점
- 화면 구현 완료 직후, PR 생성 직전
- `/flow-design-change` Phase 3
- 디자인 시스템 변경 후 첫 화면 적용 시

## 입력
- `docs/features/<slug>/<slug>.ux.md` (대조용)
- 구현된 화면 (스크린샷 또는 dev 서버)
- (있으면) 디자인 시스템 / token 정의

## 산출물
- `docs/features/<slug>/<slug>.ui-review.md`
  - PASS / FAIL / NEEDS-WORK 판정
  - 항목별 코멘트 (위치 + 권장 수정)
  - before/after 스크린샷 (변경 시)

## 점검 항목 (체크리스트)

```
[ ] wireframe 대비 시각적 일치
[ ] 디자인 시스템 token 사용 (하드코딩 금지)
[ ] 5종 상태(idle/loading/success/error/empty) 모두 구현
[ ] 반응형 (mobile / tablet / desktop)
[ ] 색대비 4.5:1 이상 (텍스트)
[ ] 키보드 포커스 visible
[ ] 한국어 텍스트 잘림/줄바꿈
[ ] 다크모드 (시스템에 있을 때)
[ ] 애니메이션 60fps / prefers-reduced-motion 존중
```

## 실행 단계
1. dev 서버 기동 또는 스크린샷 수집 (gstack `/browse` 활용)
2. 위 체크리스트 항목별 검증
3. 위반 항목 → 위치(파일:라인) + 권장 수정
4. PASS / FAIL / NEEDS-WORK 판정
5. NEEDS-WORK 이상이면 `/implement` 재진입 권고

## 완료 조건
- 모든 항목 검증 완료
- 판정 명시
- FAIL 항목 0개 (PASS 조건)

## Strict Rules
- **하드코딩된 색·폰트·spacing 발견 시 자동 FAIL**
- **wireframe과 구조 다르면 FAIL**

---

## `--consistency` 모드 상세

**전체 화면 단위**의 일관성 점검. 기본 모드가 한 화면을 깊게 본다면, `--consistency` 모드는 여러 화면을 비교한다.

### 사용 시점
- 디자인 시스템 / token 변경 후
- `/flow-feature --mode=design` 흐름 (P12 ui-review 후 + 구현 후 재실행)
- `/flow-feature --mode=add`에서 신규 컴포넌트가 기존 패턴과 다를 때

### 입력
- 변경된 token / 컴포넌트 리스트
- 영향 화면 인벤토리 (없으면 자동 추출)

### 산출물
- `docs/planning/design-consistency-<date>.md`
  - 화면별 PASS/FAIL 매트릭스
  - 시각 회귀 스크린샷 차이
  - 권장 수정 리스트

### 점검 항목 (System-wide)
```
[ ] 모든 화면이 동일 spacing scale 사용
[ ] 버튼 variant 일관성 (primary/secondary/ghost)
[ ] form 입력 패턴 일관성 (label, error, helper text)
[ ] empty/error state 톤·일러스트 일관
[ ] 아이콘 라이브러리 단일
[ ] 한·영 타이포 위계 일관
[ ] 페이지 transition / loading skeleton 패턴 일치
```

### 실행 단계
1. 영향 화면 인벤토리 (token 변경 시 grep으로 추출)
2. 각 화면 스크린샷 (before / after)
3. 매트릭스 작성 (화면 × 항목)
4. FAIL 항목 → 권장 수정
5. 종합 판정 (PASS / FAIL)

### 완료 조건
- 매트릭스 작성 완료
- FAIL 0개 또는 의도된 변경만 존재
- 시각 회귀 모두 설명됨

### Strict Rules
- **단일 PR로 일괄 변경** 원칙 준수 검증 — 부분 적용 발견 시 FAIL
