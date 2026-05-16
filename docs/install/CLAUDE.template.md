# {{PROJECT_NAME}}

> **Note**: 본 파일은 agent-toolkit 도입 시 newProject용 최소 CLAUDE.md 템플릿이다.
> 도입 절차는 [manual-sync-guide.md](manual-sync-guide.md) 참조.
> `{{...}}` 자리표시자(placeholder)는 도입 시 newProject에 맞춰 채운다.

---

## 보안 (절대 규칙)
1. .env, .env.*, API Key, 시크릿, 인증서 파일은 절대 커밋하지 않는다
2. 코드, 로그, 커밋 메시지, PR 본문에 API Key/시크릿 값을 절대 포함하지 않는다
3. 환경변수 출력 금지: cat .env, echo $ANTHROPIC_API_KEY, printenv 등 실행하지 않는다
4. 보안 파일 경로 패턴: .env*, *.key, *.pem, credentials.json, *secret*, *api_key*
5. settings.json PreToolUse 훅이 보안 파일 Write/Edit를 자동 차단한다
6. /cso 보안 점검 시 시크릿 노출 여부를 반드시 확인한다

## 분량 가드 (300줄 권고, WARN-only)
1. **운영 문서만 가드 대상** — `.claude/commands/`, `.claude/harness/`, `.claude/agents/`, `CLAUDE.md`, `USAGE_GUIDE.md`, `docs/planning/conventions/`, `docs/planning/operations/`, `docs/planning/adr/`. 툴킷을 작은 컨텍스트로 유지하기 위함
2. **산출 문서는 가드 외** — RFP/맥락에 따라 분량 자유 (01~15 1수준·분할 폴더·`docs/features/<slug>/*`·`retro/`)
3. 300줄 초과 시 settings.json hook(`.claude/scripts/check-line-count.sh`)이 stderr 권고만 출력 — 차단 없음
4. 분할 트리거·하위 순번·INDEX.md는 [`docs/planning/conventions/file-numbering.md`](../docs/planning/conventions/file-numbering.md) 정본

## 산출 문서 Schema (재현 가능 형식 규격, ADR-0010)
1. 모든 산출은 28종 doc_type 중 하나에 매핑 — `.claude/schemas/<doc_type>.schema.yaml`이 형식 정본
2. 신규 산출은 `bash .claude/scripts/scaffold-doc.sh <doc_type> <output>`로 골격 생성 후 작성
3. 작성 완료 후 `bash .claude/scripts/validate-doc.sh <output>`로 검증 — 위반 시 BLOCKED
4. 같은 RFP 입력 → 같은 형식 출력이 보장되어야 함 (재현성)
5. 의존: `yq` (mikefarah/yq v4+) — 미설치 시 RUNBOOK §4 fallback
6. 상세: [`docs/planning/conventions/document-manifest.md`](../docs/planning/conventions/document-manifest.md)

## gstack
Use /browse from gstack for all web browsing. Never use mcp__claude-in-chrome__* tools.
Available skills: /office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review,
/design-consultation, /review, /ship, /land-and-deploy, /canary, /benchmark, /browse,
/qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy, /retro,
/investigate, /document-release, /codex, /cso, /autoplan, /careful, /freeze, /guard,
/unfreeze, /gstack-upgrade.

## DevToolKit Command (v6)
실제 사용 가능한 Command는 `.claude/commands/`의 파일이 정본이다. 주요 진입점:
- Meta: `/flow-new-project`, `/flow-feature`, `/start-feature`
- Phase: `/intention-brief`, `/ux-flow-design`, `/srs`, `/prd`, `/wbs`, `/change-contract`,
  `/implementation-planner`, `/plan-eng-review`, `/acceptance-criteria`, `/risk-check`,
  `/implement`, `/code-review`, `/qa-test`, `/ui-design-review`, `/docs-update`
- 보조: `/context-loader`, `/debug-investigator`

> 전체 목록·용도·BLOCKED 케이스는 `.claude/COMMANDS_REFERENCE.md` 참조.
> 본 프로젝트 사용법은 `.claude/USAGE_GUIDE.md` 참조.

