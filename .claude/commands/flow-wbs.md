---
description: Phase 3/4 of NEW_PROJECT — risk identification and WBS breakdown. Use this after /flow-design and human review of 06~13. Produces 15·14 outputs. Hand off to /flow-bootstrap after human review of WBS.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /flow-wbs

## 목적

NEW_PROJECT **Phase 3/4** — 운영 산출(15 Risk · 14 WBS, ADR-0031 재할당). 설계 통과 후 작업 분해. 끝에 사용자 WBS 검수 후 `/flow-bootstrap`으로 명시 호출.

> **ADR-0016 §2.1**: 4단계 분리의 세 번째. 본 메타 단독으로는 GitHub 등록 안 함 — WBS 산출 검수까지만.
> **ADR-0031**: 1수준 +1 재할당으로 13→14(WBS), 14→15(Risk). 본 메타 산출 번호 갱신.
> **명명 주의**: 본 메타 `/flow-wbs`는 NEW_PROJECT Phase 3 진입점. 산출 Command `/wbs`(14-wbs 단독 작성)와 *다른 계층*. flow-wbs가 risk + wbs를 일괄 호출.

## 사용 시점

- `/flow-design` 완료 + 사용자 Gate C 검토 OK
- 06~13 산출 모두 v0.1+ + `/plan-eng-review` PASS 상태
- 14·15 산출이 미존재 또는 DRAFT

## 산출 (2건)

| # | 산출 | layer | 위치 |
|---|---|---|---|
| 15 | Risk | 운영 | `15-risk/15-risk.md` |
| 14 | WBS | 운영 | `14-wbs/14-wbs.md` |

**순서 주의**: 리스크 인지 *후* WBS 분해 (리스크가 우선순위 보정 입력). 14가 마지막 산출.

## Phase Sequence (내부 자동 호출)

```
0. (자동) /context-loader 입력 검증
   - 06~13 폴더 + 메인 파일 + INDEX.md 모두 존재?
   - /plan-eng-review PASS 흔적 (적어도 1회 호출)?
   - 아니면 BLOCKED: "/flow-design 미통과 — 먼저 호출하세요"

─── 운영 산출 ─────────────────────────
1. (자동) /risk-check (mode=planning)
                                  → 15-risk/15-risk.md
                                    (시스템 차원 리스크 식별·완화·등급·Rollback trigger)

2. (자동) /wbs (신규 작성 모드)
                                  → 14-wbs/14-wbs.md
                                    - 스프린트(Milestone) → 이슈(1~3일) 2계층 분해
                                    - 이슈 8필드 강제 (Acceptance/Contract/Effort/DoD + 매핑)
                                    - §7 sprint-bootstrap YAML 자동 채움
                                    - 04·05 R-ID/F-ID 100% 매핑 BLOCK

─── 휴먼 게이트 (본 메타 끝) ──────────────
▶ 사용자 검수: 15·14 산출 OK?
   - 15 Risk 식별 누락 없는가 (외부 의존·성능·보안·운영 7카테고리)
   - 14 WBS 스프린트당 이슈 수 5~15
   - 각 이슈 추정 1~3 working days 이내
   - SRS R-ID·PRD F-ID가 모두 1개 이상 이슈에 매핑됨
   - DAG 순환 없음
   - 의존성(Blocked-by) 명시
▶ OK면 다음 메타 호출: /flow-bootstrap
```

## 입력

- `docs/planning/01~13/` 13개 폴더 (`/flow-design` 통과 산출)
- 누락 시 BLOCKED + `/flow-design` 호출 안내

## 완료 조건

- [ ] 15-risk/15-risk.md 존재 + validate-doc.sh 통과
- [ ] 14-wbs/14-wbs.md 존재 + validate-doc.sh 통과
- [ ] 14 §1 스프린트 일람 표 BLOCK 충족
- [ ] 14 §4 추적성 매트릭스 — SRS R-ID·PRD F-ID 100% 커버
- [ ] 14 §7 sprint-bootstrap YAML 작성 (sprints: + project: 둘 다)
- [ ] 모든 이슈 8필드(Acceptance/Contract Before·After/Effort/DoD) 충족

## 다음 메타

```
사용자 WBS 검수 OK
   ▼
/flow-bootstrap
   → Phase 4/4: git commit + PR + sprint-bootstrap dry-run → GitHub 실 등록
```

## BLOCKED 케이스

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: /flow-design 미통과` | 06~13 산출 부재 | `/flow-design` 먼저 |
| `BLOCKED: R-ID/F-ID 미매핑 — R-XX` | WBS가 SRS R-ID 누락 | 이슈 신설 또는 PRD에서 Out 처리 |
| `BLOCKED: 이슈 추정 초과 — Issue X (>3d)` | 이슈 비대 | 더 잘게 분해 |
| `BLOCKED: DAG 순환 — A↔B` | 의존성 순환 | 분해 재구성 또는 ADR |
| `BLOCKED: 이슈 템플릿 필드 누락 — Acceptance/Contract/Effort/DoD 중 X` | 8필드 미충족 | 보강 (ADR-0008 §2.3) |
| `BLOCKED: sprint-bootstrap YAML 부재` | 14 §7 미작성 | `/wbs` 재실행으로 YAML 자동 채움 |

## Strict Rules

- **본 메타 안에서 sprint-bootstrap 실행 안 함** — 외부 GitHub 쓰기는 `/flow-bootstrap` 책임 (단계 명확화)
- **15·14 둘 다 v0.1+ DRAFT 상태로 충분** — v1.0+ Accepted는 사용자가 WBS 검수 후 결정
- **다음 Phase 메타 호출은 사용자가 명시** — 자동 진행 안 함

## Artifact Binding

- 입력: `/flow-design` 산출 (06~13)
- 출력: → `/flow-bootstrap`의 입력 (14 §7 YAML 특히 중요)

## 트리거 매칭

- "WBS 분해", "스프린트 분해", "리스크 점검 + WBS", "/flow-wbs"
- 자연어: "작업 분해", "이슈 분해할게", "스프린트 짜자"
