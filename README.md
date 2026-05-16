# Conduit — RealWorld Implementation (test-case-4)

> A [RealWorld](https://realworld-docs.netlify.app/) Medium.com clone — built end-to-end with the
> [agent-toolkit](https://github.com/chaelee-dev/agent-toolkit) dogfooding loop (4-phase NEW_PROJECT
> + 32-issue Sprint runner).

**Stack**: Spring Boot 3.4 + Java 21 + PostgreSQL 16 (backend) · React 19 + Vite 6 + TailwindCSS 3.4 (frontend) · JWT auth · Flyway · Bruno contract · Playwright E2E · k6 perf.

## Status

| KPI | Target | Status |
|---|---|---|
| API endpoints (RealWorld OpenAPI 2.0.0) | 19/19 | ✅ wired |
| FE pages | 9/9 | ✅ wired |
| BE tests | 80+ | ✅ green |
| FE tests | 5+ | ✅ green |
| 3 profile boot (dev/stg/prod) | ADR-0037 v1.1 | ✅ matrix CI staged |
| Markdown XSS safety | R-N-03 | ✅ commonmark+jsoup BE / rehype-sanitize FE |
| Sprint progression | 32/32 issues | ✅ all merged |

## Quick start

```bash
# DB
docker compose up -d postgres-dev

# Backend
cd backend
cp .env.dev.example .env.dev
export $(cat .env.dev | xargs)
./gradlew bootRun --args='--spring.profiles.active=dev'

# Frontend (new terminal)
cd frontend
cp .env.dev.example .env.dev
pnpm install
pnpm dev
```

Open <http://localhost:5173>. Backend listens on `:8080` and Vite proxies `/api` to it.

For stg/prod profile boots see [`LOCAL.md`](LOCAL.md) §3.

## Architecture

- `backend/` — Spring Boot REST API, 14 modules (auth, user, profile, article, favorite,
  comment, tag, markdown, web), JPA + Flyway migrations V0~V7.
- `frontend/` — React SPA, 9 pages, FSD-style layout (pages → components → lib).
- `docker-compose.yml` — 3 PostgreSQL containers per profile (ports 5432/5433/5434).
- `specs/api/bruno/` — Forked RealWorld contract suite.
- `tests/e2e/` — Playwright spec seeds (home, auth, xss).
- `tests/performance/k6/` — Load + boundary scenarios.
- `docs/planning/` — 01~15 NEW_PROJECT design + ADRs (single source of truth).
- `docs/features/feat-project-bootstrap/` — Per-issue planning artifacts (brief/contract/plan/acceptance).
- `docs/ci/workflows/` — GitHub Actions CI templates (move into `.github/workflows/` once
  a token with `workflow` scope is available).

## Documentation

| Doc | Purpose |
|---|---|
| [LOCAL.md](LOCAL.md) | 3 profile boot procedure for local dev (ADR-0040) |
| [docs/planning/INDEX.md](docs/planning/INDEX.md) | All design + WBS + risk docs |
| [docs/planning/14-wbs/14-wbs.md](docs/planning/14-wbs/14-wbs.md) | 4 sprints × 32 issues |
| [docs/planning/15-risk/15-risk.md](docs/planning/15-risk/15-risk.md) | 12 risks (5 categories) |
| [docs/planning/09-lld-api-spec/09-lld-api-spec.md](docs/planning/09-lld-api-spec/09-lld-api-spec.md) | All 19 endpoints |
| [docs/planning/10-lld-screen-design/10-lld-screen-design.md](docs/planning/10-lld-screen-design/10-lld-screen-design.md) | 9 screens + design tokens |

## License

MIT (matches RealWorld upstream).
