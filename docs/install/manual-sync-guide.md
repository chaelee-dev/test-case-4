# agent-toolkit 도입 가이드 — 수동 동기화 방식

> 🚀 **처음이세요?** 도입 절차에 들어가기 전 [`../../QUICK-START.md`](../../QUICK-START.md)부터 — 툴킷이 무엇을 하고 사용자 컨펌이 언제 일어나는지 5분 안내.
>
> ⚡ **단순 도입이라면 자동화 권장 (ADR-0017)**: `/install-toolkit <target-dir>` 또는 셸로 `bash scripts/install.sh <target-dir>` 한 번이면 끝. 본 가이드는 *수동 양방향 카피·디버깅·고급 사용*을 위한 fallback.
>
> **대상**: agent-toolkit을 자기 프로젝트(이하 *newProject*)에 도입해 빌드·테스트하면서 동시에 툴킷 자체도 디벨롭하려는 개발자
> **방식**: 수동 양방향 카피 (junction/submodule 미사용). 일회성 도입은 자동화 권장.
> **기본 환경**: Linux/macOS 또는 Windows + WSL2. 명령어는 bash/rsync 기준. Windows 네이티브 PowerShell 사용자는 §8 참조
> **버전**: v0.4 (2026-05-07)

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| 0.7 | 2026-05-16 | yongtae.cho@bespinglobal.com | carry-over 자산 2종 추가 (ADR-0017 v1.2 + ADR-0040). §0 폴더 구성 표에 `docs/install/scripts/check-local-md-sync.sh`·`docs/install/ci.yml.template` 행 추가, §6 카피 범위 표에 newProject `scripts/check-local-md-sync.sh`·`docs/install/ci.yml.template`(staged) 행 추가. install.sh가 check-local-md-sync.sh를 newProject `scripts/`로 명시 카피(+x), ci.yml.template는 docs/install/ 통째 rsync로 staged 카피. test-case-3 d0834f9가 newProject 자체로 만든 자산을 일반화해 흡수. |
| 0.6 | 2026-05-16 | yongtae.cho@bespinglobal.com | §6 카피 범위 표 갱신 (ADR-0041 — `./devkit` wrapper 폐기) — `devtoolkit.config.yaml` 행은 유지하되 `commands` 블록 폐기 명시(빌드·실행 정본은 12-scaffolding §5 / LOCAL.md §3 양축). `scripts/devkit.template` 행 제거(파일 자체 삭제). |
| 0.5 | 2026-05-14 | chae.lee | §6 카피 범위 표에 `devtoolkit.config.yaml` 행 추가 — ADR-0027 fallback 2순위 정합. install.sh가 newProject에 없을 때만 carry-over (기존 yaml 덮어쓰지 않음). |
| 0.4 | 2026-05-07 | chae.lee | (1) `docs/install/` 폴더 구성 명세(§0 신설) — `CLAUDE.template.md` 정본 경로를 표 첫 행에 박아 못 찾는 문제 해소. (2) `scripts/sprint-bootstrap.sh` 도입 절차 추가 — §3 사전 요구사항(`gh project` scope, bash 4.3+, bc), §4.2 단일 파일 카피, §4.6 환경 검증 신설, §5.1 fresh copy 갱신, §6 카피 범위 표 행 추가, §8 PowerShell fallback 갱신, §10 체크리스트 4행 추가 |
| 0.3 | 2026-05-06 | chae.lee | (1) `state/` 통째 제외로 카피 절차 단순화 — gitignore template의 whitelist 줄 제거, 머릿속 룰 1단계화. example 파일은 툴킷 clone에서 직접 열람. (2) 명령어 기본을 Linux/WSL bash+rsync로 전환, 경로 표기를 `/mnt/c/work/...`로 통일. Windows 네이티브 PowerShell은 §8 fallback으로 보존 |
| 0.2 | 2026-05-06 | chae.lee | `gitignore.template` 신설 + 첫 커밋 순서(§4.4.1) 명문화 (v0.3에서 state 처리 재단순화) |
| 0.1 | 2026-05-06 | chae.lee | 초안 — 수동 양방향 카피 방식 + CLAUDE.md 템플릿 도입 |

---

## 0. `docs/install/` 폴더 구성 — 도입에 필요한 모든 자산이 여기에

도입 절차에 필요한 자산은 본 폴더(`docs/install/`)에 모두 모여 있다. 툴킷 clone 후 절대 경로:

