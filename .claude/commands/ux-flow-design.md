---
description: Use this when the user is about to design a screen or interaction, asks for a wireframe or user flow, needs to map states/transitions, or is about to write code that has UI surface area.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /ux-flow-design

## 목적
사용자 흐름·화면 상태·전환을 **그림 + 텍스트**로 명세. 프론트엔드 구현 직전 단계.

> **Schema 강제 (ADR-0010)**: NEW_PROJECT 게이트 B는 `doc_type=user-scenarios`(03), 게이트 C 와이어프레임은 `doc_type=screen-design`(07), FEATURE는 `doc_type=feature-ux`. 각 산출은 `scaffold-doc.sh <doc_type> <output>` → 작성 → `validate-doc.sh`. UC-NN/S-NN subsection 강제. schema: `.claude/schemas/{user-scenarios,screen-design,feature-ux}.schema.yaml`.

## 사용 시점
- `/intention-brief` 통과 후 UI가 있는 기능
- `/flow-design-change` Phase 2
- 모달·복합 폼·실시간 업데이트 등 상태가 많은 UI

## 입력
- `docs/features/<slug>/<slug>.brief.md` (필수)
- (있으면) 기존 화면 자산 / 디자인 시스템

## 산출물
- `docs/features/<slug>/<slug>.ux.md`
  - 사용자 흐름도 (mermaid)
  - 화면별 상태 머신 (entry / loading / success / error / empty)
  - wireframe (텍스트 또는 ASCII 또는 외부 링크)
  - 데이터·이벤트 의존성

## 문서 구조

```
## 1. 사용자 흐름 (mermaid flowchart)
## 2. 화면 인벤토리 (이름·경로·진입점)
## 3. 화면별 상태
   - {{화면}}: idle → loading → success | error | empty
## 4. wireframe
## 5. 입력/출력 데이터
## 6. 외부 의존성 (API, 이벤트, 라우팅)
## 7. a11y 요건 (color contrast, keyboard, screen reader)
## 8. 회귀 영향 화면 (modify 시 필수)
```

## 실행 단계
1. brief의 Success criteria → 화면 단위 분해
2. 각 화면의 상태(state) 나열
3. mermaid 흐름도 작성
4. wireframe 텍스트화 (필요 시 도구 호출)
5. 데이터·API 연결점 식별

## 완료 조건
- 모든 화면이 5종 상태(idle/loading/success/error/empty) 명시
- 흐름도 mermaid 검증 통과
- a11y 요건 1+ 항목 명시
- `/ui-design-review`로 넘기기 가능한 상태

## Artifact Binding
- 입력: brief
- 출력: → `/ui-design-review`, `/implementation-planner`, `/qa-test`
