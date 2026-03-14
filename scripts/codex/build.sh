#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

log_step "Codex 빌드 산출물 생성"
require_dir "$SRC_DIR"

sync_tree "$SRC_DIR" "$BUILD_DIR"
prune_codex_only_noise "$BUILD_DIR"
sanitize_markdown_tree "$BUILD_DIR"

log_success "Codex 빌드 완료 → $BUILD_DIR"
