#!/usr/bin/env bash
# install.sh — agent-toolkit을 newProject에 자동 도입 (ADR-0017)
#
# 사용:
#   bash <toolkit>/scripts/install.sh <target-dir> [옵션]
#
# RFP 표준 위치 (자동 감지 우선순위):
#   1. <target-dir>/RFP.md          ← 표준 (단일 RFP, 가장 권장)
#   2. <target-dir>/*.rfp.md        ← 명시적 접미 (예: client-x.rfp.md)
#   3. <target-dir>/RFP/*.md        ← 여러 RFP를 폴더로 묶을 때
#   미발견 시 /flow-init에 자연어 의도 직접 입력 가능.
#   양식 자유 — 외부 문서 그대로 두어도 /flow-init이 흡수.
#
# 옵션:
#   --rfp=<path>     RFP 파일 명시 (위 자동 탐색 우회)
#   --commit         git init + 첫 커밋 자동
#   --force          기존 .claude/ 덮어쓰기 허용
#   --dry-run        실제 카피 없이 시뮬레이션
#   --help           도움말
#
# Exit codes:
#   0 = 성공
#   2 = 사용자 입력 오류 (target 미지정 등)
#   3 = 충돌 (--force 없이 기존 .claude/ 발견)
#   4 = 의존성 부재 (rsync·git)
#
# 의존성: bash 4.3+, git, (rsync 권장 — 미설치 시 cp -r 자동 fallback, ADR-0017 v1.1)

set -euo pipefail

# ─── 인자 파싱 ─────────────────────────────────
TARGET=""
RFP_PATH=""
DO_COMMIT=0
FORCE=0
DRY_RUN=0

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  exit 0
}

for arg in "$@"; do
  case "$arg" in
    --rfp=*)   RFP_PATH="${arg#--rfp=}" ;;
    --commit)  DO_COMMIT=1 ;;
    --force)   FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage ;;
    -*)        echo "[ERROR] 알 수 없는 옵션: $arg" >&2; exit 2 ;;
    *)         [ -z "$TARGET" ] && TARGET="$arg" || { echo "[ERROR] 인자 과다: $arg" >&2; exit 2; } ;;
  esac
done

[ -z "$TARGET" ] && { echo "[ERROR] target-dir 미지정. 사용법: $0 <target-dir> [옵션]" >&2; exit 2; }

# ─── 환경 검증 ─────────────────────────────────
# rsync 미설치 환경(Windows + Git Bash 등) → cp -r fallback (ADR-0017 v1.1)
HAVE_RSYNC=1
if ! command -v rsync >/dev/null 2>&1; then
  HAVE_RSYNC=0
  echo "[INFO] rsync 미설치 — cp -r fallback 사용 (Windows + Git Bash 환경)"
  # rsync shell 함수로 redefine — 기존 \$RSYNC 호출처는 변경 안 함
  rsync() {
    local dry=0 exclude=""
    local positional=()
    while [ $# -gt 0 ]; do
      case "$1" in
        -a|-r) ;;
        -an|-rn) dry=1 ;;
        --exclude=*) exclude="${1#--exclude=}" ;;
        *) positional+=("$1") ;;
      esac
      shift
    done
    local src="${positional[0]:-}" dst="${positional[1]:-}"
    [ -z "$src" ] || [ -z "$dst" ] && { echo "rsync(fallback): src/dst 누락" >&2; return 1; }
    if [ $dry -eq 1 ]; then
      echo "  (dry-run cp) $src → $dst${exclude:+ (exclude: $exclude)}"
      return 0
    fi
    # 디렉토리 contents 카피 (rsync "src/" trailing-slash semantics 모방)
    if [ -d "$src" ] || [ "${src: -1}" = "/" ]; then
      mkdir -p "$dst"
      local src_norm="${src%/}"
      if [ -n "$exclude" ]; then
        (cd "$src_norm" && find . -path "./$exclude*" -prune -o -type f -print) \
          | while read -r f; do
              mkdir -p "$dst/$(dirname "$f")"
              cp "$src_norm/$f" "$dst/$f"
            done
      else
        cp -r "$src_norm/." "$dst/"
      fi
    else
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
    fi
  }
  export -f rsync
