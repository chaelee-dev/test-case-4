---
name: sprint
version: 1.0.0
description: >
  Sprint Contract 생성 + 태스크 분해. 설계 산출물을 기반으로
  인수 기준이 포함된 Sprint Contract를 생성하고, 실행 가능한
  태스크로 분해한다.
  Use when asked to "sprint", "스프린트 계획", "태스크 분해",
  "Sprint Contract", or "작업 분배".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - AskUserQuestion
---

# /sprint - Sprint Contract + 태스크 분해

## 프로세스

### 1. 설계 산출물 읽기
- docs/design/architecture.md
- docs/design/api-spec.md
- docs/design/database-schema.md
- docs/design/code-conventions.md
- docs/design/code-definitions.md
- docs/design/directory-structure.md

### 2. Sprint Contract 생성

Sprint 단위로 deliverables + acceptance_criteria + verification 방법을 정의.

```yaml
# docs/plan/sprint-contracts/SPRINT-{NNN}.yaml
sprint_contract:
  sprint_id: "SPRINT-001"
  title: ""
  deliverables: []
  acceptance_criteria:
    - id: "AC-001"
      description: ""
      verification: ""  # 단위 테스트 | 통합 테스트 | /qa | /cso
  quality_criteria:
    # 프론트엔드
    design_quality: 0    # 0-10
    originality: 0
    craft: 0
    # 백엔드
    correctness: 0       # 0-10
    security: 0
    maintainability: 0
```

### 3. 태스크 분해

각 Sprint Contract → 실행 가능한 태스크로 분해.

```yaml
# docs/plan/tasks/TASK-{PHASE}-{NNN}.yaml
task:
  id: "TASK-DEV-001"
  title: ""
  phase: "DEV"
  status: "CREATED"
  priority: "MEDIUM"
  assignee: ""
  dependencies: []
  blocked_by: []
  description: ""
  acceptance_criteria: []
  deliverables: []
  sprint_contract_ref: "SPRINT-001"
  files_owned: []
  branch: ""
  estimated_complexity: ""  # S | M | L | XL
  created_at: ""
  started_at: ""
  completed_at: ""
  updated_at: ""
  review:
    reviewer: ""
    result: ""
    comments: []
    reviewed_at: ""
  history: []
```

### 4. 의존성 그래프 구성
- 태스크 간 선후행 관계 정의
- 병렬 실행 가능 태스크 식별
- 크리티컬 패스 도출

### 5. 에이전트/팀원 할당
- 태스크별 담당 에이전트 지정
- 파일 소유권 할당 (충돌 방지)
- 브랜치 전략: feature/TASK-{ID}-{summary}

### 6. 산출물
- docs/plan/sprint-contracts/SPRINT-{NNN}.yaml
- docs/plan/tasks/TASK-{PHASE}-{NNN}.yaml
- docs/plan/task-list.md (전체 태스크 요약)
- docs/plan/dependency-graph.md (의존성 그래프)
