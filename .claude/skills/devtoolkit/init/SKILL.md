---
name: init
version: 1.0.0
description: >
  DevToolKit 프로젝트 초기화. devtoolkit.config.yaml 생성,
  기술 스택 선택, .claude/ 디렉토리 구성.
  Use when asked to "init", "initialize project", "프로젝트 초기화",
  or "새 프로젝트 시작".
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---

# /init - 프로젝트 초기화

## 프로세스

1. **기술 스택 확인**: devtoolkit.config.yaml이 있으면 읽기, 없으면 사용자에게 질문
   - 프로젝트 이름/설명
   - 프로젝트 타입 (fullstack | frontend | backend | library)
   - 프론트엔드 프레임워크 (기본: React 19 + TypeScript)
   - 백엔드 프레임워크 (기본: Java 21 + Spring Boot 3.4)
   - 데이터베이스 (기본: PostgreSQL)
   - 협업 모드 (solo | collaborative)

2. **devtoolkit.config.yaml 생성/업데이트**

3. **디렉토리 구조 확인**:
   - .claude/agents/ (에이전트 정의 파일 존재 확인)
   - .claude/skills/devtoolkit/ (DevToolKit 스킬 존재 확인)
   - .claude/skills/gstack/ (gstack 설치 확인)
   - docs/ (analysis, design, plan, review, deploy 서브디렉토리)

4. **CLAUDE.md 확인**: gstack 섹션 + DevToolKit 규칙 포함 여부

5. **.claude/settings.json 확인**: 권한, 훅, teammateMode, 환경변수

6. **gstack 설정 확인**:
   ```bash
   gstack-config set telemetry off
   gstack-config set repo_mode solo  # 또는 collaborative
   ```

7. **Git 초기화** (필요 시):
   ```bash
   git init
   git remote add origin <github-url>
   ```

8. **.gitignore 생성/업데이트**:
   - .claude/settings.local.json
   - node_modules/
   - .env
   - build/
   - dist/

## 완료 조건
- devtoolkit.config.yaml 존재
- .claude/ 디렉토리 구조 완성
- CLAUDE.md에 gstack 섹션 포함
- gstack 스킬 동작 확인
