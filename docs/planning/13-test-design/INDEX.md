---
doc_type: index
version: v0.1
status: Draft
author: <name@email>
date: 2026-05-16
gate: C
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# 13-test-design — Index

> 본 폴더는 test-design 폴더 분할 산출 (ADR-0030). 폴더 내 sub-file 목록.

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | <author> | 초안 (scaffold-doc.sh folder-split 생성) |

## 파일 목록

| 파일 | 한 줄 요약 |
|---|---|
| [01-strategy.md](01-strategy.md) | Test Strategy |
| [02-catalog.md](02-catalog.md) | Test Scenario Catalog (단위·통합·E2E 별 묶음) |
| [03-regression.md](03-regression.md) | Regression Test Policy |
| [04-performance.md](04-performance.md) | Performance & Security Tests |
| [05-delivery-format.md](05-delivery-format.md) | Customer Delivery Format |

## 정합
- 정본 schema: `.claude/schemas/test-design.schema.yaml` (`folder_split` 블록)
- 폴더 분할 결정: [ADR-0030](../adr/0030-test-design-folder-split-scaffold.md)
- 게이트: C
