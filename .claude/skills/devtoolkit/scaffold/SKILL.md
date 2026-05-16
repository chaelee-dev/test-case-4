---
name: scaffold
version: 1.0.0
description: >
  기술 스택별 프로젝트 골격 코드 생성.
  devtoolkit.config.yaml 기반으로 디렉토리, 설정 파일, 공통 모듈 생성.
  Use when asked to "scaffold", "스캐폴딩", "프로젝트 골격 생성",
  or "기본 코드 생성".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

# /scaffold - 프로젝트 스캐폴딩

## 프로세스

1. **devtoolkit.config.yaml 읽기**: 기술 스택 확인

2. **docs/design/directory-structure.md 읽기**: 설계된 디렉토리 구조 확인

3. **프론트엔드 스캐폴딩** (해당 시):
   - 프로젝트 초기화 (vite, next 등)
   - TypeScript 설정
   - ESLint + Prettier 설정
   - 디렉토리 구조 생성 (api, components, features, hooks, pages, stores, types, utils)
   - 공통 컴포넌트 기본 파일
   - API 클라이언트 설정
   - 글로벌 스타일 설정

4. **백엔드 스캐폴딩** (해당 시):
   - 프로젝트 초기화 (Spring Initializr, npm init 등)
   - 디렉토리 구조 생성 (global/config, global/common/code, global/common/dto, global/common/exception, global/error, domain/)
   - 공통 코드 생성:
     - ApiResponse DTO (docs/design/code-definitions.md 기반)
     - 상태/오류 코드 Enum
     - GlobalExceptionHandler
     - 기본 설정 클래스 (CORS, Security 등)
   - application.yml (dev, prod 프로파일)
   - DB 마이그레이션 초기 파일

5. **인프라 스캐폴딩** (해당 시):
   - Dockerfile (frontend, backend)
   - docker-compose.yml
   - GitHub Actions CI/CD 워크플로우

6. **테스트 구조 생성**:
   - 단위 테스트 디렉토리
   - 통합 테스트 디렉토리
   - E2E 테스트 디렉토리

## 완료 조건
- devtoolkit.config.yaml의 tech_stack과 일치하는 프로젝트 구조
- 공통 코드 (ApiResponse, 오류 코드 등) 생성 완료
- 빌드/실행 가능한 상태 (빈 프로젝트)
