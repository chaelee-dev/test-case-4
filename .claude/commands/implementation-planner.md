---
description: Use this when the user has a contract but no implementation plan, asks for a step-by-step build plan, needs to break work into commits, or is about to write code without first deciding the order of operations. Also produces NEW_PROJECT design docs (06 Architecture, 07 HLD, 08 Module Spec, 09 API, 11 Conventions, 12 Scaffolding, 13 Test Design) via --mode flags (ADR-0031).
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /implementation-planner

## 목적
두 가지 산출을 모드 분기로 처리한다.

1. **(기본 — 모드 없음)** `change-contract`를 받아 **커밋 단위로 분해된 실행 계획**을 만든다. Generator가 무엇을, 어떤 순서로 할지 명시.
2. **(NEW_PROJECT 모드)** 게이트 C 산출 문서 7종(06·07·08·09·11·12·13)을 모드 분기로 작성한다 (ADR-0004 + ADR-0031).

## 모드 (NEW_PROJECT, ADR-0004)

> 단계 ↔ 모드 매핑은 [`docs/planning/conventions/foldering-rules.md`](../../docs/planning/conventions/foldering-rules.md) §2 정본. 분할 시 INDEX.md 의무는 [`file-numbering.md`](../../docs/planning/conventions/file-numbering.md). 산출 schema 강제는 [`document-manifest.md`](../../docs/planning/conventions/document-manifest.md) + ADR-0010.

| 모드 | doc_type | 산출 파일 | 입력 |
|---|---|---|---|
| `--mode=architecture` | `architecture` | `docs/planning/06-architecture/06-architecture.md` | 04 SRS · 05 PRD |
| `--mode=hld` | `hld` | `docs/planning/07-hld/07-hld.md` (ADR-0031 신설) | 06 Architecture · 04 SRS · 05 PRD |
| `--mode=module --domain=<x>` | `module-spec` | `docs/planning/08-lld-module-spec/08-lld-module-spec.md` (또는 도메인 분할 `08-lld-module-spec/<domain>/`) | 07 HLD · 04 SRS · 05 PRD |
| `--mode=api` | `api-spec` | `docs/planning/09-lld-api-spec/09-lld-api-spec.md` | 07 HLD · 08 module-spec |
| `--mode=conventions` | `coding-conventions` | `docs/planning/11-coding-conventions/11-coding-conventions.md` | 06 Architecture · stack 결정 |
| `--mode=scaffold --lang=<lang>` | `scaffolding` | `docs/planning/12-scaffolding/<lang>.md` (평면 명명, §3.2) **+ newProject 루트 `LOCAL.md` 본문 §2·§3·§4 동시 채움 (ADR-0040)** | 06 Architecture · 07 HLD |
| `--mode=test` | `test-design` | `docs/planning/13-test-design/` (5절 폴더 자동 골격, ADR-0014·0015·**0030**) | 04·05 시나리오 MUST · 07 HLD |
| **(모드 없음, default)** | **context 자동 분기** — 아래 §0.1 결정 트리 | — | — |

> **`--lang` 필수 (mode=scaffold 전용)** — 미지정 시 BLOCKED. 다국어 스택은 언어별로 반복 호출.
> **`--mode=scaffold`는 LOCAL.md 동시 채움 (ADR-0040)** — install.sh가 newProject 루트에 카피한 `LOCAL.md` 빈 골격의 본문 §2 셋업·§3 profile별 부팅 명령·§4 자산 표를 같은 단계에서 채운다. 12-scaffolding §7(SoT)과 LOCAL.md(유저 facing)는 매 PR 동기 진화 — AI 게이트 6번째 축이 `local_runnability.must_contain.LOCAL.md 동기` BLOCK으로 강제.
> **`--domain` 권고 (mode=module 분할 시)** — 산출 직후 `.claude/scripts/gen-index.sh docs/planning/08-lld-module-spec/<domain>/` 자동 호출하여 INDEX.md 갱신.
> **폴더 자동 생성 (ADR-0015)** — scaffold-doc.sh가 출력 경로의 부모 폴더 + INDEX.md 자동 생성.
> **--mode=architecture는 §Stack Decision 박스 강제** — foldering-rules §3 + `architecture.schema.yaml` 정합. 박스 부재 시 `validate-doc.sh` BLOCK + `/plan-eng-review` BLOCKED.
> **--mode=hld는 §1 모듈 표 강제 (ADR-0031)** — `hld.schema.yaml`의 §1 핵심 모듈/컴포넌트 표가 BLOCK. 08 Module Spec(LLD)이 본 §1 표 행에서 fan-out.

