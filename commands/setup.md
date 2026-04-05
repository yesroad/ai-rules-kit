---
name: setup
description: cc-kit을 현재 프로젝트에 설치합니다. 프로젝트 기술 스택을 입력받아 맞춤형 CLAUDE.md와 .claude/ 설정을 생성합니다.
---

현재 프로젝트에 cc-kit을 설치합니다.

## 진행 상황 추적

실행 시작 시 아래 항목을 TaskCreate로 등록한다. 각 단계 시작 시 `in_progress`, 완료 시 `completed`로 TaskUpdate한다.

- 프로젝트 탐색 (자동 감지)
- 기술 스택 인터뷰
- CLAUDE.md 생성
- 설정 파일 생성
- 설치 완료

---

## 0단계: 프로젝트 탐색

인터뷰 전에 프로젝트를 탐색하여 기술 스택을 자동 감지합니다.

```bash
# package.json 읽기
cat package.json 2>/dev/null || true

# 라우터 감지 (Next.js인 경우)
ls app/ src/app/ 2>/dev/null | head -1 || true
ls pages/ src/pages/ 2>/dev/null | head -1 || true

# 스타일링 설정 파일 감지
ls tailwind.config.* 2>/dev/null || true
```

감지 결과를 아래 매핑표에 따라 자동 확정합니다:

| 감지 조건 | 자동 확정 |
|-----------|-----------|
| `dependencies`에 `next` 있음 | Q1 → Next.js |
| `dependencies`에 `react` 있음 (next 없음) | Q1 → React |
| `app/` 또는 `src/app/` 디렉토리 있음 | Q2 → App Router |
| `pages/` 또는 `src/pages/` 디렉토리 있음 | Q2 → Pages Router |
| `dependencies`에 `tailwindcss` 있음 | Q3 → TailwindCSS |
| `tailwindcss` 버전이 `^4` 또는 `>=4` | Q3-version → v4 |
| `tailwindcss` 버전이 `^3` 또는 `>=3 <4` | Q3-version → v3 |
| `dependencies`에 `@emotion/react` 또는 `@emotion/styled` 있음 | Q3 → Emotion |
| `dependencies`에 `@tanstack/react-query` 있음 | Q4 → TanStack Query |
| `dependencies`에 `swr` 있음 | Q4 → SWR |
| `dependencies`에 `jotai` 있음 | Q5 → Jotai |
| `dependencies`에 `zustand` 있음 | Q5 → Zustand |
| `dependencies`에 `@reduxjs/toolkit` 있음 | Q5 → Redux Toolkit |
| `dependencies`에 `zod` 있음 | Q6 → Zod |
| `dependencies`에 `yup` 있음 | Q6 → Yup |

---

## 1단계: 프로젝트 기술 스택 인터뷰

### 감지 결과 확인 → 미감지만 질문

0단계 감지 결과가 있으면 사용자에게 확인을 받는다.

**진행 방식 (순서대로 엄격히 지킨다):**

**STEP A. 감지 결과만 보여주고 Y/n을 받는다** — 이 메시지에 다른 질문을 추가하지 않는다:
   ```
   📋 감지된 기술 스택:
   - 프레임워크: Next.js (App Router)
   - 스타일링: TailwindCSS v4
   - 서버 상태: TanStack Query
   - 전역 상태: Zustand
   - 폼 검증: Zod

   이대로 진행할까요? (Y/n)
   ```

**STEP B. Y/n 응답을 받은 후** 다음 중 하나를 실행한다:
- `Y` 또는 엔터 → 감지 항목 확정. 미감지 항목(Q1~Q6 중 감지 안 된 것)을 순서대로 **하나씩** 질문
- `n` → 감지 결과 무시. Q1~Q6을 순서대로 **하나씩** 질문
- 감지된 항목이 하나도 없으면 → Q1~Q6을 순서대로 **하나씩** 질문

