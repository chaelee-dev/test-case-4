---
description: Phase 2/4 of NEW_PROJECT — system design (Architecture + HLD + LLD + code conventions + test design). Use this after /flow-init and human review of 01~05. Produces 06·07·08·09·10·11·12·13 outputs (Gate C). Hand off to /flow-wbs after human review.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /flow-design

## 목적

NEW_PROJECT **Phase 2/4** — Gate C 산출 일괄 작성. Architecture(06) + HLD(07) + LLD 3종(08·09·10) + 코드 규약(11·12) + 테스트 설계(13) 8건을 한 메타에서 자동 호출. 끝에 사용자 검토 후 `/flow-wbs`로 명시 호출.

> **ADR-0016 §2.1**: 4단계 분리의 두 번째. `/flow-init` 산출(01~05)을 입력으로 받음. 본 메타 단독으로는 WBS·GitHub 등록 안 함.
> **ADR-0031**: 06을 Architecture 본체로 축소하고 07 HLD를 신설. 모듈 분해는 07로 이전, 08~13으로 +1 재할당.

## 사용 시점

- `/flow-init` 완료 + 사용자 Gate A·B 검토 OK
- 01~05 산출 5건 모두 v0.1+ DRAFT 또는 v1.0+ Accepted 상태
- 06~13 산출이 미존재 또는 DRAFT

## 산출 (8건, 폴더 강제 ADR-0015 + ADR-0031)

| # | 산출 | layer | 위치 |
|---|---|---|---|
| 06 | Architecture | **Architecture** | `06-architecture/06-architecture.md` (시스템·Stack·컨테이너 — ADR-0031로 축소) |
| 07 | HLD | **HLD** | `07-hld/07-hld.md` (§1 모듈 분해 BLOCK, ADR-0031 신설) |
| 08 | Module Spec | **LLD** | `08-lld-module-spec/08-lld-module-spec.md` (또는 도메인 분할) |
| 09 | API Spec | **LLD** | `09-lld-api-spec/09-lld-api-spec.md` |
| 10 | Screen Design | **LLD** | `10-lld-screen-design/10-lld-screen-design.md` (BE-only는 `status: N/A` 골격) |
| 11 | Coding Conventions | 코드 규약 | `11-coding-conventions/11-coding-conventions.md` |
| 12 | Scaffolding | 코드 규약 | `12-scaffolding/<lang>.md` (평면 명명, 다국어 시 언어별) |
| 13 | Test Design | 검증 | `13-test-design/` (5절 폴더 자동 골격, ADR-0030: 01-strategy·02-catalog·03-regression·04-performance·05-delivery-format) — sub-file 본문 BLOCK은 **ADR-0034** (01-strategy 방법론·레벨·커버리지 ≥80% / 02-catalog R-/F- fan-in + 출처 + 매트릭스 ❌ 금지 / 05-delivery-format ID 채번·전달 시점) / 02-catalog 섹션 구조는 **ADR-0036** (§1 단위 / §2 통합 / §3 E2E / §4 매트릭스) |

각 폴더에 `INDEX.md` 자동 생성. 04·05의 R-ID/F-ID별 시나리오는 13/02-catalog의 *해당 레벨 섹션*(ADR-0036)에 fan-in. 이슈 단위 점진 갱신은 P13(`/docs-update` §9, **ADR-0035**) `check-test-catalog-sync.sh` WARN 기반.

## Phase Sequence (내부 자동 호출, ADR-0012 + ADR-0031 순서)

