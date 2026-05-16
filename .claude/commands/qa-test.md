---
description: Use this when the user is about to open a PR, asks to verify a feature end-to-end, needs to generate the Test Plan 4-block for D-06 PR template, or is about to mark an issue as ready for human approval.
allowed-tools: Read, Write, Bash, Glob, Grep
---

# /qa-test

## 목적
**policies/sprint-cycle.md §2 (D-06) PR Test Plan 4블록 생성**. acceptance를 실행 가능한 검증 단계로 변환하고, 자동 검증 결과를 PR 본문에 첨부한다.

> **Schema 강제 (ADR-0010 + ADR-0011 + ADR-0037 + ADR-0038, --ai 전용)**: `doc_type=feature-ai-qa`. `scaffold-doc.sh feature-ai-qa docs/features/<slug>/<slug>.ai-qa-report.md` → 작성 → `validate-doc.sh`. Verdict(PASS/FAIL + ui_changed)·Test Plan 4 subsection(Build/Automated tests/Manual verification/DoD coverage)·**AI 게이트 6축**(ADR-0037)·**ui_changed=true 시 ## 6. UI/FE 변경 검증 BLOCK + stylesheet 적용 컬럼 BLOCK**(ADR-0038)·**## 7. 로컬 부팅 가능성 BLOCK(전 PR)**(ADR-0037) schema: `.claude/schemas/feature-ai-qa.schema.yaml`.

## 사용 시점
- `/code-review` PASS 후, `gh pr create` 직전
- `/flow-feature-add`·`modify`·`bug-fix`·`design-change` 모두 동일

## 입력
- `<slug>.acceptance.md` (필수)
- 변경된 코드 + 테스트
- **gstack `/qa` 스킬 결과 — `ui_changed=true` 시 필수 (ADR-0011)**
  - 감지 규칙: `git diff <base>...HEAD` 대상에 `*.tsx|*.jsx|*.vue|*.svelte|*.html|*.css|*.scss|*.module.*` 또는 `public/**|static/**|assets/**` 포함 → `ui_changed=true` 자동 판정
  - false인 경우(BE-only) 본 입력 N/A 명시

## 산출물

### `--ai` 모드 (D-06 1단)
- `docs/features/<slug>/<slug>.ai-qa-report.md`
  - frontmatter: `ui_changed: true|false`, (true 시) `screenshots: [...]`, `golden_path_verified: true`
  - 4블록 (Build / Automated tests / Manual verification / DoD coverage)
  - **AI 게이트 6축** (ADR-0011 + ADR-0037 + ADR-0038):
    - 1~4축 (ADR-0001): 자동 테스트·코드 리뷰·Test Plan 4블록·시크릿 스캔
    - 5번째 축 "브라우저 골든패스 실증" (ADR-0011): `ui_changed=true`일 때 BLOCK, false일 때 N/A 명시 허용. **하위 체크 "stylesheet 적용 확인"**(ADR-0038) — `ui_changed=true`일 때 stylesheet ≥ 1개 명시 필수
    - 6번째 축 "로컬 부팅 가능성" (ADR-0037): **전 PR 적용** (UI 변경 여부 무관). 12-scaffolding §5의 부팅 명령으로 dev/runtime 서버 ready 신호 확인 + 에러 0건
  - **`## 6. UI/FE 변경 검증`** 절 (`ui_changed=true` 시 필수, BLOCK) — gstack `/qa` 결과·콘솔 에러 0개·**stylesheet 적용 근거**(ADR-0038)·스크린샷 표 `[화면, 시나리오, 스크린샷경로, stylesheet 적용]`
  - **`## 7. 로컬 부팅 가능성`** 절 (ADR-0037, **전 PR 필수**, BLOCK) — 부팅 명령·부팅 결과(ready 신호)·에러 0건·부팅 자산 변경 영향 표 `[자산, 본 PR diff, 갱신 여부]`
  - **`## 발견 사항 (Found Issues) — 파생 이슈 후보`** 절 (policies/github-issue.md §5 / ADR-0008 — 3축 OX 체크박스 모두 통과 후보만)
  - **`## 같은 PR 보정 필요`** 절 (3축 OX 미통과 후보 — 같은 PR 추가 커밋으로 처리)
