# Conduit Bruno API Contract Suite

Forked from `gothinkster/realworld/specs/api/bruno/` (MIT). Verifies the
backend responses match RealWorld OpenAPI 2.0.0 shape.

## Run locally

```bash
npm install -g @usebruno/cli
bru run --env dev
```

## Run in CI

See `.github/workflows/contract-tests.yml` (added in I-30 CI matrix).

## Coverage

| Group | Cases |
|---|---|
| auth | register, login |
| articles | list |
| tags | list |

Expanded coverage upstream; this seed validates the contract shape per R-N-05.

R-IDs: R-N-05 (uniform response wrap)
