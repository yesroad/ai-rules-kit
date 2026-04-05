# cc-kit — 프론트엔드 AI 코딩 하네스

Claude Code 프론트엔드 AI 코딩 하네스 — 에이전트에 오케스트레이션·스캐폴딩·가드레일·피드백루프·메모리를 더한 완전한 코딩 환경.

> **에이전트 = 모델 + 하네스**

---

## 하네스 구성 요소

| 계층 | 파일 | 역할 |
|------|------|------|
| 오케스트레이션 | `workflows/coordination/` | 에이전트 팀 조율 |
| 에이전트/스캐폴딩 | `rules/core/`, `agents/` | 컨텍스트 + 규칙 |
| 가드레일 | `hooks/guard-check.sh` | 코드 저장 시 자동 패턴 검사 |
| 피드백 루프 | `/start`, `/work`, `/done` | Plan→Implement→Verify→Adjust 사이클 |
| 메모리 | Basic Memory MCP (선택) | 세션 간 프로젝트 메모리 |

---

## 설치

### 1. 마켓플레이스 추가

Claude Code에서 실행합니다:

```
/plugin marketplace add yesroad/cc-kit
```

### 2. 플러그인 설치

```
/plugin install cc-kit@yesroad
```

### 3. Claude Code 재시작

플러그인 적용을 위해 Claude Code를 껐다가 다시 시작합니다.

### 4. 프로젝트 설정

적용할 프로젝트 루트에서 Claude Code를 열고 실행합니다:

```
/setup
```

기술 스택 인터뷰(7문항)를 진행한 후 프로젝트에 맞춤화된 `.claude/`와 CLAUDE.md를 자동 생성합니다.
이후 커맨드는 `/start`, `/done`, `/commit` 등 네임스페이스 없이 사용할 수 있습니다.

---

## 인터뷰 항목

| 질문               | 선택지                                                       |
| ------------------ | ------------------------------------------------------------ |
| **Q1. 프레임워크** | Next.js / React / 기타                                       |
| **Q2. 라우터**     | App Router / Pages Router (Next.js만)                        |
| **Q3. 스타일링**   | TailwindCSS / Emotion / CSS Modules / 기타                   |
| **Q4. 서버 상태**  | TanStack Query / SWR / 없음                                  |
| **Q5. 전역 상태**  | Jotai / Zustand / Redux Toolkit / 없음                       |
| **Q6. 검증 라이브러리** | Zod / 없음                                             |
| **Q7. MCP 서버**   | Figma / Supabase / Playwright / Atlassian / shadcn / Basic Memory / 없음 (복수 선택) |

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
| `/update-cc-kit`  | 플러그인 파일 최신화 (CLAUDE.md·커스텀 파일 보존, 충돌 시 확인) |
| `/start`          | 작업 시작 — Plan Mode → 분석 → 계획 생성               |
| `/work`           | 구현 + 검증 — 계획 읽기 → 구현 → 계획 대비 검증         |
| `/done`           | 작업 완료 — 검증 → 커밋 → PR                           |
| `/commit`         | staged 변경사항으로 커밋 메시지 생성 후 커밋           |
| `/test`           | 단위 → 통합 → E2E 테스트 순차 실행                     |
| `/setup-notifier` | macOS 알림 초기 환경 설정 (최초 1회)                   |

---

## 스킬

스킬은 키워드를 입력하면 자동으로 트리거됩니다.

| 스킬                     | 트리거                              | 설명                                      | 조건                  |
| ------------------------ | ----------------------------------- | ----------------------------------------- | --------------------- |
| `commit-helper`            | "커밋 메시지 만들어줘"              | staged 기반 커밋 메시지 자동 생성              | 항상                  |
| `code-quality`             | "린트", "포맷", "타입체크"          | 린트·포맷·타입체크 통합 실행                  | 항상                  |
| `bug-fix`                  | "버그", "오류", "에러"              | 원인 분석 후 2-3가지 해결 옵션 제시           | 항상                  |
| `refactor`                 | "리팩토링", "구조 개선"             | 정책 보호 테스트 포함 단계별 리팩토링         | 항상                  |
| `test-unit`                | "단위 테스트", "유닛 테스트"        | 컴포넌트/함수/훅 단위 테스트 생성 (BDD)       | React / Next.js       |
| `test-integration`         | "통합 테스트", "API 테스트"         | Route Handler·Server Actions 통합 테스트 생성 | React / Next.js       |
| `test-e2e`                 | "e2e 테스트", "playwright"          | Playwright 기반 E2E 테스트 생성               | 항상                  |
| `pr-responder`             | "리뷰 반영", PR 번호/URL            | 수용/거절/질문 분류 후 자동 반영              | 항상                  |
| `migration-helper`         | "업그레이드", "마이그레이션"        | 라이브러리 버전 업그레이드 단계적 실행        | 항상                  |
| `docs-creator`             | "문서 작성", "CLAUDE.md"            | AI 코딩 도구용 문서 작성                      | 항상                  |
| `directive-generator`      | "루트 지시문 생성"                  | 프로젝트 분석 후 CLAUDE.md/AGENTS.md 생성     | 항상                  |
| `code-level-review`        | "코드 리뷰", "컨벤션 확인"          | 시니어 기준 컨벤션 적용 및 레벨 진단          | React / Next.js       |
| `component-creator`        | "컴포넌트 만들어", "페이지 추가"    | 프로젝트 패턴 기반 컴포넌트/훅 생성          | React / Next.js       |
| `nextjs-scaffold`          | "도메인 추가", "서비스 파일 만들어" | service + query 훅 + view 전체 스캐폴딩       | Next.js               |
| `web-design`               | "UI 만들어", "화면 구현"            | shadcn/ui 기반 2025 트렌드 UI 구현            | Next.js + TailwindCSS |