fi
command -v git   >/dev/null 2>&1 || { echo "[ERROR] git 미설치" >&2; exit 4; }

# 툴킷 루트 자동 감지
TOOLKIT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$TOOLKIT_ROOT/.claude" ] || { echo "[ERROR] 툴킷 루트가 아닌 곳에서 호출됨: $TOOLKIT_ROOT" >&2; exit 4; }

# target 절대 경로화 + 생성
TARGET="$(realpath -m "$TARGET")"
[ ! -d "$TARGET" ] && mkdir -p "$TARGET"

echo "=== agent-toolkit install ==="
echo "  툴킷 루트  : $TOOLKIT_ROOT"
echo "  대상 디렉토리: $TARGET"
[ $DRY_RUN -eq 1 ] && echo "  모드      : DRY-RUN (실제 쓰기 없음)"
echo

# ─── 충돌 검사 ─────────────────────────────────
if [ -d "$TARGET/.claude" ] && [ $FORCE -eq 0 ]; then
  echo "[ERROR] 기존 $TARGET/.claude 발견 — --force 없이 덮어쓰기 불가" >&2
  exit 3
fi

# ─── 카피 단계 ─────────────────────────────────
RSYNC="rsync -a"
[ $DRY_RUN -eq 1 ] && RSYNC="rsync -an"

echo "[1/5] 툴킷 자산 카피"
# rsync(3.2.3 미만)은 grandparent 디렉토리 자동 생성 안 함 — `docs/install/` 같은 2단 깊이 dst의
# 부모를 미리 만들어 둬야 한다. --mkpath 플래그는 rsync 3.2.3+ 한정이라 비호환.
# 따라서 모든 rsync 호출 전에 `mkdir -p`로 dst 부모를 명시적으로 확보한다.
mkdir -p "$TARGET/.claude" "$TARGET/docs" "$TARGET/scripts"
$RSYNC --exclude='_archive' "$TOOLKIT_ROOT/.claude/" "$TARGET/.claude/"
$RSYNC "$TOOLKIT_ROOT/docs/install/" "$TARGET/docs/install/"
$RSYNC "$TOOLKIT_ROOT/scripts/" "$TARGET/scripts/"

# .github/ 자산 — ADR-0021 정합 (이슈/PR 제목 통일을 newProject에서도 강제)
# - workflows/issue-pr-title-lint.yml: 항상 carry-over (머신 검증 BLOCK)
# - ISSUE_TEMPLATE/: newProject에 없을 때만 카피 (덮어쓰지 않음, 기존 newProject 고유 템플릿 보호)
# - pull_request_template.md: carry-over 안 함 (newProject 고유 가능성 — manual-sync-guide §4.x에서 안내)
mkdir -p "$TARGET/.github/workflows"
$RSYNC "$TOOLKIT_ROOT/.github/workflows/issue-pr-title-lint.yml" "$TARGET/.github/workflows/issue-pr-title-lint.yml"
$RSYNC "$TOOLKIT_ROOT/.github/workflows/sync-issue-labels.yml" "$TARGET/.github/workflows/sync-issue-labels.yml"
if [ ! -d "$TARGET/.github/ISSUE_TEMPLATE" ]; then
  $RSYNC "$TOOLKIT_ROOT/.github/ISSUE_TEMPLATE/" "$TARGET/.github/ISSUE_TEMPLATE/"
else
  echo "  → 기존 $TARGET/.github/ISSUE_TEMPLATE/ 발견. 보존 (덮어쓰지 않음). ADR-0021 정합 확인 권장."
fi

