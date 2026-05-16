---
description: Use this when the user is about to declare a feature done, asks for testable success conditions, needs to write Definition of Done for a GitHub issue, or is about to push code without explicit acceptance gates.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /acceptance-criteria

## 목적
"완료"를 **검증 가능한 항목 리스트**로 못 박기. 이슈 DoD가 되며 PR Test Plan(D-06)으로 자동 변환된다.

> **Schema 강제 (ADR-0010)**: `doc_type=feature-acceptance`. `scaffold-doc.sh feature-acceptance docs/features/<slug>/<slug>.acceptance.md` → 작성 → `validate-doc.sh`. AC-NN subsection·Given/When/Then·DoD 6항(단위 테스트/AI 게이트/Test Plan 4블록/tested 라벨/Approve/CI green) BLOCK. schema: `.claude/schemas/feature-acceptance.schema.yaml`.

## 사용 시점
- 모든 Flow의 "구현 직전 / 직후" 단계
- GitHub Issue 본문 DoD 작성
- PR 본문 Test Plan 4블록 생성 직전

## 입력
- `<slug>.contract.md`
- `<slug>.plan.md`
- (있으면) `<slug>.ux.md`

## 산출물
- `docs/features/<slug>/<slug>.acceptance.md`
- (자동) GitHub Issue 본문에 DoD 체크리스트 코멘트
- (자동) PR Test Plan 4블록의 시드

## 문서 구조

```markdown
# Acceptance Criteria — <slug>

## 1. Functional
- [ ] 사용자가 X를 입력하면 Y가 표시된다
- [ ] 빈 입력 시 에러 메시지 "..." 노출
- [ ] 1000+ 항목에서도 응답 < 200ms

## 2. UX
- [ ] 5종 상태(idle/loading/success/error/empty) 모두 구현
- [ ] 모바일/데스크탑 반응형
- [ ] a11y: keyboard navigation, screen reader label

## 3. 회귀 (Modify/Bug-fix 시 필수)
- [ ] 기존 시나리오 A 정상
- [ ] 기존 시나리오 B 정상

## 4. Test Plan 4블록 시드 (D-06 변환용)
### Build
- [ ] `npm run build` 성공
### Automated tests
- [ ] `npm test` 통과 (신규 테스트 포함)
### Manual verification
- [ ] (위 Functional·UX의 사람이 검증할 항목)
### DoD coverage
- [ ] 본 acceptance의 모든 항목이 PR diff에 매핑됨
```

## 실행 단계
1. contract / plan / ux 읽기
2. 각 변경 항목 → "테스트 가능한 문장"으로 변환
3. Functional / UX / 회귀 분류
4. 4블록 Test Plan 시드 작성
5. (선택) `gh issue comment <N> -b "$(cat ...)"` 자동화

## 완료 조건
- 항목 모두 측정 가능 (애매한 형용사 없음)
- 회귀 항목 ≥ 1개 (modify/bug-fix 시)
- 4블록 시드 모두 작성

## Strict Rules
- **이 문서 없이 PR 생성 금지** (D-06 게이트 전제)
- 항목이 "잘 동작한다"식이면 INVALID — 구체화 필수

## Artifact Binding
- 입력: contract, plan, ux
- 출력: → `/qa-test`, GitHub Issue DoD, PR Test Plan
