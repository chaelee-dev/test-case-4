---
doc_type: user-scenarios
version: v0.1 (Draft)
status: Draft
author: yongtae.cho@bespinglobal.com
date: 2026-05-16
gate: B
related:
  R-ID: []
  F-ID: []
  supersedes: null
---

# Conduit (RealWorld 클론) — 사용자 시나리오

## 변경 이력

| Version | Date | Author | Change |
|---|---|---|---|
| v0.1 | 2026-05-16 | yongtae.cho@bespinglobal.com | 초안 — 페르소나 3종 + UC 12건 |

## 1. 페르소나

| 페르소나 | 역할 | 환경 / 컨텍스트 | 주요 목표 |
| --- | --- | --- | --- |
| **신규 작성자 Aiden** | 처음 가입하는 블로그 작성자 | 데스크탑 브라우저, 영어 UI | 회원가입 후 첫 글을 쓰고, 자기 글이 피드에 노출되는 것을 확인 |
| **활성 독자 Bora** | 로그인 사용자 (글 작성 안 함) | 데스크탑·모바일 웹, 영어 UI | 관심 태그·작성자 팔로우, 좋아한 글 따로 모아보기 |
| **익명 방문자 Visitor** | 비로그인 | 데스크탑/모바일 웹, 검색엔진 유입 | 글로벌 피드·태그·단일 글·프로필 열람 (회원 가입 유인) |
| **저자 본인 Self-Editor** | 자기 글 관리하는 로그인 사용자 | 데스크탑 | 자기 글 수정·삭제, 자기 댓글 삭제, 설정·로그아웃 |

## 2. 사용자 여정 (큰 그림)

```
[Visitor (익명)]
      │
      │  글 목록·단일 글·프로필 열람으로 가치 체험
      ▼
[회원가입 (Aiden)]  ─────► [로그인 직후 Home]
      │                          │
      │                          ├── Global Feed (모두에게 동일)
      │                          ├── Your Feed (팔로잉 작성자 글만, 초기 비어있음)
      │                          └── Tag Feed (태그 클릭 시)
      │                                  │
      ▼                                  │
[Editor — 새 글 작성]  ──► [Article — 자기 글 노출]
      │                          │
      │                          ├── 좋아요(Favorite)
      │                          ├── 팔로우(Follow author)
      │                          ├── 댓글 작성/삭제
      │                          └── (저자만) 수정/삭제 버튼
      │
      ▼
[Profile — 자기 글 / 좋아요한 글 토글]
      │
      ▼
[Settings — bio·image·email·password 수정 / 로그아웃]
```

각 분기는 헤더(Header)에서도 진입 가능. 비로그인 사용자가 보호 라우트(`/editor`, `/settings`)에 진입하면 `/login`으로 리다이렉트.

## 3. Use Case

### UC-01: 익명 사용자 글로벌 피드 열람

- **Actor**: Visitor
- **Precondition**: 비로그인 상태
- **Trigger**: `/` 진입
- **Happy path**:
  1. Visitor가 `/`에 접속한다
  2. 헤더에 "Sign in", "Sign up" 링크가 보인다
  3. "Global Feed" 탭이 활성화돼 있다 ("Your Feed" 탭은 보이지 않음)
  4. 글 카드(저자·날짜·좋아요 카운트·제목·요약·태그)가 페이지당 20건씩 표시된다
  5. 페이지네이션 버튼 클릭 시 다음 페이지가 로드된다
  6. 사이드바에 인기 태그가 표시된다
- **Failure path**:
  - 백엔드 `/api/articles` 에러 → "글을 불러올 수 없습니다" 메시지 + 재시도 버튼

### UC-02: 회원가입

- **Actor**: Aiden (신규)
- **Precondition**: 비로그인
- **Happy path**:
  1. `/register` 진입
  2. username/email/password 입력 후 "Sign up"
  3. 백엔드 `POST /users` 호출 → 201 + `{user: {..., token}}`
  4. 토큰을 localStorage에 저장
  5. 헤더가 "New Article", "Settings", "<username>" 로 갱신
  6. `/`로 이동, "Your Feed" 탭이 활성 (비어 있음)
- **Failure path**:
  - 동일 username/email 존재: 422 + `{errors:{username:["has already been taken"]}}` → 폼 상단에 에러 출력, 토큰 미저장
  - 입력 누락: 422 + 필드별 에러 → 인라인 에러

