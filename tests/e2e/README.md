# Conduit E2E (Playwright)

Forked & adapted from `gothinkster/realworld/specs/e2e/` (MIT).

## Run locally

```bash
cd tests/e2e
pnpm install
pnpm exec playwright install chromium
pnpm test
```

Requires backend + frontend running locally:
- backend: `cd backend && ./gradlew bootRun`
- frontend: `cd frontend && pnpm dev`

## CI

See `.github/workflows/3profile-boot.yml` (I-30).

## Coverage seeds

| spec | scenarios |
|---|---|
| home.spec.ts | banner + tabs + header (anonymous) |
| auth.spec.ts | login/register forms + protected redirect |
| xss.spec.ts | no `dialog` events fire on any rendered markdown |

Full RealWorld canonical scenarios (article/comment/favorite/follow/editor)
are upstreamed iteratively; the seed validates the routing and protection
contract.

R-IDs: R-N-03 (XSS), R-F-26 (protected redirect), F-09