## 필수 규칙
1. 모든 작업은 태스크/이슈 단위, 상태(FSM) 반드시 업데이트
2. `/plan-eng-review` 통과 전 코드 작성 금지
3. 프로젝트 코딩 컨벤션 준수 (게이트 C에서 생성: `docs/planning/10-coding-conventions/10-coding-conventions.md`)
4. 프로젝트 코드 정의서의 상태/오류 코드 사용 (생성된 시점부터 적용)
5. 단위 테스트 없이 완료 처리 금지
6. `/freeze`로 파일 소유 범위 확인
7. PR에 이슈 ID 포함 (예: `Closes #N`)
8. `/careful` 상시 활성화
9. **UI/FE 변경은 dev 서버 + 브라우저로 골든패스 1회 이상 실증한 후에만 완료 처리 (ADR-0011)** — gstack `/qa` 또는 `$B`(browse 바이너리) 사용. `tsc/vitest/build/newman` 등 헤드리스 검증 통과는 "코드가 컴파일된다"는 의미일 뿐 "사용자 눈에 동작한다"가 아니다. 스크린샷은 `docs/features/<slug>/screenshots/`에 저장. AI 게이트 6축 중 5번째 축이 본 규칙을 schema-level로 강제한다.
10. **매 PR은 dev/stg/prod 3 profile 각각 로컬 부팅 가능성 검증 후에만 PR 생성 (ADR-0037 v1.1 + ADR-0040)** — fresh checkout 상태에서 12-scaffolding §5 부팅 명령을 profile별로 실행해 ready 신호 + 에러 0건 확인. 부팅 자산은 profile별로 함께 진화 — `.env.{dev,stg,prod}.example`·DB migrations·lockfile·setup scripts·profile별 부팅 명령. 한 profile만 갱신하고 나머지 누락 시 BLOCK(같은 PR 추가 커밋으로 동기, 별 hotfix PR 금지). 단일 환경 운영(stg=prod 공유 또는 단일 환경)은 N/A + 사유 명시 허용. UI 변경 여부와 무관 — BE-only PR도 backend dev 서버를 3 profile 모두 검증한다. 외부 의존(예: DB 컨테이너) 장애 시에만 사용자 승인 후 명시적 skip 허용. **본 프로젝트 루트 `LOCAL.md`가 부팅 사용자 가이드 정본** — install.sh가 카피한 LOCAL.md 템플릿을 채우고, 부팅 자산 변경 시 같은 PR에서 동기 갱신(ADR-0040). 12-scaffolding §7(SoT)과 책임 분리. AI 게이트 6번째 축이 본 규칙을 schema-level로 강제한다.
11. **frontend layer가 있는 프로젝트는 12-scaffolding §8 "스타일링 솔루션" 선택·설치·entrypoint import 강제 (ADR-0038)** — Tailwind/CSS Modules/styled-components/emotion/vanilla-extract/Sass 중 1개 이상. 10-lld-screen-design §3 디자인 토큰(Color·Typography·Spacing·Component primitives 4종 BLOCK)이 §8 styling 솔루션과 schema-level로 매핑되어야 한다. AI 게이트 5번째 축 하위 체크 "stylesheet 적용 확인"이 매 PR마다 stylesheet ≥ 1개 적용을 검증 — plain HTML 머지 차단. BE-only / CLI-only는 §8 N/A 명시 허용.

## 에이전트 규칙 (하네스 엔지니어링)
- 에이전트 6종: analyst, architect, developer, reviewer, deployer, orchestrator
- Generator ≠ Evaluator (자기 평가 금지). developer ↔ reviewer 도메인 분리
- Sprint Contract 인수 기준으로 검수
- 파일 기반 핸드오프 (docs/ 산출물로 Phase 간 전달)
- 실패 시 BLOCKED + 사유 기록
- `/investigate`로 디버깅 (조사 없이 수정 금지)

## 태스크 관리 (FSM)
- 작업 정본: GitHub Issues (mode=sprint) 또는 `docs/planning/` 산출 문서 (mode=planning)
- 상태: CREATED → PENDING → IN_PROGRESS → IN_REVIEW → DONE
- 분기: REJECTED → IN_PROGRESS (재작업), BLOCKED → PENDING (해소)
- 모든 전이에 history 기록 (from, to, by, at, reason)