| 파일 | 용도 | 사용 시점 |
|---|---|---|
| **[`docs/install/manual-sync-guide.md`](manual-sync-guide.md)** | 본 가이드 (절차서) | 가장 먼저 읽기 |
| **[`docs/install/CLAUDE.template.md`](CLAUDE.template.md)** | newProject용 `CLAUDE.md` 템플릿 (placeholder 포함) | §4.3에서 newProject 루트로 카피·편집 |
| **[`docs/install/LOCAL.template.md`](LOCAL.template.md)** | newProject용 `LOCAL.md` 템플릿 — 로컬 부팅 사용자 가이드 정본 (ADR-0040) | §4.3에서 newProject 루트로 카피. 본문 채움은 Phase 2 `/flow-design` 시점(12-scaffolding §7과 동기) |
| **[`docs/install/gitignore.template`](gitignore.template)** | newProject용 `.gitignore`에 추가할 툴킷 필수 패턴 | §4.4에서 카피 또는 append |
| **[`docs/install/github-issue-guide.md`](github-issue-guide.md)** | 이슈/PR 제목·라벨·파생 이슈 사용자 가이드 (ADR-0021) | install.sh가 자동 carry-over. newProject 합류자가 일상적으로 참조 |
| **[`docs/install/scripts/check-local-md-sync.sh`](scripts/check-local-md-sync.sh)** | LOCAL.md 구조 + profile 3분기 env + lockfile + §4 부팅 자산 표 lint (ADR-0040 + ADR-0037 v1.1, stack-agnostic) | install.sh가 자동 카피 → newProject `scripts/check-local-md-sync.sh` (+x). CI에서 호출 |
| **[`docs/install/ci.yml.template`](ci.yml.template)** | GitHub Actions CI 워크플로 staged template — local-md-sync job 사전 제공 + test/boot-smoke job skeleton (ADR-0037 v1.1 3 profile matrix) | install.sh가 staged 상태로 자동 카피. 도입자가 명시적으로 `.github/workflows/ci.yml`로 이동 (`gh auth refresh -s workflow` 후 `git mv`) + boot-smoke 채움 |
| **[`../../.github/workflows/issue-pr-title-lint.yml`](../../.github/workflows/issue-pr-title-lint.yml)** | 이슈/PR 제목 정규식 검증 BLOCK (ADR-0021) | install.sh가 자동 carry-over → newProject `.github/workflows/`로 복제. 도입 즉시 제목 형식 강제 |
| **[`../../.github/ISSUE_TEMPLATE/`](../../.github/ISSUE_TEMPLATE/)** (feature·bug·derived 3종) | 이슈 생성 시 제목 placeholder + 본문 4필드 + Origin 블록 (ADR-0008·0021) | install.sh가 자동 carry-over (newProject에 ISSUE_TEMPLATE 없을 때만, 덮어쓰지 않음) |

> **CLAUDE.template.md 자주 못 찾는다는 보고가 있어 명시**: 위 표의 절대 경로(`docs/install/CLAUDE.template.md`)가 정본 위치. 본 파일은 newProject로 자동 카피되지 *않는다* — §4.3에서 사용자가 직접 `cp`해서 newProject 루트의 `CLAUDE.md`로 만든다 (rsync 대상이 `.claude/`와 `scripts/` 한정이라 본 파일은 의도적 제외).

> **sprint-bootstrap.sh도 함께 도입**된다 — `scripts/sprint-bootstrap.sh`는 newProject로 카피되며, 설정·검증 절차는 §4.6 참조.

---

## 1. 이 가이드는 무엇인가

agent-toolkit은 Claude Code 네이티브 묶음(`.claude/` + `CLAUDE.md`)이다 (PLAN D-07 / ADR-0005). 별도 런타임이 없으므로 "설치"는 곧 **파일 카피**다.

본 가이드는 다음 시나리오를 다룬다:

- newProject(기존 또는 신규)에 agent-toolkit을 도입해 자율 개발 흐름을 적용
- 사용 중 발견한 툴킷 개선점을 agent-toolkit repo로 환류 (dogfooding)
- 1인 작업과 팀 작업 모두에 적합한 단순한 카피 절차

자동 동기화(junction, submodule)는 **본 가이드의 범위 밖**이다 — 정식 release 전까지는 카피 방식이 가장 단순·안전하다고 판단했다. 추후 자동화는 §9 참조.

---

## 2. 동기화 모델 (한 줄 규칙)

> **agent-toolkit이 정본. newProject의 `.claude/`와 `CLAUDE.md`는 항상 throwaway 스냅샷.**

이 규칙만 지키면 드리프트가 안 생긴다.