## §0.1 default 동작 — context 자동 분기

인자 없이 호출된 경우 다음 결정 트리로 동작 분기.

```
/implementation-planner                       (인자 없음)
    │
    ▼
┌── 1. FEATURE context ── docs/features/<slug>/<slug>.contract.md 존재? ──┐
│                                                                        │
│ YES → mode=feature-plan                                                │
│        - 입력: <slug>.contract.md                                       │
│        - 산출: docs/features/<slug>/<slug>.plan.md                      │
│        - (기존 동작 유지)                                                │
│                                                                        │
│ NO  → 2단계로                                                            │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌── 2. NEW_PROJECT 게이트 C context ── 04-srs.md 존재 + 06~13 중 일부 미작성? ┐
│                                                                          │
│ YES → mode=all (게이트 C 일괄 — implementation-planner 책임 7건)            │
│        순차 자동 호출:                                                     │
│        ① --mode=architecture → 06-architecture.md                         │
│        ② --mode=hld          → 07-hld.md (ADR-0031 신설)                  │
│        ③ --mode=module       → 08-lld-module-spec.md (도메인 분할 자동 감지)    │
│        ④ --mode=api          → 09-lld-api-spec.md                             │
│        ⑤ --mode=conventions  → 11-coding-conventions.md                   │
│        ⑥ --mode=scaffold     → 12-scaffolding/<lang>.md                   │
│                              (06 §Stack Decision에서 lang 자동 추출 후 반복)│
│        ⑦ --mode=test         → 13-test-design/ (5절 폴더 자동, ADR-0030)   │
│        ※ 10 Screen Design은 본 Command 영역 아님 — /ux-flow-design이 별도 처리 │
│        ※ 기존 산출은 keep (ADR-0004 §2.5 Idempotency). --force-regenerate로 override │
│                                                                          │
│ NO  → 3단계로                                                              │
└───────────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌── 3. context 모호 ────────────────────────────────────────────────────────┐
│                                                                          │
│ BLOCKED — "context 자동 감지 실패. 다음 중 하나로 명시 호출:               │
│    - FEATURE: /implementation-planner --mode=feature-plan (또는 --slug=<x>) │
│    - NEW_PROJECT 일괄: /implementation-planner --mode=all                 │
│    - 개별 산출: /implementation-planner --mode=architecture|hld|module|api|... │
│ "                                                                        │
└──────────────────────────────────────────────────────────────────────────┘
```

### `--mode=all` 명시 호출 (선택적, default와 동일 동작)

`--mode=all`은 default의 NEW_PROJECT 분기를 **명시적으로 강제**한다. FEATURE context에서도 NEW_PROJECT 일괄을 실행하고 싶을 때(드물지만) 사용. `/flow-new-project`는 default 또는 `--mode=all` 어느 쪽으로 호출해도 동일.

### default 동작 흐름 (mode=all일 때)

```bash
# 본 Command 안에서 7개 모드 순차 자동 호출 (각각 scaffold-doc.sh → 작성 → validate-doc.sh)
for MODE in architecture hld module api conventions scaffold test; do
  # 기존 산출 존재 시 keep (ADR-0004 §2.5)
  [ -f $(target_path_of_$MODE) ] && { echo "[KEEP] $MODE 산출 존재 — 건너뜀"; continue; }

  # mode=scaffold는 06 §Stack Decision에서 lang 자동 추출하여 언어별 반복
  if [ "$MODE" = "scaffold" ]; then
    LANGS=$(extract_langs_from_architecture)
    for L in $LANGS; do
      bash .claude/scripts/scaffold-doc.sh scaffolding "docs/planning/12-scaffolding/$L.md"
      # ... 작성 + validate
    done
  else
    bash .claude/scripts/scaffold-doc.sh "<doc_type_of_$MODE>" "<output_path>"
    # ... 작성 + validate
  fi
done

# 산출 직후 분할 폴더 INDEX.md 자동 갱신
bash .claude/scripts/gen-index.sh docs/planning/08-lld-module-spec/  # 분할 시
bash .claude/scripts/gen-index.sh docs/planning/12-scaffolding/  # 다국어 시
```

## Schema 강제 (ADR-0010)

