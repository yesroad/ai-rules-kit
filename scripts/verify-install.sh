#!/bin/bash
# cc-kit 설치 검증 스크립트
# /setup 또는 /update-cc-kit 실행 후 대상 프로젝트 루트에서 실행
# 사용법: bash <path-to-cc-kit>/scripts/verify-install.sh

# ---------------------------------------------------------------------------
# 색상 코드 (터미널 지원 여부에 따라 비활성화)
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BOLD=''
  RESET=''
fi

# ---------------------------------------------------------------------------
# 카운터
# ---------------------------------------------------------------------------
PASS=0
FAIL=0
WARN=0

# ---------------------------------------------------------------------------
# 헬퍼 함수
# ---------------------------------------------------------------------------
pass() {
  echo -e "${GREEN}✅ PASS${RESET}  $1"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "${RED}❌ FAIL${RESET}  $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo -e "${YELLOW}⚠️  WARN${RESET}  $1"
  WARN=$((WARN + 1))
}

section() {
  echo ""
  echo -e "${BOLD}── $1${RESET}"
}

# ---------------------------------------------------------------------------
# 실행 위치 확인
# ---------------------------------------------------------------------------
if [ ! -d ".claude" ]; then
  echo -e "${RED}오류: .claude/ 디렉토리를 찾을 수 없습니다.${RESET}"
  echo "대상 프로젝트 루트에서 실행하세요."
  exit 1
fi

echo ""
echo -e "${BOLD}cc-kit 설치 검증${RESET}"
echo "검증 경로: $(pwd)/.claude"

# ---------------------------------------------------------------------------
# 1. .claude/agents/ 검사
# ---------------------------------------------------------------------------
section "1. agents/"

