#!/usr/bin/env bash
# ai-rules-kit install script
# Usage: ./install.sh [--claude|--cursor|--opencode|--codex|--all] [target-dir]
#
# 소스: src/ (단일 원본)
#
#   --claude   src/ 전체 복사                         → .claude/
#   --cursor   src/ 복사 (skills 제외) + .agents/skills/ → .cursor/ + .agents/
#   --opencode src/ 전체 복사 + AGENTS.md             → .opencode/
#   --codex    src/ 복사 (skills 제외) + .agents/skills/ + AGENTS.md → .codex/ + .agents/
#   --all      위 4개 모두
#
# 원격 실행 (curl | bash):
#   curl -fsSL https://raw.githubusercontent.com/yesroad/ai-rules-kit/main/install.sh \
#     | bash -s -- --cursor .

set -euo pipefail

REMOTE_REPO="https://github.com/yesroad/ai-rules-kit.git"
AI_KIT_CACHE="$HOME/.config/ai-rules-kit"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# curl | bash로 실행된 경우 src/가 없음 → 레포를 캐시에 clone 후 재실행
if [[ ! -d "$SCRIPT_DIR/src" ]]; then
  echo "ai-rules-kit 소스를 다운로드합니다..."
  if [[ ! -d "$AI_KIT_CACHE" ]]; then
    git clone --depth=1 "$REMOTE_REPO" "$AI_KIT_CACHE"
  else
    git -C "$AI_KIT_CACHE" pull --quiet
  fi
  exec "$AI_KIT_CACHE/install.sh" "$@"
fi

SRC_DIR="$SCRIPT_DIR/src"
RULES_DIR="$SRC_DIR/rules/core"
AGENTS_DIR="$SRC_DIR/agents"
SKILLS_DIR="$SRC_DIR/skills"
COMMANDS_DIR="$SRC_DIR/commands"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
NC='\033[0m'

# ────────────────────────────────────────
# helpers
# ────────────────────────────────────────

usage() {
  echo ""
  echo "Usage: $0 [--claude|--cursor|--opencode|--codex|--all] [target-dir]"
  echo ""
  echo "Options:"
  echo "  --claude    src/ 전체 복사 (Claude Code)"
  echo "  --cursor    src/ 복사 (plugins/, skills/, settings 제외) + .agents/skills/ (Cursor)"
  echo "  --opencode  src/ 전체 복사 (hooks/, settings 제외) + AGENTS.md (OpenCode)"
  echo "  --codex     src/ 복사 (plugins/, skills/, settings 제외) + .agents/skills/ + AGENTS.md (Codex)"
  echo "  --all       위 4개 모두"
  echo ""
  echo "target-dir: 설치 경로 (기본값: 현재 디렉토리)"
  exit 1
}

check_target() {
  if [[ ! -d "$1" ]]; then
    echo -e "${RED}오류: 디렉토리 없음 → $1${NC}"
    exit 1
  fi
}

# src 디렉토리를 dest로 복사 (변경분만 동기화)
copy_dir() {
  local src="$1" dest="$2" label="$3"
  mkdir -p "$dest"
  rsync -a --exclude='.DS_Store' "$src/" "$dest/" > /dev/null
  local count
  count=$(find "$src" -maxdepth 1 -mindepth 1 | wc -l | tr -d ' ')
  echo -e "  ${GREEN}✓${NC} ${DIM}${label}${NC} (${count}개)"
}