- PR 본문 자동 채움 (Test Plan 4블록 + 6축 결과 + 발견 사항 요약 + 스크린샷 링크 + 부팅 결과)

### `--human` 모드 (D-06 2단, 가이드)
- 사람을 위한 재현 체크리스트 + **PR 변경 요청 작성 가이드** (사람이 발견 시)
- 산출 파일은 통상 별도 생성 안 함. PR 본문 코멘트로 변경 요청 직접 작성

## Test Plan 4블록 (D-06 강제 템플릿)

```markdown
## Build
- [x] `<build cmd>` (output: ...)

## Automated tests
- [x] `<test cmd>` — N tests, M passed, 0 failed

## Manual verification
- [ ] {{acceptance Functional 항목}} (사람이 ✅)
- [ ] {{acceptance UX 항목}} (사람이 ✅)
- [ ] {{회귀 시나리오}}

## DoD coverage
| Acceptance | PR diff | 검증 |
|---|---|---|
| Functional A | src/x.ts:42 | 단위 테스트 x.test.ts |
| UX 5상태 | src/Y.tsx | 스크린샷 첨부 |
```

## 실행 단계
1. acceptance 읽기 → 항목 분류
2. **ui_changed 자동 판정** (ADR-0011) — `git diff <base>...HEAD --name-only`로 변경 파일 목록 확인:
   - `*.tsx|*.jsx|*.vue|*.svelte|*.html|*.css|*.scss|*.module.*` 또는 `public/**|static/**|assets/**` 매칭 시 `ui_changed=true`
   - 매칭 없음 → `ui_changed=false` (5번째 축 N/A 명시 허용)
   - frontmatter에 명시적 `ui_changed: true` 지정도 인정 (override)
3. Build / Automated tests 실제 실행
4. 결과 캡처 (성공/실패 + 로그 요약)
5. **`ui_changed=true`이면 gstack `/qa` 호출 (의무, BLOCK)**:
   - `Skill {skill: "gstack:qa"}` 또는 `$B goto <dev-server-url>` 직접 실행
   - acceptance.md의 Functional 골든패스 시나리오 1개 이상을 실제 브라우저에서 수행
   - 화면별 스크린샷 1장 이상 → `docs/features/<slug>/screenshots/<screen>.png`
   - 콘솔 에러 0개 확인 (`$B console --errors`)
   - **stylesheet 적용 확인 (ADR-0038, BLOCK)**: 빌드 산출(`dist/assets/*.css` 등) 또는 dev 서버 응답에서 stylesheet ≥ 1개 검출. `[화면, 시나리오, 스크린샷경로, stylesheet 적용]` 표의 `stylesheet 적용` 컬럼에 적용 근거 명시 (예: `✅ tailwind base.css`, `✅ CSS Modules: ArticleCard.module.css`). 적용 0개 → FAIL
   - 결과를 `## 6. UI/FE 변경 검증` 섹션에 표로 정리
   - gstack 미설치/환경 미구성 시 BLOCKED → 사용자에게 환경 셋업 요청 (추측 진행 금지)
6. **로컬 부팅 가능성 검증 (ADR-0037 v1.1, 전 PR 필수, BLOCK, profile 3분기)**:
   - 12-scaffolding §5 "빌드·실행"의 부팅 명령을 profile별로 그대로 인용 (예: `pnpm dev:local`, `pnpm dev:stg`, `pnpm dev:prod` / Spring `--spring.profiles.active=dev|stg|prod`)
   - **dev profile** 부팅 → ready 신호 확인 (예: `:3000 listening`, `ready in X ms`, `Server started`) + 에러 0건
   - **stg profile** 부팅 → ready 신호 + 에러 0건. 단일 환경 운영(stg=prod 공유)이면 N/A + 사유 명시
   - **prod profile** 부팅 → ready 신호 + 에러 0건. 단일 환경이면 N/A + 사유
   - 표 컬럼 `[프로파일, 부팅 명령, 결과(ready 신호), 에러, 부팅 자산 변경]`을 3행(dev/stg/prod)로 작성. 단일 환경이면 N/A 행도 명시
   - **부팅 자산 변경 영향**: 12-scaffolding §7의 자산 목록을 본 PR `git diff <base>...HEAD`와 대조. 변경됐다면 profile별 갱신(예: `.env.dev.example`에 새 키 추가 → `.env.stg.example`·`.env.prod.example`도 동기 추가)이 PR에 포함됐는지 확인 — 한 profile만 갱신하고 나머지 누락 시 BLOCK
   - **LOCAL.md 동기 확인 (ADR-0040, BLOCK)**: 부팅 자산이 변경된 경우 newProject 루트 `LOCAL.md`도 같은 PR diff에 포함됐는지 확인. (a) 새 환경 변수 추가 → LOCAL.md §2 셋업 또는 §4 자산 표 갱신, (b) 부팅 명령 변경 → §3 profile별 명령 갱신, (c) 트러블슈팅 신규 패턴 → §5 누적. 부팅 자산 변경 없음이면 `LOCAL.md 동기` 컬럼에 "N/A 부팅 자산 변경 없음" 명시 허용. 부팅 자산은 변했는데 LOCAL.md 미갱신 시 BLOCK → 같은 PR 추가 커밋
   - 누락 자산/profile 발견 시 BLOCKED → 같은 PR 추가 커밋으로 자산 갱신 (별도 hotfix PR로 미루지 않음)
   - 외부 의존(예: DB 컨테이너) 장애로 부팅 불가 시 `verdict.local_runnable: skip`을 사용자에게 *명시적 승인* 요청 — 자동 skip 금지