# .gitattributes carry-over — WSL/Linux 호환성 (CRLF 차단, 본 툴킷 .gitattributes 정책)
# newProject가 Windows에서 작업되더라도 .sh/.yaml/.md를 LF로 강제 → WSL bash 실행 보장
GITATTR_SRC="$TOOLKIT_ROOT/.gitattributes"
GITATTR_DST="$TARGET/.gitattributes"
if [ -f "$GITATTR_SRC" ]; then
  if [ -f "$GITATTR_DST" ] && [ $FORCE -eq 0 ]; then
    echo "  → 기존 $TARGET/.gitattributes 발견. 보존 (LF 정책 적용 여부 수동 확인 권장)."
  elif [ $DRY_RUN -eq 1 ]; then
    echo "  → (dry-run) $GITATTR_SRC → $GITATTR_DST"
  else
    cp "$GITATTR_SRC" "$GITATTR_DST"
    echo "  → .gitattributes 카피 (WSL/Linux 호환성: *.sh LF 강제)"
  fi
fi

# ─── CLAUDE.md 템플릿 치환 ─────────────────────
echo "[2/5] CLAUDE.md 템플릿 적용"
TEMPLATE="$TOOLKIT_ROOT/docs/install/CLAUDE.template.md"
TARGET_CLAUDE_MD="$TARGET/CLAUDE.md"
# PROJECT_NAME은 CLAUDE.md·LOCAL.md 양쪽에서 placeholder 치환에 사용되므로 분기 위에서 정의
PROJECT_NAME=$(basename "$TARGET")

if [ -f "$TARGET_CLAUDE_MD" ] && [ $FORCE -eq 0 ]; then
  echo "  → 기존 $TARGET/CLAUDE.md 발견. 보존. 수동 머지 필요할 수 있음."
elif [ $DRY_RUN -eq 1 ]; then
  echo "  → (dry-run) $TEMPLATE → $TARGET_CLAUDE_MD"
else
  # placeholder 자동 치환: {{PROJECT_NAME}} → newProject 이름
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$TEMPLATE" > "$TARGET_CLAUDE_MD"
fi

# LOCAL.md 카피 (ADR-0040 — 루트 부팅 가이드 정본)
# placeholder 치환: {{PROJECT_NAME}}·{{INIT_DATE}}·{{INIT_AUTHOR}}
# 기존 newProject LOCAL.md는 보존 (매 PR 진화 자산이므로 도입자 갱신 손실 방지)
LOCAL_TEMPLATE="$TOOLKIT_ROOT/docs/install/LOCAL.template.md"
TARGET_LOCAL_MD="$TARGET/LOCAL.md"
if [ -f "$TARGET_LOCAL_MD" ] && [ $FORCE -eq 0 ]; then
  echo "  → 기존 $TARGET/LOCAL.md 발견. 보존 (매 PR 진화 자산)."
elif [ $DRY_RUN -eq 1 ]; then
  echo "  → (dry-run) $LOCAL_TEMPLATE → $TARGET_LOCAL_MD"
elif [ -f "$LOCAL_TEMPLATE" ]; then
  INIT_DATE=$(date +%Y-%m-%d)
  INIT_AUTHOR=$(git config user.name 2>/dev/null || echo "TBD")
  sed -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
      -e "s/{{INIT_DATE}}/$INIT_DATE/g" \
      -e "s/{{INIT_AUTHOR}}/$INIT_AUTHOR/g" \
      "$LOCAL_TEMPLATE" > "$TARGET_LOCAL_MD"
  echo "  → LOCAL.md 카피 (newProject 루트 부팅 가이드, ADR-0040)"
fi

# devtoolkit.config.yaml 카피 (tech_stack/conventions/collaboration/agent 등 정본 데이터)
# 기존 newProject yaml은 보존 (도입자가 채운 값 손실 방지)
# 주의: 빌드·실행 commands 블록은 ADR-0041로 폐기. 빌드 명령은 12-scaffolding §5 / LOCAL.md §3 양축 정본.
CONFIG_SRC="$TOOLKIT_ROOT/devtoolkit.config.yaml"
CONFIG_DST="$TARGET/devtoolkit.config.yaml"
if [ -f "$CONFIG_DST" ] && [ $FORCE -eq 0 ]; then
  echo "  → 기존 $TARGET/devtoolkit.config.yaml 발견. 보존."