질문 후 대답을 받으면 다음 질문으로 넘어간다. Q1~Q6이 모두 확정되면 Q7, Q8을 순서대로 **하나씩** 질문한다.

> **⚠️ Q7(MCP)과 Q8(Basic Memory)는 항상 묻는 항목이다.** 감지 여부와 무관하게 반드시 포함한다.
>
> **⚠️ 질문은 반드시 하나씩 순서대로 한다. 여러 질문을 한 번에 보내지 않는다.**
> 모든 답변을 받은 뒤 2단계로 넘어간다.

아래는 **미감지 시 질문할 내용**입니다:

---

**Q1. 프레임워크**

1. Next.js
2. React (CRA / Vite)
3. 기타 (Node.js, Python, Go 등 — 프론트엔드 전용 rules 제외)

> **참고**: Vue는 지원하지 않습니다. Vue 프로젝트는 Q1 = 기타로 선택하세요.

---

**Q2. 라우터** (Q1 = Next.js일 때만 질문)

1. App Router
2. Pages Router

---

**Q3. 스타일링**

1. TailwindCSS
2. Emotion
3. CSS Modules
4. 기타

**Q3-1. TailwindCSS 버전** (Q3 = TailwindCSS일 때만, 미감지 시 질문)

1. v4 (`tailwind.config.js` 없음, CSS `@theme` 기반)
2. v3 (`tailwind.config.js` 기반)

---

**Q4. 서버 상태 관리**

1. TanStack Query
2. SWR
3. 없음

---

**Q5. 전역 UI 상태 관리**

1. Jotai
2. Zustand
3. Redux Toolkit
4. 없음

---

**Q6. 폼 검증 라이브러리**

1. Zod
2. Yup
3. 없음

---

**Q7. MCP 서버** (복수 선택 가능)

| 번호 | 서버       | 용도                                               |
| ---- | ---------- | -------------------------------------------------- |
| 1    | Figma      | 피그마 디자인 파일 읽기 (API 키 필요)              |
| 2    | Supabase   | DB 쿼리, 마이그레이션, Edge Function (API 키 필요) |
| 3    | Playwright | 브라우저 자동화, E2E 테스트 (설정 불필요)          |
| 4    | Atlassian  | Jira·Confluence 연동 (API 키 필요)                 |
| 5    | shadcn     | shadcn/ui 컴포넌트 검색 및 설치 (설정 불필요)      |
| 6    | 없음       |                                                    |

예시: "1 3" → Figma + Playwright 설치

---

**Q8. Basic Memory** — 세션이 끊겨도 프로젝트 컨텍스트를 기억합니다. 사용하시겠어요?

1. 예
2. 아니오

> Basic Memory는 로컬에서만 실행되며 별도 API 키가 필요 없습니다.

---

## 2단계: 파일 설치

답변을 받은 후 아래 스크립트를 실행합니다.

Q7 답변을 기반으로 스크립트 실행 전에 `SELECTED_MCP` 변수를 설정합니다:

| Q7 선택         | SELECTED_MCP 값         |
| --------------- | ----------------------- |
| 1 (Figma)       | `Figma`                 |
| 2 (Supabase)    | `supabase`              |
| 3 (Playwright)  | `playwright`            |
| 4 (Atlassian)   | `Atlassian`             |
| 5 (shadcn)      | `shadcn`                |
| 복수 선택 "1 3" | `Figma,playwright`      |
| 6 또는 엔터     | (빈 문자열, 설치 안 함) |

Q8 답변을 기반으로 `INSTALL_BASIC_MEMORY` 변수를 설정합니다:

| Q8 선택  | INSTALL_BASIC_MEMORY 값 |
| -------- | ----------------------- |
| 1 (예)   | `y`                     |
| 2 또는 엔터 | (빈 문자열)          |