```
[정본]                         [스냅샷]
agent-toolkit/  ──── copy ───▶  newProject/
   .claude/                       .claude/
   CLAUDE.template.md             CLAUDE.md  (템플릿 채워서 사용)
        ▲                              │
        │                              │
        └──── cherry-pick(개선점만) ────┘
```

- 항상 agent-toolkit → newProject 방향이 우선 (전체 카피로 덮어씀)
- 반대 방향은 **수동 cherry-pick** (전체 덮어쓰기 금지). diff 보고 툴킷 변경에 가치 있는 부분만 골라서 반영
- 양쪽이 둘 다 변경된 상태로 오래 두지 말 것 (한 사이클 = 길어야 1~2일)

---

## 3. 사전 요구사항

| 항목 | 비고 |
|---|---|
| **Claude Code** 설치 | https://claude.com/claude-code |
| **gh-cli** 설정 (`gh auth login`) | mode=sprint 단계에서 필수 (D-02) |
| **gh-cli `project` scope** | `gh auth refresh -s project` — sprint-bootstrap.sh의 Projects v2 item-add에 필요 (ADR-0009 단방향 sync) |
| **git** 설정 | newProject 루트에 `git init` 또는 기존 repo |
| **bash 4.3+ + rsync** | 기본 가정 (Linux/macOS 네이티브 또는 Windows + WSL2). bash 4.3+는 `local -n` 등 nameref 지원 — sprint-bootstrap.sh가 의존 |
| **`yq` (mikefarah/yq v4+)** | schema 검증 스크립트(scaffold-doc.sh / validate-doc.sh) + sprint-bootstrap.sh의 YAML 파싱에 의존. `brew install yq` / `apt install yq` (ADR-0010) |
| **`bc`** | sprint-bootstrap.sh의 API rate-limit sleep 계산에 사용 (대부분 OS에 기본 설치) |
| **agent-toolkit clone** | 권장 위치: `/mnt/c/work/agent-toolkit/` (WSL에서 Windows-side) 또는 `~/work/agent-toolkit/` (linux-side) |

> 본 가이드는 툴킷 위치를 `/mnt/c/work/agent-toolkit/`, newProject 위치를 `/mnt/c/work/newProject/`로 가정한다. 다른 경로면 명령에서 그에 맞춰 치환한다.

---

## 4. 최초 도입 (one-time setup)

### 4.1 newProject 폴더 준비

```bash
# 신규 프로젝트
mkdir -p /mnt/c/work/newProject
cd /mnt/c/work/newProject
git init

# 또는 기존 프로젝트면 cd만
cd /mnt/c/work/existingProject
```

### 4.2 `.claude/` + `scripts/sprint-bootstrap.sh` 카피 (정본 → newProject)

```bash
# (1) .claude/ 카피 (런타임 상태·아카이브·개인 설정 제외)
rsync -av \
  --exclude 'state/' \
  --exclude '_archive/' \
  --exclude 'settings.local.json' \
  /mnt/c/work/agent-toolkit/.claude/ ./.claude/

# (2) sprint-bootstrap.sh 카피 (newProject의 scripts/에 단일 파일)
mkdir -p ./scripts
cp /mnt/c/work/agent-toolkit/scripts/sprint-bootstrap.sh ./scripts/sprint-bootstrap.sh
chmod +x ./scripts/sprint-bootstrap.sh
```

> 툴킷 `scripts/`의 다른 스크립트(`setup.sh`, `check-env.sh`, `setup-playwright.sh`)는 툴킷 *자체* 개발용이므로 newProject로 가져오지 않는다.

**제외 대상 설명**:
- `state/` — 런타임 상태 디렉토리. newProject가 자체적으로 `/context-loader` 시점에 생성. 툴킷의 dogfooding 상태가 newProject로 새지 않도록 통째 제외
- `settings.local.json` — 사용자 개인 설정 (각자 다름)
- `_archive/` — 격리된 비활성 산출(예: Learning Layer, ADR-0009). 도입 팀에 불필요. 단 추후 디벨롭으로 재활성화 결정 시 툴킷 본체에서 복원하므로 전파 불필요

**필수 포함 폴더 (ADR-0010, schema 강제)**:
- `.claude/schemas/` — 산출 28종 schema 정본. 도입 팀의 `validate-doc.sh`/`scaffold-doc.sh`가 이 폴더를 참조. 누락 시 schema 검증 동작 불가
- `.claude/scripts/` — `scaffold-doc.sh`, `validate-doc.sh`, `check-line-count.sh`, `gen-index.sh` 4개 스크립트. 도입 팀에서 동일하게 동작해야 함