## 사용자 승인
- 배포(Phase 6)와 운영(Phase 7), 그리고 게이트 A·B·C, 휴먼 게이트(D-06 2단)만 사용자 승인 필요
- 그 외 모든 Phase는 자동 진행

## 실행 방법
- `claude` 진입 후 `/context-loader` → 권고된 Command 따라 진행
- 멀티에이전트가 필요할 때만 `claude --agent orchestrator`
- 개별 gstack 스킬도 CLI에서 직접 호출 가능 (예: `/review`, `/qa`, `/cso`)

## 기술 스택
> 도입 시 newProject에 맞춰 채운다. 게이트 C(`/implementation-planner --mode=hld`) 산출물에서 확정.

- 프론트엔드: {{FRONTEND_STACK}}
- 백엔드: {{BACKEND_STACK}}
- 인프라: {{INFRA}}

## 빌드·실행 명령 (ADR-0041)

> **정본 = 양축**: `docs/planning/12-scaffolding/12-scaffolding.md` §5 빌드·실행 (SoT, plan layer) + 루트 `LOCAL.md` §3 Profile별 부팅 명령 (유저 facing, ADR-0040). 두 문서가 매 PR 동기 갱신.
> **호출 방식**: build tool **native script 직호출** — `pnpm build` · `./gradlew bootRun` · `uv run pytest` 등. `/implement` Phase도 본 절을 참조.
> (이전 ADR-0028 `./devkit` wrapper + ADR-0027 3-fallback lookup은 ADR-0041로 폐기 — test-case-3 PR #38 회귀 후 wrapper 우회·native script 직호출이 사실상 표준이라는 사용자 검증 결과.)

도입자 절차:
1. `/flow-design` Phase에서 12-scaffolding §5 빌드·실행 코드블록 작성 (SoT)
2. 같은 시점에 루트 `LOCAL.md` §3 dev/stg/prod profile별 부팅 명령 작성 (ADR-0037 v1.1 profile 3분기)
3. 매 PR에서 부팅 자산 변경 시 §5 + LOCAL.md §3 동시 갱신 (ADR-0040 §2.4 동기 lint 권고)
4. multi-module은 빌드 도구 native syntax — Node `pnpm -r build` / `pnpm --filter @app/backend dev`, Java `./gradlew build` / `./gradlew :backend:bootRun`, Python `uv workspace --all build`, Go `go build ./...` 등

---

## v6 Addendum — Meta Command + Harness 시스템

> 위치: `.claude/commands/`, `.claude/harness/`, `.claude/state/`, `.claude/USAGE_GUIDE.md`
> 본 Addendum은 위 v5 규칙 위에 **Phase 강제·Artifact Binding·Resumability**를 추가한다.

### Meta Routing

**0단계 — 툴킷 도입** (newProject마다 한 번, 툴킷 디렉토리에서 호출): `/install-toolkit <target-dir>` (ADR-0017). RFP는 다음 위치에 미리 두면 자동 감지:
- 표준: `<newProject>/RFP.md`
- 대체: `<newProject>/<name>.rfp.md` 또는 `<newProject>/RFP/*.md`
- 미발견 시 `/flow-init "<자연어 의도>"`로 직접 입력 가능

이후 작업은 다음 2가지 분류로 시작한다.

- **NEW_PROJECT** — 4 Phase 메타 분리 호출 (`/flow-init` → `/flow-design` → `/flow-wbs` → `/flow-bootstrap`, ADR-0016 권장). 일괄 호출자는 `/flow-new-project`.
- **FEATURE** (add / modify / bug / design 통합) → `/flow-feature` (모드 자동 감지)

분류가 모호하면 `/start-feature <자연어>`로 자동 분류 위임. `/flow-feature`는 이슈 라벨·자연어·git 상태로 모드(add/modify/bug/design)를 자동 결정하며, 수동 override는 `--mode=...`.

### Strict Harness Mode (강제)
1. Meta Command 없이 시작 금지
2. `change-contract` 없이 코드 수정 금지
3. `acceptance-criteria` 없이 PR 생성 금지
4. `/plan-eng-review` PASS 없이 `/implement` 금지
5. 단위 테스트 없이 `/code-review` 진입 금지
6. **AI 테스트 게이트 미통과 시 PR 생성 금지 (D-06 1단, 6축, ADR-0011 + ADR-0037)**
7. `tested` 라벨 부재 시 머지 금지 (D-06 2단)
8. `Blocked-by:` 미해소 이슈 작업 금지
9. **`ui_changed=true`인데 gstack `/qa` 미호출·스크린샷 미첨부 시 PR 생성 금지 (ADR-0011)** — AI 게이트 5번째 축(브라우저 골든패스 실증) 미충족
10. **dev/stg/prod 3 profile 부팅 검증 누락 또는 부팅 자산(`.env.{dev,stg,prod}.example`·migrations·lockfile·LOCAL.md) profile별 동기 누락 시 PR 생성 금지 (ADR-0037 v1.1 + ADR-0040)** — AI 게이트 6번째 축 미충족. 별도 hotfix PR로 미루지 않음. 단일 환경 운영은 N/A + 사유 명시 허용
11. **`ui_changed=true`인데 stylesheet 적용 근거 명시 누락 시 PR 생성 금지 (ADR-0038)** — plain HTML 머지 차단. AI 게이트 5번째 축 하위 체크 "stylesheet 적용 확인" 미충족

### Artifact Binding (필수 흐름)
`/intention-brief → /change-contract → /implementation-planner → /plan-eng-review(PASS) → /acceptance-criteria → /risk-check → /implement → /code-review → /qa-test --ai (AI 게이트) → PR 생성 → /qa-test --human (휴먼 게이트, tested 라벨) → /docs-update`

각 단계의 산출물 파일이 다음 단계의 입력. 누락 시 BLOCKED. AI 게이트와 휴먼 게이트는 D-06 2단의 동일 Test Plan 4블록을 공유한다.

### State 영속화
런타임 상태는 `.claude/state/flow-state.yaml`에 저장 (`.gitignore` 권장). 새 세션에서 `/context-loader`로 복원.

### FSM ↔ GitHub Label 매핑
- CREATED → 라벨 미부착
- PENDING → `status:todo`
- IN_PROGRESS → `status:in-progress` (`/implement` 진입 시 자동 부여)
- IN_REVIEW → `status:in-review` (PR open 시)
- DONE → 이슈 close
- BLOCKED → `status:blocked`
- REJECTED → `status:in-progress` 회귀 + 코멘트

### gstack 스킬과의 관계
본 시스템은 gstack을 폐기하지 않는다. 다음 단계에서 gstack 스킬을 함께 호출:

| Phase | 보완 gstack 스킬 |
|---|---|
| /plan-eng-review | `/plan-eng-review`(gstack) — 본 Command와 동명, gstack 절차 포함 |
| /code-review | `/review` |
| /qa-test | `/qa`, `/qa-only` |
| /risk-check | `/cso` |
| /debug-investigator | `/investigate` |
| (전반) | `/careful` 상시 활성 (필수 규칙 8) |

### 진입 권장 순서 (새 세션)
1. (있으면) `docs/planning/INDEX.md` 또는 `docs/planning/01-project-brief/01-project-brief.md`, 본 `CLAUDE.md`, `.claude/USAGE_GUIDE.md` 일독
2. `/context-loader` 실행
3. 권고된 Command 따라 진행
4. 의문 시 BLOCKED → 사용자 확인 (추측 진행 금지)

### 한계
- 무인 야간 자동 재개 미지원
- 동시 다중 이슈 작업 미지원 (flow-state.yaml은 single-issue)
- 본 Addendum 변경 시 ADR 필수 (`docs/planning/adr/`)

---

## newProject 도입 메모

본 파일은 agent-toolkit에서 카피된 템플릿이다. agent-toolkit 측 변경 사항은 [manual-sync-guide.md](manual-sync-guide.md)의 "5. 개발 사이클" 절차로 동기화한다. 정본은 `c:\work\agent-toolkit\` (또는 도입 팀의 agent-toolkit clone 위치).
