#!/usr/bin/env bash
# sprint-bootstrap.sh — WBS §7 YAML → GitHub Milestones + Issues + Labels + Projects v2 items
#
# 사용:
#   ./scripts/sprint-bootstrap.sh                       # WBS 전체 (Sprint 1..N) 일괄 등록
#   ./scripts/sprint-bootstrap.sh --sprint=N+1          # Sprint N+1만 (rollover)
#   ./scripts/sprint-bootstrap.sh --input=PATH          # WBS 경로 지정 (기본: docs/planning/13-wbs/13-wbs.md)
#   ./scripts/sprint-bootstrap.sh --repo=OWNER/NAME     # 대상 리포 지정 (기본: gh default)
#   ./scripts/sprint-bootstrap.sh --dry-run             # gh 쓰기 호출 없이 시뮬레이션
#   ./scripts/sprint-bootstrap.sh --help
#
# 입력: docs/planning/13-wbs/13-wbs.md §7 YAML 블록 (sprints: + project:)
# 출력: GitHub Milestones + Issues + Labels (FSM/priority/type/area) + Projects v2 items
#
# 정합:
# - D-02 SoT = Issues + Milestone (정본). Projects v2 = View 계층 단방향 sync (ADR-0009).
# - D-04 스프린트=Milestone, 이슈=Issue 2계층 (PLAN §5).
# - ADR-0008: 파생 이슈는 평면 독립. Parent/Children/sub-of:#N 메커니즘 없음.
# - 이슈 템플릿 4필드(Acceptance/Contract/Effort/DoD) 검증은 /wbs가 담당. 본 스크립트는 등록만.
#
# 의존성: bash 4.3+, gh (authenticated, project scope 권장), yq 4.x, git

set -euo pipefail

readonly VERSION="1.0.0"
readonly DEFAULT_INPUT="docs/planning/13-wbs/13-wbs.md"
readonly API_SLEEP_MS=100

# FSM 라벨 (policies/github-issue.md §2 / §5.3)
readonly -a FSM_LABEL_NAMES=("status:todo" "status:in-progress" "status:in-review" "status:blocked" "tested")
readonly -a FSM_LABEL_COLORS=("ededed" "0e8a16" "fbca04" "d93f0b" "5319e7")
readonly -a FSM_LABEL_DESCS=(
  "FSM: pending/todo"
  "FSM: work in progress"
  "FSM: pull request under review"
  "FSM: blocked by dependency"
  "D-06 2nd gate: human tested"
)

# 우선순위 라벨 (policies/github-issue.md §2)
readonly -a PRIORITY_LABEL_NAMES=("priority:P0" "priority:P1" "priority:P2" "priority:P3")
readonly -a PRIORITY_LABEL_COLORS=("b60205" "d93f0b" "fbca04" "c5def5")
readonly -a PRIORITY_LABEL_DESCS=(
  "P0: blocker / must ship"
  "P1: high"
  "P2: medium"
  "P3: low / nice-to-have"
)

# 유형 라벨 (policies/github-issue.md §2)
readonly -a TYPE_LABEL_NAMES=("type:feature" "type:bug" "type:chore" "type:docs" "type:test")
readonly -a TYPE_LABEL_COLORS=("a2eeef" "ee0701" "fef2c0" "0075ca" "bfd4f2")
readonly -a TYPE_LABEL_DESCS=(
  "Feature work"
  "Bug fix"
  "Chore / maintenance"
  "Documentation"
  "Test work"
)

# 영역 라벨 (policies/github-issue.md §2)
readonly -a AREA_LABEL_NAMES=("area:frontend" "area:backend" "area:agent" "area:infra" "area:docs")
readonly -a AREA_LABEL_COLORS=("c2e0c6" "bfdadc" "f9d0c4" "d4c5f9" "fef2c0")
readonly -a AREA_LABEL_DESCS=(
  "Frontend"
  "Backend"
  "Agent / harness"
  "Infrastructure / build / CI"
  "Documentation / planning"
)

DRY_RUN=false
SPRINT_NUM=""
INPUT_PATH=""
REPO_FLAG=""
YAML_TEMP=""

# ── Logging (stderr) ────────────────────────────────────────────────
mask_secrets() {
  sed -E \
    -e 's/ghp_[A-Za-z0-9_]+/***/g' \
    -e 's/gho_[A-Za-z0-9_]+/***/g' \
    -e 's/ghs_[A-Za-z0-9_]+/***/g' \
    -e 's/ghu_[A-Za-z0-9_]+/***/g' \
    -e 's/github_pat_[A-Za-z0-9_]+/***/g'
}