> 툴킷의 `flow-state.example.yaml`(스키마 reference)은 newProject로 가져오지 않는다. 사람이 스키마를 직접 보고 싶을 땐 툴킷 clone(`/mnt/c/work/agent-toolkit/.claude/state/flow-state.example.yaml`)을 직접 열면 된다.

> **`yq` 의존성 (mikefarah/yq v4+)**: schema 스크립트 실행 필수. 도입 팀이 `brew install yq` 또는 `apt install yq` 후 카피된 스크립트를 사용. 미설치 시 RUNBOOK §4 fallback 안내.

> rsync 경로에서 source 끝의 `/`(`/.claude/`)는 "내용물만 카피" 의미. `/.claude` (끝 `/` 없음)이면 `.claude` 폴더 자체가 dest 안에 중첩 생성되니 주의.

### 4.3 `CLAUDE.md` + `LOCAL.md` 템플릿 카피·편집

```bash
cp /mnt/c/work/agent-toolkit/docs/install/CLAUDE.template.md ./CLAUDE.md
cp /mnt/c/work/agent-toolkit/docs/install/LOCAL.template.md ./LOCAL.md
```

복사 후 `CLAUDE.md`·`LOCAL.md`를 열어 placeholder를 채운다:

| Placeholder | 위치 | 채울 값 예시 |
|---|---|---|
| `{{PROJECT_NAME}}` | CLAUDE.md + LOCAL.md | `newProject` 또는 실제 제품명 |
| `{{FRONTEND_STACK}}` | CLAUDE.md | `React 19 + TypeScript + Vite` (없으면 `(없음)`) |
| `{{BACKEND_STACK}}` | CLAUDE.md | `Java 21 + Spring Boot 3.4` (없으면 `(없음)`) |
| `{{INFRA}}` | CLAUDE.md | `(미정 — 게이트 C에서 확정)` |
| `{{INIT_DATE}}` | LOCAL.md 변경 이력 표 | `2026-05-15` 등 카피 시점 날짜 |
| `{{INIT_AUTHOR}}` | LOCAL.md 변경 이력 표 | 카피 작성자 이름 |

> 템플릿 맨 위 "Note" 블록은 newProject에 어울리도록 가볍게 정리하거나 그대로 두어도 무관 (참고 링크).
>
> **LOCAL.md 본문 채움 시점 (ADR-0040)**: 카피 직후는 빈 골격 상태. 본문(§1 사전 요구사항·§2 셋업·§3 profile별 부팅 명령·§4 자산 표)은 Phase 2 `/flow-design`에서 12-scaffolding §7 작성 시 함께 채움. 자동화 도입(`install.sh`)을 쓰면 placeholder 치환은 자동.

### 4.4 `.gitignore` 설정

툴킷이 제공하는 `gitignore.template`을 카피·append. 본 템플릿엔 보안 절대 규칙 + Claude Code 런타임 + gstack 심볼릭 링크 패턴이 포함된다 (수동 베끼기 누락 방지).

**Case A — newProject에 기존 `.gitignore`가 없을 때**:
```bash
cp /mnt/c/work/agent-toolkit/docs/install/gitignore.template ./.gitignore
```

**Case B — 기존 `.gitignore`가 있을 때 (append)**:
```bash
cat /mnt/c/work/agent-toolkit/docs/install/gitignore.template >> ./.gitignore
```

> 핵심 패턴: `.claude/state/` ignore + `.claude/settings.local.json` ignore + 보안 파일 + gstack 심볼릭 링크. `.claude/` 본체는 git에 포함시킨다 (팀원 간 공유). 언어 스택(Java/Node/Python)·IDE·OS 패턴은 newProject의 기술 스택 결정 후 별도로 추가.

### 4.4.1 첫 커밋 (`.claude/` 본체 + `.gitignore` 정렬)

`.gitignore`를 먼저 설정한 다음 `.claude/`를 커밋해야 의도치 않은 런타임 파일이 함께 커밋되지 않는다. 권장 순서:

```bash
git add .gitignore
git commit -m "chore: agent-toolkit 도입 — .gitignore 설정"

git add .claude/ CLAUDE.md scripts/sprint-bootstrap.sh
git commit -m "chore: agent-toolkit .claude/ + CLAUDE.md + sprint-bootstrap.sh 도입"
```

`git status`로 `.claude/state/`가 보이지 않는지 확인 (§4.2 rsync가 `--exclude 'state/'`로 카피에서 제외했으므로 폴더 자체가 없음. `/context-loader` 첫 호출 시 newProject가 자체 생성하며 `.gitignore`로 무시됨).

### 4.5 첫 검증

```bash
claude
```

