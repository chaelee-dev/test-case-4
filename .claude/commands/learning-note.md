---
description: Use this when the AI gate (qa-test --ai) has just passed and the flow needs Learning Note artifacts (P10b, default mode), OR after PR merge to post the archive to GitHub Discussions via local gh-cli (--post mode). LLM is invoked only once at P10b on the user's local machine — never in CI. Educator agent territory — generates explanations only, does NOT judge code quality.
allowed-tools: Read, Write, Grep, Glob, Bash
---

# /learning-note

> 정합 문서: ADR-0007 (Learning Layer 비블로킹 통합), PRD `docs/planning/05-prd-learning-layer.md`

## 목적

PRD R-L-01~09 충족. AI 게이트 통과 코드에 대해 **학습용 설명**(Learning Note)을 생성·아카이빙한다. **코드 품질 판단·머지 결정은 본 명령어 영역이 아님** (reviewer/사람 영역).

본 명령어는 두 시점에 호출된다:

| 시점 | 모드 | 동작 |
|---|---|---|
| AI 게이트 PASS 직후, `gh pr create` 직전 (P10b-learning) | (기본) | educator 호출 → 두 산출물 동시 생성 |
| 머지 직후 (`/docs-update` 내부 자동 호출 또는 사용자 직접) | `--post` | LLM 호출 없음. archive.md → `gh api graphql` 으로 Discussions POST |

**LLM은 P10b 1회만, 사용자 로컬에서.** CI(GitHub Actions)에서 claude CLI 재호출은 ADR-0007 §2.5로 금지(보안·결정성·D-07 B1). 머지 후 처리는 이미 PR diff에 포함된 archive payload를 사용자 로컬 `gh-cli`로 단순 POST. 이로써:

- ANTHROPIC_API_KEY를 GitHub Secret에 보관하지 않음 (CLAUDE.md 보안 룰 1순위 정합)
- GitHub Actions workflow yml 자체 불필요 (D-07 B1 — 자체 런타임 0줄 정합)
- 머지 권한자 = Discussions 포스팅 권한자 (단일 사용자 흐름)
- 사람이 PR review 단계에서 archive 본문도 함께 검토 가능 (휴먼 게이트가 보호)
- 결정론적 — 같은 archive payload = 같은 Discussions 포스팅

## 사용 시점

| 시점 | 호출자 | 동작 |
|---|---|---|
| `/qa-test --ai` PASS 직후, `gh pr create` 직전 (P10b-learning) | flow-feature 내부 (자동) | 두 산출물 동시 생성 (educator 호출) |
| 머지 직후 | `/docs-update` 내부 (자동) 또는 사용자 직접 | `--post` 모드. LLM 없음 |

## 비블로킹 (ADR-0007 §2.6)

본 명령어는 본 하네스 유일의 비블로킹 Phase. 다음 4조건을 모두 충족하므로 비블로킹 허용:

1. 출력이 코드·테스트·머지 대상에 영향 없음
2. 실패가 안전·보안·정합성에 영향 없음
3. 명시적 timeout: **30초** (PRD Q-L-01 잠정)
4. 실패 시 PR body·flow-state.yaml에 audit 흔적

→ **실패해도 P11-pr-open(PR 자동 생성)은 정상 진행**.

## 입력

- `<slug>.ai-qa-report.md` — verdict=PASS 검증 필수. PASS 아니면 즉시 skip + `skipped_reason: "ai_qa_fail"`
- `git diff <base>..<head>` 출력
- 이슈 본문 (mode=sprint: `gh issue view <N>`)
- (선택) 다음 스프린트 이슈 — `scripts/sprint-bootstrap.sh` 완성 후 활성화 (R-L-08)

## 산출

### 1. `docs/planning/<slug>.learning-note.md` — PR body 삽입용

PRD R-L-03~08 정합 — 4개 섹션:

```markdown
## 📚 Learning Note (학습용 — 리뷰 대상 아님)

### 1. 핵심 개념 (R-L-04)
{{개념 ≤ 3개. 개념당 ≤ 5줄. diff 발췌 코드 예시. 전문 용어 부연 필수}}

### 2. 의사결정 이유 (why) (R-L-05)
{{선택 방법 + 선택 안 한 대안 비교 표}}

| 방안 | 채택? | 이유 |
|---|---|---|
| A. ... | ✅ | ... |
| B. ... | ❌ | ... |

### 3. 더 알고 싶다면 (R-L-07)
- 공식 문서: <URL>
- 검색 키워드: `keyword1` `keyword2`

### 4. 이 패턴 다음에 또 나올 곳 (R-L-08, 조건부)
{{다음 스프린트 이슈가 있을 때만. 이슈 번호·제목·한 줄 예고. 없으면 섹션 생략}}
```