elif [ $DRY_RUN -eq 1 ]; then
  echo "  → (dry-run) $CONFIG_SRC → $CONFIG_DST"
elif [ -f "$CONFIG_SRC" ]; then
  cp "$CONFIG_SRC" "$CONFIG_DST"
  echo "  → devtoolkit.config.yaml 카피 (tech_stack/conventions 등은 도입자가 채움. 빌드 명령은 12-scaffolding §5 / LOCAL.md §3)"
fi

# devkit wrapper는 ADR-0041로 폐기 (test-case-3 PR #38 회귀 — wrapper 우회·native script 직호출로 회귀).
# 빌드·실행 명령은 12-scaffolding §5 / LOCAL.md §3에 newProject별 native script로 명시한다.

# check-local-md-sync.sh 카피 (ADR-0017 v1.2 + ADR-0040 — LOCAL.md 구조/profile 3분기/lockfile lint, stack-agnostic)
# docs/install/scripts/check-local-md-sync.sh (staged, rsync로 자동 카피됨) → newProject scripts/check-local-md-sync.sh (활성 위치 + 실행권)
# 기존 newProject 스크립트는 보존 (도입자 커스텀 보호)
LINT_SRC="$TOOLKIT_ROOT/docs/install/scripts/check-local-md-sync.sh"
LINT_DST="$TARGET/scripts/check-local-md-sync.sh"
if [ -f "$LINT_DST" ] && [ $FORCE -eq 0 ]; then
  echo "  → 기존 $TARGET/scripts/check-local-md-sync.sh 발견. 보존."
elif [ $DRY_RUN -eq 1 ]; then
  echo "  → (dry-run) $LINT_SRC → $LINT_DST (+x)"
elif [ -f "$LINT_SRC" ]; then
  cp "$LINT_SRC" "$LINT_DST"
  chmod +x "$LINT_DST" 2>/dev/null || true
  echo "  → check-local-md-sync.sh 카피 (LOCAL.md 구조 + profile 3분기 lint, ADR-0040)"
fi

# ci.yml.template은 staged 상태 그대로 docs/install/에 둠 (rsync로 자동 카피).
# 도입자가 명시적으로 .github/workflows/ci.yml로 git mv + boot-smoke skeleton 채움
# (workflow scope 부여 필요: gh auth refresh -s workflow). ADR-0037 v1.1 3 profile matrix.

# ─── .gitignore ────────────────────────────────
echo "[3/5] .gitignore 카피/append"
GITIGNORE_TEMPLATE="$TOOLKIT_ROOT/docs/install/gitignore.template"
TARGET_GITIGNORE="$TARGET/.gitignore"

if [ -f "$GITIGNORE_TEMPLATE" ]; then
  if [ -f "$TARGET_GITIGNORE" ]; then
    if ! grep -q "# === agent-toolkit ===" "$TARGET_GITIGNORE" 2>/dev/null; then
      if [ $DRY_RUN -eq 0 ]; then
        {
          echo ""
          echo "# === agent-toolkit ==="
          cat "$GITIGNORE_TEMPLATE"
        } >> "$TARGET_GITIGNORE"
      fi
      echo "  → 기존 .gitignore에 툴킷 섹션 append"
    else
      echo "  → 툴킷 섹션 이미 존재. skip"
    fi
  else
    [ $DRY_RUN -eq 0 ] && cp "$GITIGNORE_TEMPLATE" "$TARGET_GITIGNORE"
    echo "  → 신규 .gitignore 생성"
  fi
else
  echo "  → gitignore.template 부재. skip"
fi

# ─── git init ──────────────────────────────────
echo "[4/5] git init"
if [ -d "$TARGET/.git" ]; then
  echo "  → 기존 .git 발견. skip"
