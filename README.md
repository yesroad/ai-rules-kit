# Claude Code 설정 모음

범용 프론트엔드 개발 환경을 위한 Claude Code 커스터마이징 설정 모음입니다.

멀티 에이전트 협업, 병렬 실행, 코드 품질 자동 검증을 통해 개발 효율을 높이는 것이 목표입니다.

---

## 디렉토리 구조

```
.claude/
├── agents/                     # 전문화된 서브에이전트 정의
│   ├── explore.md              # 코드베이스 탐색 (haiku 모델)
│   ├── lint-fixer.md           # 린트/타입 오류 자동 수정
│   ├── git-operator.md         # git 상태 확인, 커밋, PR 관리
│   ├── implementation-executor.md  # 계획 기반 코드 구현
│   └── code-reviewer.md        # 코드 품질·규칙 준수 검토
│
├── commands/                   # 슬래시 커맨드 (/start, /done 등)
│   ├── start.md                # 작업 시작: 분석 → 계획 → 확인
│   ├── done.md                 # 작업 완료: 검증 → 커밋 → PR
│   └── setup-notifier.md       # 초기 환경 설정 (terminal-notifier)
│
├── skills/                     # 복잡한 다단계 작업 스킬
│   ├── commit-helper/          # 커밋 메시지 자동 생성 (Conventional Commits)
│   ├── code-quality/           # 린트·포맷·타입체크 통합 실행
│   ├── refactor/               # 코드 리팩토링 분석 및 실행
│   ├── bug-fix/                # 버그 분석·수정 (3가지 옵션 제시)
│   ├── docs-creator/           # CLAUDE.md·SKILL.md 문서 작성
│   └── agents-generator/       # 프로젝트 분석 후 AGENTS.md 생성
│
├── rules/core/                 # 프론트엔드 코딩 규칙
│   ├── thinking-model.md       # 통합 사고 모델 (READ→REACT→ANALYZE→...)
│   ├── coding-standards.md     # TypeScript 표준, 에러 처리, React 패턴
│   ├── react-nextjs-conventions.md  # React/Next.js 컨벤션, Import 순서
│   ├── react-hooks-patterns.md      # Hook 성능 패턴 (useMemo, useRef 등)
│   ├── nextjs-app-router.md         # App Router 전용 규칙
│   ├── state-and-server-state.md    # TanStack Query v5 + Jotai 상태 경계
│   └── unit-test-conventions.md     # 순수 함수 유닛 테스트 규칙
│
├── instructions/               # 작업 방식·검증 가이드
│   ├── index.md                # 전체 문서 카탈로그
│   ├── multi-agent/            # 멀티 에이전트 협업 패턴
│   │   ├── coordination-guide.md    # 병렬 실행, 모델 라우팅
│   │   ├── agent-roster.md          # 에이전트 카탈로그
│   │   ├── execution-patterns.md    # Fan-Out, 배치, 백그라운드
│   │   ├── team-evaluation.md       # 팀원 평가 기준
│   │   └── teammate-done-process.md # 팀원 완료 5단계 프로세스
│   ├── validation/             # 검증 규칙
│   │   ├── forbidden-patterns.md    # 금지 패턴 (any, 서버상태 useState 등)
│   │   ├── required-behaviors.md    # 필수 행동 (병렬 읽기, 검증 등)
│   │   └── release-readiness-gate.md  # 커밋/PR 전 최종 게이트
│   └── workflow-patterns/
│       └── sequential-thinking.md  # LOW/MEDIUM/HIGH 복잡도별 단계
│
├── hooks/                      # Claude Code 이벤트 훅
│   └── notification/           # 작업 완료 시 macOS 알림
│
├── memory/                     # 대화 간 지속되는 프로젝트 메모
│   └── MEMORY.md
│
└── settings.local.json         # 로컬 권한 설정 (gitignore 권장)
```

---

## 주요 기능

### 1. 멀티 에이전트 병렬 실행

독립적인 작업을 동시에 여러 에이전트에 위임해 5~10배 속도를 높입니다.

