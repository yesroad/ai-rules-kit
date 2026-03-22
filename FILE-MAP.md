# cc-kit 파일 맵

> 전체 파일 설명서 — 버전 1.0.1 (2026-03-22 기준)
>
> **이원화 구조**: 루트(`/`)와 `.claude/`에 동일 파일이 존재합니다.
> 루트는 플러그인 배포용, `.claude/`는 설치된 프로젝트에서 사용됩니다.
> 아래 설명은 루트 기준이며, `.claude/` 사본은 내용이 100% 동일합니다.

---

## 목차

1. [루트 파일](#1-루트-파일)
2. [Rules — 코딩 규칙](#2-rules--코딩-규칙)
3. [Agents — 서브에이전트](#3-agents--서브에이전트)
4. [Skills — 자동 트리거 스킬](#4-skills--자동-트리거-스킬)
5. [Commands — 슬래시 커맨드](#5-commands--슬래시-커맨드)
6. [Instructions — 작업 방식 가이드](#6-instructions--작업-방식-가이드)
7. [Hooks & Scripts — 자동화](#7-hooks--scripts--자동화)
8. [플러그인 메타데이터](#8-플러그인-메타데이터)
9. [참조 체인 다이어그램](#9-참조-체인-다이어그램)

---

## 1. 루트 파일

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `CLAUDE.md` | ~25 | **플러그인 개발용 루트 지시문**. `thinking-model.md`, `required-behaviors.md`, `forbidden-patterns.md`를 `<instructions>`로 로드. 플러그인 개발 시 참조 진입점. |
| `README.md` | ~200 | **플러그인 사용 설명서**. 설치 방법, 인터뷰 항목, 커맨드/스킬 목록, 디렉토리 구조, MCP 서버 템플릿, 개발 사이클 설명. |
| `CHANGELOG.md` | ~43 | **변경 이력**. Semantic Versioning 기반. 1.0.0 초기 릴리스, 1.0.1 정합성 보정/크로스 플랫폼/Vue 지원. |
| `.mcp.json` | ~43 | **MCP 서버 설정 템플릿**. Atlassian(Jira/Confluence), Figma, Supabase, Playwright, shadcn(/ui 컴포넌트 검색) 연동 설정. `/setup` Q6에서 선택한 서버만 설치됨. |
| `.gitignore` | ~21 | `settings.local.json`, `temp/`, `memory/` 등 로컬 전용 파일 제외. |

---

## 2. Rules — 코딩 규칙

`rules/core/` 하위 11개 파일. 프로젝트에 설치되면 `.claude/rules/core/`로 자동 로드되어 모든 코드 작성에 적용됩니다.

### 핵심 사고 모델

| 파일 | 줄 수 | 적용 대상 | 설명 |
|------|:-----:|-----------|------|
| `thinking-model.md` | ~180 | 모든 프로젝트 | **통합 사고 모델 (SSOT)**. `READ → REACT → ANALYZE → RESTRUCTURE → STRUCTURE → REFLECT` 6단계 인지 흐름. 복잡도(LOW/MEDIUM/HIGH)에 따라 단계 수 조절. 기존 로직 참조 원칙, 디자인 시스템 컴포넌트 사용 전 Grep 필수, lint/tsc 검증 체크리스트 포함. |
| `policy-definitions.md` | ~80 | 모든 프로젝트 | **정책(Policy) 정의 기준**. 날짜/기간 계산, 가격/할인, 상태 전이, 필터 기본값, disabled 조건, 권한 규칙을 "정책"으로 분류. 정책 변경 시 탐색→확인→테스트→변경 4단계 프로세스. 텍스트/스타일/변수명은 정책이 아님. |

### TypeScript / 공통

| 파일 | 줄 수 | 적용 대상 | 설명 |
|------|:-----:|-----------|------|
| `coding-standards.md` | ~310 | 모든 프로젝트 | **TypeScript 코딩 표준**. KISS/DRY/YAGNI/Readability 원칙. 변수·함수 네이밍, Immutability(`toSorted()` 사용), 에러 처리(`Promise.all` 병렬), null 처리(optional chaining), 조건부 렌더링, Early Return, 매직 넘버 상수화, 배럴 export(`index.ts`), services/queries 폴더 구조, enum 호환성 규칙. |
| `unit-test-conventions.md` | ~180 | 모든 프로젝트 | **순수 함수 유닛 테스트 규칙**. jest/vitest 러너 자동 감지. `__tests__/{파일명}.test.ts` 위치. 정상/경계값/에러/정책 4가지 케이스 필수. 날짜 함수는 `useFakeTimers()` 필수. 정책 보호(회귀 방지) 테스트 패턴. |
| `pr-guide.md` | ~100 | 모든 프로젝트 | **PR 작성 가이드**. `{type}({scope}): {한 줄 요약}` 제목 형식(50자 이내). 작업 내용(필수), 디자인(선택), 특이사항(선택) 3개 섹션. 변경 유형별 판단 기준표. |

### React / Next.js

| 파일 | 줄 수 | 적용 대상 | 설명 |
|------|:-----:|-----------|------|
| `react-nextjs-conventions.md` | ~210 | React / Next.js | **React/Next.js 컨벤션**. Import 순서(외부→내부→상대경로), Props 타입 정의, Emotion 스타일링(styled.ts 분리), 기존 코드 패턴 참조 규칙, 파일 명명 규칙(PascalCase 컴포넌트, camelCase 훅). |
| `react-hooks-patterns.md` | ~100 | React | **Hook 성능 패턴**. useMemo 과용 금지(단순 primitive엔 불필요), useState 지연 초기화(`() => expensiveFn()`), useRef(리렌더 불필요 값 — 타이머 ID, 이전 값, 이벤트 핸들러 ref). |
| `nextjs-app-router.md` | ~130 | Next.js 13+ App Router | **App Router 전용 규칙**. Suspense 경계 전략(독립 로딩), Server Actions 인증 검증 필수, RSC Props 직렬화 최소화, Component Composition 병렬 데이터 패칭, `React.cache()` 중복 제거, `after()` 비차단 사이드 이펙트. |
| `state-and-server-state.md` | ~280 | React / Next.js | **상태 관리 경계**. TanStack Query(서버 상태), Jotai(전역 UI), React Hook Form(폼), useState(로컬). 쿼리 키 팩토리 패턴, 캐시 무효화 도메인 훅, 5가지 안티패턴(useEffect 데이터 패칭, 파생 상태 useEffect, atom 과다 생성, 불안정 쿼리 키, 서버/클라이언트 혼합). |
| `accessibility.md` | ~130 | 프론트엔드 전체 | **WCAG 2.1 AA 접근성**. 색상 대비 4.5:1, 터치 타깃 44×44px, aria-label(아이콘 버튼), label-input 연결, 모달 포커스 트랩, 동적 콘텐츠 `aria-live`, 애니메이션 `prefers-reduced-motion`. |

### Vue

| 파일 | 줄 수 | 적용 대상 | 설명 |
|------|:-----:|-----------|------|
| `vue-conventions.md` | ~147 | Vue 3 프로젝트 | **Vue 3 + Composition API 컨벤션**. `<script setup lang="ts">` 필수, Options API/Vuex/Mixin 금지. Pinia 상태 관리, `withDefaults(defineProps<>())` 타입, `defineEmits<>()`, Composable 패턴(`composables/use*.ts`). |

---

## 3. Agents — 서브에이전트

`agents/` 하위 5개 파일. 각 에이전트는 특화된 역할과 기본 모델이 지정되어 있습니다.

| 파일 | 줄 수 | 기본 모델 | 병렬 | 설명 |
|------|:-----:|:---------:|:----:|------|
| `explore.md` | 131 | haiku | ✅ | **코드베이스 탐색 전문가**. Glob/Grep/Read로 파일·코드 패턴 검색. 절대 경로 사용, 3개 이상 도구 동시 호출로 탐색 속도 극대화. 탐색만 수행하고 코드 수정은 하지 않음. |
| `code-reviewer.md` | 182 | sonnet | ✅ | **시니어 코드 리뷰어**. `git diff` 기반 변경사항 집중 분석. 보안/타입/상태관리/접근성 검사. 심각도별 분류(치명적/경고/제안)로 건설적 피드백. 포맷팅은 리뷰 대상 아님. |
| `lint-fixer.md` | 97 | haiku | ✅ | **린트/타입 오류 자동 수정**. 간단한 오류(prefer-const, console.log)는 즉시 수정, 복잡한 타입 오류(TS2322)는 분석 후 수정. 하나씩 검사→수정→재검사 반복. |
| `implementation-executor.md` | 101 | sonnet | ⚠️ | **구현 전문가**. 옵션 제시 없이 최적 방법으로 즉시 구현. 복잡도별 접근(간단/보통/복잡) 및 기존 패턴 확인 후 구현. 구현 후 lint/build 검증 필수. 같은 파일 수정 시 순차 실행. 비즈니스 로직 포함 시 opus 상향. |
| `git-operator.md` | 143 | haiku | ❌ | **Git 관리 전문가**. 명시된 파일만 스테이징(`git add -A` 금지). 커밋 메시지 `{type}: {한글 설명}` 형식. 한 커밋 = 한 논리적 변경. 파괴적 명령(force push, reset --hard) 금지. |

---

## 4. Skills — 자동 트리거 스킬

`skills/` 하위 12개 스킬. 키워드 입력 시 자동 활성화되거나 커맨드 내부에서 호출됩니다.

### 코드 완성 스킬

| 스킬 | 줄 수 | 트리거 | 설명 |
|------|:-----:|--------|------|
| `commit-helper/SKILL.md` | 243 | "커밋 메시지" | **커밋 메시지 자동 생성**. 기존 커밋 컨벤션 감지 → staged 변경 분석 → 타입 결정 → Scope 추론 → Body 포함 여부 판단. 프리픽스 영어, 제목/Body 한글. 3가지 옵션(기본/간결/상세) 제시. |
| `code-quality/SKILL.md` | 155 | "린트", "포맷", "타입체크" | **포맷/린트/타입 통합 검사**. 패키지 매니저·실행 경로 자동 감지(모노레포 포함). Prettier → ESLint `--fix` → TypeScript `--noEmit` 순서 실행. `--format-only`, `--lint-only`, `--type-only`, `--no-fix` 옵션. |

### 개발 스킬

| 스킬 | 줄 수 | 트리거 | 설명 |
|------|:-----:|--------|------|
| `bug-fix/SKILL.md` | 328 | "버그", "오류", "에러" | **버그 분석 및 수정**. 복잡도 자동 판단(LOW/MEDIUM/HIGH). 증상 파악 → 원인 분석(explore 에이전트) → **2-3가지 해결 옵션 제시** → 사용자 선택 후 구현 → 검증. |
| `refactor/SKILL.md` | 280 | "리팩토링", "구조 개선" | **정책 보호 리팩토링**. 현황 분석 → 계획(HIGH면 Plan 에이전트) → **정책 보호 테스트 먼저 작성** → 단계적 실행 → 병렬 검증(lint-fixer + code-reviewer). 리팩토링 판단 기준: 3곳+ 중복, 책임 분리 위반, 테스트 불가능 구조. |
| `component-creator/SKILL.md` | 212 | "컴포넌트 만들어", "훅 만들어" | **프로젝트 패턴 기반 컴포넌트/훅 생성**. 기존 유사 컴포넌트 탐색 → 스타일링/export/Props/`use client` 패턴 추출 → 생성 계획 출력 → 파일 생성 → 배럴 `index.ts` 업데이트 → tsc/lint 검증. 단일 컴포넌트만 (도메인 전체는 `next-project-structure`). |
| `next-project-structure/SKILL.md` | 297 | "도메인 추가", "폴더 구조" | **Next.js 도메인 전체 스캐폴딩**. service + query 훅 + view를 한 번에 생성. `types/api/{domain}.ts` → `services/api/{domain}.ts` → `queries/{domain}/queryKeys.ts` + `index.ts` → `views/{page}/` → 배럴 업데이트. App Router/Pages Router 모두 지원. |
| `web-design/SKILL.md` | 430 | "UI 만들어", "디자인해줘" | **2025-2026 트렌드 UI 구현**. Next.js + TailwindCSS v3/v4 + shadcn/ui. 컨텍스트 파악(업종/분위기) → 디자인 스타일 선택(어스톤/다크테크/파스텔 등) → 레이아웃 패턴 → **HTML 목업 필수(사용자 확인)** → React 구현 → 여백/간격 품질 체크. |
| `test-generator/SKILL.md` | 231 | "테스트 작성", "커버리지" | **정책 케이스 포함 테스트 생성**. 순수 함수 우선(utils, helpers, lib). 정상/경계값/에러/정책 4가지 카테고리 커버. jest/vitest 자동 감지. `__tests__/{파일명}.test.ts` 생성 → 실행 → 결과 요약. |
| `migration-helper/SKILL.md` | 244 | "업그레이드", "마이그레이션" | **라이브러리 안전 마이그레이션**. 현황 분석(영향 파일 탐색) → 계획 수립 → **정책 보호 테스트 작성(마이그레이션 전)** → 단계적 실행(각 단계 후 검증) → 최종 검증. React Query v4→v5, Pages→App Router 등. |

### PR / 문서 스킬

| 스킬 | 줄 수 | 트리거 | 설명 |
|------|:-----:|--------|------|
| `pr-review-responder/SKILL.md` | 176 | "리뷰 반영", PR 번호 | **PR 리뷰 코멘트 대응**. `gh api`로 코멘트 수집 → **수용/거절/질문 3분류** → 수용 항목 즉시 구현 → 거절 항목 근거 정리 → 질문 항목 확인 후 결정 → 응답 초안 작성. |
| `docs-creator/SKILL.md` | 279 | "문서 작성", "CLAUDE.md" | **AI 코딩 도구 문서 작성**. CLAUDE.md / AGENTS.md / SKILL.md / COMMAND.md / rules 생성·수정. 고밀도, 실행 가능 문서 원칙. XML/표/코드 활용. 플랫폼별(Claude Code/Cursor/Codex) 최적화. |
| `agents-generator/SKILL.md` | 234 | "루트 지시문 생성" | **CLAUDE.md/AGENTS.md 자동 생성**. 프로젝트 자동 분석(프레임워크 감지) → 비직관적 요소 발굴 → 루트 지시문 생성. 모노레포 지원(워크스페이스별 중첩 파일). Vue 프로젝트면 `vue-conventions.md` 자동 포함. |

### Skills References (참조 자료)

스킬이 내부적으로 참조하는 보조 문서입니다. 직접 트리거되지 않습니다.

#### next-project-structure/references/

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `app-router.md` | 227 | App Router 프로젝트 폴더 구조. `src/app/`, `src/views/` 레이어 분리, Server/Client Component 패턴, SSR-safe localStorage. |
| `pages-router.md` | 224 | Pages Router 프로젝트 패턴. `pages/`, `src/views/` 구조, `getServerSideProps`/`getStaticProps`, `_app.tsx` Provider. |
| `boilerplate-templates.md` | 354 | **복사 즉시 사용 코드 템플릿 10종**. Service, QueryKeys, Query Hook, View, Component, Type 등 새 도메인 추가 시 일관된 구조 보장. |

#### web-design/references/

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `color.md` | 233 | 2025-2026 트렌드 컬러값 및 다크모드 구현. 팬톤 모카 무스, 어스톤 톤 팔레트. Tailwind + CSS 변수 다크모드 코드. |
| `fonts.md` | 306 | 한글·영문 폰트 추천. Pretendard(한글 표준), Inter/Fraunces(영문). `next/font` 활용 가이드, 한영 혼용 조합. |
| `interaction.md` | 300 | 인터랙션·기술 트렌드. 다이나믹 커서, 마이크로인터랙션, 스켈레톤 UI, 패럴랙스 스크롤 구현 코드. |
| `layout.md` | 181 | 레이아웃 패턴 치트시트. 벤토 박스, Above-the-fold CTA, 탈구축 히어로. 타입별(랜딩/SaaS/대시보드) 권장 매트릭스. |
| `responsive.md` | 104 | 반응형 브레이크포인트. Tailwind/Bootstrap 비교, 콘텐츠 기반 브레이크포인트, 컨테이너 쿼리. |
| `spacing.md` | 124 | 스페이싱 시스템. 8px 그리드, 디자인 토큰, 브레이크포인트별 여백값, WCAG 기준(45-75자, 줄간격 1.5배). |
| `trend.md` | 262 | 2025-2026 디자인 종합 트렌드. AI 침투, UX 강화, 비주얼 양극화 4대 흐름. 모바일 퍼스트, 볼드 타이포그래피 등 10가지. |
| `typography.md` | 186 | 타이포그래피 가이드. 자간 -0.01em~-0.02em, 줄간격 1.5-1.6, `clamp()` 유체 타이포그래피, rem/ch 단위. |

---

## 5. Commands — 슬래시 커맨드

`commands/` 하위 6개 파일. 사용자가 `/커맨드명`으로 명시적으로 호출합니다.

| 파일 | 줄 수 | 커맨드 | 설명 |
|------|:-----:|--------|------|
| `setup.md` | ~310 | `/setup` | **프로젝트 초기 설치**. 기술 스택 인터뷰 6문항(프레임워크/라우터/스타일링/서버상태/전역상태/MCP서버) → 응답 기반 `.claude/` 파일 설치 + 맞춤형 CLAUDE.md 생성. Rules 결정표에 따라 프레임워크별 필요 규칙만 선별 포함. |
| `start.md` | ~150 | `/start` | **작업 시작**. 입력 유형 판별(Jira/MD/텍스트) → 작업 내용 파악 → 디자인 분석(선택) → 코드 분석(explore 에이전트) → 작업 계획 출력 → 복잡도 판단 및 에이전트 전략 → **"작업을 시작할까요?" 확인 후 구현**. Step 7 전에는 구현하지 않음. |
| `done.md` | ~170 | `/done` | **작업 완료 → PR**. 변경 분석(정책 영향 판단) → 테스트 전략(순수 함수+정책이면 `test-generator`, UI면 스킵) → 코드 검증(`code-quality` 스킬) → 출시 게이트 5항목 → 선별 커밋(`commit-helper` 스킬) → PR 생성(`pr-guide.md` 템플릿). `--skip-test`, `--force-test`, `--draft` 옵션. |
| `commit.md` | ~90 | `/commit` | **Git 플로우 자동화**. main 최신화 → 작업 브랜치 생성(`{type}/{description}`) → 커밋(`commit-helper` 스킬) → 푸시 → main 머지 → 브랜치 삭제 → main 최신화. staged 변경만 처리(`git add .` 금지). `--branch`, `--no-gate` 옵션. |
| `quality.md` | ~18 | `/quality` | **코드 품질 검사**. `code-quality` 스킬 호출로 Prettier → ESLint → TypeScript 순차 실행. `--format-only`, `--lint-only`, `--type-only`, `--no-fix` 옵션. |
| `setup-notifier.md` | ~76 | `/setup-notifier` | **macOS 알림 환경 설정**. terminal-notifier 설치 확인 → `install-notifier.sh` 실행 → `.claude/settings.local.json` 훅 설정 병합(PermissionRequest 이벤트에 notify.sh 연결). 최초 1회. |

---

## 6. Instructions — 작업 방식 가이드

`instructions/` 하위 3개 카테고리. 에이전트 협업, 품질 검증, 워크플로우 패턴을 정의합니다.

### multi-agent/ — 멀티 에이전트 협업

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `agent-roster.md` | ~200 | **에이전트 카탈로그**. 6개 에이전트(explore/code-reviewer/lint-fixer/Plan/implementation-executor/git-operator)의 모델·병렬 여부·용도. 조합 패턴(탐색→구현, 구현→검증). 12개 스킬 카탈로그 및 연결 흐름. |
| `coordination-guide.md` | ~453 | **병렬 실행 원칙 (SSOT)**. Agent Teams 우선(3개+ 에이전트 시), 일반 Task 병렬(폴백). 동기화 전략, 팀 수명주기(생성→협업→완료→정리). 버그 수정 복잡도 판단 기준표(LOW/MEDIUM/HIGH) 포함. 병렬 실행으로 5-10배 속도 향상 목표. |
| `execution-patterns.md` | ~294 | **실행 패턴 상세**. 6가지 패턴: Agent Teams, Single-Message Parallel, Fan-Out/Fan-In, Sequential Pipeline, Batching, Background. `/start`, `/done` 커맨드의 구체적 병렬 검증 패턴. |
| `model-routing.md` | ~103 | **모델 선택 전략**. LOW(haiku), MEDIUM(sonnet), HIGH(opus). 비즈니스 로직(날짜/수치/상태 계산) 포함 시 상향. **불확실할 때 상향 원칙** 및 키워드별 빠른 참조 포함. coordination-guide.md에 종속. |
| `team-evaluation.md` | ~147 | **팀원 작업 평가 기준**. 10개 항목 100점 만점. 규칙 참조/코딩 표준/React 컨벤션/디자인 품질/테스트/Done 프로세스 등. A등급(90+) 목표. 팀 리드만 평가 수행. |
| `teammate-done-process.md` | ~103 | **팀원 5단계 완료 프로세스**. 변경 분석 → 정책 키워드 탐지 → 린트 검증 → 커밋(Co-Authored-By 금지) → SendMessage 보고. 범위 밖 변경 금지, Skill 도구 사용 불가. |
| `README.md` | ~136 | **Instructions 인덱스**. 멀티에이전트/검증/워크플로우 문서 카탈로그. 상황별(작업 시작/코드 작성/검증/커밋) 참조 가이드. 스킬 맵. |

### validation/ — 품질 검증

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `required-behaviors.md` | ~230 | **필수 행동 13개**. 작업 범위 확인, 인지 모델 적용, Read 후 Edit, 3개+ 파일 병렬 읽기, TypeScript strict, TanStack Query 사용, Import 순서, lint/tsc 검증, 정책 변경 시 테스트, 에이전트 위임, 모델 선택, 커밋 형식, 해당 파일만 커밋, 출시 게이트 통과. |
| `forbidden-patterns.md` | ~277 | **금지 패턴**. 언어 표현(추측 금지), 코드 품질(`any`/`@ts-ignore` 금지), 상태 관리(useState로 서버 상태 금지), Barrel Import 제한, Git/PR(이모지/AI 표시/force push 금지), 보안(토큰 하드코딩 금지), Emotion 스타일링(inline style/!important 금지, `$` transient props). |
| `release-readiness-gate.md` | ~120 | **출시 품질 게이트 5개**. Gate 1 작업 범위(범위 초과 검출), Gate 2 구현 적합성(과구현/미구현), Gate 3 안정성/보안, Gate 4 사용자 흐름/UX, Gate 5 커밋/PR 준비. 각 게이트에 PASS/FAIL 예시 포함. |

### workflow-patterns/ — 워크플로우 패턴

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `sequential-thinking.md` | ~180 | **복잡도별 사고 단계 (SSOT)**. LOW(1-2단계: READ→REACT), MEDIUM(3-5단계: +ANALYZE/STRUCTURE/REFLECT), HIGH(7-10단계: 전체+Plan). 에이전트 연계(LOW=직접, MEDIUM=explore+code-reviewer, HIGH=Plan+code-reviewer). 자동 복잡도 판단 로직. |
| `error-recovery.md` | ~101 | **에러 복구 가이드**. 병렬 에이전트 실패(일부/전체/타임아웃), `/commit` 머지 충돌·푸시 실패·staged 유실 복구, `/done` 중단 후 재개(테스트/린트/PR 실패별), 빌드 실패 부분 롤백(`git checkout <커밋> -- <파일>`). |

---

## 7. Hooks & Scripts — 자동화

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `hooks/notify.sh` | ~33 | **크로스 플랫폼 알림 스크립트**. macOS: terminal-notifier(기본) → osascript(폴백). Linux: notify-send(libnotify). 환경변수 `NOTIFIER_TITLE`, `NOTIFIER_MESSAGE`로 커스텀. 터미널 벨(`printf '\a'`) 공통. |
| `hooks/hooks.json` | ~15 | **훅 이벤트 설정**. `PermissionRequest` 이벤트 발생 시 `notify.sh` 실행(타임아웃 5초). Claude Code가 사용자 확인 필요할 때 데스크톱 알림 전송. |
| `scripts/install-notifier.sh` | ~60 | **알림 의존성 설치 스크립트**. macOS: Homebrew + terminal-notifier 설치. Linux: apt-get/dnf/pacman으로 libnotify 설치. 훅 스크립트 실행 권한 부여(`chmod +x`). |

---

## 8. 플러그인 메타데이터

`.claude-plugin/` 하위. 마켓플레이스 등록 및 플러그인 식별 정보.

| 파일 | 줄 수 | 설명 |
|------|:-----:|------|
| `plugin.json` | ~12 | **플러그인 메타데이터**. name: `cc-kit`, version: `1.0.1`, author: `yesroad`, license: MIT. |
| `marketplace.json` | ~24 | **마켓플레이스 등록 정보**. `yesroad` 마켓플레이스에 `cc-kit` 등록. 설치 명령: `/plugin install cc-kit@yesroad`. |

---

## 9. 참조 체인 다이어그램

### CLAUDE.md에서 시작하는 핵심 참조

```
CLAUDE.md
├── rules/core/thinking-model.md ─────────────── 사고 모델 (SSOT)
│   ├── instructions/workflow-patterns/sequential-thinking.md  복잡도 판단
│   ├── instructions/multi-agent/coordination-guide.md         병렬 실행
│   └── instructions/multi-agent/model-routing.md              모델 선택
│
├── instructions/validation/required-behaviors.md ── 필수 행동 13개
│   ├── instructions/validation/forbidden-patterns.md
│   ├── instructions/validation/release-readiness-gate.md
│   ├── rules/core/state-and-server-state.md
│   └── rules/core/unit-test-conventions.md
│
└── instructions/validation/forbidden-patterns.md ── 금지 패턴
    ├── rules/core/react-nextjs-conventions.md
    ├── rules/core/state-and-server-state.md
    └── rules/core/unit-test-conventions.md
```

### 커맨드 → 스킬 → 에이전트 호출 흐름

```
/setup ──→ agents-generator 스킬 ──→ explore 에이전트
/start ──→ explore 에이전트 (코드 분석)
/done  ──→ test-generator 스킬 (정책 변경 시)
       ──→ code-quality 스킬 ──→ lint-fixer 에이전트
       ──→ commit-helper 스킬 ──→ git-operator 에이전트
/commit ──→ commit-helper 스킬
/quality ──→ code-quality 스킬
```

### 스킬 간 연결

```
component-creator → test-generator (생성 후 테스트)
bug-fix           → test-generator (수정 후 회귀 방지)
refactor          → test-generator (정책 보호 테스트)
migration-helper  → test-generator (마이그레이션 검증)
/done             → pr-review-responder (리뷰 대응)
```

---

## 파일 수 요약

| 카테고리 | 파일 수 | 비고 |
|----------|:-------:|------|
| 루트 파일 | 5 | CLAUDE.md, README.md, CHANGELOG.md, .mcp.json, .gitignore |
| Rules | 11 | 코딩 규칙 (프레임워크별 조건부 설치) |
| Agents | 5 | 특화 서브에이전트 |
| Skills (SKILL.md) | 12 | 자동 트리거 |
| Skills (references) | 11 | web-design 8 + next-project-structure 3 |
| Commands | 6 | 슬래시 커맨드 |
| Instructions | 10 | 멀티에이전트 7 + 검증 3 + 워크플로우 2 + README 1 |
| Hooks & Scripts | 3 | 알림 자동화 |
| 메타데이터 | 2 | plugin.json, marketplace.json |
| **.claude/ 사본** | **동일** | 루트와 100% 동기화 |
| **합계 (고유 파일)** | **65** | |
