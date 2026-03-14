#!/usr/bin/env bash

set -euo pipefail

CODEX_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$CODEX_LIB_DIR/../.." && pwd)"
SRC_DIR="$ROOT_DIR/src"
BUILD_DIR="${CODEX_BUILD_DIR:-$ROOT_DIR/.build/codex-src}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_step() {
  echo -e "${BLUE}▶ $*${NC}"
}

log_success() {
  echo -e "  ${GREEN}✓${NC} $*"
}

log_warn() {
  echo -e "  ${YELLOW}⚠${NC} $*"
}

fail() {
  echo -e "${RED}오류:${NC} $*" >&2
  exit 1
}

require_dir() {
  [[ -d "$1" ]] || fail "디렉토리 없음 → $1"
}

sync_tree() {
  local src="$1"
  local dest="$2"

  mkdir -p "$dest"
  rsync -a --delete --exclude='.DS_Store' "$src/" "$dest/" > /dev/null
}

sanitize_markdown_file() {
  local file="$1"

  perl -0pi -e '
    s/\r\n/\n/g;
    s/^tools:\s.*\n//mg;
    s/^model:\s.*\n//mg;
    s/^allowed-tools:\s.*\n//mg;
    s/^disable-model-invocation:\s.*\n//mg;
    s/^argument-hint:\s.*\n//mg;
    s/@(?=(?:\.{1,2}\/|\.claude\/|\.codex\/))//g;
    s{^(\.{1,2}/[^\n]+)$}{참조 파일: `$1`}mg;

    s{\.claude/skills/}{.agents/skills/}g;
    s{\.claude/agents/}{.codex/agents/}g;
    s{\.claude/rules/}{.codex/rules/}g;
    s{\.claude/instructions/}{.codex/instructions/}g;
    s{\.claude/commands/}{.codex/commands/}g;
    s{\.claude/hooks/}{.codex/hooks/}g;
    s{\.claude/settings\.local\.json}{.codex/settings.json}g;
    s{\.claude/}{.codex/}g;

    s/Task\s+병렬\s+모드/병렬 위임 모드/g;
    s/Task\s+병렬\s+호출/병렬 위임/g;
    s/일반\s+Task\s+병렬/일반 병렬 위임/g;
    s/Agent\s+Teams\s+모드/병렬 협업 모드/g;
    s/Agent\s+Teams/병렬 협업/g;
    s/TeamCreate/Parallel delegation/g;
    s/Task\s+\(/Delegate (/g;
    s/Task\s+\(([^\n]+)\)/Delegate ($1)/g;
    s/subagent_type\s*=/role =/g;
    s/Task\(/Delegate(/g;
    s/model\s*=\s*"haiku"/reasoning = "low"/g;
    s/model\s*=\s*"sonnet"/reasoning = "medium"/g;
    s/model\s*=\s*"opus"/reasoning = "high"/g;
    s/model\s*=\s*'"'"'haiku'"'"'/reasoning = '"'"'low'"'"'/g;
    s/model\s*=\s*'"'"'sonnet'"'"'/reasoning = '"'"'medium'"'"'/g;
    s/model\s*=\s*'"'"'opus'"'"'/reasoning = '"'"'high'"'"'/g;
    s/Claude 직접/Codex 직접/g;
    s/Claude Code/Codex/g;
    s/\bhaiku\b/low/g;
    s/\bsonnet\b/medium/g;
    s/\bopus\b/high/g;
  ' "$file"
}

sanitize_markdown_tree() {
  local dir="$1"
  while IFS= read -r file; do
    sanitize_markdown_file "$file"
  done < <(find "$dir" -type f \( -name '*.md' -o -name 'SKILL.md' \) | sort)
}

prune_codex_only_noise() {
  local dir="$1"

  rm -f "$dir/settings.json" \
        "$dir/settings.local.json" \
        "$dir/commands/setup-notifier.md" \
        "$dir/scripts/install-notifier.sh"
  rm -rf "$dir/plugins"
}

create_codex_agents_md() {
  local base_dir="$1"
  local out="$2"
  local rules_dir="$base_dir/rules/core"
  local agents_dir="$base_dir/agents"
  local skills_dir="$base_dir/skills"
  local commands_dir="$base_dir/commands"

  mkdir -p "$(dirname "$out")"

  {
    echo "# AI Kit — Codex 사용 가이드"
    echo ""
    echo "이 프로젝트에는 Codex에서 바로 참조할 수 있는 규칙, 에이전트, 스킬, 커맨드가 포함되어 있습니다."
    echo ""
    echo "## 규칙 (Rules)"
    echo ""
    echo "코드 작성 시 상황에 맞는 규칙 파일을 먼저 확인하세요."
    echo ""

    for rule in "$rules_dir"/*.md; do
      [[ -e "$rule" ]] || continue
      local filename name when
      filename=$(basename "$rule")
      name="${filename%.md}"

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

      echo "- \`.codex/rules/core/${filename}\` — ${when}"
    done
    echo ""

    if [[ -d "$agents_dir" ]]; then
      echo "## 에이전트 (Agents)"
      echo ""
      echo "복잡한 작업은 역할별 에이전트 문서를 참고해 분리하세요."
      echo ""
      for agent in "$agents_dir"/*.md; do
        [[ -e "$agent" ]] || continue
        local filename title
        filename=$(basename "$agent")
        title=$(grep -m1 '^# ' "$agent" 2>/dev/null | sed 's/^# //') || true
        [[ -z "$title" ]] && title="${filename%.md}"
        echo "- \`.codex/agents/${filename}\` — ${title}"
      done
      echo ""
    fi

    if [[ -d "$skills_dir" ]]; then
      echo "## 스킬 (Skills)"
      echo ""
      echo "반복 작업은 설치된 스킬 경로를 직접 읽고 실행하세요."
      echo ""
      for skill_dir in "$skills_dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name=$(basename "$skill_dir")
        echo "- \`.agents/skills/${name}\`"
      done
      echo ""
    fi

    if [[ -d "$commands_dir" ]]; then
      echo "## 커맨드 (Commands)"
      echo ""
      echo "커맨드 문서는 Codex 작업 프롬프트 템플릿으로 활용하세요."
      echo ""
      for cmd in "$commands_dir"/*.md; do
        [[ -e "$cmd" ]] || continue
        local filename name
        filename=$(basename "$cmd")
        name="${filename%.md}"
        echo "- \`/${name}\` — \`.codex/commands/${filename}\` 참조"
      done
      echo ""
    fi
  } > "$out"
}

rewrite_installed_references() {
  local target_dir="$1"

  if [[ -d "$target_dir/.codex/commands" ]]; then
    find "$target_dir/.codex/commands" -type f -name '*.md' | while read -r file; do
      perl -0pi -e '
        s{\.\./skills/}{../../.agents/skills/}g;
      ' "$file"
    done
  fi

  if [[ -d "$target_dir/.agents/skills" ]]; then
    find "$target_dir/.agents/skills" -type f -name 'SKILL.md' | while read -r file; do
      perl -0pi -e '
        s{\.\./\.\./instructions/}{../../../.codex/instructions/}g;
        s{\.\./\.\./rules/}{../../../.codex/rules/}g;
        s{\.\./\.\./skills/}{../}g;
      ' "$file"
    done
  fi
}

validate_installed_markdown_refs() {
  local target_dir="$1"

  TARGET_DIR="$target_dir" python3 - <<'PY'
import os
import pathlib
import re
import sys

root = pathlib.Path(os.environ["TARGET_DIR"])
scan_roots = [root / ".codex", root / ".agents" / "skills"]
pattern = re.compile(r"`((?:\.\./)+[^`\n]+?\.(?:md|json|sh))`")
problems = []

for scan_root in scan_roots:
    if not scan_root.exists():
        continue
    for path in scan_root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() != ".md" and path.name != "SKILL.md":
            continue

        text = path.read_text(encoding="utf-8")
        for ref in pattern.findall(text):
            resolved = (path.parent / ref.split("#", 1)[0]).resolve()
            if not resolved.exists():
                problems.append((str(path.relative_to(root)), ref, str(resolved)))

if problems:
    print("broken markdown references:")
    for path, ref, resolved in problems:
        print(f"{path}\t{ref}\t{resolved}")
    sys.exit(1)
PY
}