진입 후:

```
> /context-loader
```

- 정상: 현재 위치(mode=planning) + 권고 Command 출력
- 비정상: §7 트러블슈팅 참조

이 시점에 newProject는 `docs/planning/`이 아직 없는 빈 상태일 것이다. 다음 단계는 보통:

```
> /flow-new-project "<RFP|PRD|자연어 한 줄>"
```

자세한 흐름은 `.claude/USAGE_GUIDE.md` 참조.

### 4.6 sprint-bootstrap 환경 검증 (mode=sprint 진입 전 1회)

`/flow-new-project` 후반(WBS 작성 직후)에 본 스크립트가 자동 호출된다. 그 전에 환경이 준비됐는지 1분 안에 확인:

```bash
# (1) 스크립트가 실행 가능한지 — --help가 떠야 정상
bash ./scripts/sprint-bootstrap.sh --help

# (2) gh CLI 인증 + project scope 확인
gh auth status
gh auth status 2>&1 | grep -q 'project' \
  && echo "project scope OK" \
  || gh auth refresh -s project   # Projects v2 item-add (ADR-0009)에 필요

# (3) 의존성 확인
yq --version | grep -E 'version (v)?4\.'   # mikefarah/yq v4.x
bash --version | head -1                    # 4.3+
which bc                                     # api_sleep 계산 (없으면 0.1초로 fallback)
```

**자동 호출 흐름** (참고, `/flow-new-project` 내부):

```
12. /wbs                       → docs/planning/13-wbs/13-wbs.md (§7 YAML 자동 채움)
13~15. (자동) git commit + push + gh pr create
16. (자동) bash scripts/sprint-bootstrap.sh --dry-run
   ▶ 사용자: 실 실행 승인 (5번째 컨펌)
17. (자동, 승인 후) bash scripts/sprint-bootstrap.sh
                               → GitHub Milestones + Issues + Labels(19종) + Projects v2 items
```

**Sprint N→N+1 rollover 시 (이후 사이클)**:

```bash
# /retro + /wbs --update 후, 사용자가 직접 호출
bash ./scripts/sprint-bootstrap.sh --sprint=N+1 --dry-run    # 미리보기 (강추)
bash ./scripts/sprint-bootstrap.sh --sprint=N+1              # 실 등록
```

> 본 스크립트가 만드는 라벨 19종(FSM 5 + priority 4 + type 5 + area 5)은 **이슈 단위 git/lifecycle 정책**(implement.md / qa-test.md / policies/github-issue.md §3)의 전제다. 라벨 누락 시 `gh issue create --label`이 실패하므로 첫 1회 실행이 필수.

---

## 5. 개발 사이클

### 5.1 작업 시작 — 정본 → newProject fresh copy

매 작업 세션 시작 시 툴킷 정본의 최신 변경을 가져온다:

```bash
cd /mnt/c/work/agent-toolkit
git pull           # 툴킷 최신화

cd /mnt/c/work/newProject
# .claude/
rsync -av \
  --exclude 'state/' \
  --exclude '_archive/' \
  --exclude 'settings.local.json' \
  /mnt/c/work/agent-toolkit/.claude/ ./.claude/

# scripts/sprint-bootstrap.sh (단일 파일 갱신)
cp /mnt/c/work/agent-toolkit/scripts/sprint-bootstrap.sh ./scripts/sprint-bootstrap.sh
chmod +x ./scripts/sprint-bootstrap.sh
```

**주의**: 이 카피는 newProject의 `.claude/` 안에 사용자가 임시로 넣은 변경을 덮어씀. 5.3 환류 절차로 미리 툴킷에 반영했는지 확인.

> rsync에 `--delete`는 의도적으로 넣지 않았다 — newProject 측에서 임시로 추가한 파일이 silent 삭제되는 사고 방지. 툴킷에서 **삭제된** 파일을 newProject에서도 정리하려면 `--delete`를 추가하되 dry-run(`-n`)으로 먼저 확인.

### 5.2 newProject에서 작업 (정상 흐름)

평소대로 Claude Code에서 명령어 실행. `.claude/` 변경은 가능하면 피하고, *코드/문서*만 변경.

### 5.3 툴킷 개선점 발견 시 — cherry-pick 환류

newProject에서 작업 중 툴킷 자체의 결함·개선점을 발견했다면:

**A. 권장: 툴킷에서 직접 수정 (clean)**

1. 작업을 잠시 멈추고 `/mnt/c/work/agent-toolkit/`에서 해당 파일을 직접 수정
2. 툴킷 측에서 commit (`feat: ...` / `fix: ...`)
3. newProject로 돌아와 5.1 fresh copy 재실행
4. Claude Code 세션 재시작 (변경 반영 위해)

