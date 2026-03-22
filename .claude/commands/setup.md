---
name: setup
description: cc-kit을 현재 프로젝트에 설치합니다. 프로젝트 기술 스택을 입력받아 맞춤형 CLAUDE.md와 .claude/ 설정을 생성합니다.
---

현재 프로젝트에 cc-kit을 설치합니다.

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

감지 결과를 기반으로 아래 매핑표에 따라 각 질문의 `(추천)` 항목을 결정합니다:

| 감지 조건 | 추천 항목 |
|-----------|-----------|
| `dependencies`에 `next` 있음 | Q1 → Next.js |
| `dependencies`에 `react` 있음 (next 없음) | Q1 → React |
| `dependencies`에 `vue` 있음 | Q1 → Vue |
| `app/` 또는 `src/app/` 디렉토리 있음 | Q2 → App Router |
| `pages/` 또는 `src/pages/` 디렉토리 있음 | Q2 → Pages Router |
| `dependencies`에 `tailwindcss` 있음 | Q3 → TailwindCSS |
| `dependencies`에 `@emotion/react` 또는 `@emotion/styled` 있음 | Q3 → Emotion |
| `dependencies`에 `@tanstack/react-query` 있음 | Q4 → TanStack Query |
| `dependencies`에 `swr` 있음 | Q4 → SWR |
| `dependencies`에 `jotai` 있음 | Q5 → Jotai |
| `dependencies`에 `zustand` 있음 | Q5 → Zustand |
| `dependencies`에 `@reduxjs/toolkit` 있음 | Q5 → Redux Toolkit |

감지된 항목이 없으면 `(추천)` 없이 질문합니다.

---

## 1단계: 프로젝트 기술 스택 인터뷰

아래 질문을 순서대로 물어보세요. 답변을 모두 받은 후 설치를 진행합니다.
0단계에서 감지된 항목은 해당 번호 옆에 `(추천)` 을 표시합니다.

---

**Q1. 프레임워크**

1. Next.js
2. React (CRA / Vite)
3. Vue
4. 기타 (Node.js, Python, Go 등 — 프론트엔드 전용 rules 제외)

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

**Q6. MCP 서버** (복수 선택 가능)

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

## 2단계: 파일 설치

답변을 받은 후 아래 스크립트를 실행합니다.

Q6 답변을 기반으로 스크립트 실행 전에 `SELECTED_MCP` 변수를 설정합니다:

| Q6 선택         | SELECTED_MCP 값         |
| --------------- | ----------------------- |
| 1 (Figma)       | `Figma`                 |
| 2 (Supabase)    | `supabase`              |
| 3 (Playwright)  | `playwright`            |
| 4 (Atlassian)   | `Atlassian`             |
| 5 (shadcn)      | `shadcn`                |
| 복수 선택 "1 3" | `Figma,playwright`      |
| 6 또는 엔터     | (빈 문자열, 설치 안 함) |

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

for dir in rules instructions agents skills commands hooks scripts; do
  [ -d "$PLUGIN_ROOT/$dir" ] && cp -r "$PLUGIN_ROOT/$dir/" ".claude/$dir/"
done

# hooks 실행 권한 부여
[ -f ".claude/hooks/notify.sh" ] && chmod +x .claude/hooks/notify.sh

# .mcp.json: Q6 선택 서버만 추가 (없으면 새로 생성, 있으면 선택 항목만 머지)
# SELECTED_MCP: Q6 답변 기반으로 Claude가 설정 — 쉼표 구분 서버 키 목록
# 예) SELECTED_MCP="Figma,playwright" 또는 SELECTED_MCP="" (없음)
# 서버 키 매핑: 1=Figma, 2=supabase, 3=playwright, 4=Atlassian
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

[ "$PLUGIN_ROOT" = "/tmp/cc-kit_install" ] && rm -rf /tmp/cc-kit_install

# .mcp.json 보안 안내
if [ -f ".mcp.json" ]; then
  if ! grep -q ".mcp.json" .gitignore 2>/dev/null; then
    echo "⚠️  .mcp.json에 API 키를 입력한 후 .gitignore에 추가하세요: echo '.mcp.json' >> .gitignore"
  fi
fi