7. Manual verification 항목 → 사람이 할 일로 명시 (휴먼 게이트가 별도 재현)
8. DoD coverage 표 작성 (acceptance ↔ diff 매핑)
9. **발견 사항 분류 (policies/github-issue.md §5 / ADR-0008)**

   **`--ai` 모드**: 자동 테스트 중 발견된 인접 영역 결함·미커버 시나리오·플레이키 테스트 등을 3축 OX 체크박스로 분류:

   ```
   각 후보별로:
   - [ ] in_scope == False           Q1. 부모 acceptance/contract 미명시 (No → 체크)
   - [ ] blocks_parent_merge == False Q2. 본 작업 없이 부모 PR 머지 가능 (Yes → 체크)
   - [ ] same_area == False           Q3. 부모와 다른 파일·모듈·영역 (Yes → 체크)
   ```

   > [분량] 축은 폐기 — WBS 단계 이슈 템플릿 4필드로 사전 보장. 판정 로직 상세는 policies/github-issue.md §5.3 표 참조.

   - **3개 모두 ✅ → "## 발견 사항 — 파생 이슈 후보"**: A. Derived 분류 + 권장 Command (`/flow-feature "..."`) + 3축 OX 결과 + 근거(테스트명/시나리오). **Origin 5필드 자동 첨부 (ADR-0021 §2.4)** — Discovered-by=`/qa-test --ai`. 사용자 승인 시 [`issue-spinoff`](../skills/devtoolkit/issue-spinoff/SKILL.md) Skill이 호출되어 `derived` 라벨 + Origin 본문 자동 생성 (ADR-0022). PR 본문 Test Plan 4블록은 [`test-plan`](../skills/devtoolkit/test-plan/SKILL.md) Skill이 자동 생성.
   - **Q2 ❌ → B. Blocker** 별도 이슈 (`Blocked-by: #N`)
   - **Q1·Q3만 ❌ (Q2 ✅) → "## 같은 PR 보정 필요"**: 현 PR 추가 커밋으로 처리
   - **무관한 결함 → C. Bug** (`/flow-feature --mode=bug "..."`)

   `issue-spinoff` 스킬이 사용자 승인 후 자동 등록. 모든 파생 이슈는 독립 — 부모 추적 링크 없음.

   **`--human` 모드**: 사람이 PR 검토 중 발견하면 **기본은 PR 변경 요청** (policies/github-issue.md §5.3 수동 절차). gh CLI 가이드:

   ```bash
   gh pr review <PR_N> --request-changes --body "발견 사항: <설명> (파일:라인 + 재현 절차)"
   ```

   에이전트가 변경 요청을 받으면 P10-qa-ai 회귀 → 같은 PR 추가 커밋 → 머지로 완결. **scope 완전 밖일 때만**(위 3축 OX 모두 충족) `/start-feature "PR #N 리뷰 중 발견: ... (현 PR scope 밖)"`로 A. Derived 등록.