---

## 디렉토리 구조

```
cc-kit/
├── rules/core/                 # 코딩 규칙
│   ├── coding-standards.md         # TypeScript 표준, 에러 처리, React 패턴
│   ├── react-conventions.md        # React/Next.js 컨벤션, Import 순서
│   ├── react-hooks-patterns.md     # Hook 성능 패턴 (useMemo, useRef 등)
│   ├── nextjs-app-router.md        # App Router 전용 규칙
│   ├── state-and-server-state.md   # TanStack Query v5 + Jotai 상태 경계
│   ├── unit-test-conventions.md    # 순수 함수 유닛 테스트 규칙
│   ├── accessibility.md            # WCAG 2.1 AA 접근성 규칙
│   └── policies.md                 # 정책(Policy) 정의 기준
│
├── agents/                     # 전문화된 서브에이전트
│   ├── explorer.md                 # 코드베이스 탐색
│   ├── lint-fixer.md               # 린트/타입 오류 자동 수정
│   ├── git-operator.md             # git 상태 확인, 커밋, PR 관리
│   ├── code-reviewer.md            # 코드 품질·규칙 준수 검토
│   └── nextjs-reviewer.md          # Next.js 레벨 진단 (주니어/미들/시니어)
│
├── skills/                     # 스킬 (자동 트리거)
│   ├── commit-helper/
│   ├── code-quality/
│   ├── bug-fix/
│   ├── refactor/
│   ├── component-creator/          # React/Next.js 전용
│   ├── nextjs-scaffold/            # Next.js 전용
│   ├── web-design/                 # Next.js + TailwindCSS 전용
│   ├── test-unit/                  # React/Next.js 전용
│   ├── test-integration/           # React/Next.js 전용
│   ├── test-e2e/
│   ├── code-level-review/          # React/Next.js 전용
│   ├── pr-responder/
│   ├── migration-helper/
│   ├── docs-creator/
│   └── directive-generator/
│
├── commands/                   # 슬래시 커맨드
│   ├── setup.md                # 기술 스택 인터뷰 → 프로젝트 설정
│   ├── start.md                # Plan Mode → 분석 → 계획 생성
│   ├── work.md                 # 계획 기반 구현 + 검증
│   ├── done.md
│   ├── commit.md
│   ├── test.md
│   ├── update-cc-kit.md
│   └── setup-notifier.md
│
├── workflows/                  # 작업 방식 가이드
│   ├── coordination/           # 멀티 에이전트 협업 패턴
│   ├── quality-gates/          # 금지 패턴, 필수 행동
│   ├── git/                    # Git 워크플로우 (pr-guide.md)
│   └── thinking/               # 복잡도별 작업 단계 (model.md 포함)
│
├── hooks/
│   ├── notify.sh               # 크로스 플랫폼 알림 훅
│   └── hooks.json              # 훅 이벤트 설정
│
├── scripts/
│   └── install-notifier.sh     # 알림 의존성 설치 스크립트
│
├── .mcp.json                   # MCP 서버 설정 템플릿
├── plugin.json                 # 플러그인 메타데이터
└── marketplace.json            # 마켓플레이스 등록 정보
```

---

## MCP 서버 템플릿

`/setup` Q7에서 선택한 서버만 `.mcp.json`에 추가됩니다.
기존 `.mcp.json`이 있으면 없는 항목만 머지합니다.

| 서버         | 용도                                 | API 키 필요 |
| ------------ | ------------------------------------ | :---------: |
| Figma        | 피그마 디자인 파일 읽기              |     ✅      |
| Supabase     | DB 쿼리, 마이그레이션, Edge Function |     ✅      |
| Playwright   | 브라우저 자동화, E2E 테스트          |     ❌      |
| Atlassian    | Jira·Confluence 연동                 |     ✅      |
| shadcn       | shadcn/ui 컴포넌트 검색 및 설치      |     ❌      |
| Basic Memory | 세션 간 프로젝트 메모리              |     ❌      |

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
/start       → Plan Mode: 분석 + 계획 생성
  ↓ 계획 검토
/work        → 구현 + 계획 대비 검증
  ↓ 구현 중 활용
  component-creator     → 컴포넌트/훅 생성
  bug-fix               → 버그 분석 + 해결 옵션
  refactor              → 구조 개선
  test-unit             → 단위 테스트 작성
  test-integration      → 통합 테스트 작성
  test-e2e              → E2E 테스트 작성
  ↓ 검증 PASS
/done        → 품질 검증 → 커밋 → PR
  ↓ 리뷰 후
pr-responder            → 리뷰 코멘트 반영
```