# AGENTS.md 생성 — 전체 ai-kit 자산 사용 시점 안내
# $1: target dir
# $2: 출력 파일 경로 (기본값: target/AGENTS.md)
# $3: 설치된 툴 폴더 (예: .opencode, .codex) — 파일 경로 prefix로 사용
# $4: skills 경로 오버라이드 (기본값: $3/skills, 예: .agents/skills)
create_agents_md() {
  local target="$1"
  local out="${2:-$target/AGENTS.md}"
  local tool_dir="${3:-}"
  local skills_dir="${4:-${tool_dir:+${tool_dir}/skills}}"

  if [[ -f "$out" && ! -L "$out" ]]; then
    echo -e "  ${YELLOW}경고: $(basename "$out") 이미 존재. 덮어씁니다.${NC}"
  fi

  {
    echo "# AI Kit — 사용 가이드"
    echo ""
    echo "이 프로젝트에는 AI 코딩 도구를 위한 규칙, 에이전트, 스킬, 커맨드가 포함되어 있습니다."
    echo ""

    # ── Rules ──────────────────────────────────────
    echo "## 규칙 (Rules)"
    echo ""
    echo "코드 작성 시 상황에 맞는 규칙 파일을 참고하세요."
    echo ""

    for rule in "$RULES_DIR"/*.md; do
      [[ -e "$rule" ]] || continue
      local filename name title when
      filename=$(basename "$rule")
      name="${filename%.md}"

      title=$(grep -m1 '^# ' "$rule" 2>/dev/null | sed 's/^# //') || true
      [[ -z "$title" ]] && title="$name"

      case "$name" in
        coding-standards)         when="TypeScript/JavaScript 코드 작성, 리팩토링 시" ;;
        nextjs-app-router)        when="Next.js App Router(app/ 디렉토리) 사용 시" ;;
        react-hooks-patterns)     when="React 훅 작성, 성능 최적화 시" ;;
        react-nextjs-conventions) when="React 컴포넌트, Next.js 페이지 작성 시" ;;
        state-and-server-state)   when="서버 상태(API), 전역 상태, 폼 상태 관리 시" ;;
        thinking-model)           when="복잡한 작업 시작 전, 구조 설계 시" ;;
        unit-test-conventions)    when="순수 함수(utils, helpers) 유닛 테스트 작성 시" ;;
        *)                        when="코드 작성 시" ;;
      esac

      if [[ -n "$tool_dir" ]]; then
        echo "- \`${tool_dir}/rules/core/${filename}\` — $when"
      else
        echo "- **$title** — $when"
      fi
    done
    echo ""

    # ── Agents ─────────────────────────────────────
    if [[ -d "$AGENTS_DIR" ]]; then
      echo "## 에이전트 (Agents)"
      echo ""
      echo "복잡한 작업은 전문 에이전트에게 위임하세요."
      echo ""
      for agent in "$AGENTS_DIR"/*.md; do
        [[ -e "$agent" ]] || continue
        local afilename aname atitle
        afilename=$(basename "$agent")
        aname="${afilename%.md}"
        atitle=$(grep -m1 '^# ' "$agent" 2>/dev/null | sed 's/^# //') || true
        [[ -z "$atitle" ]] && atitle="$aname"
        if [[ -n "$tool_dir" ]]; then
          echo "- \`${tool_dir}/agents/${afilename}\` — $atitle"
        else
          echo "- **$atitle**"
        fi
      done
      echo ""
    fi

    # ── Skills ─────────────────────────────────────
    if [[ -d "$SKILLS_DIR" ]]; then
      echo "## 스킬 (Skills)"
      echo ""
      echo "반복 작업은 스킬로 실행하세요."
      echo ""
      for skill_dir in "$SKILLS_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local sname
        sname=$(basename "$skill_dir")
        if [[ -n "$skills_dir" ]]; then
          echo "- \`${skills_dir}/${sname}\`"
        else
          echo "- **$sname**"
        fi
      done
      echo ""
    fi

    # ── Commands ───────────────────────────────────
    if [[ -d "$COMMANDS_DIR" ]]; then
      echo "## 커맨드 (Commands)"
      echo ""
      echo "슬래시 커맨드로 워크플로우를 실행하세요."
      echo ""
      for cmd in "$COMMANDS_DIR"/*.md; do
        [[ -e "$cmd" ]] || continue
        local cfilename cname ctitle
        cfilename=$(basename "$cmd")
        cname="${cfilename%.md}"
        ctitle=$(grep -m1 '^# ' "$cmd" 2>/dev/null | sed 's/^# //') || true
        [[ -z "$ctitle" ]] && ctitle="$cname"
        if [[ -n "$tool_dir" ]]; then
          echo "- \`/${cname}\` — \`${tool_dir}/commands/${cfilename}\` 참조"
        else
          echo "- \`/${cname}\` — $ctitle"
        fi
      done
      echo ""
    fi

  } > "$out"

  echo -e "  ${GREEN}✓${NC} $(basename "$out") 생성"
}

# agents/*.md에서 OpenCode/Codex 비호환 필드 제거
strip_agent_fields() {
  local dir="$1"
  find "$dir/agents" -name "*.md" 2>/dev/null | while read -r f; do
    sed -i '' '/^tools: /d; /^model: /d; /^@\.\./d' "$f"
  done
}

# ────────────────────────────────────────
# installers
# ────────────────────────────────────────

install_claude() {
  local target="$1"
  echo -e "${BLUE}▶ Claude Code${NC}"

  [[ -d "$target/.claude" ]] && \
    echo -e "  ${YELLOW}경고: .claude/ 이미 존재. 덮어씁니다.${NC}"

  rsync -a \
    --exclude='settings.local.json' \
    --exclude='plugins' \
    --exclude='.DS_Store' \
    "$SRC_DIR/" "$target/.claude/" > /dev/null

  echo -e "  ${GREEN}✓${NC} .claude/ 복사 완료"

  local mcp_src="$SCRIPT_DIR/.mcp.json"
  if [[ -f "$mcp_src" ]]; then
    if [[ -f "$target/.mcp.json" ]]; then
      echo -e "  ${YELLOW}경고: .mcp.json 이미 존재. 덮어씁니다.${NC}"
    fi
    cp "$mcp_src" "$target/.mcp.json"
    echo -e "  ${GREEN}✓${NC} .mcp.json 복사 완료"
  fi

  local settings="$target/.claude/settings.local.json"
  if [[ -f "$settings" ]]; then
    echo -e "  ${YELLOW}경고: settings.local.json 이미 존재. 훅 설정 스킵 (/setup-notifier로 수동 병합)${NC}"
  else
    cat > "$settings" << 'EOF'
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "NOTIFIER_TITLE='Claude Code' bash ./.claude/hooks/notify.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
EOF
    echo -e "  ${GREEN}✓${NC} settings.local.json 훅 설정 완료"
  fi
}

install_cursor() {
  local target="$1"
  echo -e "${BLUE}▶ Cursor${NC}"

  mkdir -p "$target/.cursor"
  rsync -a \
    --exclude='plugins' \
    --exclude='skills' \
    --exclude='settings.json' \
    --exclude='settings.local.json' \
    --exclude='.DS_Store' \
    "$SRC_DIR/" "$target/.cursor/" > /dev/null
  rm -f "$target/.cursor/settings.json" "$target/.cursor/settings.local.json"
  echo -e "  ${GREEN}✓${NC} ${DIM}src/${NC} (plugins/, skills/, settings 제외)"

  mkdir -p "$target/.agents/skills"
  rsync -a --exclude='.DS_Store' "$SKILLS_DIR/" "$target/.agents/skills/" > /dev/null
  echo -e "  ${GREEN}✓${NC} .agents/skills/ 복사"

  local hooks_file="$target/.cursor/hooks.json"
  if [[ -f "$hooks_file" ]]; then
    echo -e "  ${YELLOW}경고: .cursor/hooks.json 이미 존재. 훅 설정 스킵${NC}"
  else
    cat > "$hooks_file" << 'EOF'
{
  "preToolUse": [
    {
      "command": "NOTIFIER_TITLE='Cursor' bash ./.cursor/hooks/notify.sh",
      "timeout": 5
    }
  ]
}
EOF
    echo -e "  ${GREEN}✓${NC} .cursor/hooks.json 훅 설정 완료"
  fi

  echo -e "  ${GREEN}✓${NC} Cursor 복사 완료"
}

install_opencode() {
  local target="$1"
  echo -e "${BLUE}▶ OpenCode${NC}"

  mkdir -p "$target/.opencode"
  rsync -a \
    --exclude='hooks' \
    --exclude='settings.json' \
    --exclude='settings.local.json' \
    --exclude='.DS_Store' \
    "$SRC_DIR/" "$target/.opencode/" > /dev/null
  rm -f "$target/.opencode/settings.json" "$target/.opencode/settings.local.json"
  echo -e "  ${GREEN}✓${NC} ${DIM}src/${NC} (hooks/, settings 제외)"

  strip_agent_fields "$target/.opencode"
  echo -e "  ${GREEN}✓${NC} agents/ 필드 변환 (tools/model/@ 제거)"

  create_agents_md "$target" "$target/.opencode/AGENTS.md" ".opencode"
  echo -e "  ${GREEN}✓${NC} OpenCode 복사 완료"
}

install_codex() {
  local target="$1"
  echo -e "${BLUE}▶ Codex${NC}"

  mkdir -p "$target/.codex"
  rsync -a \
    --exclude='plugins' \
    --exclude='skills' \
    --exclude='settings.json' \
    --exclude='settings.local.json' \
    --exclude='.DS_Store' \
    "$SRC_DIR/" "$target/.codex/" > /dev/null
  rm -f "$target/.codex/settings.json" "$target/.codex/settings.local.json"
  echo -e "  ${GREEN}✓${NC} ${DIM}src/${NC} (plugins/, skills/, settings 제외)"

  mkdir -p "$target/.agents/skills"
  rsync -a --exclude='.DS_Store' "$SKILLS_DIR/" "$target/.agents/skills/" > /dev/null
  echo -e "  ${GREEN}✓${NC} .agents/skills/ 복사"

  strip_agent_fields "$target/.codex"
  echo -e "  ${GREEN}✓${NC} agents/ 필드 변환 (tools/model 제거)"

  create_agents_md "$target" "$target/.codex/AGENTS.md" ".codex" ".agents/skills"

  echo -e "  ${GREEN}✓${NC} Codex 복사 완료"
}

# ────────────────────────────────────────
# main
# ────────────────────────────────────────

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  usage
fi

MODE=""
TARGET="."

for arg in "$@"; do
  case $arg in
    --claude|--cursor|--opencode|--codex|--all) MODE="$arg" ;;
    -*) echo -e "${RED}알 수 없는 옵션: $arg${NC}"; usage ;;
    *)  TARGET="$arg" ;;
  esac
done

[[ -z "$MODE" ]] && usage
check_target "$TARGET"

echo ""
echo -e "${YELLOW}ai-kit install${NC} → $(realpath "$TARGET")"
echo ""

case $MODE in
  --claude)   install_claude   "$TARGET" ;;
  --cursor)   install_cursor   "$TARGET" ;;
  --opencode) install_opencode "$TARGET" ;;
  --codex)    install_codex    "$TARGET" ;;
  --all)
    install_claude   "$TARGET"; echo ""
    install_cursor   "$TARGET"; echo ""
    install_opencode "$TARGET"; echo ""
    install_codex    "$TARGET"
    ;;
esac

echo ""
echo -e "${GREEN}완료!${NC}"