### UC-03: 로그인

- **Actor**: 기존 사용자 (Bora)
- **Happy path**:
  1. `/login` 진입
  2. email/password 입력
  3. `POST /users/login` → 200 + `{user: {..., token}}`
  4. 토큰 저장, 헤더 갱신, `/`로 이동
- **Failure path**:
  - 자격 미스매치: 401 + `{errors:{"email or password":["is invalid"]}}` → 폼 상단 에러
  - 422(필드 누락): 인라인 에러

### UC-04: 새 글 작성

- **Actor**: Aiden (로그인)
- **Happy path**:
  1. 헤더 "New Article" 클릭 → `/editor`
  2. title/description/body(markdown)/tag list 입력 (태그는 Enter로 칩 추가)
  3. "Publish Article" 클릭
  4. `POST /articles` Authorization: Token … → 201 + `{article: {slug, ...}}`
  5. `/article/:slug` 로 이동, 본문이 마크다운 렌더로 표시
- **Failure path**:
  - 비로그인이지만 토큰 만료/위변조: 401 → `/login` 리다이렉트 + 안내
  - title/body 누락: 422 → 인라인 에러
  - 같은 slug 충돌: 백엔드가 자동 nanoid suffix → 사용자 입장 정상 진행

### UC-05: 단일 글 열람 + 마크다운 렌더

- **Actor**: 누구든 (auth optional)
- **Happy path**:
  1. `/article/:slug` 접근
  2. `GET /articles/:slug` → 200 + article
  3. body가 sanitize 된 마크다운 → HTML로 렌더 (script·iframe 제거)
  4. `GET /articles/:slug/comments` → 댓글 리스트
  5. 비로그인이면 댓글 폼이 "로그인 후 작성 가능" 메시지로 대체
- **Failure path**:
  - 404: 글 없음 → "Article not found" 화면 + 홈 링크
  - 마크다운에 `<script>` 포함 시 sanitize로 제거 (XSS 방어, RB-03)

### UC-06: 좋아요 / 좋아요 취소

- **Actor**: 로그인 사용자
- **Happy path (좋아요)**:
  1. 글 카드 또는 글 상세의 ♥ 클릭
  2. `POST /articles/:slug/favorite` Token … → 200 + article(favoritesCount+1, favorited=true)
  3. UI 즉시 갱신 (낙관 업데이트 + 응답으로 정정)
- **Happy path (취소)**: 동일 버튼 한 번 더 → `DELETE …/favorite` → favoritesCount-1
- **Failure path**:
  - 비로그인이면 ♥ 버튼이 disabled or 로그인 페이지로 안내
  - 토큰 만료: 401 → 로그인으로

### UC-07: 팔로우 / 언팔로우

- **Actor**: 로그인 사용자 (자기 자신 제외)
- **Happy path**:
  1. `/profile/:username` 또는 글 상세에서 "Follow" 클릭
  2. `POST /profiles/:username/follow` → 200 + profile(following=true)
  3. 버튼이 "Unfollow"로 토글
  4. 이후 `/articles/feed` (Your Feed)에 해당 작성자의 글이 노출
- **Failure path**:
  - 자기 자신 팔로우: UI에서 버튼 미노출 + 백엔드 거부 (422)
  - 비로그인: 버튼 클릭 시 `/login`으로

### UC-08: 댓글 작성 / 삭제

- **Actor**: 로그인 사용자
- **Happy path (작성)**:
  1. `/article/:slug` 하단 댓글 폼
  2. body 입력 → "Post Comment"
  3. `POST /articles/:slug/comments` → 200 + comment
  4. 목록 상단에 즉시 추가
- **Happy path (삭제)**:
  1. 자기 댓글의 🗑 아이콘 클릭
  2. `DELETE /articles/:slug/comments/:id` → 200
  3. 목록에서 제거
- **Failure path**:
  - 타인 댓글 삭제 시도: 403 (UI에서는 아이콘 미노출이지만 직접 호출 방어)
  - 빈 body: 422 인라인 에러

### UC-09: 자기 글 수정 / 삭제