```bash
#!/bin/bash
set -e

command -v python3 >/dev/null 2>&1 || { echo "❌ python3가 필요합니다. (MCP 서버 선택 시 사용)"; exit 1; }

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT" ]; then
  PLUGIN_ROOT="$HOME/.claude/plugins/cache/cc-kit"
fi

if [ ! -d "$PLUGIN_ROOT" ]; then
  echo "GitHub에서 cc-kit을 가져옵니다..."
  git clone --depth 1 https://github.com/yesroad/cc-kit.git /tmp/cc-kit_install
  PLUGIN_ROOT="/tmp/cc-kit_install"
fi

mkdir -p .claude

for dir in rules workflows agents skills commands hooks scripts; do
  [ -d "$PLUGIN_ROOT/$dir" ] && cp -r "$PLUGIN_ROOT/$dir/" ".claude/$dir/"
done

# hooks 실행 권한 부여
[ -f ".claude/hooks/notify.sh" ] && chmod +x .claude/hooks/notify.sh
[ -f ".claude/hooks/guard-check.sh" ] && chmod +x .claude/hooks/guard-check.sh

# settings.json에 harness hooks 주입 (없으면 생성, 있으면 머지)
python3 - <<'PYEOF'
import json, os

settings_path = ".claude/settings.json"
settings = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)

hooks = settings.setdefault("hooks", {})

# PostToolUse 훅 (guard-check) — 이미 있으면 건드리지 않음
if "PostToolUse" not in hooks:
    hooks["PostToolUse"] = [{
        "matcher": "Write|Edit",
        "hooks": [{"type": "command",
                   "command": "bash \"./.claude/hooks/guard-check.sh\"",
                   "timeout": 10}]
    }]

# Stop 훅 (완료 알림) — 이미 있으면 건드리지 않음
if "Stop" not in hooks:
    hooks["Stop"] = [{
        "matcher": "",
        "hooks": [{"type": "command",
                   "command": "NOTIFIER_TITLE='CC-Kit' NOTIFIER_MESSAGE='응답 완료 — /done으로 검증하세요' bash \"./.claude/hooks/notify.sh\"",
                   "timeout": 5}]
    }]

# planMode 기본값 설정 — 이미 설정한 경우 덮어쓰지 않음
if "planMode" not in settings:
    settings["planMode"] = True

# Plan Mode 계획 파일을 프로젝트 로컬에 저장
if "plansDirectory" not in settings:
    settings["plansDirectory"] = "./.claude/plans"

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("📋 settings.json harness hooks 주입 완료")
PYEOF

# .mcp.json: Q7 선택 서버만 추가 (없으면 새로 생성, 있으면 선택 항목만 머지)
# SELECTED_MCP: Q7 답변 기반으로 Claude가 설정 — 쉼표 구분 서버 키 목록
# 예) SELECTED_MCP="Figma,playwright" 또는 SELECTED_MCP="" (없음)
# 서버 키 매핑: 1=Figma, 2=supabase, 3=playwright, 4=Atlassian, 5=shadcn
if [ -n "$SELECTED_MCP" ] && [ -f "$PLUGIN_ROOT/.mcp.json" ]; then
  MCP_TEMPLATE="$PLUGIN_ROOT/.mcp.json" MCP_SELECTED="$SELECTED_MCP" python3 - <<'PYEOF'
import json, os

template_path = os.environ["MCP_TEMPLATE"]
selected_keys = [k.strip() for k in os.environ.get("MCP_SELECTED", "").split(",") if k.strip()]

with open(template_path) as f:
    template = json.load(f)

template_servers = template.get("mcpServers", {})

# 선택된 서버만 필터
selected_servers = {k: v for k, v in template_servers.items() if k in selected_keys}
if not selected_servers:
    print("📋 선택된 MCP 서버 없음 — .mcp.json 생성 안 함")
    exit(0)

# 기존 .mcp.json 로드 또는 빈 구조 생성
if os.path.exists(".mcp.json"):
    with open(".mcp.json") as f:
        existing = json.load(f)
else:
    existing = {}

existing_servers = existing.setdefault("mcpServers", {})

added = []
for name, config in selected_servers.items():
    if name not in existing_servers:
        existing_servers[name] = config
        added.append(name)

with open(".mcp.json", "w") as f:
    json.dump(existing, f, indent=2, ensure_ascii=False)
    f.write("\n")

if added:
    print(f"📋 .mcp.json 완료 — 추가된 서버: {', '.join(added)}")
else:
    print("📋 .mcp.json 변경 없음 (선택 서버가 이미 존재)")
PYEOF
fi

# Basic Memory MCP: Q8 y/n 기반으로 Claude가 설정
# INSTALL_BASIC_MEMORY="y" 또는 "" (설치 안 함)
if [ "$INSTALL_BASIC_MEMORY" = "y" ] && [ -f "$PLUGIN_ROOT/.mcp.json" ]; then
  MCP_TEMPLATE="$PLUGIN_ROOT/.mcp.json" python3 - <<'PYEOF'
import json, os

template_path = os.environ["MCP_TEMPLATE"]
with open(template_path) as f:
    template = json.load(f)

basic_memory_config = template.get("mcpServers", {}).get("basic-memory")
if not basic_memory_config:
    print("❌ basic-memory 설정을 찾을 수 없습니다")
    exit(0)

if os.path.exists(".mcp.json"):
    with open(".mcp.json") as f:
        existing = json.load(f)
else:
    existing = {}

existing_servers = existing.setdefault("mcpServers", {})

if "basic-memory" not in existing_servers:
    existing_servers["basic-memory"] = basic_memory_config
    with open(".mcp.json", "w") as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("📋 .mcp.json Basic Memory 추가 완료")
else:
    print("📋 .mcp.json Basic Memory 이미 존재 — 건드리지 않음")
PYEOF
fi

# manifest.json 생성/갱신 (.claude/manifest.json에 cc-kit 키로 기록)
PLUGIN_ROOT="$PLUGIN_ROOT" python3 - <<'PYEOF'
import json, os
from datetime import date
from pathlib import Path

plugin_root = os.environ["PLUGIN_ROOT"]

# plugin.json에서 버전 읽기
plugin_json_path = os.path.join(plugin_root, "plugin.json")
version = "unknown"
if os.path.exists(plugin_json_path):
    with open(plugin_json_path) as f:
        version = json.load(f).get("version", "unknown")

# 설치된 파일 목록 수집
managed_dirs = ["rules", "workflows", "agents", "skills", "commands", "hooks", "scripts", "references"]
files = []
for d in managed_dirs:
    dir_path = Path(".claude") / d
    if dir_path.exists():
        for p in sorted(dir_path.rglob("*")):
            if p.is_file():
                files.append(str(p.relative_to(".claude")))

# 기존 manifest.json 로드 또는 빈 구조 생성
manifest_path = ".claude/manifest.json"
manifest = {}
if os.path.exists(manifest_path):
    with open(manifest_path) as f:
        manifest = json.load(f)

manifest["cc-kit"] = {
    "version": version,
    "installedAt": str(date.today()),
    "files": files
}

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"📋 manifest.json 생성 완료 — {len(files)}개 파일 기록")
PYEOF

[ "$PLUGIN_ROOT" = "/tmp/cc-kit_install" ] && rm -rf /tmp/cc-kit_install

# .mcp.json 보안 안내
if [ -f ".mcp.json" ]; then
  if ! grep -q ".mcp.json" .gitignore 2>/dev/null; then
    echo "⚠️  .mcp.json에 API 키를 입력한 후 .gitignore에 추가하세요: echo '.mcp.json' >> .gitignore"
  fi
fi

echo "✅ .claude/ 설치 완료"
```