_log() { local lvl="$1"; shift; echo "[$lvl] $*" | mask_secrets >&2; }
info()  { _log "INFO"  "$@"; }
warn()  { _log "WARN"  "$@"; }
error() { _log "ERROR" "$@"; }

error_exit() {
  local msg="${1:-unknown error}" code="${2:-1}"
  error "$msg"; exit "$code"
}

cleanup() { [[ -n "${YAML_TEMP:-}" && -f "${YAML_TEMP:-}" ]] && rm -f "$YAML_TEMP" || true; }
trap cleanup EXIT

api_sleep() { sleep "$(echo "scale=3; $API_SLEEP_MS / 1000" | bc 2>/dev/null || echo "0.1")"; }

# ── Dependency guards ───────────────────────────────────────────────
check_command() {
  local cmd="$1" label="${2:-$1}"
  command -v "$cmd" &>/dev/null || error_exit "$label not found. Please install $label and retry." 1
}

check_bash_version() {
  local maj="${BASH_VERSINFO[0]}" min="${BASH_VERSINFO[1]}"
  if (( maj < 4 )) || { (( maj == 4 )) && (( min < 3 )); }; then
    error_exit "bash 4.3+ required (found ${BASH_VERSION}). On macOS: brew install bash" 1
  fi
}

check_yq_version() {
  local v; v="$(yq --version 2>&1 || true)"
  echo "$v" | grep -qE 'version (v)?4\.' \
    || error_exit "yq 4.x (mikefarah/yq) required. Found: $v" 1
}

check_gh_auth() {
  local out; out="$(gh auth status 2>&1 || true)"
  echo "$out" | grep -qi "not logged in\|no valid\|authentication\|failed" \
    && error_exit "gh CLI not authenticated. Run 'gh auth login' first." 1 || true
}

check_deps() {
  check_bash_version
  check_command "gh"  "gh CLI"
  check_command "yq"  "yq"
  check_command "git" "git"
  check_gh_auth
  check_yq_version
}

# ── Argument parsing ────────────────────────────────────────────────
show_help() {
  cat <<HELP
sprint-bootstrap.sh v${VERSION}
  WBS §7 YAML → GitHub Milestones + Issues + Labels + Projects v2 items

USAGE:
  scripts/sprint-bootstrap.sh [OPTIONS]

OPTIONS:
  (no args)            Register all sprints from WBS (batch mode)
  --sprint=N           Register only Sprint N (incremental / rollover)
  --sprint N           Same (space-separated)
  --input=PATH         WBS markdown path (default: ${DEFAULT_INPUT})
  --input PATH         Same
  --repo=OWNER/NAME    Target GitHub repo (default: gh-resolved)
  --repo OWNER/NAME    Same
  --dry-run            Preview only, no GitHub writes
  --help, -h           Show this help

EXAMPLES:
  scripts/sprint-bootstrap.sh
  scripts/sprint-bootstrap.sh --sprint=2
  scripts/sprint-bootstrap.sh --dry-run --sprint=1
  scripts/sprint-bootstrap.sh --repo=myorg/myrepo --input=docs/planning/13-wbs/13-wbs.md
HELP
  exit 0
}

validate_repo_format() {
  [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] \
    || error_exit "Invalid --repo format: '$1'. Expected OWNER/NAME (e.g., myorg/myrepo)" 1
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --sprint=*) SPRINT_NUM="${1#*=}"; shift ;;
      --sprint)   [[ -n "${2:-}" ]] || error_exit "--sprint requires a value" 1
                  SPRINT_NUM="$2"; shift 2 ;;
      --input=*)  INPUT_PATH="${1#*=}"; shift ;;
      --input)    [[ -n "${2:-}" ]] || error_exit "--input requires a path" 1
                  INPUT_PATH="$2"; shift 2 ;;
      --repo=*)   validate_repo_format "${1#*=}"; REPO_FLAG="--repo ${1#*=}"; shift ;;
      --repo)     [[ -n "${2:-}" ]] || error_exit "--repo requires OWNER/NAME" 1
                  validate_repo_format "$2"; REPO_FLAG="--repo $2"; shift 2 ;;
      --dry-run)  DRY_RUN=true; shift ;;
      --help|-h)  show_help ;;
      *)          error_exit "Unknown option: $1. Use --help for usage." 1 ;;
    esac
  done
  [[ -z "$INPUT_PATH" ]] && INPUT_PATH="$DEFAULT_INPUT"
  if [[ -n "$SPRINT_NUM" ]]; then
    [[ "$SPRINT_NUM" =~ ^[0-9]+$ ]] \
      || error_exit "--sprint must be a positive integer, got: '$SPRINT_NUM'" 1
    [[ "$SPRINT_NUM" -ge 1 ]] \
      || error_exit "--sprint must be >= 1, got: '$SPRINT_NUM'" 1
  fi
}

