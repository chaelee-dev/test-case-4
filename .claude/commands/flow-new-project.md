---
description: One-shot wrapper for NEW_PROJECT — sequentially invokes /flow-init → /flow-design → /flow-wbs → /flow-bootstrap with confirmation between. Use this when you want to bootstrap a fresh codebase in a single command. For step-by-step review, call the 4 phase metas individually (recommended for newcomers).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /flow-new-project — 4단계 메타 일괄 호출자

> **ADR-0016 §2.3**: `/flow-new-project`는 **4 Phase 메타의 일괄 호출자**로 보존된다. 한 번에 끝내고 싶은 사용자용. **단계별 검토를 명시화하려면 4 Phase 메타를 개별 호출 권장** (QUICK-START.md 참조).

## 본 메타가 하는 일

4 Phase 메타를 *순차 자동 호출*하면서 사이마다 사용자 컨펌을 요청:

```
사용자: /flow-new-project "<RFP 또는 자연어 의도>"
   │
   ▼
[1/4] /flow-init      → 01~05 (의도·요구)
   ▶ ✋ Gate A·B 컨펌
   │
   ▼
[2/4] /flow-design    → 06~12 (HLD·LLD·규약·검증)
   ▶ ✋ Gate C 컨펌
   │
   ▼
[3/4] /flow-wbs       → 14·13 (리스크·WBS)
   ▶ ✋ WBS 검수 컨펌
   │
   ▼
[4/4] /flow-bootstrap → git + PR + sprint-bootstrap
   ▶ ✋ dry-run 후 실 등록 승인
   │
   ▼
mode=sprint 전환 → /flow-feature #N로 이어서
```

= 사용자 입력 1회(RFP) + 컨펌 4회. 기존 v0.7.10까지의 흐름과 동일.

## 언제 4 Phase 분리 호출 vs 일괄 호출자?

| 상황 | 권장 |
|---|---|
| 신규 도입자, 흐름 이해 중 | 4 Phase 분리 호출 (`/flow-init` → 검토 → `/flow-design` → …) |
| 단계별 산출 검토를 명시적으로 하고 싶음 | 4 Phase 분리 호출 |
| 특정 Phase만 재실행 필요 | 4 Phase 분리 (예: `/flow-design`만 재호출) |
| 툴킷에 익숙, 빠르게 진행 원함 | `/flow-new-project` 일괄 호출 |
| dogfooding·예제 데모 | `/flow-new-project` 일괄 호출 |

## 자동화 범위

- **자동**: 4 Phase 메타 순차 호출 + 사이마다 사용자 컨펌 프롬프트 + 마지막에 `/flow-feature` 안내
- **수동**: Gate A·B 컨펌(Phase 1 후), Gate C 컨펌(Phase 2 후), WBS 검수(Phase 3 후), sprint-bootstrap 실 등록 승인(Phase 4 안) — **총 4회**
- **범위 밖**: 무인 야간 자동 재개 (docs/planning/open-items.md O-01 영역)

## 사용 시점

- 빈 저장소 또는 PLAN.md만 있는 상태
- RFP / PRD / 자연어 어느 형태든 입력 가능
- 산출 `docs/planning/01~14/` + `adr/`이 미완 상태

## 기존 산출물 처리 (Idempotency, 재실행 시)

각 Phase 메타가 자체적으로 Idempotency 정책 적용 (ADR-0004 §2.5):

| 기존 상태 | 동작 |
|---|---|
| 파일 부재 | NEW → 정상 생성 |
| `v0.x` DRAFT + 분량 권고 준수 | 사용자에게 `[k]eep / [r]egen / [m]erge` 묻기, 기본 keep |
| `v0.x` DRAFT + 분량 초과 | 폴더 분할 권고 + Phase BLOCKED |
| `v1.0+` 정식 | BLOCKED — `--force-regenerate` 또는 ADR로만 |

### 일괄 옵션 (모든 Phase 메타에 전파)

| 옵션 | 의미 |
|---|---|
| `--force-regenerate` | 모든 DRAFT를 묻지 않고 regen (RELEASED는 여전히 BLOCKED) |
| `--keep-existing` | 모든 기존 파일 keep, NEW만 생성 |
| `--from-phase=<1\|2\|3\|4>` | 특정 Phase부터 재진입 (이전 Phase는 SKIP) |

## Phase Sequence (4 메타 순차 자동 호출)

