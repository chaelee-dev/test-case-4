---
name: orchestrate
version: 3.0.0
description: >
  통합 자율 개발 파이프라인. 사용자 요구사항 입력 후 gstack 스킬과 하네스 엔지니어링으로
  분석→설계→계획→스캐폴딩→개발→빌드→테스트→검수→배포→운영 자동 진행.
  배포/운영만 사용자 승인, 나머지 자동.
  Use when: "orchestrate", "자율 실행", "전체 파이프라인", "자동 개발", "개발 시작".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Agent
  - WebFetch
  - WebSearch
  - AskUserQuestion
---

# /orchestrate — 통합 자율 개발

사용자 요구사항(PRD 또는 프롬프트) 입력 후 개발 완료까지 자동 진행.
배포/운영만 사용자 승인, 나머지는 자동.

## Phase 1: 분석 — /office-hours (gstack 필수)
1. PRD 읽기
2. /office-hours 실행 (Builder 모드)
3. docs/analysis/ 에 requirements.md, domain-model.md, user-stories.md, risk-assessment.md 생성
4. **자동으로 Phase 2 진행**

## Phase 2: 설계 — /autoplan + /plan-eng-review (gstack 필수)
1. docs/analysis/* 읽기
2. /autoplan 실행 (또는 /plan-ceo-review → /plan-design-review → /plan-eng-review)
3. /plan-eng-review 통과 필수
4. UI/UX 요구사항 있으면 /design-consultation 실행
5. docs/design/ 에 architecture.md, api-spec.md, database-schema.md, code-conventions.md, code-definitions.md, directory-structure.md 생성
6. **자동으로 Phase 3 진행**

## Phase 3: 계획 — 태스크 FSM 생성
1. docs/design/* 읽기
2. Sprint Contract 작성: docs/plan/sprint-contracts/SPRINT-001.yaml
3. 태스크 분해: docs/plan/tasks/TASK-DEV-NNN.yaml (status=CREATED, history 기록)
4. **자동으로 Phase 3.5 진행**

## Phase 3.5: 스캐폴딩
1. 기술 스택 결정: PRD + docs/design/architecture.md 우선, 없으면 devtoolkit.config.yaml 기본값 사용
2. 빌드 파일 + 프로젝트 골격 생성
3. 빌드 성공 확인
4. **자동으로 Phase 4 진행**

## Phase 4: 개발 — /careful + /freeze (gstack 필수)
태스크 의존성 순서대로:
1. 태스크 YAML 읽기, status: CREATED → PENDING → IN_PROGRESS (YAML 편집 + history)
2. 설계 문서 참고하여 코드 + 단위 테스트 구현
3. /careful 상시, 디버깅 시 /investigate
4. status: IN_PROGRESS → IN_REVIEW (YAML 편집 + history)
5. **자동으로 Phase 4.5 진행**

## Phase 4.5: 빌드 + 실행 (모든 단계 필수)
1. 백엔드 빌드: `cd backend && ./gradlew build` — BUILD SUCCESSFUL 확인
2. 프론트엔드 빌드: `cd frontend && npm install && npm run build` — 성공 확인
3. 빌드 실패 시 /investigate → 수정 → 재빌드 (성공까지)
4. **백엔드 서버 실행**: `cd backend && ./gradlew bootRun &` — Started 로그까지 대기
5. **프론트엔드 서버 실행**: `cd frontend && npx vite --port 5173 --host &` — **반드시 실행**
6. `curl http://localhost:8080/api/todos` — 백엔드 API 응답 확인
7. `curl http://localhost:5173` — **프론트엔드 접속 확인**
8. **두 서버 모두 실행 중인 상태에서** Phase 5 진행
> /qa는 localhost:5173에서 Playwright 브라우저 테스트. 프론트엔드 서버 미실행 시 /qa 불가.

## Phase 5: 검수 — /review + /qa + /cso (gstack 필수)
서버 실행 중 수행:
1. /review 실행 (코드 리뷰)
2. /qa 실행 (브라우저 QA, 서버 필수)
3. /cso 실행 (보안 점검 8/10+ 게이트)
4. Sprint Contract acceptance_criteria 검증
5. 각 태스크: APPROVED → DONE / REJECTED → IN_PROGRESS (재작업)
6. 3회 연속 REJECTED → 사용자에게 에스컬레이션
7. 모든 태스크 DONE 후 서버 종료
8. **자동으로 Phase 6 진행**

## Phase 6: 배포 — /ship + /land-and-deploy (gstack 필수) — 사용자 승인 필요
1. **사용자에게 배포 승인 요청** (AskUserQuestion)
2. 승인 시: /ship → /land-and-deploy → /canary → /document-release
3. 거부 시: 중단

## Phase 7: 운영/회고 — /retro (gstack 필수) — 사용자 승인 필요
1. **사용자에게 운영 확인 요청** (AskUserQuestion)
2. /retro 실행
3. /task-sync로 최종 정합성 확인
4. 모든 태스크 DONE 확인 후 완료 보고

## 하네스 엔지니어링 규칙
- Generator(Developer)가 작성한 코드를 Generator가 승인하지 않는다
- Evaluator(Reviewer)가 독립적으로 /review + /qa + /cso 실행
- Sprint Contract 인수 기준으로 검수
