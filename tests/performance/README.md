# Conduit Performance (k6)

3 scenarios covering R-N-01 (response time) and R-N-07 (page boundary).

| Scenario | VUs | Duration | Threshold |
|---|---|---|---|
| p1-single-user | 1 | 1m | 95p < 300ms |
| p2-load | 10→50 | 5m | 95p < 500ms, error < 1% |
| p3-huge-offset | 1 | 5 iter | 95p < 500ms |

## Run locally

```bash
k6 run tests/performance/k6/p1-single-user.js
BASE_URL=http://localhost:8080/api k6 run tests/performance/k6/p2-load.js
```

## CI (nightly)

Triggered by `.github/workflows/nightly-perf.yml` (created in I-30).

R-IDs: R-N-01, R-N-07
