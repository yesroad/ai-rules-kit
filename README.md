# cc-kit

Claude Code 확장 플러그인 — rules, agents, skills, commands를 포함한 AI 코딩 워크플로우 키트.

---

## 설치

### 1. 레포 클론

```bash
git clone https://github.com/yesroad/cc-kit
```

### 2. 프로젝트에 복사

적용할 프로젝트 루트에서 실행합니다:

```bash
CLAUDE_KIT=/path/to/cc-kit

mkdir -p .claude
cp -r $CLAUDE_KIT/rules      ./.claude/rules
cp -r $CLAUDE_KIT/agents     ./.claude/agents
cp -r $CLAUDE_KIT/skills     ./.claude/skills
cp -r $CLAUDE_KIT/commands   ./.claude/commands
cp -r $CLAUDE_KIT/hooks      ./.claude/hooks
cp    $CLAUDE_KIT/.mcp.json  ./.mcp.json
```

### 3. 프로젝트 설정

Claude Code에서 실행합니다:

```
/setup
```

기술 스택 인터뷰(6문항)를 진행한 후 프로젝트에 맞춤화된 `.claude/`와 CLAUDE.md를 자동 생성합니다.
이후 커맨드는 `/start`, `/done`, `/commit` 등 네임스페이스 없이 사용할 수 있습니다.

---

## 인터뷰 항목

| 질문               | 선택지                                                       |
| ------------------ | ------------------------------------------------------------ |
| **Q1. 프레임워크** | Next.js / React / Vue / 기타                                 |
| **Q2. 라우터**     | App Router / Pages Router (Next.js만)                        |
| **Q3. 스타일링**   | TailwindCSS / Emotion / CSS Modules / 기타                   |
| **Q4. 서버 상태**  | TanStack Query / SWR / 없음                                  |
| **Q5. 전역 상태**  | Jotai / Zustand / Redux Toolkit / 없음                       |
| **Q6. MCP 서버**   | Figma / Supabase / Playwright / Atlassian / shadcn / 없음 (복수 선택) |

---

## 사전 요구사항

```bash
# terminal-notifier (macOS 작업 완료 알림)
brew install terminal-notifier

# gh CLI (PR 생성 및 리뷰 조회)
brew install gh && gh auth login
```

---

## 커맨드

| 커맨드            | 설명                                                   |
| ----------------- | ------------------------------------------------------ |
| `/setup`          | 기술 스택 인터뷰 → 맞춤형 `.claude/` + CLAUDE.md 생성 |
| `/start`          | 작업 시작 — 분석 → 계획 → 확인                         |
| `/done`           | 작업 완료 — 검증 → 커밋 → PR                           |
| `/commit`         | staged 변경사항으로 커밋 메시지 생성 후 커밋           |
| `/quality`        | 포맷 → 린트 → 타입 체크 자동 수정                      |
| `/setup-notifier` | macOS 알림 초기 환경 설정 (최초 1회)                   |

---

## 스킬

스킬은 키워드를 입력하면 자동으로 트리거됩니다.

| 스킬                     | 트리거                              | 설명                                      | 조건                  |
| ------------------------ | ----------------------------------- | ----------------------------------------- | --------------------- |
| `commit-helper`          | "커밋 메시지 만들어줘"              | staged 기반 커밋 메시지 자동 생성         | 항상                  |
| `code-quality`           | "린트", "포맷", "타입체크"          | 린트·포맷·타입체크 통합 실행              | 항상                  |
| `bug-fix`                | "버그", "오류", "에러"              | 원인 분석 후 2-3가지 해결 옵션 제시       | 항상                  |
| `refactor`               | "리팩토링", "구조 개선"             | 정책 보호 테스트 포함 단계별 리팩토링     | 항상                  |
| `test-generator`         | "테스트 작성", "커버리지"           | 테스트 케이스 생성 + 커버리지 리포트      | 항상                  |
| `pr-review-responder`    | "리뷰 반영", PR 번호/URL            | 수용/거절/질문 분류 후 자동 반영          | 항상                  |
| `migration-helper`       | "업그레이드", "마이그레이션"        | 라이브러리 버전 업그레이드 단계적 실행    | 항상                  |
| `docs-creator`           | "문서 작성", "CLAUDE.md"            | AI 코딩 도구용 문서 작성                  | 항상                  |
| `agents-generator`       | "루트 지시문 생성"                  | 프로젝트 분석 후 CLAUDE.md/AGENTS.md 생성 | 항상                  |
| `component-creator`      | "컴포넌트 만들어", "페이지 추가"    | 프로젝트 패턴 기반 컴포넌트/훅 생성      | React / Next.js       |
| `next-project-structure` | "도메인 추가", "서비스 파일 만들어" | service + query 훅 + view 전체 스캐폴딩   | Next.js               |
| `web-design`             | "UI 만들어", "화면 구현"            | shadcn/ui 기반 2025 트렌드 UI 구현        | Next.js + TailwindCSS |