각 모드 산출은 다음 흐름:

```bash
# 1. schema에서 빈 골격 생성
bash .claude/scripts/scaffold-doc.sh <doc_type> <output_path>

# 2. 입력 산출(SRS/PRD/HLD 등)에서 추출한 내용으로 채움 + Stack Decision 박스(mode=hld) + R-ID/F-ID 매핑

# 3. schema 검증
bash .claude/scripts/validate-doc.sh <output_path>

# 4. (mode=module/scaffold 분할 시) INDEX.md 갱신
bash .claude/scripts/gen-index.sh <분할 폴더>
```

BLOCK 위반 시 `/plan-eng-review` 차단. schema: `.claude/schemas/<doc_type>.schema.yaml`.

## 사용 시점
- **default (인자 없음)**: context 자동 감지
  - FEATURE 이슈 작업 (contract 작성 직후) → feature-plan
  - NEW_PROJECT 게이트 C 진입 시점 (04 SRS 통과, 06~13 부분 또는 전체 미작성) → 7건 일괄
- 개별 모드 호출 (`--mode=architecture|hld|module|api|conventions|scaffold|test|feature-plan`): 특정 산출만 재생성

## 입력
- **default — FEATURE 분기**: `<slug>.contract.md` (필수) + 기존 코드베이스 인벤토리(있으면) + **contract §0 Referenced-IDs 기반 selective read (ADR-0018)** — 아래 §0.2 알고리즘 참조
- **default — NEW_PROJECT 분기**: `04-srs.md`·`05-prd.md` (필수). 이미 작성된 06~13 산출은 keep
- **개별 모드**: 위 §0 모드 표의 입력 문서 컬럼 참조

## §0.2 FEATURE 분기 — Referenced-IDs 기반 selective read (ADR-0018)

contract.md를 읽은 직후, §0 표를 파싱해 LLD 정본 본문을 *선택적으로* 입력 컨텍스트에 합류시킨다. 전체 06~12 자동 로드 X (분량 가드 + 분할 폴더 정합).

```
1. <slug>.contract.md §0 "참조 정본 ID (Referenced-IDs)" 표 파싱
2. 각 행의 [종류, 정본 위치, 영향 ID] 추출. 영향 ID가 "(none)"인 행은 skip
3. 행별 → 실제 파일 경로 매핑:

   ┌─ R-ID 행
   │   영향 ID "R-04, R-07" → docs/planning/04-srs/04-srs.md
   │   (분할 시: docs/planning/04-srs/<sub>.md 중 해당 R-ID가 포함된 sub만)
   │   Read → R-04·R-07 절만 발췌
   │
   ├─ F-ID 행
   │   영향 ID "F-12" → docs/planning/05-prd/05-prd.md (또는 분할 sub)
   │   Read → F-12 절만 발췌
   │
   ├─ 영향 모듈 행
   │   영향 ID "auth/session, billing/invoice" → docs/planning/08-lld-module-spec/auth/session.md, billing/invoice.md
   │   (08이 분할 폴더면 도메인별 파일을 직접 지정. 미분할이면 메인 08-lld-module-spec.md에서 해당 모듈 절 발췌)
   │   Read → 전체 (모듈 단위는 작아 발췌 불필요한 경우가 많음)
   │
   ├─ 영향 엔드포인트 행
   │   영향 ID "POST /api/v1/login" → docs/planning/09-lld-api-spec/09-lld-api-spec.md
   │   Read → 해당 엔드포인트 절만 발췌
   │
   └─ 적용 컨벤션 절 행
       영향 ID "§2 에러코드, §3 명명" → docs/planning/11-coding-conventions/11-coding-conventions.md
       Read → §2·§3 절만 발췌

4. 발췌된 본문을 plan 작성 시 입력 컨텍스트로 합류
5. plan.md 산출 시 "참조 정본 인용" 항목에 위 발췌 출처를 명시 (추적성)
```

### Strict Rules (FEATURE 분기)
- contract.md §0 표 누락 시 BLOCKED — `/change-contract` 회귀 (schema가 이미 BLOCK이므로 도달 안 함이 정상)
- §0 영향 ID 컬럼이 모두 "(none)"이면 WARN — mode 재판정 신호 (정말 06~12 어디도 안 건드리는 변경인가?)
- 정본 위치가 가리키는 실제 파일 부재 시 BLOCKED — 게이트 C 미통과 신호. `/flow-init`/`/flow-design` 회귀

