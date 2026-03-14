#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

TARGET_DIR="${1:-$BUILD_DIR}"
require_dir "$TARGET_DIR"

log_step "Codex 빌드 검증"

patterns=(
  'Task\('
  '\.claude/'
  '@\.claude/'
  '^tools:'
  '^model:'
  '^allowed-tools:'
  '\bhaiku\b'
  '\bsonnet\b'
  '\bopus\b'
  'TeamCreate'
  'Task 병렬'
  '일반 Task'
)

for pattern in "${patterns[@]}"; do
  if rg -n "$pattern" "$TARGET_DIR" -S >/dev/null 2>&1; then
    echo "금지 패턴 발견: $pattern"
    rg -n "$pattern" "$TARGET_DIR" -S || true
    exit 1
  fi
done

required_paths=(
  "$TARGET_DIR/agents"
  "$TARGET_DIR/commands"
  "$TARGET_DIR/instructions"
  "$TARGET_DIR/rules/core"
  "$TARGET_DIR/skills"
)

for path in "${required_paths[@]}"; do
  [[ -e "$path" ]] || fail "필수 경로 없음 → $path"
done

STAGE_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

"$SCRIPT_DIR/install.sh" "$STAGE_DIR" "$TARGET_DIR" > /dev/null
validate_installed_markdown_refs "$STAGE_DIR"

log_success "검증 완료"