PR body 하단 `<!-- BEGIN/END LEARNING NOTE -->` 마커 사이에 자동 삽입. Test Plan 4블록과 시각 분리.

### 2. `docs/planning/learning/<slug>.archive.md` — Discussions 아카이브 payload

PR diff에 포함되어 머지와 함께 main에 들어간다. GitHub Action이 머지 후 본 파일을 읽어 Discussions에 POST한다.

```markdown
# {{이슈 제목 또는 PR 제목}}

> {{한 줄 요약 — 이 PR이 무엇을 했는가}}

## 핵심 개념
{{learning-note.md의 1번 섹션 동일}}

## 의사결정 이유
{{learning-note.md의 2번 섹션 동일}}

## 더 알고 싶다면
{{learning-note.md의 3번 섹션 동일}}

## 이 패턴 다음에 또 나올 곳 (조건부)
{{learning-note.md의 4번 섹션 동일}}

<!-- BEGIN PR COMMENTS -->
<!-- GitHub Action이 머지 시점에 PR 댓글 상위 5개를 단순 발췌하여 채움 (R-L-09) -->
<!-- END PR COMMENTS -->
```

**주의**: 본 파일은 LLM이 PR 생성 직전 1회 채운다. 머지 후 GitHub Action은:
- PR URL/머지 커밋/시각 머리말을 prepend
- PR 댓글 상위 5개를 `BEGIN/END PR COMMENTS` 마커 사이에 단순 발췌 삽입 (요약 X)
- Discussions `Learning Log` 카테고리에 POST

→ Action에 LLM 없음. claude CLI 호출 없음.

## 실행 단계 (P10b 단일 호출)

1. **AI 게이트 검증**: `ai-qa-report.verdict` 확인. PASS 아니면 skip + flow-state 갱신
2. **Timeout 설정**: 30초
3. **educator 에이전트 호출**: diff·이슈 본문 입력. 두 산출물 동시 생성
   - `docs/planning/<slug>.learning-note.md` (PR body 마커 사이 삽입용)
   - `docs/planning/learning/<slug>.archive.md` (PR diff 포함, GitHub Action이 머지 후 사용)
4. **휴리스틱 체크** (간이 evaluator):
   - 두 파일 모두 작성됨
   - 4개 섹션 존재 (조건부 4번 제외)
   - 핵심 개념: 코드 예시 포함
   - 의사결정: 비교 표 존재
   - 참고 자료: URL ≥ 1개
   - archive.md 끝에 `<!-- BEGIN/END PR COMMENTS -->` 마커 존재
5. **flow-state.yaml 갱신**:
   ```yaml
   artifacts:
     learning_note:
       path: "docs/planning/<slug>.learning-note.md"
       archive_path: "docs/planning/learning/<slug>.archive.md"
       exists: true
       generated_at: <now>
       skipped_reason: null
   ```
6. **P11-pr-open으로 진행**: PR body 마커 사이에 `learning-note.md` 내용 삽입. `archive.md`는 PR diff에 자연스럽게 포함되어 머지와 함께 main에 들어간다.

## 실행 단계 (`--post` 모드, 머지 후)

**전제**: 머지 직후 사용자 로컬 작업 디렉토리. `/docs-update` 내부에서 자동 호출되거나 사용자가 직접 호출. LLM 호출 없음 — `gh-cli` 호출 시퀀스만 수행.

1. **archive payload 위치 확인**:
   ```bash
   PAYLOAD=$(ls docs/planning/learning/*.archive.md 2>/dev/null | head -n 1)
   if [ -z "$PAYLOAD" ]; then
     echo "archive payload 없음 — 본 PR은 educator skip된 상태. 정상 종료"
     exit 0
   fi
   ```

2. **PR 메타데이터 머리말 prepend**:
   ```bash
   PR_NUMBER=$(gh pr view --json number --jq .number)   # 또는 인자로 받음
   PR_URL=$(gh pr view "$PR_NUMBER" --json url --jq .url)
   MERGE_SHA=$(gh pr view "$PR_NUMBER" --json mergeCommit --jq .mergeCommit.oid)
   {
     echo "> **원본 PR**: $PR_URL"
     echo "> **머지 커밋**: \`$MERGE_SHA\`"
     echo "> **머지 시각**: $(TZ=Asia/Seoul date +"%Y-%m-%dT%H:%M:%S KST")"
     echo ""
     echo "---"
     echo ""
     cat "$PAYLOAD"
   } > "$PAYLOAD.tmp" && mv "$PAYLOAD.tmp" "$PAYLOAD"
   ```