```
복잡도별 모델 라우팅:
- LOW 작업 → haiku (빠르고 저렴)
- MEDIUM 작업 → sonnet (균형)
- HIGH 작업 → opus (최고 품질)
```

### 2. Commands & Skills

Claude Code에서 `/명령어`로 호출할 수 있는 두 가지 유형입니다.

**Commands** (`commands/` 디렉토리) - 워크플로우 진입점

| 커맨드            | 설명                                          |
| ----------------- | --------------------------------------------- |
| `/start`          | 작업 시작 - 코드 분석 → 계획 수립 → 구현 확인 |
| `/done`           | 작업 완료 - 검증 → 테스트 → 커밋 → PR         |
| `/setup-notifier` | 초기 환경 설정 (macOS terminal-notifier)      |

**Skills** (`skills/` 디렉토리) - 특정 작업 자동화

| 스킬                | 설명                                       |
| ------------------- | ------------------------------------------ |
| `/commit-helper`    | staged 변경사항 기반 커밋 메시지 자동 생성 |
| `/refactor`         | 코드 리팩토링 분석 및 단계별 실행          |
| `/bug-fix`          | 버그 원인 분석 후 3가지 해결 옵션 제시     |
| `/code-quality`     | 린트·포맷·타입체크 통합 실행               |
| `/docs-creator`     | CLAUDE.md·SKILL.md 문서 작성               |
| `/agents-generator` | 프로젝트 분석 후 AGENTS.md 자동 생성       |

### 3. 통합 사고 모델

모든 코드 작성 시 자동으로 적용되는 절차:

```
READ → REACT → ANALYZE → RESTRUCTURE → STRUCTURE → REFLECT
```

복잡도에 따라 단계 조절:

- **LOW** (1파일, 명확한 수정): READ → REACT
- **MEDIUM** (2~5파일, 기존 패턴): READ → ANALYZE → STRUCTURE → REFLECT
- **HIGH** (5파일+, 새 아키텍처): 전체 6단계 + Plan 에이전트

### 4. 프론트엔드 규칙 자동 적용

- **TanStack Query v5** - 모든 서버 상태 관리
- **Jotai** - 전역 UI 상태
- **React Hook Form** - 폼 상태
- **Emotion** - CSS-in-JS 스타일링
- **Conventional Commits** - 커밋 메시지 형식

---

## 설치 방법

```bash
# 이 저장소 클론 후 프로젝트에 복사
git clone <이 저장소>
cp -r claude/.claude /path/to/your-project/

# 또는 심볼릭 링크로 공유
ln -s /path/to/claude/.claude /path/to/your-project/.claude
```

### 초기 설정

```bash
# macOS 알림 설정
/setup-notifier

# 프로젝트 분석 후 AGENTS.md 자동 생성
/agents-generator
```

---

## GitHub 공개 여부

| 항목                    | 공개 가능 여부 | 이유                 |
| ----------------------- | -------------- | -------------------- |
| `.claude/agents/`       | ✅ 가능        | 범용 에이전트 정의   |
| `.claude/commands/`     | ✅ 가능        | 범용 워크플로우      |
| `.claude/skills/`       | ✅ 가능        | 재사용 가능한 스킬   |
| `.claude/rules/core/`   | ✅ 가능        | 범용 프론트엔드 규칙 |
| `.claude/instructions/` | ✅ 가능        | 범용 작업 가이드     |
| `.claude/hooks/`        | ✅ 가능        | 범용 알림 훅         |

---

## 기술 스택 가정

이 설정은 아래 스택을 사용하는 프론트엔드 프로젝트에 최적화되어 있습니다:

- **React** + **TypeScript**
- **Next.js** (Pages Router / App Router 자동 감지)
- **TanStack Query v5** (서버 상태)
- **Jotai** (전역 UI 상태)
- **Emotion** (스타일링)
- **ESLint** + **Prettier** + **TypeScript**

다른 스택을 사용하는 경우 `rules/core/` 파일을 수정하여 적용하세요.

---

## 참고

- [Claude Code 공식 문서](https://docs.anthropic.com/claude-code)
- [TanStack Query v5](https://tanstack.com/query/v5)
- [Jotai](https://jotai.org)
