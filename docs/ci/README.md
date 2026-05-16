# CI Workflow Templates

These GitHub Actions workflow YAMLs are staged here because the current
gh CLI token lacks the `workflow` scope to push directly into
`.github/workflows/`. Move them once a repo admin re-authorises with
`workflow` scope:

```bash
git mv docs/ci/workflows/ci.yml .github/workflows/ci.yml
git mv docs/ci/workflows/nightly-perf.yml .github/workflows/nightly-perf.yml
git commit -am "ci: activate workflows"
git push
```

## ci.yml (per-PR)
- backend-build: `./gradlew clean build` + Jacoco reports artifact
- frontend-build: `pnpm install --frozen-lockfile && pnpm test && pnpm build`
- three-profile-boot-smoke: matrix dev/stg/prod → `GET /api/health` 200
- contract-tests: bruno CLI vs booted backend

## nightly-perf.yml (cron 09:00 UTC = 18:00 KST)
- k6 p1 (single user 95p < 300ms)
- k6 p3 (huge offset < 500ms + empty)

R-IDs: R-N-06 (3 profile boot per ADR-0037 v1.1)