**B. 빠른 hot-fix: newProject에서 수정 후 환류 (faster, 드리프트 위험)**

1. newProject의 `.claude/` 안에서 수정해 즉시 검증
2. 검증 끝나면 diff 확인:
   ```bash
   # newProject → toolkit 방향 dry-run
   rsync -avn \
     --exclude 'state/' \
     --exclude '_archive/' \
     --exclude 'settings.local.json' \
     ./.claude/ /mnt/c/work/agent-toolkit/.claude/
   ```
   `-n`은 dry-run — 무엇이 카피될지만 보여준다. 실제 적용 시 `-n` 제거.
3. 가치 있는 변경만 골라 툴킷에 반영. **전체 덮어쓰기 절대 금지** (newProject 고유 변경이 툴킷에 섞일 수 있음).
   - 권장: 각 파일을 개별로 직접 편집 (`cp`, 또는 `code` 등 에디터로)
   - 또는 `meld`, `kdiff3`, `vimdiff`로 양방향 비교 후 선택적 카피
4. 툴킷 측에서 `git diff .claude/`로 변경 확인 → commit
5. 다음 세션 시작 시 5.1 절차로 정렬

### 5.4 다음 세션 / 종료

세션 종료 시점에 newProject `.claude/`에 미환류 변경이 남아 있는지 확인:

```bash
# 양방향 diff (dry-run, newProject → toolkit)
rsync -avn \
  --exclude 'state/' \
  --exclude '_archive/' \
  --exclude 'settings.local.json' \
  /mnt/c/work/newProject/.claude/ /mnt/c/work/agent-toolkit/.claude/
```

미환류 변경이 있으면 5.3 절차 완료 후 종료. 그대로 두면 다음 5.1에서 덮어써져 작업 손실 발생.

---

## 6. 카피 범위 — 무엇을 카피하고 무엇을 카피하지 않는가

| 경로 | 툴킷 → newProject | newProject → 툴킷 | 비고 |
|---|---|---|---|
| `.claude/commands/` | ✅ | ✅ (cherry-pick) | 정본 |
| `.claude/skills/` | ✅ | ✅ (cherry-pick) | 정본 |
| `.claude/agents/` | ✅ | ✅ (cherry-pick) | 정본 |
| `.claude/harness/` | ✅ | ✅ (cherry-pick) | 정본 |
| `.claude/USAGE_GUIDE.md` | ✅ | ✅ (cherry-pick) | 참고 정본 |
| `.claude/COMMANDS_REFERENCE.md` | ✅ | ✅ (cherry-pick) | 참고 정본 |
| `.claude/settings.json` | ✅ | ⚠️ 주의 | newProject 고유 hook이 생기면 분기 — 환류 시 충돌 가능 |
| `.claude/state/` (전체) | ❌ | ❌ | 런타임 상태 디렉토리. newProject가 자체 생성. 스키마 reference(`flow-state.example.yaml`)는 툴킷 clone에서 직접 열람 |
| `.claude/settings.local.json` | ❌ | ❌ | per-user (커밋 금지) |
| `CLAUDE.md` | ❌ (템플릿 1회만) | ❌ | newProject 고유. 템플릿 갱신은 툴킷 측 `docs/install/CLAUDE.template.md` 별도 관리 |
| **`devtoolkit.config.yaml`** | **✅ (newProject에 없을 때만)** | ❌ | **tech_stack/conventions/collaboration/agent 등 정본 데이터**. install.sh가 자동 carry-over. 도입자가 tech_stack 등을 채움. 기존 newProject yaml은 덮어쓰지 않음. ⚠️ `commands:` 블록은 ADR-0041로 폐기 — 빌드·실행 명령은 12-scaffolding §5 / LOCAL.md §3 양축 정본 (ADR-0040). |
| `.gitignore` | ❌ (템플릿 append만) | ❌ | newProject 고유. 툴킷 측 `docs/install/gitignore.template`이 툴킷 필수 패턴 정본 |
| **`scripts/sprint-bootstrap.sh`** | **✅ (단일 파일)** | ✅ (cherry-pick) | sprint-bootstrap 정본. §4.2/§5.1에서 cp로 단일 파일 카피. ADR-0021 제목 정규식 BLOCK 포함 |
| **`scripts/check-local-md-sync.sh`** | **✅ (install.sh 명시 카피)** | ✅ (cherry-pick) | ADR-0017 v1.2 + ADR-0040. 정본 위치는 `docs/install/scripts/check-local-md-sync.sh` (staged). install.sh가 newProject `scripts/`로 카피 + chmod +x. CI ci.yml의 local-md-sync job이 호출. LOCAL.md 구조 + profile 3분기 + lockfile lint (stack-agnostic, 단순 grep) |
| `scripts/setup.sh`, `check-env.sh`, `setup-playwright.sh` | ❌ | ❌ | 툴킷 자체 개발용. newProject 불필요 |
| `docs/planning/` | ❌ | ❌ | 툴킷 자체 산출 (INDEX·policies·conventions·adr·CHANGELOG·_archive). newProject은 `/flow-new-project`로 자체 생성 |
| `docs/install/` | ✅ (전체) | ❌ | install.sh + 본 가이드 + `github-issue-guide.md`(ADR-0021 사용자 가이드) 포함. newProject 합류자 일상 참조 |
| **`.github/workflows/issue-pr-title-lint.yml`** | **✅ (단일 파일)** | ✅ (cherry-pick) | **ADR-0021 머신 검증 BLOCK 정본**. install.sh가 자동 carry-over → newProject 도입 즉시 이슈/PR 제목 형식 강제 |
| **`.github/ISSUE_TEMPLATE/`** (feature·bug·derived 3종) | **✅ (newProject에 없을 때만)** | ✅ (cherry-pick) | ADR-0021·0008 정합 템플릿. **기존 newProject 템플릿은 덮어쓰지 않음** — 있으면 보존하고 정합 확인 권고 |
| `.github/pull_request_template.md` | ❌ | ❌ | newProject 고유 가능성 — 툴킷 측 본 파일은 reference. §4.x에서 사용자가 필요 시 직접 카피·머지 |
| **`docs/install/ci.yml.template`** (staged) | **✅ (staged 그대로)** | ✅ (cherry-pick) | ADR-0017 v1.2 + ADR-0037 v1.1. install.sh가 docs/install/ 통째 카피 시 함께 들어감. **활성화는 도입자가 명시적** — `gh auth refresh -s workflow` 후 `git mv docs/install/ci.yml.template .github/workflows/ci.yml` + boot-smoke skeleton 채움. local-md-sync job은 사전 제공(stack-agnostic) |
| `docs/devtoolkit/` | ❌ | ❌ | v5 archive (툴킷 측 한정) |

