---
description: One-shot toolkit installation into a newProject. Use this when starting from a fresh toolkit clone and want to set up the toolkit + auto-detect RFP in a target folder. Calls scripts/install.sh and prints next-step commands (cd + /flow-init). Run from toolkit root, not from newProject.
allowed-tools: Bash, Read, Glob
---

# /install-toolkit

## 목적

툴킷을 **newProject 폴더에 1번에 도입**. 수동 7~10단계(rsync·템플릿 채움·git init·...)를 명령어 1번으로 압축. 호출 후 사용자에게 *다음 명령어 2개*(cd + `/flow-init`)를 출력.

> **ADR-0017**: Claude Code 세션이 *작업 디렉토리에 묶임*이라 툴킷 → newProject 자동 점프 불가. 사용자가 cd 1회는 필연이지만 그 외 모든 셋업 자동.

## 사용 시점

- **툴킷 clone 직후**: `git clone <agent-toolkit> ~/agent-toolkit`
- newProject 폴더 준비 (비어 있어도 OK)
- (권장) RFP를 newProject 안에 미리 둠 — 아래 §RFP 표준 위치 참조
- **호출 위치는 툴킷 디렉토리** (`cd ~/agent-toolkit && claude` 후 호출)

## §RFP 표준 위치 (자동 감지 우선순위)

본 메타는 다음 순서로 RFP를 자동 탐색. 첫 발견된 파일을 끝 안내에 사용.

| 우선순위 | 위치 | 권장 시나리오 |
|---|---|---|
| **표준** | `<target-dir>/RFP.md` | 단일 RFP, 가장 권장 |
| 대체 1 | `<target-dir>/<name>.rfp.md` | 명시적 접미 (예: `client-x.rfp.md`) |
| 대체 2 | `<target-dir>/RFP/*.md` | 여러 RFP 폴더 |

명시 우회: `--rfp=<path>` 옵션으로 자동 탐색 건너뜀.

> **양식 자유** — 토킷이 RFP 형식 강제 안 함. 외부 문서(고객 요청서·사내 기획안)를 *그대로* 두어도 `/flow-init`이 흡수.

## 호출 예시

```
/install-toolkit ~/my-project
/install-toolkit ~/my-project --rfp=~/my-project/RFP.md --commit
/install-toolkit /c/work/realworld-c2 --force
/install-toolkit ~/test-project --dry-run
```

## 인자

| 인자 | 필수 | 의미 |
|---|---|---|
| `<target-dir>` | 필수 | newProject 절대 경로. 없는 폴더면 자동 mkdir |
| `--rfp=<path>` | 선택 | RFP 파일 경로 명시. 미지정 시 target-dir에서 자동 탐색 (RFP.md → *.rfp.md → RFP/*.md) |
| `--commit` | 선택 | git init + 첫 커밋 자동 생성 |
| `--force` | 선택 | 기존 `.claude/` 덮어쓰기 허용. 없으면 충돌 시 BLOCKED |
| `--dry-run` | 선택 | 실제 카피 없이 시뮬레이션 출력 |

## 자동 진행 5단계

```
1. 툴킷 자산 rsync                                    .claude/·docs/install/·scripts/
2. CLAUDE.md + LOCAL.md 템플릿 적용                   placeholder {{PROJECT_NAME}}·{{INIT_DATE}}·{{INIT_AUTHOR}} 자동 치환 (ADR-0040)
3. .gitignore 카피/append                             기존 있으면 툴킷 섹션 추가
4. git init                                           이미 있으면 skip
5. RFP 자동 감지                                      RFP.md → *.rfp.md → RFP/*.md 순
```

(`--commit` 시 추가: 첫 커밋)

## 산출

- `<target>/.claude/` (commands·schemas·scripts·USAGE_GUIDE 등)
- `<target>/docs/install/` (도입 가이드·템플릿)
- `<target>/scripts/` (sprint-bootstrap.sh·install.sh 등)
- `<target>/CLAUDE.md` (template 기반)
- `<target>/LOCAL.md` (template 기반 빈 골격 — Phase 2 `/flow-design` 단계에서 12-scaffolding §7과 함께 채움, ADR-0040)
- `<target>/.gitignore` (툴킷 섹션 포함)
- (옵션) `<target>/.git/` + 첫 커밋

## 출력 (사용자가 따라 실행)

```
✅ 툴킷 도입 완료

다음 단계 (수동):
  cd "<target-dir>"
  claude
  /flow-init "$(cat RFP.md)"           ← RFP 감지된 경우
  또는
  /flow-init "<자연어 의도>"             ← RFP 없을 때

참고:
  - QUICK-START.md  : 4 Phase 흐름 1분 안내
  - docs/planning/INDEX.md : 1수준 산출 일람 + 용어집
  - LOCAL.md : 로컬 부팅 가이드 빈 골격 — Phase 2 12-scaffolding §7 작성 시점에 함께 채움 (ADR-0040)
```

## 실행 단계 (Claude Code 진입점)

본 메타는 다음 셸 호출을 그대로 진행:

```bash
bash scripts/install.sh <target-dir> [옵션 전달]
```

스크립트 출력을 사용자에게 그대로 표시 + 마지막에 "**다음 명령어를 새 세션에서 실행하세요**" 안내 강조.

## BLOCKED 케이스

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: target-dir 미지정` | 인자 누락 | `/install-toolkit <경로>` 형식으로 |
| `BLOCKED: 기존 .claude/ 발견 (--force 없음)` | 충돌 방지 | 의도적이면 `--force` 추가 |
| `BLOCKED: rsync/git 미설치` | 환경 의존 | `apt install rsync` 등 |
| `BLOCKED: 툴킷 루트가 아닌 곳에서 호출` | install.sh가 `.claude/` 못 찾음 | 툴킷 디렉토리에서 호출 |

## Strict Rules

- **본 메타는 툴킷 디렉토리에서만 호출** — `.claude/` 부재 시 BLOCKED
- **`--dry-run`으로 미리 시뮬레이션 권장** (특히 `--force` 사용 시)
- **셋업 후 직접 cd 필요** — Claude Code 세션 제약 (OS)
- **`docs/install/manual-sync-guide.md` 비교** — 본 메타 실패 시 수동 도입 fallback

## Artifact Binding

- 입력: 툴킷 자체 자산 + 사용자 지정 target-dir
- 출력: → newProject의 `/flow-init` 호출 환경 (CLAUDE.md·.claude/·docs/install/·scripts/ 갖춰진 상태)

## 트리거 매칭

- "툴킷 설치", "프로젝트에 도입", "/install-toolkit", "newProject 시작"
- 자연어: "툴킷 설치해줘", "<폴더>에 세팅", "이 폴더에 에이전트 깔아"

## 셸 단독 사용 (Claude Code 없이)

Claude Code 없이 동일 효과:

```bash
bash ~/agent-toolkit/scripts/install.sh ~/my-project --commit
```

CI 자동화·다른 IDE 사용자도 동일하게 사용 가능 (ADR-0017 §2.5).