## 3단계: 기존 CLAUDE.md 백업

기존 `CLAUDE.md`가 있으면 `.claude/CLAUDE.back.md`로 백업합니다:

```bash
[ -f CLAUDE.md ] && cp CLAUDE.md .claude/CLAUDE.back.md && echo "✅ 기존 CLAUDE.md → .claude/CLAUDE.back.md 백업 완료"
```

## 4단계: 알림 설정

`/setup-notifier`를 실행합니다.

## 5단계: CLAUDE.md 생성

`directive-generator` 스킬을 호출하여 CLAUDE.md를 생성합니다.

호출 시 아래 컨텍스트를 함께 전달합니다:

**기술 스택 (인터뷰 답변 요약):**

- 프레임워크: {Q1 답변} ({Q2 답변, Next.js인 경우})
- 스타일링: {Q3 답변}
- 서버 상태: {Q4 답변}
- 전역 상태: {Q5 답변}

**포함할 @참조 (결정표 기반):**

| 파일                                             | 위치                       | 포함 조건                            |
| ------------------------------------------------ | -------------------------- | ------------------------------------ |
| `model.md`                                       | `workflows/thinking/` | 항상                                     |
| `required-patterns.md`                           | `workflows/quality-gates/` | 항상                                  |
| `anti-patterns.md`                               | `workflows/quality-gates/` | 항상                                  |
| `unit-test-conventions.md`                       | `rules/core/`              | 항상                                 |
| `pr-guide.md`                                    | `workflows/git/`           | 항상                                 |
| `policies.md`                                    | `rules/core/`              | 항상                                 |
| `coding-standards.md`                            | `rules/core/`              | Q1 = Next.js 또는 React              |
| `react-conventions.md`                           | `rules/core/`              | Q1 = Next.js 또는 React              |
| `react-hooks-patterns.md`                        | `rules/core/`              | Q1 = Next.js 또는 React              |
| `nextjs-app-router.md`                           | `rules/core/`              | Q1 = Next.js **AND** Q2 = App Router |
| `state-and-server-state.md`                      | `rules/core/`              | Q4 = TanStack Query 또는 SWR         |
| `accessibility.md`                               | `rules/core/`              | Q1 = Next.js 또는 React              |
| `validation-patterns.md`                         | `rules/optional/`          | Q6 = Zod                             |
| `tailwindcss-v4.md`                              | `rules/optional/`          | Q3 = TailwindCSS **AND** Q3-1 = v4   |