echo "✅ .claude/ 설치 완료"
```

## 3단계: settings.json 생성

`.claude/settings.json`이 없는 경우 생성합니다:

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ./.claude/hooks/notify.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## 4단계: 기존 CLAUDE.md 백업

기존 `CLAUDE.md`가 있으면 `.claude/CLAUDE.back.md`로 백업합니다:

```bash
[ -f CLAUDE.md ] && cp CLAUDE.md .claude/CLAUDE.back.md && echo "✅ 기존 CLAUDE.md → .claude/CLAUDE.back.md 백업 완료"
```

## 5단계: 알림 설정

`/setup-notifier`를 실행합니다.

## 6단계: CLAUDE.md 생성

`agents-generator` 스킬을 호출하여 CLAUDE.md를 생성합니다.

호출 시 아래 컨텍스트를 함께 전달합니다:

**기술 스택 (인터뷰 답변 요약):**

- 프레임워크: {Q1 답변} ({Q2 답변, Next.js인 경우})
- 스타일링: {Q3 답변}
- 서버 상태: {Q4 답변}
- 전역 상태: {Q5 답변}

**포함할 @참조 (결정표 기반):**

| rules 파일                    | 포함 조건                            |
| ----------------------------- | ------------------------------------ |
| `thinking-model.md`           | 항상                                 |
| `required-behaviors.md`       | 항상                                 |
| `forbidden-patterns.md`       | 항상                                 |
| `unit-test-conventions.md`    | 항상                                 |
| `pr-guide.md`                 | 항상                                 |
| `policy-definitions.md`       | 항상                                 |
| `coding-standards.md`         | Q1 = Next.js 또는 React              |
| `react-nextjs-conventions.md` | Q1 = Next.js 또는 React              |
| `react-hooks-patterns.md`     | Q1 = Next.js 또는 React              |
| `nextjs-app-router.md`        | Q1 = Next.js **AND** Q2 = App Router |
| `state-and-server-state.md`   | Q4 = TanStack Query 또는 SWR         |
| `accessibility.md`            | Q1 = 프론트엔드 (Vue 포함)           |
| `vue-conventions.md`          | Q1 = Vue                             |

> **Q1 = 기타**: `thinking-model.md`, `required-behaviors.md`, `forbidden-patterns.md`, `unit-test-conventions.md`, `pr-guide.md`, `policy-definitions.md`만 포함. 프론트엔드 전용 rules (`coding-standards.md`, `react-*`, `nextjs-*`, `state-*`, `accessibility.md`)는 제외.

**포함할 스킬 quick_ref (결정표 기반):**

| 스킬                     | 포함 조건                                        |
| ------------------------ | ------------------------------------------------ |
| `commit-helper`          | 항상                                             |
| `pr-review-responder`    | 항상                                             |
| `code-quality`           | 항상                                             |
| `refactor`               | 항상                                             |
| `bug-fix`                | 항상                                             |
| `migration-helper`       | 항상                                             |
| `test-generator`         | 항상                                             |
| `next-project-structure` | Q1 = Next.js                                     |
| `component-creator`      | Q1 = Next.js 또는 React                          |
| `web-design`             | Q1 = Next.js 또는 React **AND** Q3 = TailwindCSS |

agents-generator가 생성한 CLAUDE.md에 `<quick_ref>` 섹션이 없으면 아래 결정표에 따라 추가합니다.

**예시: Q1=Next.js, Q3=TailwindCSS인 경우**

```markdown
<quick_ref>
| 상황 | 커맨드/스킬 |
|------|------------|
| 작업 시작 | /start |
| 작업 완료+PR | /done |
| 커밋 | /commit |
| UI 구현 | web-design 스킬 |
| 컴포넌트 생성 | component-creator 스킬 |
| 도메인 스캐폴딩 | next-project-structure 스킬 |
| 버그 수정 | bug-fix 스킬 |
| 리팩토링 | refactor 스킬 |
| 테스트 | test-generator 스킬 |
| 에이전트 선택 | @.claude/instructions/multi-agent/agent-roster.md |
| 복잡도 판단 | @.claude/instructions/workflow-patterns/sequential-thinking.md |
</quick_ref>
```

**예시: Q1=React, Q3=Emotion인 경우** (`web-design` 제외, `next-project-structure` 제외)

```markdown
<quick_ref>
| 상황 | 커맨드/스킬 |
|------|------------|
| 작업 시작 | /start |
| 작업 완료+PR | /done |
| 커밋 | /commit |
| 컴포넌트 생성 | component-creator 스킬 |
| 버그 수정 | bug-fix 스킬 |
| 리팩토링 | refactor 스킬 |
| 테스트 | test-generator 스킬 |
| 에이전트 선택 | @.claude/instructions/multi-agent/agent-roster.md |
| 복잡도 판단 | @.claude/instructions/workflow-patterns/sequential-thinking.md |
</quick_ref>
```

**예시: Q1=Vue인 경우** (`component-creator`, `web-design`, `next-project-structure` 모두 제외)

```markdown
<quick_ref>
| 상황 | 커맨드/스킬 |
|------|------------|
| 작업 시작 | /start |
| 작업 완료+PR | /done |
| 커밋 | /commit |
| 버그 수정 | bug-fix 스킬 |
| 리팩토링 | refactor 스킬 |
| 테스트 | test-generator 스킬 |
| 에이전트 선택 | @.claude/instructions/multi-agent/agent-roster.md |
| 복잡도 판단 | @.claude/instructions/workflow-patterns/sequential-thinking.md |
</quick_ref>
```

## 7단계: 설치 완료 보고

설치된 항목, 백업 여부, 생성된 CLAUDE.md 내용을 사용자에게 보여주고 사용 가능한 커맨드를 안내합니다.
