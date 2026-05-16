---
name: devtoolkit
version: 1.1.0
description: >
  DevToolKit - Claude Code 자율개발환경 개발 킷.
  gstack 기반 + 하네스 엔지니어링 패턴을 통합한 자율 개발 도구.
  사용 가능한 스킬: /init, /scaffold, /orchestrate, /sprint, /task-sync,
  issue-spinoff, test-plan, scenario-derive, issue-claim, issue-unblock, issue-pick.
---

# DevToolKit

gstack 위에 자율 파이프라인 오케스트레이션을 추가하는 개발 킷.

## 스킬 목록 (11종)

### 부트스트랩·실행 (5종, v1.0)
- `/init` - 프로젝트 초기화 + 기술 스택 설정
- `/scaffold` - 기술 스택별 프로젝트 골격 코드 생성
- `/orchestrate` - 전체 Phase(1→7) 자율 실행
- `/sprint` - Sprint Contract 생성 + 태스크 분해
- `/task-sync` - 태스크 상태 일관성 검증 + 누락 검출

### 이슈·검증 자동화 (6종, v1.1 — ADR-0022)
- [`issue-spinoff`](issue-spinoff/SKILL.md) — AI 검증 보고서 → 파생 이슈 자동 등록 (`derived` 라벨 + Origin 블록)
- [`test-plan`](test-plan/SKILL.md) — 이슈 DoD + 상류 시나리오 → PR Test Plan 4블록 자동 생성
- [`scenario-derive`](scenario-derive/SKILL.md) — 04 SRS / 05 PRD 시나리오 → 이슈 DoD 자동 인용
- [`issue-claim`](issue-claim/SKILL.md) — 이슈 작업 진입 시 `Blocked-by:` 자동 검사 + `status:blocked` 부착
- [`issue-unblock`](issue-unblock/SKILL.md) — 선수 close 시 의존 이슈 일괄 해제 (사용자 명시 호출, `/issue-sync` Command와 별개)
- [`issue-pick`](issue-pick/SKILL.md) — 다음 작업 가능한 이슈 자동 선정 (블록 제외, 우선순위 정렬)