# ── gh wrappers ─────────────────────────────────────────────────────
gh_write() {
  local desc="$1"; shift
  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] would execute: gh $*"
    return 0
  fi
  api_sleep
  gh "$@"
}

gh_read() { gh "$@"; }

# ── YAML extraction from markdown §7 ────────────────────────────────
extract_yaml() {
  local input_file="$1"
  [[ -f "$input_file" ]] || error_exit "Input file not found: $input_file" 2

  local in_s7=false in_yaml=false yaml="" found=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+7\. ]]; then in_s7=true; continue; fi
    if $in_s7 && [[ "$line" =~ ^##[[:space:]] ]] && [[ ! "$line" =~ ^##[[:space:]]+7\. ]]; then
      in_s7=false; continue
    fi
    if $in_s7; then
      if [[ "$line" =~ ^\`\`\`yaml ]]; then in_yaml=true; found=true; continue; fi
      if $in_yaml && [[ "$line" =~ ^\`\`\` ]]; then in_yaml=false; continue; fi
      $in_yaml && yaml+="$line"$'\n'
    fi
  done < "$input_file"

  [[ "$found" == true && -n "$yaml" ]] \
    || error_exit "BLOCKED: No section-7 YAML block found in $input_file" 2

  YAML_TEMP="$(mktemp)"; echo "$yaml" > "$YAML_TEMP"
  yq eval '.' "$YAML_TEMP" &>/dev/null \
    || error_exit "BLOCKED: Invalid YAML in §7 block of $input_file" 2
  echo "$YAML_TEMP"
}

load_wbs_sprint_count() {
  local cnt; cnt="$(yq eval '.sprints | length' "$1" 2>/dev/null || echo "0")"
  if [[ "$cnt" -eq 0 ]]; then warn "No sprints to register in WBS."; exit 0; fi
  echo "$cnt"
}

# ── Ensure labels (FSM + priority + type + area) ────────────────────
ensure_label_set() {
  local existing="$1"
  local -n names_ref=$2
  local -n colors_ref=$3
  local -n descs_ref=$4
  local i nm cl ds
  for i in "${!names_ref[@]}"; do
    nm="${names_ref[$i]}"; cl="${colors_ref[$i]}"; ds="${descs_ref[$i]}"
    if echo "$existing" | grep -qxF "$nm"; then
      info "Label '$nm' already exists, skipping."
    else
      info "Creating label: $nm (#$cl)"
      # shellcheck disable=SC2086
      gh_write "create label $nm" label create "$nm" --color "$cl" --description "$ds" \
        $REPO_FLAG 2>/dev/null \
        || warn "Failed to create label: $nm (may already exist with different color)"
    fi
  done
}

ensure_all_labels() {
  local existing
  # shellcheck disable=SC2086
  existing="$(gh_read label list $REPO_FLAG --limit 200 --json name -q '.[].name' 2>/dev/null || echo "")"
  ensure_label_set "$existing" FSM_LABEL_NAMES      FSM_LABEL_COLORS      FSM_LABEL_DESCS
  ensure_label_set "$existing" PRIORITY_LABEL_NAMES PRIORITY_LABEL_COLORS PRIORITY_LABEL_DESCS
  ensure_label_set "$existing" TYPE_LABEL_NAMES     TYPE_LABEL_COLORS     TYPE_LABEL_DESCS
  ensure_label_set "$existing" AREA_LABEL_NAMES     AREA_LABEL_COLORS     AREA_LABEL_DESCS
}

# ── Ensure milestone ────────────────────────────────────────────────
find_existing_milestone() {
  # shellcheck disable=SC2086
  gh_read api "repos/{owner}/{repo}/milestones" --method GET \
    --jq ".[] | select(.title == \"$1\") | .number" $REPO_FLAG 2>/dev/null || echo ""
}

ensure_milestone() {
  local name="$1" due="$2" existing
  existing="$(find_existing_milestone "$name")"
  if [[ -n "$existing" ]]; then
    info "Milestone '$name' already exists (#$existing), skipping."
    echo "$existing"; return 0
  fi
  info "Creating milestone: $name${due:+ (due: $due)}"
  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] would create milestone: $name${due:+ (due: $due)}" >&2
    echo "dry-run-ms"; return 0
  fi
  api_sleep
  local args=(--method POST --field "title=$name")
  [[ -n "$due" && "$due" != "null" ]] && args+=(--field "due_on=${due}T23:59:59Z")
  local num
  # shellcheck disable=SC2086
  num="$(gh api "repos/{owner}/{repo}/milestones" "${args[@]}" --jq '.number' $REPO_FLAG 2>/dev/null)" \
    || error_exit "Failed to create milestone: $name" 1
  info "Created milestone: $name (#$num)"
  echo "$num"
}

# ── Idempotency — find existing issue by exact title ────────────────
find_existing_issue() {
  local norm
  norm="$(echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+/ /g')"
  # shellcheck disable=SC2086
  gh_read issue list --search "\"$norm\" in:title" --state all \
    --json number,title --jq ".[] | select(.title == \"$norm\") | .number" \
    $REPO_FLAG 2>/dev/null | head -1 || echo ""
}

# ── Projects v2 helpers ─────────────────────────────────────────────
resolve_project_owner() {
  local yaml_file="$1" yaml_owner
  yaml_owner="$(yq eval '.project.owner // ""' "$yaml_file" 2>/dev/null || echo "")"
  if [[ -n "$yaml_owner" && "$yaml_owner" != "null" ]]; then
    echo "$yaml_owner"; return 0
  fi
  if [[ "$DRY_RUN" == true ]]; then
    echo "<repo-owner>"; return 0
  fi
  # shellcheck disable=SC2086
  gh_read repo view --json owner --jq '.owner.login' $REPO_FLAG 2>/dev/null || echo ""
}

add_to_project() {
  local issue_num="$1" project_num="$2" project_owner="$3"
  [[ -z "$project_num" || "$project_num" == "null" ]] && return 0
  [[ -z "$project_owner" ]] && { warn "Project owner unresolved — skip Projects v2 add for #$issue_num"; return 0; }

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] would add issue #$issue_num to Project v2 #$project_num (owner=$project_owner)"
    return 0
  fi

  local issue_url
  # shellcheck disable=SC2086
  issue_url="$(gh issue view "$issue_num" --json url --jq '.url' $REPO_FLAG 2>/dev/null || echo "")"
  [[ -z "$issue_url" ]] && { warn "Cannot resolve URL for issue #$issue_num"; return 0; }

  api_sleep
  gh project item-add "$project_num" --owner "$project_owner" --url "$issue_url" >/dev/null 2>&1 \
    && info "Added issue #$issue_num to Project v2 #$project_num" \
    || warn "Failed to add issue #$issue_num to Project v2 #$project_num (gh 'project' scope 필요할 수 있음)"
}

# ── Create issues for one sprint ────────────────────────────────────
create_issues() {
  local yaml_file="$1" sprint_idx="$2" project_num="$3" project_owner="$4"
  local cnt; cnt="$(yq eval ".sprints[$sprint_idx].issues | length" "$yaml_file")"
  [[ "$cnt" -gt 0 ]] || { warn "No issues in sprint index $sprint_idx."; return 0; }

  # ADR-0021: 이슈 제목 정규식 (Conventional Commits 스타일)
  local TITLE_REGEX='^(feat|fix|chore|docs|test|refactor)\([a-z][a-z0-9,_-]*\): .+$'

  local i
  for ((i = 0; i < cnt; i++)); do
    local title body labels_raw ms_name issue_num
    title="$(yq eval ".sprints[$sprint_idx].issues[$i].title" "$yaml_file")"
    body="$(yq eval ".sprints[$sprint_idx].issues[$i].body" "$yaml_file")"
    labels_raw="$(yq eval ".sprints[$sprint_idx].issues[$i].labels | join(\",\")" "$yaml_file" 2>/dev/null || echo "")"
    [[ -n "$labels_raw" && "$labels_raw" != "null" ]] \
      && labels_raw="${labels_raw},status:todo" \
      || labels_raw="status:todo"
    ms_name="$(yq eval ".sprints[$sprint_idx].milestone" "$yaml_file")"

    # ADR-0021: 제목 정규식 검증 (BLOCK) — docs/planning/policies/github-issue.md §1.5
    if ! echo "$title" | grep -qE "$TITLE_REGEX"; then
      warn "Issue title BLOCK (ADR-0021): '$title' — 형식 '<type>(<area>): <summary>' 필요. 13-wbs/13-wbs.md 수정 후 재실행."
      continue
    fi

    # 멱등성: 동명 이슈가 이미 있으면 skip하고 Project 추가만 시도
    local existing; existing="$(find_existing_issue "$title")"
    if [[ -n "$existing" ]]; then
      info "Issue '$title' already exists (#$existing), skipping create."
      add_to_project "$existing" "$project_num" "$project_owner"
      continue
    fi

    info "Creating issue: $title"
    if [[ "$DRY_RUN" == true ]]; then
      echo "[DRY-RUN] would create issue: $title (milestone: $ms_name, labels: $labels_raw)"
      add_to_project "dry-run" "$project_num" "$project_owner"
      continue
    fi

    api_sleep
    # shellcheck disable=SC2086
    issue_num="$(gh issue create --title "$title" --body "$body" --label "$labels_raw" \
      --milestone "$ms_name" $REPO_FLAG 2>/dev/null | grep -oE '[0-9]+$')" || {
        warn "Failed to create issue: $title"
        continue
      }
    info "Created issue: $title (#$issue_num)"
    add_to_project "$issue_num" "$project_num" "$project_owner"
  done
}

# ── Main flow ───────────────────────────────────────────────────────
main() {
  parse_args "$@"
  info "sprint-bootstrap.sh v${VERSION}"
  info "Mode: $(if [[ -n "$SPRINT_NUM" ]]; then echo "single sprint ($SPRINT_NUM)"; else echo "all sprints (batch)"; fi)"
  info "Input: $INPUT_PATH"
  info "Dry-run: $DRY_RUN"
  [[ -n "$REPO_FLAG" ]] && info "Target repo: ${REPO_FLAG#--repo }"

  check_deps

  local yaml_file; yaml_file="$(extract_yaml "$INPUT_PATH")"
  local sprint_count; sprint_count="$(load_wbs_sprint_count "$yaml_file")"
  info "Found $sprint_count sprint(s) in WBS."

  ensure_all_labels

  # Projects v2 정보 (선택)
  local project_num project_owner
  project_num="$(yq eval '.project.number // ""' "$yaml_file" 2>/dev/null || echo "")"
  if [[ -n "$project_num" && "$project_num" != "null" ]]; then
    project_owner="$(resolve_project_owner "$yaml_file")"
    info "Projects v2: number=$project_num, owner=${project_owner:-<unresolved>}"
  else
    info "Projects v2: project.number not set — skipping Project sync."
    project_num=""
    project_owner=""
  fi

  local start_idx=0 end_idx=$((sprint_count - 1))
  if [[ -n "$SPRINT_NUM" ]]; then
    local found=false s
    for ((s = 0; s < sprint_count; s++)); do
      local sn; sn="$(yq eval ".sprints[$s].name" "$yaml_file")"
      if [[ "$sn" == "Sprint $SPRINT_NUM" ]]; then
        start_idx=$s; end_idx=$s; found=true; break
      fi
    done
    if ! $found; then
      warn "Sprint $SPRINT_NUM not found in WBS. Available:"
      for ((s = 0; s < sprint_count; s++)); do
        warn "  - $(yq eval ".sprints[$s].name" "$yaml_file")"
      done
      exit 0
    fi
  fi

  local s
  for ((s = start_idx; s <= end_idx; s++)); do
    local sname sms sdue
    sname="$(yq eval ".sprints[$s].name" "$yaml_file")"
    sms="$(yq eval ".sprints[$s].milestone" "$yaml_file")"
    sdue="$(yq eval ".sprints[$s].due // \"\"" "$yaml_file")"
    info "--- Processing: $sname ---"
    ensure_milestone "$sms" "$sdue" >/dev/null
    create_issues "$yaml_file" "$s" "$project_num" "$project_owner"
  done

  if [[ "$DRY_RUN" == true ]]; then
    info "Dry-run complete. No changes were made to GitHub."
  else
    info "Bootstrap complete."
  fi
}

# 직접 실행 시에만 main 호출 (source는 함수 단위 테스트 허용)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