3. **PR 댓글 상위 5개를 단순 발췌 (R-L-09)** — `<!-- BEGIN/END PR COMMENTS -->` 마커 사이 채움. LLM 요약 없음:
   ```bash
   COMMENTS=$(gh api "repos/{owner}/{repo}/issues/$PR_NUMBER/comments" \
     --jq '[.[] | select(.user.login != "github-actions[bot]") |
            {author: .user.login, body: (.body | split("\n")[0] | .[0:200])}] |
            sort_by(.body | length) | reverse | .[0:5]')
   # archive.md의 마커 사이에 echo "$COMMENTS" | jq -r ... 삽입
   ```

4. **Discussion 카테고리 ID 조회** (`Learning Log`):
   ```bash
   CAT_ID=$(gh api graphql -f query='
     query($owner:String!,$name:String!){repository(owner:$owner,name:$name){
       discussionCategories(first:25){nodes{id name}}}}' \
     -F owner=... -F name=... \
     --jq '.data.repository.discussionCategories.nodes[]
           | select(.name=="Learning Log") | .id')
   if [ -z "$CAT_ID" ]; then
     echo "Discussion category 'Learning Log' 없음 — 운영자가 1회 생성 필요 (PRD Q-L-03). skip"
     exit 0
   fi
   ```

5. **Discussions에 POST**:
   ```bash
   gh api graphql -f query='
     mutation($repo:ID!,$cat:ID!,$title:String!,$body:String!){
       createDiscussion(input:{repositoryId:$repo,categoryId:$cat,title:$title,body:$body}){
         discussion{url}}}' \
     -F repo=... -F cat="$CAT_ID" \
     -F title="[PR #$PR_NUMBER] $(gh pr view $PR_NUMBER --json title --jq .title)" \
     -F body="$(cat $PAYLOAD)" \
     --jq '.data.createDiscussion.discussion.url'
   ```

6. **실패 시**: 비블로킹 — `echo "Discussions POST 실패 (사유: ...). PR은 이미 머지됨. 비블로킹"` 후 정상 종료. archive.md는 main 브랜치에 보존되어 있어 사용자가 수동 재시도 가능.

> **카테고리 ID 자동 캐시**: 첫 호출 시 `.claude/state/discussion-category.json` 등에 저장하여 매 머지마다 GraphQL 호출 1회 절감 가능 (선택).

## 실패 처리 (비블로킹)

| 상황 | 처리 |
|---|---|
| AI 게이트 verdict ≠ PASS | skip, `skipped_reason: "ai_qa_fail"`, archive.md 미생성 |
| 30초 timeout | skip, `skipped_reason: "timeout"` |
| educator 에이전트 오류 | skip, `skipped_reason: "<error_summary>"` |
| 휴리스틱 체크 실패 | skip, `skipped_reason: "schema_violation"` |

모든 실패 시 PR body 마커 사이에 한 줄 표기:

```
## 📚 Learning Note (학습용 — 리뷰 대상 아님)
> Learning Note 생성 실패 (사유: <skipped_reason>). PR 진행에는 영향 없음.
```

archive.md가 없으면 GitHub Action도 자동 skip(`::notice::archive payload 없음`). → P11-pr-open으로 정상 진행.

## 완료 조건

| 모드 | 완료 조건 |
|---|---|
| 기본 (P10b) | 두 파일 모두 작성 또는 audit 흔적 + flow-state 갱신. archive.md 끝에 `<!-- BEGIN/END PR COMMENTS -->` 마커 존재 |
| `--post` (머지 후) | Discussions URL 출력 또는 skip 사유 출력 (재시도 큐 없음, best-effort 1회) |

## Strict Rules

- **AI 게이트 미통과 코드에 호출 금지** — PRD R-L-02. educator가 잘못된 코드 패턴을 가르치는 것을 방지
- **PR 생성·머지를 블로킹하지 않음** — ADR-0007 §2.6
- **코드 품질 판단·승인 권한 없음** — reviewer 영역. 본 명령어가 발화하면 BLOCKED
- **GitHub Actions·CI에서 LLM 호출 금지** — ADR-0007 §2.5. P10b 생성은 사용자 로컬 1회, `--post`는 LLM 없는 gh-cli 시퀀스
- **`--post` 모드에서 LLM 호출 금지** — 본 모드는 ANTHROPIC_API_KEY 없이도 동작해야 함 (gh-cli만 사용)

## Artifact Binding

- 입력 (기본): ai-qa-report (PASS), 코드 diff, 이슈 본문
- 출력 (기본): `<slug>.learning-note.md` + `<slug>.archive.md` → P11-pr-open(PR body 첨부 + diff 포함)
- 입력 (`--post`): main에 머지된 archive.md, 머지된 PR 메타데이터, PR 댓글 스레드
- 출력 (`--post`): Discussions `Learning Log` 카테고리 포스트 URL
