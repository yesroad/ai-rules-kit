#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

TARGET_DIR="${1:-.}"
SOURCE_DIR="${2:-$BUILD_DIR}"

require_dir "$TARGET_DIR"
require_dir "$SOURCE_DIR"

log_step "Codex 설치"

mkdir -p "$TARGET_DIR/.codex" "$TARGET_DIR/.agents/skills"

rsync -a \
  --delete \
  --exclude='skills' \
  --exclude='.DS_Store' \
  "$SOURCE_DIR/" "$TARGET_DIR/.codex/" > /dev/null
log_success ".codex/ 동기화"

rsync -a \
  --delete \
  --exclude='.DS_Store' \
  "$SOURCE_DIR/skills/" "$TARGET_DIR/.agents/skills/" > /dev/null
log_success ".agents/skills/ 동기화"

rewrite_installed_references "$TARGET_DIR"
log_success "설치 후 참조 경로 보정"

create_codex_agents_md "$SOURCE_DIR" "$TARGET_DIR/.codex/AGENTS.md"
log_success ".codex/AGENTS.md 생성"