```
0. /context-loader            (현재 위치 + mode 자동 감지)

─── Phase 1/4 ─────────────────────────────
1. (자동) /flow-init "<RFP>"  → 01~05 폴더 5개
   ▶ 사용자: Gate A·B 컨펌 입력 (팀장 OK + 팀 합의)

─── Phase 2/4 ─────────────────────────────
2. (자동) /flow-design        → 06~12 폴더 7개 + /plan-eng-review PASS
   ▶ 사용자: Gate C 컨펌 입력 (개발팀 검토)

─── Phase 3/4 ─────────────────────────────
3. (자동) /flow-wbs           → 14·13 폴더 2개
   ▶ 사용자: WBS 검수 컨펌

─── Phase 4/4 ─────────────────────────────
4. (자동) /flow-bootstrap     → git + PR + sprint-bootstrap dry-run
   ▶ 사용자: 실 등록 승인
   (자동, 승인 후) sprint-bootstrap 실 실행 → mode=sprint 전환

─── Sprint 1+ 안내 ─────────────────────
✅ NEW_PROJECT 완료. /flow-feature #<이슈번호>로 이어서.
```

## 입력

- 사용자 자연어 입력: RFP 전문 / PRD 초안 / 1줄 의도
- (있으면) `docs/planning/INDEX.md`, `docs/planning/_brainstorm/<slug>.md`

## 산출물

- **`docs/planning/`** 14개 폴더 + `adr/` (각 폴더에 `INDEX.md` 자동)
- **git**: 신규 브랜치 + Planning 단일 커밋 + Planning PR
- **GitHub**: Milestones (Sprint 1..N) + Issues (이슈 8필드) + Labels 20종 + Projects v2 items

## 완료 조건

- [ ] 4 Phase 메타 모두 PASS (각 메타의 완료 조건 충족)
- [ ] `/plan-eng-review` 게이트 C PASS (Phase 2 내부)
- [ ] sprint-bootstrap 실 실행 exit 0 (Phase 4 내부)
- [ ] flow-state.yaml `mode: sprint`로 전환
- [ ] GitHub `gh issue list --milestone "Sprint 1"` 정상 출력

## 다음 단계

```
mode=sprint 전환 완료
   ▼
/flow-feature #<이슈번호>      (이슈마다 반복)
   → 이슈 1개씩 끝까지 (계약 → 구현 → 리뷰 → 테스트 → PR 머지)
```

## BLOCKED 케이스

각 Phase 메타의 BLOCKED를 그대로 전파 + 일괄 호출자 차원의 케이스:

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: Phase N 사용자 컨펌 미입력` | 사이 컨펌 대기 중 비-TTY | 직접 4 Phase 메타 분리 호출 |
| `BLOCKED: --from-phase=N의 N-1 산출 부재` | 재진입 검증 실패 | `--from-phase=<더 앞>` 지정 또는 분리 호출 |
| (기타) | 각 Phase 메타의 BLOCKED | 해당 메타 단독 호출로 진단 |

## Strict Rules

- **사용자 컨펌 없이 다음 Phase 진행 금지** — 4회 컨펌이 본 메타의 안전망
- **외부 GitHub 쓰기는 dry-run 후 한 번 더 명시 승인** (Phase 4 내부)
- **재실행 시 RELEASED 상태(v1.0+) 산출 덮어쓰기 금지** — `--force-regenerate` 또는 ADR로만

## Artifact Binding

- 입력: 사용자 자연어 의도
- 출력: → `/flow-feature`의 입력 환경 (mode=sprint, GitHub Issues 등록 완료)

## 트리거 매칭

- "프로젝트 시작", "RFP 던질게", "/flow-new-project", "한 번에 다 끝내기"
- 자연어: "처음부터 끝까지 자동으로 진행해줘"

## 4 Phase 메타 단독 호출 (분리 호출 — 권장)

신규 도입자는 다음 4개를 차례로 호출 권장 (각 단계 검토 명시화):

| 단계 | 명령어 | 산출 |
|---|---|---|
| 1 | `/flow-init "<RFP>"` | 01~05 |
| 2 | `/flow-design` | 06~12 |
| 3 | `/flow-wbs` | 14·13 |
| 4 | `/flow-bootstrap` | GitHub 등록 |

각 단계 끝에 산출 검토 후 다음 호출. 자세한 흐름은 [QUICK-START.md](../../QUICK-START.md) 참조.