> rsync 명령은 `.claude/`만 대상으로 하므로 위 ❌ 중 `docs/`는 자연히 제외된다. `CLAUDE.md`는 §4.3에서, `.gitignore`는 §4.4에서 1회 카피·append. (ADR-0020 정합: 구 `PLAN.md`는 폐지되어 `docs/planning/INDEX.md`+`CHANGELOG.md`로 흡수.)

---

## 7. 트러블슈팅

| 증상 | 원인 / 해결 |
|---|---|
| `/context-loader`가 명령어를 못 찾음 | cwd가 newProject 루트인지 확인. `.claude/commands/`가 카피됐는지 `ls .claude/commands/` |
| Claude Code가 변경한 `.claude/` 파일을 못 알아챔 | Claude Code 세션 재시작 필요 (CLAUDE.md·hooks는 세션 시작 시 로드) |
| `rsync: change_dir failed: Permission denied` | 권한 문제. WSL이면 Windows-side 폴더 권한 확인 (`ls -la /mnt/c/work/`). 필요 시 `sudo` 또는 폴더 소유권 조정 |
| WSL에서 `rsync` 명령 못 찾음 | `sudo apt install rsync` (Ubuntu/Debian) / `sudo dnf install rsync` (Fedora) |
| 카피 후 쉘 스크립트 실행 권한 사라짐 | rsync `-a`는 권한 보존하지만 Windows-side(`/mnt/c/...`) ↔ Linux-side(`~/...`) 간 카피는 일부 메타데이터 손실. 필요 시 `chmod +x` 재적용 |
| 툴킷 측 `git diff`에 의도하지 않은 대량 변경 | 5.3 B 경로에서 전체 덮어쓰기 발생. `git checkout .claude/` 후 cherry-pick으로 재시도 |
| newProject `.claude/state/` 안에 툴킷 dogfooding 상태가 보임 | rsync `--exclude 'state/'` 옵션 누락. 명령 재확인 |
| `Blocked-by:` 미해소 등 툴킷 BLOCKED 메시지 | `.claude/USAGE_GUIDE.md` §7 "자주 마주칠 BLOCKED" 참조 |
| 시크릿 노출 의심 | STOP. CLAUDE.md 보안 절대 규칙 6번에 따라 `/cso` 점검 |