## 산출물
- **default — FEATURE 분기**: `docs/features/<slug>/<slug>.plan.md`
- **default — NEW_PROJECT 분기**: `06-architecture.md` · `07-hld.md` · `08-lld-module-spec.md` · `09-lld-api-spec.md` · `11-coding-conventions.md` · `12-scaffolding/<lang>.md` · `13-test-design/` (5절 폴더, ADR-0030) (7건. 10 Screen Design은 /ux-flow-design이 별도 처리)
- **개별 모드**: 위 §0 모드 표의 산출 파일

## 문서 구조 — 기본 모드 (contract → plan)

```markdown
# Implementation Plan — <slug>

## 1. 작업 단위 (commit-sized)
| # | 작업 | 파일 | 단위 테스트 | 예상 시간 |
|---|---|---|---|---|
| 1 | 인터페이스 정의 | src/x.ts | x.test.ts | 30m |
| 2 | 구현 | src/x.ts | (확장) | 1h |
| ... |

## 2. 코딩 컨벤션 적용
- naming: <규칙>
- 테스트 파일 위치: <경로>
- 폴더 구조 변경 여부

## 3. 의존성 변경
- 신규 패키지: <목록>
- 버전 호환성 검토: <결과>

## 4. 단위 테스트 plan
- given / when / then
- happy path + 경계 케이스

## 5. 성능·보안 고려
- <항목>

## 6. 작업 순서 (DAG)
mermaid graph로 1→2→3 순서 표현
```

## 문서 구조 — NEW_PROJECT 모드별

### `--mode=architecture` → 06-architecture.md (Architecture 본체, ADR-0031)
0. **Stack Decision 박스 (강제)** — foldering-rules §3 정합. 단계 ① 언어 + ② 프레임워크 명시. 박스 부재 시 `/plan-eng-review` BLOCKED
1. 시스템 컨텍스트 (외부 의존·경계)
2. 컨테이너 구조 (배포 단위·런타임 경계)
3. 외부 시스템 / 경계 (선택)

### `--mode=hld` → 07-hld.md (HLD, 모듈 분해 정본, ADR-0031 신설)
1. 핵심 모듈 / 컴포넌트 표 (모듈·책임·의존·08에서 상세) — **BLOCK**
2. 모듈 간 데이터 흐름 (sequence·이벤트 흐름)
3. 비기능 대응 (비기능 R-ID → 대응 전략 매핑) — **BLOCK**
4. 외부 인터페이스 윤곽 (선택)

### `--mode=module` → 08-lld-module-spec.md ("문서만 보고 개발 가능" 수준)
1. 모듈 개요 (07 HLD §1 참조 BLOCK)
2. 외부 인터페이스
3. 내부 컴포넌트
4. 데이터 흐름
6. 에러 처리
8. 테스트 진입점

### `--mode=api` → 09-lld-api-spec.md (API 단위 점진)
1. 엔드포인트 (method·path·요약)
2. 요청·응답 스키마
3. 인증·권한·에러 케이스

### `--mode=conventions` → 11-coding-conventions.md
1. 명명 규칙 (camel/snake/Pascal — 변수·함수·파일·폴더)
2. 에러 코드 표준 (PREFIX·SUFFIX·범위)
3. 주석·포맷·lint 규칙 (가능한 한 lint·CI로 자동 강제)

### `--mode=scaffold --lang=<lang>` → 12-scaffolding/&lt;lang&gt;.md
1. 디렉토리 구조 + 패키지 구성 (MVC/DDD/FSD/Atomic 결정)
2. 파일 단위 적용 규칙 (파일당 책임·import 규칙)
3. 빌드·테스트 도구 + 표준 명령

### `--mode=test` → `docs/planning/13-test-design/` (5절 폴더 자동 골격, ADR-0030)

scaffold-doc.sh 폴더 분할 모드(`bash scaffold-doc.sh test-design docs/planning/13-test-design/`)로 다음 5개 sub-file이 일괄 골격 생성된다(INDEX.md 포함):