EXPECTED_AGENTS=("code-reviewer.md" "explore.md" "git-operator.md" "lint-fixer.md" "nextjs-reviewer.md")
EXPECTED_AGENT_COUNT=${#EXPECTED_AGENTS[@]}

if [ ! -d ".claude/agents" ]; then
  fail ".claude/agents/ 디렉토리가 없습니다"
else
  ACTUAL_AGENT_COUNT=$(find .claude/agents -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')

  if [ "$ACTUAL_AGENT_COUNT" -eq "$EXPECTED_AGENT_COUNT" ]; then
    pass ".claude/agents/ 존재 (파일 수: ${ACTUAL_AGENT_COUNT}/${EXPECTED_AGENT_COUNT})"
  elif [ "$ACTUAL_AGENT_COUNT" -gt "$EXPECTED_AGENT_COUNT" ]; then
    warn ".claude/agents/ 존재하나 파일 수 불일치 (${ACTUAL_AGENT_COUNT}개, 기준 ${EXPECTED_AGENT_COUNT}개) — 커스텀 에이전트가 포함되었을 수 있습니다"
  else
    fail ".claude/agents/ 파일 부족 (${ACTUAL_AGENT_COUNT}/${EXPECTED_AGENT_COUNT}개)"
  fi

  # 필수 에이전트 파일 개별 확인
  for agent in "${EXPECTED_AGENTS[@]}"; do
    if [ ! -f ".claude/agents/${agent}" ]; then
      fail "  누락: .claude/agents/${agent}"
    fi
  done
fi

# ---------------------------------------------------------------------------
# 2. .claude/skills/ 검사
# ---------------------------------------------------------------------------
section "2. skills/"

EXPECTED_SKILLS=(
  "agents-generator"
  "bug-fix"
  "code-quality"
  "commit-helper"
  "component-creator"
  "docs-creator"
  "migration-helper"
  "next-project-structure"
  "nextjs-coding-convention"
  "pr-review-responder"
  "refactor"
  "test-e2e"
  "test-integration"
  "test-unit"
  "web-design"
)
EXPECTED_SKILL_COUNT=${#EXPECTED_SKILLS[@]}

if [ ! -d ".claude/skills" ]; then
  fail ".claude/skills/ 디렉토리가 없습니다"
else
  ACTUAL_SKILL_COUNT=$(find .claude/skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')

  if [ "$ACTUAL_SKILL_COUNT" -eq "$EXPECTED_SKILL_COUNT" ]; then
    pass ".claude/skills/ 존재 (디렉토리 수: ${ACTUAL_SKILL_COUNT}/${EXPECTED_SKILL_COUNT})"
  elif [ "$ACTUAL_SKILL_COUNT" -gt "$EXPECTED_SKILL_COUNT" ]; then
    warn ".claude/skills/ 존재하나 디렉토리 수 불일치 (${ACTUAL_SKILL_COUNT}개, 기준 ${EXPECTED_SKILL_COUNT}개) — 커스텀 스킬이 포함되었을 수 있습니다"
  else
    fail ".claude/skills/ 디렉토리 부족 (${ACTUAL_SKILL_COUNT}/${EXPECTED_SKILL_COUNT}개)"
  fi

  # 필수 스킬 디렉토리 개별 확인
  for skill in "${EXPECTED_SKILLS[@]}"; do
    if [ ! -d ".claude/skills/${skill}" ]; then
      fail "  누락: .claude/skills/${skill}/"
    fi
  done
fi

# ---------------------------------------------------------------------------
# 3. .claude/settings.json 존재 확인
# ---------------------------------------------------------------------------
section "3. settings.json 존재"

if [ -f ".claude/settings.json" ]; then
  pass ".claude/settings.json 존재"
else
  fail ".claude/settings.json 없음"
fi

# ---------------------------------------------------------------------------
# 4. settings.json에 planMode: true 포함 여부
# ---------------------------------------------------------------------------
section "4. planMode 설정"

if [ ! -f ".claude/settings.json" ]; then
  warn "settings.json 없어 planMode 확인 불가 (항목 3 실패)"
else
  # JSON 파싱: python3 → python → grep 순서로 폴백
  if command -v python3 &>/dev/null; then
    PLAN_MODE=$(python3 -c "
import json, sys
try:
    d = json.load(open('.claude/settings.json'))
    print(str(d.get('planMode', '')).lower())
except Exception as e:
    print('error')
" 2>/dev/null)
  elif command -v python &>/dev/null; then
    PLAN_MODE=$(python -c "
import json, sys
try:
    d = json.load(open('.claude/settings.json'))
    print(str(d.get('planMode', '')).lower())
except Exception as e:
    print('error')
" 2>/dev/null)
  else
    # python 없을 경우 grep으로 단순 검사
    PLAN_MODE=$(grep -o '"planMode"\s*:\s*true' .claude/settings.json | wc -l | tr -d ' ')
    [ "$PLAN_MODE" -gt 0 ] && PLAN_MODE="true" || PLAN_MODE="false"
  fi

  if [ "$PLAN_MODE" = "true" ]; then
    pass "planMode: true 확인"
  elif [ "$PLAN_MODE" = "error" ]; then
    warn "settings.json JSON 파싱 실패 — 파일 형식을 확인하세요"
  else
    fail "planMode: true 미설정 (현재 값: '${PLAN_MODE}')"
  fi
fi

# ---------------------------------------------------------------------------
# 5. hooks 설정 존재 여부
# ---------------------------------------------------------------------------
section "5. hooks 설정"

HOOKS_DIR_EXISTS=false
HOOKS_IN_SETTINGS=false

if [ -d ".claude/hooks" ]; then
  HOOK_FILE_COUNT=$(find .claude/hooks -maxdepth 1 -type f | wc -l | tr -d ' ')
  if [ "$HOOK_FILE_COUNT" -gt 0 ]; then
    HOOKS_DIR_EXISTS=true
  fi
fi

if [ -f ".claude/settings.json" ]; then
  if command -v python3 &>/dev/null; then
    HAS_HOOKS=$(python3 -c "
import json
try:
    d = json.load(open('.claude/settings.json'))
    print('true' if 'hooks' in d and d['hooks'] else 'false')
except:
    print('false')
" 2>/dev/null)
  elif command -v python &>/dev/null; then
    HAS_HOOKS=$(python -c "
import json
try:
    d = json.load(open('.claude/settings.json'))
    print('true' if 'hooks' in d and d['hooks'] else 'false')
except:
    print('false')
" 2>/dev/null)
  else
    HAS_HOOKS=$(grep -o '"hooks"' .claude/settings.json | wc -l | tr -d ' ')
    [ "$HAS_HOOKS" -gt 0 ] && HAS_HOOKS="true" || HAS_HOOKS="false"
  fi
  [ "$HAS_HOOKS" = "true" ] && HOOKS_IN_SETTINGS=true
fi

if $HOOKS_DIR_EXISTS && $HOOKS_IN_SETTINGS; then
  pass "hooks 설정 존재 (.claude/hooks/ 디렉토리 + settings.json hooks 키)"
elif $HOOKS_DIR_EXISTS; then
  warn ".claude/hooks/ 디렉토리 존재하나 settings.json에 hooks 키 없음"
elif $HOOKS_IN_SETTINGS; then
  warn "settings.json에 hooks 키 존재하나 .claude/hooks/ 디렉토리 없음"
else
  warn "hooks 설정 없음 — /setup-notifier 실행 여부를 확인하세요"
fi

# ---------------------------------------------------------------------------
# 6. .claude/commands/ 검사
# ---------------------------------------------------------------------------
section "6. commands/"

EXPECTED_COMMANDS=("commit.md" "done.md" "setup.md" "setup-notifier.md" "start.md" "test.md" "update-cc-kit.md" "work.md")
EXPECTED_COMMAND_COUNT=${#EXPECTED_COMMANDS[@]}

if [ ! -d ".claude/commands" ]; then
  fail ".claude/commands/ 디렉토리가 없습니다"
else
  ACTUAL_COMMAND_COUNT=$(find .claude/commands -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')

  if [ "$ACTUAL_COMMAND_COUNT" -eq "$EXPECTED_COMMAND_COUNT" ]; then
    pass ".claude/commands/ 존재 (파일 수: ${ACTUAL_COMMAND_COUNT}/${EXPECTED_COMMAND_COUNT})"
  elif [ "$ACTUAL_COMMAND_COUNT" -gt "$EXPECTED_COMMAND_COUNT" ]; then
    warn ".claude/commands/ 존재하나 파일 수 불일치 (${ACTUAL_COMMAND_COUNT}개, 기준 ${EXPECTED_COMMAND_COUNT}개) — 커스텀 커맨드가 포함되었을 수 있습니다"
  else
    fail ".claude/commands/ 파일 부족 (${ACTUAL_COMMAND_COUNT}/${EXPECTED_COMMAND_COUNT}개)"
  fi

  # 필수 커맨드 파일 개별 확인
  for cmd in "${EXPECTED_COMMANDS[@]}"; do
    if [ ! -f ".claude/commands/${cmd}" ]; then
      fail "  누락: .claude/commands/${cmd}"
    fi
  done
fi

# ---------------------------------------------------------------------------
# 최종 요약
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}────────────────────────────────${RESET}"
echo -e "${BOLD}검증 요약${RESET}"
echo -e "  ${GREEN}✅ PASS${RESET}  ${PASS}개"
echo -e "  ${RED}❌ FAIL${RESET}  ${FAIL}개"
echo -e "  ${YELLOW}⚠️  WARN${RESET}  ${WARN}개"
echo -e "${BOLD}────────────────────────────────${RESET}"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}설치가 불완전합니다. FAIL 항목을 확인 후 /setup 또는 /update-cc-kit을 다시 실행하세요.${RESET}"
  echo ""
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}설치가 완료되었으나 경고 항목을 검토하세요.${RESET}"
  echo ""
  exit 0
else
  echo -e "${GREEN}모든 검증 통과. cc-kit 설치가 정상입니다.${RESET}"
  echo ""
  exit 0
fi