10. **mode=sprint**: push + PR 본문 자동 작성 + 이슈 연결
   ```bash
   # AI 게이트 PASS 직후 일괄 push (자가 push 금지 정책)
   BRANCH="$(git rev-parse --abbrev-ref HEAD)"
   git push -u origin "$BRANCH"

   # PR 생성 (base=main, head=현 브랜치, 본문에 Test Plan 4블록 + Closes #N)
   gh pr create \
     --base main \
     --head "$BRANCH" \
     --title "<title>" \
     --body "$(cat docs/features/<slug>/<slug>.ai-qa-report.md)
     
     Closes #<N>"
   ```
   - PR open 시점에 `.github/workflows/sync-issue-labels.yml` (ADR-0029)이 PR body `Closes #N` 파싱 후 이슈 라벨을 `status:in-progress` → `status:in-review`로 자동 전이
   - PR 본문에 `Closes #N` 키워드 강제 (머지 시 이슈 자동 close)
   - `--draft` 플래그는 사용하지 않음 (D-06 1단 통과 = 머지 후보 자격)
11. **mode=planning**: PR 생성 skip 또는 docs-only PR로 생성
   - GitHub 미연동 상태면 qa-report.md 만 산출
   - 게이트 검토자(팀장/팀)에게 문서 링크로 보고

## 완료 조건
- 4블록 모두 작성됨
- 자동 항목 (Build/Automated) 모두 ✅
- AI 게이트 **6축** 모두 PASS (5번째 축은 `ui_changed=false`일 때 N/A 명시 허용; 6번째 축은 외부 의존 장애 시에만 사용자 승인 후 skip)
- `ui_changed=true`이면: 스크린샷 ≥ 1, 콘솔 에러 0개, `## 6. UI/FE 변경 검증` 표 작성, **stylesheet 적용 ≥ 1개 명시 (ADR-0038)**
- **`## 7. 로컬 부팅 가능성` 표 작성 (전 PR 필수, ADR-0037)** — 부팅 명령·ready 신호·에러 0건·부팅 자산 변경 영향
- Manual·DoD 블록은 사람을 위한 체크박스 (현 시점 미체크)
- PR 생성됨, 본문에 4블록 + 6축 결과 + (필요 시) 스크린샷 링크 + 부팅 결과 포함, 이슈 링크(`Closes #N`) 포함

## Strict Rules (D-06 + ADR-0011 + ADR-0037 + ADR-0038)
- **4블록 누락 시 PR 생성 금지** — `.github/pull_request_template.md` 강제
- **Build/Automated 미통과 시 PR 생성 금지**
- **`ui_changed=true`인데 gstack `/qa` 호출·스크린샷·콘솔 에러 검증 누락 시 PR 생성 금지 (ADR-0011)**
- **`ui_changed=true`인데 `golden_path_verified: true`가 frontmatter에 없으면 BLOCK**
- **`ui_changed=true`인데 stylesheet 적용 근거 명시 누락 시 PR 생성 금지 (ADR-0038)** — plain HTML 머지 차단
- **dev/stg/prod 3 profile 부팅 검증 누락 또는 부팅 실패 시 PR 생성 금지 (ADR-0037 v1.1 + ADR-0040)** — 부팅 자산(`.env.{dev,stg,prod}.example`·migrations·lockfile·LOCAL.md 등) 변경분이 PR에 profile별 동기로 누락된 경우 같은 PR 추가 커밋으로 해결 (별도 hotfix PR로 미루지 않음). 단일 환경 운영은 N/A + 사유 명시 허용
- **DoD coverage 매핑 누락 항목 발견 시 회귀**
- **`Closes #N` 키워드 누락 시 PR 생성 금지** — 머지 시 이슈 자동 close가 끊기면 lifecycle 불일치
- **`git push --force` 금지** (CLAUDE.md 보안 규칙). main/master 직접 push 금지 — 항상 `<mode>/<slug>-issue-<N>` 브랜치 → PR 경유

## 머지 게이트 안내 (PR 본문에 자동 포함)
- 자동 CI green
- 사람 Approve ≥ 1
- `tested` 라벨 부착 (사람이 빌드+검증 후 부착)
- 위 3개 모두 충족해야 머지 가능 (branch protection)

## Artifact Binding
- 입력: acceptance, code-review(PASS), 코드
- 출력: PR + Test Plan, → 사람의 검증 단계 (D-06)
