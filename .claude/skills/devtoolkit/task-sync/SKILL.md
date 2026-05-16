---
name: task-sync
version: 1.0.0
description: >
  태스크 상태 일관성 검증 + 누락 검출. 모든 태스크 YAML 파일을
  스캔하여 상태 불일치, 누락된 업데이트, 의존성 오류를 검출한다.
  Use when asked to "task-sync", "태스크 동기화", "상태 확인",
  "누락 검출", or "태스크 정합성 검사".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

# /task-sync - 태스크 상태 일관성 검증

## 검증 항목

### 1. 상태 일관성
- IN_PROGRESS인데 started_at이 비어있는 태스크
- DONE인데 completed_at이 비어있는 태스크
- DONE인데 review.result가 APPROVED가 아닌 태스크
- IN_REVIEW인데 reviewer가 비어있는 태스크
- history에 상태 전이 기록이 없는 태스크

### 2. 의존성 정합성
- dependencies의 태스크가 실제 존재하는지
- DONE인 태스크에 의존하는 BLOCKED 태스크 → PENDING으로 전환
- 순환 의존성 검출

### 3. 파일 소유권
- 동일 파일을 여러 태스크가 소유하는 경우 경고
- files_owned의 파일이 실제 존재하는지 (개발 후)

### 4. Sprint Contract 연결
- sprint_contract_ref가 비어있는 DEV 태스크
- Sprint Contract의 acceptance_criteria가 태스크에 반영되었는지

### 5. 완료율 리포트
- Phase별 완료율 (DONE / 전체)
- 전체 진행률
- BLOCKED 태스크 목록 + 차단 사유
- REJECTED 태스크 목록 + 재작업 필요 사항

## 실행

```bash
# docs/plan/tasks/ 디렉토리의 모든 YAML 파일 스캔
find docs/plan/tasks/ -name "*.yaml" -type f
```

## 산출물
- 콘솔 리포트 (상태 불일치, 누락, 경고 목록)
- 자동 수정 가능한 항목은 수정 (의존성 해제 등)
- 수동 개입 필요 항목은 목록으로 제시
