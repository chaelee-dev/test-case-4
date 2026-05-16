---
description: Phase 1/4 of NEW_PROJECT — initialize intent and requirements (Gate A + B). Use this when starting a new project from RFP / PRD / natural language. Produces 01·02·03·04·05 outputs. Hand off to /flow-design after human review.
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch
---

# /flow-init

## 목적

NEW_PROJECT **Phase 1/4** — 의도와 요구사항 산출까지. Gate A(팀장 컨펌)와 Gate B(팀 합의)를 한 메타에서 일괄. 끝에 사용자 검토 후 다음 메타(`/flow-design`)로 명시 호출.

> **ADR-0016 §2.1**: `/flow-new-project`를 4단계로 분리한 첫 단계. 본 메타 단독으로는 *설계까지 진행 안 함* — 의도·요구만 산출하고 검토.

## 사용 시점

- 빈 저장소 또는 PLAN.md만 있는 상태에서 시작
- RFP / PRD / 자연어 어느 형태든 입력 가능
- 산출 `docs/planning/01~05/`가 미존재 또는 DRAFT

## 산출 (5건, 폴더 강제 ADR-0015)

| # | 산출 | 위치 | layer | 게이트 |
|---|---|---|---|---|
| 01 | Project Brief | `docs/planning/01-project-brief/01-project-brief.md` | 의도 | A |
| 02 | Feasibility | `docs/planning/02-feasibility/02-feasibility.md` | 의도 | A |
| 03 | User Scenarios | `docs/planning/03-user-scenarios/03-user-scenarios.md` | 요구 | B |
| 04 | SRS | `docs/planning/04-srs/04-srs.md` (분량 초과 시 도메인 분할) | 요구 | B |
| 05 | PRD | `docs/planning/05-prd/05-prd.md` (분량 초과 시 영역 분할) | 요구 | B |

각 폴더에 `INDEX.md` 자동 생성 (`scaffold-doc.sh`).

## Phase Sequence (내부 자동 호출)

```
0. /context-loader                          (현재 위치 + mode 감지)

─── Gate A (팀장 컨펌) ──────────────────────
1. (자동, 옵션) /intention-brief --brainstorm
                                           → docs/planning/_brainstorm/<slug>.md (의도 모호 시)
2. (자동) /intention-brief                 → 01-project-brief/01-project-brief.md
3. (자동, 필수, ADR-0013) /intention-brief --mode=feasibility
                                           → 02-feasibility/02-feasibility.md (≤ 1장)

─── Gate B (팀 합의) ──────────────────────
4. (자동) /ux-flow-design (시나리오 모드)   → 03-user-scenarios/03-user-scenarios.md
5. (자동) /srs                              → 04-srs/04-srs.md
                                              (R-ID + 3축 BLOCK: 테스트 레벨/Happy/Failure, ADR-0014)
6. (자동) /prd                              → 05-prd/05-prd.md
                                              (F-ID + MVP Cut + 3축 BLOCK)

─── 휴먼 게이트 (본 메타 끝) ──────────────
▶ 사용자 검토: 01·02·03·04·05 5개 폴더 산출 OK?
   - 의도가 RFP와 정합한가
   - R-ID·F-ID 카탈로그 누락 없는가
   - 각 R-ID/F-ID에 검증 시나리오(Happy + Failure) 작성됐는가
   - 팀장·팀 합의 통과 가능 상태인가
▶ OK면 다음 메타 호출: /flow-design
```

## 입력

- 사용자 자연어 입력: RFP 전문 / PRD 초안 / 1줄 의도 (어느 형태든)
- (있으면) `docs/planning/_brainstorm/<slug>.md` (의도 모호 시 사전 brainstorm)
- (있으면) `docs/planning/INDEX.md` (툴킷 자체 작업 시)

## 완료 조건

- [ ] 01·02·03·04·05 폴더 5개 + 각 폴더에 메인 파일 + INDEX.md 존재
- [ ] 각 산출 `validate-doc.sh` 통과 (BLOCK 위반 0)
- [ ] 04 SRS R-ID 1개 이상, 05 PRD F-ID 1개 이상 (MVP Cut 명시)
- [ ] 각 R-ID/F-ID에 검증 시나리오 (Happy + Failure + 테스트 레벨) — ADR-0014
- [ ] 변경 이력 표 작성됨

## 다음 메타

```
사용자 검토 OK
   ▼
/flow-design
   → Phase 2/4: HLD·LLD·코드 규약·테스트 설계 (06~12)
```

## BLOCKED 케이스

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: 입력 의도 모호` | RFP/자연어 너무 짧거나 모호 | `--brainstorm` 모드 먼저 진입 |
| `BLOCKED: schema validate 실패 — 04-srs §<...>` | R-ID 시나리오 누락 등 | 해당 R-ID 보강 후 재실행 |
| `BLOCKED: 폴더 존재 + 정식 v1.0+` | 이미 합의 통과된 산출 | `--force-regenerate` 또는 ADR로만 |

## Strict Rules

- **Gate A·B 사용자 컨펌은 본 메타 *종료 후*에 일괄로**. 메타 내부 인터랙티브 컨펌은 *오류·BLOCKED 시*에만
- **다음 Phase 메타(`/flow-design`) 호출은 사용자가 명시 입력** — 본 메타가 자동 진행 안 함 (ADR-0016 §2.1 단계 분리 정신)
- **선행 산출이 *정식 v1.0+* 상태면 BLOCK** — `--force-regenerate`로만 덮어쓰기

## Artifact Binding

- 입력: 사용자 자연어 의도
- 출력: → `/flow-design`의 입력 (01~05 산출)

## 트리거 매칭

- "새 프로젝트 시작", "RFP 시작", "프로젝트 init", "기획 시작", "/flow-init"
- 자연어: "프로젝트 시작하자", "RFP 던질게", "처음부터"