- **Actor**: Self-Editor (글 저자 본인)
- **Happy path (수정)**:
  1. 자기 글 상세에서 "Edit Article" 클릭 → `/editor/:slug`
  2. 폼이 기존 값으로 prefill
  3. 변경 후 "Update Article"
  4. `PUT /articles/:slug` → 200 + article
  5. `/article/:slug`로 이동
- **Happy path (삭제)**: "Delete Article" → 확인 다이얼로그 → `DELETE /articles/:slug` → 200 → `/` 리다이렉트
- **Failure path**:
  - 타인 글 수정/삭제 시도: 403 (UI에서는 버튼 미노출 + 백엔드 방어)

### UC-10: 태그 / 작성자 / 좋아요로 필터

- **Actor**: 누구든
- **Happy path**:
  1. Home 탭 "Global Feed" 활성 상태에서 사이드바 태그 클릭 → 새 탭 "# tagname"이 활성
  2. `GET /articles?tag=tagname&limit=20&offset=0` → 200 + filtered articles
  3. 페이지네이션 동작
  4. 같은 메커니즘으로 `?author=username` (Profile의 My Articles 탭), `?favorited=username` (Profile의 Favorited Articles 탭)
- **Failure path**: 결과 0건 → "No articles are here ... yet." 안내

### UC-11: 내 정보 수정 / 로그아웃

- **Actor**: 로그인 사용자
- **Happy path**:
  1. `/settings` 진입
  2. profile picture URL / username / bio / email / new password 변경 후 "Update Settings"
  3. `PUT /user` Token … → 200 + user(새 token 발급)
  4. 새 token 저장, 헤더 갱신
  5. "Logout" 클릭 → localStorage 토큰 제거 → `/`로 이동, 익명 헤더
- **Failure path**:
  - 동일 email/username 존재: 422 인라인 에러, 다른 필드는 미저장 (atomic)
  - 토큰 만료: 401 → `/login`

### UC-12: Your Feed (팔로잉 작성자의 글)

- **Actor**: 로그인 사용자
- **Happy path**:
  1. Home 진입, "Your Feed" 탭 활성 (기본)
  2. `GET /articles/feed?limit=20&offset=0` Token … → 200 + 팔로잉 작성자들의 최신 글
  3. 페이지네이션 동작
- **Failure path**:
  - 팔로잉 0명: "No articles are here ... yet. Try Global Feed instead." 안내 + Global Feed 탭으로 전환 가능
  - 401: 토큰 만료 → `/login`

## 4. 비기능 시나리오

| ID | 시나리오 | 기대치 |
|---|---|---|
| NF-S-01 | 일반 응답 시간 (단일 사용자, 로컬 dev) | 95p < 300ms (BE) + FE 첫 paint < 2s |
| NF-S-02 | 동시 사용자 50명 / 글 1만 개 부하 | 글 목록 1페이지 < 500ms |
| NF-S-03 | XSS 마크다운 입력 (`<script>alert(1)</script>` 포함) | 렌더 시 제거, alert 미발생 |
| NF-S-04 | JWT 위변조 토큰으로 보호 API 호출 | 401 + 로그인 안내, 데이터 유출 없음 |
| NF-S-05 | 비저자가 다른 사용자 글 PUT/DELETE 직접 호출 | 403 |
| NF-S-06 | 동일 title 글 2건 동시 생성 (슬러그 충돌) | 둘 다 성공, slug에 nanoid suffix |
| NF-S-07 | offset = 1,000,000 (대량 offset) | 결과 없음 또는 422, 서버 OOM 없음 |
| NF-S-08 | 3 profile 부팅 (ADR-0037 v1.1) | dev/stg/prod 각각 ready 신호 |

## 5. Open Questions

- **OQ-S-01**: "Your Feed"가 비어있을 때 자동으로 Global Feed로 전환할지, "Try Global Feed" 링크만 보일지? — UC-12 (캐노니컬 사양은 후자, 본 구현도 후자 채택 예정)
- **OQ-S-02**: 비로그인 사용자가 ♥/Follow 버튼 클릭 시 `/login` 즉시 리다이렉트할지, 인라인 안내만 보일지? — UC-06/07 (캐노니컬은 인라인 + 비활성, 본 구현 동일)
- **OQ-S-03**: 마크다운 link target=_blank 일괄 적용 여부 — UC-05
- **OQ-S-04**: 글 삭제 시 댓글·좋아요 cascade 정책 — 04 SRS R-AR-XX 결정