---

## 8. Windows 네이티브 PowerShell (WSL 미사용 시 fallback)

WSL2 사용을 권장하나, 부득이하게 PowerShell만 쓸 경우 robocopy로 대체:

```powershell
# §4.2 / §5.1 — toolkit → newProject (.claude)
robocopy c:\work\agent-toolkit\.claude .\.claude /E `
  /XD state /XF settings.local.json

# §4.2 / §5.1 — sprint-bootstrap.sh 단일 파일 카피
New-Item -Type Directory -Force .\scripts | Out-Null
copy c:\work\agent-toolkit\scripts\sprint-bootstrap.sh .\scripts\sprint-bootstrap.sh

# §5.3 / §5.4 — newProject → toolkit (dry-run)
robocopy .\.claude c:\work\agent-toolkit\.claude /E `
  /XD state /XF settings.local.json `
  /L

# §4.3 / §4.4 — 템플릿 카피
copy c:\work\agent-toolkit\docs\install\CLAUDE.template.md .\CLAUDE.md
copy c:\work\agent-toolkit\docs\install\gitignore.template .\.gitignore
# 또는 append (Case B)
type c:\work\agent-toolkit\docs\install\gitignore.template >> .\.gitignore
```

> sprint-bootstrap.sh는 bash 스크립트이므로 PowerShell에서 직접 실행 불가. **WSL 또는 Git Bash에서 실행**: `bash ./scripts/sprint-bootstrap.sh ...` (PowerShell이 install·카피만 담당).

robocopy `/L`은 list-only(dry-run). 의미는 rsync `-n`과 동일. 트러블슈팅:
- `robocopy ERROR 5 (0x00000005)` → 관리자 PowerShell 또는 폴더 소유권 확인
- robocopy는 `--delete` 부재 시 source의 삭제를 dest에 반영하지 않음. 명시적 동기화 원하면 `/PURGE` 추가 (rsync `--delete`와 같음, dry-run 먼저 권장)

---

## 9. 향후 개선 (자동화 후보)

본 수동 절차의 한계와 자동화 후보:

| 한계 | 자동화 안 |
|---|---|
| 매 세션 시작 시 rsync 잊기 쉬움 | `.claude/hooks/SessionStart`에 동기화 alert (단순 비교) |
| cherry-pick이 사람 손에 의존 | `tools/sync-in.sh` — diff 미리보기 + 파일 단위 인터랙티브 카피 |
| 툴킷 release 버전 추적 불가 | git submodule 전환 + `tools/install.sh` (junction/symlink 생성) |
| 공동 개발자 도입 절차 표준화 | install 스크립트화 + CI에서 sync drift 검증 |

자동화 도입 시점은 다음 조건이 모두 충족된 이후로 권장:
- 첫 newProject 도입을 끝까지 한 번 돌려봄 (스모크 통과)
- 카피 범위(§6)가 1주 이상 변동 없음
- 툴킷의 `.claude/` 자가포함성(self-containment) 정리 완료 — 즉, 내부 참조에 툴킷 *자체* 경로(`docs/planning/...`)가 깨진 채로 남아 있지 않음

---

## 10. 체크리스트 — 도입 전 1분

- [ ] agent-toolkit clone 위치 확인 (기본: `/mnt/c/work/agent-toolkit/`)
- [ ] Claude Code 설치 + 동작 확인
- [ ] gh-cli `gh auth login` 완료
- [ ] gh-cli `project` scope 확인 (`gh auth status` → 없으면 `gh auth refresh -s project`)
- [ ] bash 4.3+ + rsync + yq 4.x + bc 사용 가능 (`which rsync yq bc`, `bash --version`)
- [ ] newProject 루트에서 `git init` 또는 기존 repo
- [ ] §4.2 rsync 실행 (`.claude/state/`가 newProject에 카피되지 않았는지 확인)
- [ ] §4.2 `scripts/sprint-bootstrap.sh` 카피 + `chmod +x` (`bash ./scripts/sprint-bootstrap.sh --help` 확인)
- [ ] §4.3 CLAUDE.md 템플릿 카피·placeholder 채움 (정본 경로: `docs/install/CLAUDE.template.md`)
- [ ] §4.4 `.gitignore` 템플릿 카피/append
- [ ] §4.4.1 첫 커밋 (`.gitignore` → `.claude/`+`CLAUDE.md`+`scripts/` 순서)
- [ ] §4.5 `claude` → `/context-loader` 정상 출력 확인
- [ ] §4.6 sprint-bootstrap 환경 검증 (`--help`, gh project scope, yq/bc)