---

## 디렉토리 구조

```
cc-kit/
├── rules/core/                 # 코딩 규칙
│   ├── thinking-model.md           # 통합 사고 모델 (READ→REACT→ANALYZE→...)
│   ├── coding-standards.md         # TypeScript 표준, 에러 처리, React 패턴
│   ├── react-nextjs-conventions.md # React/Next.js 컨벤션, Import 순서
│   ├── react-hooks-patterns.md     # Hook 성능 패턴 (useMemo, useRef 등)
│   ├── nextjs-app-router.md        # App Router 전용 규칙
│   ├── state-and-server-state.md   # TanStack Query v5 + Jotai 상태 경계
│   ├── unit-test-conventions.md    # 순수 함수 유닛 테스트 규칙
│   ├── accessibility.md            # WCAG 2.1 AA 접근성 규칙
│   ├── pr-guide.md                 # PR 작성 가이드
│   ├── policy-definitions.md       # 정책(Policy) 정의 기준
│   └── vue-conventions.md          # Vue 3 + Composition API 컨벤션
│
├── agents/                     # 전문화된 서브에이전트
│   ├── explore.md                  # 코드베이스 탐색
│   ├── lint-fixer.md               # 린트/타입 오류 자동 수정
│   ├── git-operator.md             # git 상태 확인, 커밋, PR 관리
│   ├── implementation-executor.md  # 계획 기반 코드 구현
│   └── code-reviewer.md            # 코드 품질·규칙 준수 검토
│
├── skills/                     # 스킬 (자동 트리거)
│   ├── commit-helper/
│   ├── code-quality/
│   ├── bug-fix/
│   ├── refactor/
│   ├── component-creator/      # React/Next.js 전용
│   ├── next-project-structure/ # Next.js 전용
│   ├── web-design/             # Next.js + TailwindCSS 전용
│   ├── test-generator/
│   ├── pr-review-responder/
│   ├── migration-helper/
│   ├── docs-creator/
│   └── agents-generator/
│
├── commands/                   # 슬래시 커맨드
│   ├── setup.md                # 기술 스택 인터뷰 → 프로젝트 설정
│   ├── start.md
│   ├── done.md
│   ├── commit.md
│   ├── quality.md
│   └── setup-notifier.md
│
├── instructions/               # 작업 방식 가이드
│   ├── multi-agent/            # 멀티 에이전트 협업 패턴
│   ├── validation/             # 금지 패턴, 필수 행동
│   └── workflow-patterns/      # 복잡도별 작업 단계
│
├── hooks/
│   ├── notify.sh               # 크로스 플랫폼 알림 훅
│   └── hooks.json              # 훅 이벤트 설정
│
├── scripts/
│   └── install-notifier.sh     # 알림 의존성 설치 스크립트
│
├── .mcp.json                   # MCP 서버 설정 템플릿
└── .claude-plugin/
    ├── plugin.json             # 플러그인 메타데이터
    └── marketplace.json        # 마켓플레이스 등록 정보
```

---

## MCP 서버 템플릿

`/setup` Q6에서 선택한 서버만 `.mcp.json`에 추가됩니다.
기존 `.mcp.json`이 있으면 없는 항목만 머지합니다.

| 서버       | 용도                                 | API 키 필요 |
| ---------- | ------------------------------------ | :---------: |
| Figma      | 피그마 디자인 파일 읽기              |     ✅      |
| Supabase   | DB 쿼리, 마이그레이션, Edge Function |     ✅      |
| Playwright | 브라우저 자동화, E2E 테스트          |     ❌      |
| Atlassian  | Jira·Confluence 연동                 |     ✅      |
| shadcn     | shadcn/ui 컴포넌트 검색 및 설치      |     ❌      |

---

## 통합 사고 모델

모든 코드 작성 시 자동 적용:

```
READ → REACT → ANALYZE → RESTRUCTURE → STRUCTURE → REFLECT
```

복잡도에 따라 단계 수 조절:

- **LOW** (1파일, 명확한 수정): READ → REACT
- **MEDIUM** (2~5파일): READ → ANALYZE → STRUCTURE → REFLECT
- **HIGH** (5파일+, 새 아키텍처): 전체 6단계 + Plan 에이전트

---

## 전형적인 개발 사이클

```
/setup       → 최초 1회: 기술 스택 설정
/start       → 작업 시작: 분석 + 계획
  ↓ 구현
component-creator       → 컴포넌트/훅 생성
bug-fix                 → 버그 분석 + 해결 옵션
refactor                → 구조 개선
test-generator          → 테스트 작성
  ↓
/quality     → 포맷 → 린트 → 타입 체크
/done        → 검증 → 커밋 → PR
  ↓ 리뷰 후
pr-review-responder     → 리뷰 코멘트 반영
```