> **Q1 = 기타**: `model.md`(`workflows/thinking/`), `required-patterns.md`, `anti-patterns.md`, `unit-test-conventions.md`, `pr-guide.md`(`workflows/git/`), `policies.md`만 포함. 프론트엔드 전용 rules (`coding-standards.md`, `react-*`, `nextjs-*`, `state-*`, `accessibility.md`)는 제외.

**포함할 스킬 quick_ref (결정표 기반):**

| 스킬                       | 포함 조건                                        |
| -------------------------- | ------------------------------------------------ |
| `commit-helper`            | 항상                                             |
| `pr-responder`             | 항상                                             |
| `code-quality`             | 항상                                             |
| `refactor`                 | 항상                                             |
| `bug-fix`                  | 항상                                             |
| `migration-helper`         | 항상                                             |
| `docs-creator`             | 항상                                             |
| `directive-generator`      | 항상                                             |
| `test-e2e`                 | 항상                                             |
| `test-unit`                | Q1 = Next.js 또는 React                          |
| `test-integration`         | Q1 = Next.js 또는 React                          |
| `code-level-review`        | Q1 = Next.js 또는 React                          |
| `nextjs-scaffold`          | Q1 = Next.js                                     |
| `component-creator`        | Q1 = Next.js 또는 React                          |
| `web-design`               | Q1 = Next.js 또는 React **AND** Q3 = TailwindCSS |

directive-generator가 생성한 CLAUDE.md에 `<quick_ref>` 섹션이 없으면 아래 결정표에 따라 추가합니다.

**예시: Q1=Next.js, Q3=TailwindCSS인 경우**