```
0. (자동) /context-loader 입력 검증
   - 01·02·03·04·05 폴더 + 메인 파일 + INDEX.md 모두 존재?
   - 모두 v0.1+ 이상 + validate-doc.sh 통과 상태?
   - 아니면 BLOCKED: "/flow-init 미통과 — 먼저 호출하세요"

─── Gate C (개발팀 검토) ────────────────
1. (자동) /implementation-planner --mode=architecture
                                  → 06-architecture/06-architecture.md
                                    (Architecture 본체: 시스템 컨텍스트·Stack·컨테이너 구조)
2. (자동) /implementation-planner --mode=hld
                                  → 07-hld/07-hld.md
                                    (HLD 본체: §1 핵심 모듈/컴포넌트 표 BLOCK + 모듈 간 데이터 흐름 + 비기능 대응)
3. (자동) /implementation-planner --mode=module
                                  → 08-lld-module-spec/08-lld-module-spec.md
                                    (LLD 모듈 내부 본체, 07 §1 fan-out 참조 BLOCK)
4. (자동) /implementation-planner --mode=api
                                  → 09-lld-api-spec/09-lld-api-spec.md (LLD 외부 인터페이스)
5. (자동, 필수) /ux-flow-design (와이어프레임 모드)
                                  → 10-lld-screen-design/10-lld-screen-design.md
                                    (LLD UI — BE-only는 `status: N/A` 골격, ADR-0013)
6. (자동) /implementation-planner --mode=conventions
                                  → 11-coding-conventions/11-coding-conventions.md
7. (자동) /implementation-planner --mode=scaffold --lang=<lang>
                                  → 12-scaffolding/<lang>.md
                                    (06 §Stack Decision에서 lang 자동 추출, 다국어 반복)
                                    + §6 환경 변수 dev/stg/prod 3 profile 컬럼 BLOCK (ADR-0037 v1.1)
                                    + §7 부팅 자산 BLOCK + §8 스타일링 솔루션 BLOCK (ADR-0037 v1.1 + 0038)
                                    + 동시 채움: newProject 루트 `LOCAL.md` 본문 §1~§6 (ADR-0040)
                                      → LOCAL.md는 install.sh가 빈 골격 카피했음. 본 단계에서 §3 profile별
                                        부팅 명령·§4 자산 표(§7과 동기)·§2 셋업 절차를 함께 채운다.
8. (자동) /implementation-planner --mode=test
                                  → 13-test-design/ (5절 폴더 자동 골격, ADR-0014·0015·0030)
                                    (scaffold-doc.sh 분할 모드 — 01-strategy·02-catalog·
                                     03-regression·04-performance·05-delivery-format 일괄 생성)
                                    (커버리지 ≥ 80% BLOCK, R-/F- 레벨 매트릭스 BLOCK은
                                     단일 파일 모드 또는 후속 ADR의 sub-file 위임 검증에 적용)
9. (자동, 병행) ADR 결정 발생 시  → adr/NNNN-*.md
10. (자동) /plan-eng-review       → 검토 보고서 (전수 산출 검증 + 8필드)

─── 휴먼 게이트 (본 메타 끝) ──────────────
▶ 사용자 검토: Gate C 산출 8건 OK?
   - 06 Architecture가 시스템 컨텍스트·Stack 결정·컨테이너 구조에 집중하는가 (모듈 분해 없는가)
   - 07 HLD §1 모듈 분해가 시스템 큰 그림 표현하는가
   - LLD 3종(08·09·10)이 07 §1 fan-out과 정합한가
   - 13 카탈로그가 04·05 시나리오 모두 fan-in했는가
   - 커버리지 ≥ 80% 명시, 단위/통합/E2E 매트릭스 빈 칸 없는가
▶ OK면 다음 메타 호출: /flow-wbs
```

## 입력

- `docs/planning/01-project-brief/`, `02-feasibility/`, `03-user-scenarios/`, `04-srs/`, `05-prd/` 5개 폴더 (필수)
- 누락 시 BLOCKED + `/flow-init` 호출 안내

## 완료 조건

- [ ] 06~13 폴더 8개 + 각 메인 파일 + INDEX.md (13은 5절 폴더 구조)
- [ ] 각 산출 `validate-doc.sh` 통과
- [ ] 06 §Stack Decision 박스 BLOCK 충족
- [ ] 07 §1 핵심 모듈 표 BLOCK 충족 (ADR-0031)
- [ ] 08 §1 모듈 개요에 07 §1 참조 BLOCK 충족 (ADR-0031)
- [ ] 13 §1 커버리지 80~100% 명시 (ADR-0015 §2.3)
- [ ] 13 §3 시나리오 카탈로그에 04·05 fan-in 출처 인용 + 레벨 매트릭스 BLOCK
- [ ] `/plan-eng-review` PASS

## 다음 메타

```
사용자 Gate C 검토 OK
   ▼
/flow-wbs
   → Phase 3/4: 리스크 + WBS 분해 (15·14)
```

## BLOCKED 케이스

| 메시지 | 원인 | 조치 |
|---|---|---|
| `BLOCKED: /flow-init 미통과` | 01~05 폴더/산출 부재 | `/flow-init` 먼저 호출 |
| `BLOCKED: 06 §Stack Decision 미작성` | Architecture가 Stack 결정 없음 | 06 §Stack Decision 표 보강 |
| `BLOCKED: 07 §1 모듈 분해 미작성` | HLD가 시나리오만 (모듈 분해 없음) | 07 §1 표 보강 (ADR-0031) |
| `BLOCKED: 08 §1 07 §1 참조 부재` | LLD가 HLD와 trace 안 됨 | 08 §1에 "07 §1 참조" 명시 |
| `BLOCKED: 커버리지 < 80%` | 13 §1에 70% 등 명시 | 80% 이상으로 (분야 예외는 ADR 신설) |
| `BLOCKED: 13 §3 fan-in 출처 부재` | R-/F- 행에 04#·05# 인용 없음 | fan-in 출처 보강 |
| `BLOCKED: --lang 지정 부재 (mode=scaffold)` | 06 §Stack Decision 미파싱 | 06 보강 또는 `--lang=<x>` 명시 |

## Strict Rules

- **선행 산출 v1.0+ 정식이면 본 메타는 *해당 v1.0+ 정식 상태 산출만* 입력으로 사용**. DRAFT 산출은 허용 (Phase 1 작성 직후 시나리오)
- **본 메타 안에서 10 Screen Design 생략 금지** — BE-only도 `status: N/A` 골격 필수 (ADR-0013)
- **다음 Phase 메타(`/flow-wbs`) 호출은 사용자가 명시** — 본 메타가 자동 진행 안 함

## Artifact Binding

- 입력: `/flow-init` 산출 (01~05)
- 출력: → `/flow-wbs`의 입력 (06~13)

## 트리거 매칭

- "설계 진행", "Architecture/HLD/LLD 진행", "/flow-design", "Gate C 진입"
- 자연어: "이제 설계 시작", "아키텍처부터 짜자"
