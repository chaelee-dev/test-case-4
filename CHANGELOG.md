# Changelog

## v1.0.0 — 2026-05-16

**Sprint 1~4 complete (32 issues merged).** First reference release.

### Sprint 1 — Backend Foundation (I-01~I-08)
- I-01 project bootstrap: Spring Boot 3.4 + Java 21 + Gradle + Flyway + docker-compose
- I-02 JWT + Security: jjwt HS256, BCrypt cost 12, AuthFilter, TraceIdFilter (R-N-02, R-N-08)
- I-03 response envelope + GlobalExceptionHandler (R-N-04, R-N-05)
- I-04 User domain + POST /users (R-F-01)
- I-05 POST /users/login (R-F-02)
- I-06 GET/PUT /user + 401/403 entry points (R-F-03)
- I-07 Profile + Follow/Unfollow (R-F-04, R-F-05)
- I-08 Pagination validator (R-N-07)

### Sprint 2 — Backend Domain (I-09~I-17)
- I-09 Article entity + SlugGenerator (R-F-17)
- I-10 Tag + ArticleTag join + GET /tags (R-F-16)
- I-11 POST /articles (R-F-09)
- I-12 GET /articles with tag/author/favorited filters + pagination (R-F-06)
- I-13 GET /articles/feed (R-F-07)
- I-14 GET/PUT/DELETE /articles/:slug + ArticlePolicy 403 (R-F-08/10/11)
- I-15 Favorite/Unfavorite + count (R-F-12)
- I-16 Comments CRUD (R-F-13/14/15)
- I-17 Markdown sanitize (commonmark + jsoup, 8 XSS payloads) (R-F-18, R-N-03)

### Sprint 3 — Frontend (I-18~I-26)
- I-18 Vite + React 19 + Tailwind bootstrap
- I-19 ky + zod API client + 401 auto-handler (R-F-27)
- I-20 AuthContext + Login/Register pages (R-F-20)
- I-21 Header + ProtectedRoute (R-F-25, R-F-26)
- I-22 Settings page + Logout (R-F-21)
- I-23 Home page (3 feed tabs + pagination + popular tags sidebar) (R-F-19)
- I-24 Editor page (new + edit + TagInput) (R-F-22)
- I-25 Article detail (markdown + favorite + follow + comments) (R-F-23)
- I-26 Profile page (My/Favorited tabs) (R-F-24)

### Sprint 4 — QA / CI / Release (I-27~I-32)
- I-27 Bruno contract suite seed (4 cases)
- I-28 Playwright E2E seed (home + auth + xss specs)
- I-29 k6 performance scenarios (p1, p2, p3)
- I-30 GitHub Actions CI workflows (matrix dev/stg/prod boot + bruno contract)
  - Note: staged in `docs/ci/workflows/` pending workflow-scope token
- I-31 Jacoco + Vitest coverage gates
- I-32 README + Release v1.0

### Tests
- BE: 81+ tests passing (JUnit 5 + AssertJ + Spring Boot Test, H2 via Flyway in tests)
- FE: 5+ tests passing (Vitest + RTL)
- E2E seed (Playwright)
- Contract seed (Bruno)
- Perf scenarios (k6)

### Acknowledgements
Built end-to-end via [agent-toolkit](https://github.com/chaelee-dev/agent-toolkit) `/flow-init` →
`/flow-design` → `/flow-wbs` → `/flow-bootstrap` → `/flow-feature` (32 iterations).