elif [ $DRY_RUN -eq 0 ]; then
  (cd "$TARGET" && git init >/dev/null 2>&1)
  echo "  → git init 완료"
else
  echo "  → (dry-run) git init"
fi

# ─── RFP 자동 감지 ─────────────────────────────
echo "[5/5] RFP 자동 감지"
if [ -z "$RFP_PATH" ]; then
  # 우선순위: RFP.md > *.rfp.md > RFP/*.md
  if [ -f "$TARGET/RFP.md" ]; then
    RFP_PATH="$TARGET/RFP.md"
  elif ls "$TARGET"/*.rfp.md >/dev/null 2>&1; then
    RFP_PATH=$(ls "$TARGET"/*.rfp.md | head -1)
  elif [ -d "$TARGET/RFP" ] && ls "$TARGET/RFP"/*.md >/dev/null 2>&1; then
    RFP_PATH=$(ls "$TARGET/RFP"/*.md | head -1)
  fi
fi

if [ -n "$RFP_PATH" ] && [ -f "$RFP_PATH" ]; then
  echo "  → RFP 발견: $RFP_PATH"
  RFP_RELATIVE=$(realpath --relative-to="$TARGET" "$RFP_PATH")
else
  echo "  → RFP 부재. /flow-init 호출 시 자연어 의도 직접 입력 가능"
  RFP_RELATIVE=""
fi

# ─── 첫 커밋 (선택) ────────────────────────────
if [ $DO_COMMIT -eq 1 ] && [ $DRY_RUN -eq 0 ]; then
  echo
  echo "[옵션] 첫 커밋 생성"
  (
    cd "$TARGET"
    # carry-over 자산 전수 (install.sh가 카피하는 모든 항목)
    # 누락 시 newProject 사용자가 수동 git add 필요 → 도입 직후 혼란 유발
    git add .claude/ docs/install/ scripts/ .github/ \
            CLAUDE.md .gitignore .gitattributes \
            devtoolkit.config.yaml 2>/dev/null || true
    git commit -m "chore(toolkit): initial agent-toolkit import (install.sh)" >/dev/null 2>&1 \
      && echo "  → 커밋 완료" \
      || echo "  → 커밋할 변경 없음 또는 git config 미설정"
  )
fi

# ─── 완료 안내 ─────────────────────────────────
echo
echo "✅ 툴킷 도입 완료"

# ─── 다운스트림 의존성 사전 점검 (soft warning) ─────────────
# scaffold-doc.sh / validate-doc.sh / gen-index.sh 가 yq 필수.
# 미설치 시 /flow-init 진입 즉시 ERROR exit 3 — 도입자가 원인 못 찾을 가능성 차단.
MISSING_DEPS=""
command -v yq >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS} yq"
command -v gh >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS} gh"
if [ -n "$MISSING_DEPS" ]; then
  echo
  echo "⚠️  다운스트림 의존성 미설치:${MISSING_DEPS}"
  echo "    - yq (mikefarah/yq v4+) : scaffold-doc·validate-doc·gen-index 가 사용"
  echo "    - gh (GitHub CLI)        : sprint-bootstrap 가 사용 (Phase 4)"
  echo "    설치 (Ubuntu/WSL):"
  echo "      sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
  echo "      sudo apt-get install -y gh   # 또는 https://cli.github.com/manual/installation"
fi
echo
echo "다음 단계 (수동):"
echo "  cd \"$TARGET\""
echo "  claude"
if [ -n "$RFP_RELATIVE" ]; then
  echo "  /flow-init \"\$(cat $RFP_RELATIVE)\""
else
  echo "  /flow-init \"<자연어 의도 또는 RFP 본문>\""
fi
echo
echo "참고:"
echo "  - QUICK-START.md  : 4 Phase 흐름 1분 안내"
echo "  - docs/planning/INDEX.md : 1수준 산출 일람 + 용어집"