1. `01-strategy.md` — 테스트 전략 (TDD/BDD), 도구, 커버리지 목표 (≥ 80%)
2. `02-catalog.md` — 단위·통합·E2E **별 묶음 카탈로그** (ADR-0036): `## 1. 단위 / ## 2. 통합 / ## 3. E2E` 각 섹션에 04·05의 해당 레벨 시나리오를 R-/F-ID subsection으로 fan-in (한 시나리오가 여러 레벨이면 중복 인용) + `## 4. 레벨 매트릭스(R-/F-별 망라)`
3. `03-regression.md` — 회귀 테스트 정책
4. `04-performance.md` — 성능·보안 테스트
5. `05-delivery-format.md` — 고객 전달 포맷 (단위·통합·E2E 시나리오 일체)

각 sub-file은 변경 이력 §0 BLOCK + 자체 sections WARN 검증(ADR-0030 §2.3)에 더해 **ADR-0034로 sub-file 본문 BLOCK 강제**: 01-strategy(방법론·레벨·커버리지 ≥80%), 02-catalog(R-/F-ID fan-in ≥1건 + 출처 인용 + 매트릭스 ❌ 금지), 05-delivery-format(ID 채번 + 전달 시점). 빈 골격은 schema-level BLOCK으로 차단되어 `/plan-eng-review` 진입 불가. 02-catalog 섹션 구조는 **ADR-0036**으로 레벨별(단위·통합·E2E)로 재편(SI/QA 관행 정합).

## 실행 단계 — 기본 모드
1. contract 읽기
2. 변경할 파일 단위로 Subtask 분해 (커밋 1개 단위)
3. 각 Subtask에 단위 테스트 매핑
4. DAG로 의존성 표현
5. 시간 추정 → 1~3 working days 초과 시 이슈 분할 권고

## 실행 단계 — NEW_PROJECT 모드
1. 모드 + 입력 문서 검증 (없으면 BLOCKED)
2. 모드별 문서 구조에 따라 산출
3. 분량 권고 초과 시 폴더 분할 권고 (`<doc>/INDEX.md`)
4. 산출 직후 docs/planning/CHANGELOG.md §"Current Status" 진행 상황 갱신 권고

## 완료 조건
- (기본) 각 subtask가 atomic (단일 커밋 가능), 모든 변경 파일에 테스트 매핑, DAG 순환 없음, 추정 시간이 이슈 단위 범위
- (모드) 산출 파일 생성, 분량 권고 준수, 입력 문서 추적성(R-ID/F-ID 인용) 확보 (mode=test에서 특히 중요)

## Strict Rules
- (기본) **테스트 없는 subtask 금지**, 24시간 초과 추정 시 이슈 분할 권고
- (FEATURE 분기) **contract.md §0 미파싱 plan 금지 (ADR-0018)** — §0 부재면 `/change-contract` 회귀. 영향 ID로 selective read한 발췌를 입력으로 사용
- (모드=scaffold) `--lang` 미지정 시 BLOCKED
- (모드=hld) 06 Architecture 부재 시 BLOCKED — 06 §Stack Decision이 HLD 분해의 기반
- (모드=module) 07 HLD 부재 시 BLOCKED — 08은 07 §1 모듈 표의 fan-out (ADR-0031)
- (모드=conventions·scaffold) 06 Architecture 부재 시 BLOCKED
- (모드=test) 04 SRS·05 PRD 부재 시 BLOCKED (시나리오 fan-in 불가)

## 기존 산출물 처리 (Idempotency, NEW_PROJECT 모드 전용)

직접 호출(예: `/implementation-planner --mode=architecture`) 또는 `/flow-new-project` 자동 일괄 호출 모두에서 본 정책을 따른다. 자세한 정책은 [flow-new-project.md §기존 산출물 처리](flow-new-project.md) 참조.

| 기존 상태 | 동작 |
|---|---|
| 파일 부재 | 정상 생성 |
| 파일 존재 + DRAFT 마커(`v0.x`) | 사용자에게 `[k]eep / [r]egen / [m]erge` 묻기, 기본 keep |
| 파일 존재 + 정식 버전 (`v1.0+`) | BLOCKED — `--force-regenerate` 또는 ADR로만 |
| 파일 존재 + 분량 초과 | 폴더 분할 권고 + 본 호출 BLOCKED |

`--force-regenerate` / `--keep-existing` 일괄 옵션 동일 적용. `regen`·`merge` 시 기존 파일은 `docs/planning/_archive/<basename>.v<ver>.md`로 백업.

## Artifact Binding
- (기본) 입력: contract → 출력: `/plan-eng-review`, `/implement`
- (모드) 입력: 상류 산출 문서 → 출력: 게이트 C `/plan-eng-review`