```markdown
<quick_ref>
| 상황 | 커맨드/스킬 |
|------|------------|
| 작업 시작 (계획) | /start |
| 구현 + 검증 | /work |
| 작업 완료+PR | /done |
| 커밋 | /commit |
| UI 구현 | web-design 스킬 |
| 컴포넌트 생성 | component-creator 스킬 |
| 도메인 스캐폴딩 | nextjs-scaffold 스킬 |
| 버그 수정 | bug-fix 스킬 |
| 리팩토링 | refactor 스킬 |
| 단위 테스트 | test-unit 스킬 |
| 통합 테스트 | test-integration 스킬 |
| E2E 테스트 | test-e2e 스킬 |
| 코드 컨벤션 | code-level-review 스킬 |
| 에이전트 선택 | @.claude/workflows/coordination/roster.md |
| 복잡도 판단 | @.claude/workflows/thinking/model.md |
</quick_ref>
```

**예시: Q1=React, Q3=Emotion인 경우** (`web-design` 제외, `nextjs-scaffold` 제외)

```markdown
<quick_ref>
| 상황 | 커맨드/스킬 |
|------|------------|
| 작업 시작 (계획) | /start |
| 구현 + 검증 | /work |
| 작업 완료+PR | /done |
| 커밋 | /commit |
| 컴포넌트 생성 | component-creator 스킬 |
| 버그 수정 | bug-fix 스킬 |
| 리팩토링 | refactor 스킬 |
| 단위 테스트 | test-unit 스킬 |
| 통합 테스트 | test-integration 스킬 |
| E2E 테스트 | test-e2e 스킬 |
| 코드 컨벤션 | code-level-review 스킬 |
| 에이전트 선택 | @.claude/workflows/coordination/roster.md |
| 복잡도 판단 | @.claude/workflows/thinking/model.md |
</quick_ref>
```

## 6단계: 설치 완료 보고

설치된 항목, 백업 여부, 생성된 CLAUDE.md 내용을 사용자에게 보여주고 아래 형식으로 안내합니다:

```
✅ cc-kit 설치 완료

📁 설치된 항목:
  .claude/rules/        — 코딩 규칙 (프레임워크별 선별 적용)
  .claude/agents/       — 전문화된 서브에이전트
  .claude/skills/       — 자동 트리거 스킬
  .claude/commands/     — 슬래시 커맨드
  .claude/workflows/ — 작업 방식 가이드
  .claude/hooks/        — 알림 훅
  .claude/rules/references/ — 라이브러리 레퍼런스 문서 (TypeScript·Zod)
  CLAUDE.md             — 프로젝트 루트 지시문 (새로 생성)

📋 사용 가능한 커맨드:
  /start          — 작업 시작 (Plan Mode → 분석 → 계획 생성)
  /work           — 구현 + 검증 (계획 읽기 → 구현 → 계획 대비 검증)
  /done           — 작업 완료 (검증 → 커밋 → PR 생성)
  /commit         — 커밋 플로우 자동화
  /test           — 단위 → 통합 → E2E 테스트 순차 실행
  /setup-notifier — macOS 알림 환경 설정 (최초 1회)

💡 자주 쓰는 스킬 (키워드로 자동 트리거):
  bug-fix               — "버그", "오류", "에러"
  refactor              — "리팩토링", "구조 개선"
  component-creator     — "컴포넌트 만들어", "훅 만들어"
  test-unit             — "단위 테스트", "유닛 테스트"
  test-e2e              — "e2e 테스트", "playwright"
  migration-helper      — "업그레이드", "마이그레이션"
  web-design            — "UI 만들어", "화면 구현"  (Next.js + Tailwind)
  code-level-review        — "코드 리뷰", "컨벤션 확인"
```

> CLAUDE.md가 백업된 경우: `.claude/CLAUDE.back.md`에서 이전 내용을 확인할 수 있습니다.
