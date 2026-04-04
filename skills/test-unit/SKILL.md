---
name: test-unit
description: 컴포넌트/함수/훅 단위 테스트 생성. "단위 테스트", "유닛 테스트", "테스트 작성", "테스트 추가", "커버리지 올려", "테스트 없는 파일", "unit test" 언급 시 반드시 이 스킬을 활성화. BDD(Given-When-Then) 방식, 정책 케이스 포함.
user-invocable: true
allowed-tools: Read, Grep, Glob, Write, Bash
metadata:
  version: "2.0.0"
  category: testing
  priority: medium
---

# Test Unit

> BDD(Given-When-Then) 방식으로 단위 테스트를 생성. 정책 케이스 포함.

---

## 진행 상황 출력

각 Phase 시작 시 반드시 아래 접두사를 출력한다:

```
[🔍 분석 중...] 대상 파일 파악
[📋 시나리오 도출 중...] Given-When-Then 변환
[⚙️ 테스트 생성 중...] 파일 작성
[▶️ 테스트 실행 중...] 커버리지 측정
[✅ 완료] 또는 [❌ 실패 - 원인 분류 중...]
[🔄 재시도 N/2] 정책 재검토 후 재생성 중...
```

---

## Phase 0: ARGUMENTS 확인

```
$ARGUMENTS 없음 → 질문:
"어떤 파일의 단위 테스트를 작성할까요?
- 파일 경로 (예: src/utils/date.ts)
- 또는 테스트가 없는 영역 설명"

$ARGUMENTS 있음 → Phase 1 바로 진행
```

---

## Phase 1: 프레임워크 감지 + 대상 분석 [🔍 분석 중...]

### 프레임워크 감지 순서

1. `package.json` devDependencies에서 `vitest` 키 → Vitest 확정
2. `package.json` devDependencies에서 `jest` 키 → Jest 확정
3. `vitest.config.*` / `jest.config.*` 파일 존재 확인
4. `package.json` scripts의 `test` 명령어 패턴
5. 아무것도 없으면 Vitest 기본 선택 (2026년 Next.js 생태계 표준)

### 대상 파일 분석

explore 에이전트를 활용해 다음을 파악한다:

- export된 함수/컴포넌트/훅 목록
- 각 함수의 입력/출력 타입
- 날짜, 계산, 정책 로직 포함 여부
- 기존 테스트 파일 유무
- 외부 의존성 (next/navigation, API 호출, Zustand store, React Query 등)

### 테스트 대상 분류

| 유형 | 기준 | 전략 |
|------|------|------|
| 순수 함수 | utils, helpers, lib, adapters | 유닛 테스트 우선 |
| 커스텀 훅 | `use` 접두사 | renderHook + act |
| React 컴포넌트 | JSX 반환 | BDD 전체 시나리오 |
| 서버 액션 | `'use server'` | 단위 테스트 (mocking) |

---

## Phase 2: GWT 시나리오 도출 [📋 시나리오 도출 중...]

### BDD 시나리오 분류

| 분류 | 설명 |
|------|------|
| **Happy Path** | 정상 입력 → 올바른 결과 |
| **Edge Case** | 0, 빈 배열, null, undefined, 경계값 |
| **Error Case** | 잘못된 타입, API 실패, 유효성 검사 실패 |
| **State Transition** | 로딩 → 완료 → 에러 상태 전환 |
| **Policy Case** | 비즈니스 규칙 (정책 로직이 있는 경우 필수) |

### 시나리오 계획 출력 후 사용자 확인

```markdown
## 테스트 케이스 계획

### {함수/컴포넌트명}
- Happy Path: {케이스}
- Edge Case: {케이스}
- Error Case: {케이스}
- Policy: {케이스 (있는 경우)}

생성할까요? [Y/n]
```

---

## Phase 3: 테스트 파일 생성 [⚙️ 테스트 생성 중...]

### 파일 위치 결정

- 기존 `__tests__/` 폴더 있으면 → `{파일경로}/__tests__/{파일명}.test.ts(x)`
- 없으면 → co-location (`{파일경로}.test.ts(x)`)

### 기본 구조 (Vitest)

```typescript
import { describe, it, expect, vi, beforeAll, afterAll } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { 함수명 } from '../파일명'

describe('함수명/컴포넌트명', () => {
  // 날짜 의존 함수는 필수
  beforeAll(() => {
    vi.useFakeTimers().setSystemTime(new Date('2024-01-15T00:00:00.000Z'))
  })
  afterAll(() => {
    vi.useRealTimers()
  })

  describe('정상 동작', () => {
    it('[동작 설명]', async () => {
      // Given
      // When
      // Then
    })
  })

  describe('경계 조건', () => { ... })
  describe('오류 처리', () => { ... })
})
```

### it 네이밍 원칙

`it` 이름만 읽어도 무엇을 검증하는지 알 수 있어야 한다.

- ❌ `it('test 1', ...)`
- ✅ `it('이메일 형식이 올바르지 않으면 에러 메시지를 표시한다', ...)`

### next/navigation 모킹 (App Router)

```typescript
// Vitest
const mockPush = vi.fn()
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mockPush, replace: vi.fn(), back: vi.fn(), refresh: vi.fn(), prefetch: vi.fn() }),
  usePathname: vi.fn(() => '/'),
  useSearchParams: vi.fn(() => new URLSearchParams()),
}))

// Jest
const mockPush = jest.fn()
jest.mock('next/navigation', () => ({
  useRouter: () => ({ push: mockPush, replace: jest.fn(), back: jest.fn() }),
}))
```

### Zustand store 모킹

```typescript
// vi.mock으로 store 전체 대체
vi.mock('@/stores/uiStore', () => ({
  useUIStore: vi.fn(() => ({
    sidebarOpen: false,
    toggleSidebar: vi.fn(),
  })),
}))
```

### React Query 모킹

```typescript
vi.mock('@/queries/order', () => ({
  useOrderQuery: vi.fn(() => ({
    data: mockOrder,
    isLoading: false,
    isError: false,
  })),
  useUpdateOrderMutation: vi.fn(() => ({
    mutate: vi.fn(),
    isPending: false,
  })),
}))
```

### MSW API 모킹 (MSW 셋업 있는 경우)

```typescript
import { http, HttpResponse } from 'msw'
import { server } from '@/mocks/server'

server.use(
  http.post('/api/login', () => HttpResponse.json({ success: true }))
)
```

### async Server Component 처리

`async function` + `export default` + 내부 `await` 조합이면 단위 테스트 불가.

처리: "이 컴포넌트는 async Server Component입니다. test-e2e 스킬을 사용하세요." 안내 후 종료.

---

## Phase 4: 테스트 실행 및 검증 [▶️ 테스트 실행 중...]

패키지 매니저 자동 감지: `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm, `package-lock.json` → npm

Phase 1에서 감지한 프레임워크를 그대로 사용한다.

```bash
# Vitest (Phase 1에서 Vitest 감지된 경우)
{패키지매니저} test --coverage --reporter=verbose {파일명}.test

# Jest (Phase 1에서 Jest 감지된 경우)
{패키지매니저} test -- --coverage --testPathPattern="{파일명}.test" --coverageReporters=text
```

**커버리지 기준**: 90% (statements + branches)

### 실패 처리 루프 (최대 2회)

```
[❌ 실패 - 원인 분류 중...]

원인 분류:
├─ 테스트 설계 문제 (정책 오해, mock 잘못 구성, 잘못된 selector)
│     → [🔄 재시도 N/2] 정책 문서 재검토 → 시나리오 재도출 → 테스트 재생성
│
├─ 코드 버그 (실제 구현 오류)
│     → 루프 중단: "⚠️ 코드에 버그가 발견됐습니다: {내용}"
│
└─ 환경 문제 (의존성 미설치, 설정 오류)
      → 루프 중단: "🔧 환경 설정 필요: {안내}"
```

---

## Phase 5: 완료 요약 출력

```markdown
## 테스트 생성 완료

### 생성된 파일
- {테스트 파일 경로}

### 테스트 케이스
| 함수/컴포넌트 | Happy Path | Edge | Error | Policy | 합계 |
|-------------|:----------:|:----:|:-----:|:------:|:----:|
| {이름} | {N} | {N} | {N} | {N} | {N} |

### 커버리지
| 항목 | 결과 |
|------|------|
| Statements | {N}% ✅/❌ |
| Branches | {N}% ✅/❌ |

### 다음 단계 제안
- {커버리지 90% 미만 항목이 있으면 추가 케이스 제안}
```

---

## 커버리지 부족 파일 탐색

테스트가 없는 중요 파일을 찾는 경우:

```bash
find src/utils src/helpers src/lib src/adapters -name "*.ts" ! -name "*.test.ts" ! -name "*.d.ts"
```

발견된 파일 중 비즈니스 로직이 있는 것을 우선 타겟으로 제안한다.

---

## 금지 패턴

| 금지 | 이유 |
|------|------|
| 구현 상세 의존 (private 메서드 spy) | 리팩토링 시 테스트 깨짐 |
| 테스트 간 상태 공유 | 실행 순서 의존성 |
| 하드코딩 날짜 | 시간 경과 시 실패 |
| 외부 API 실제 호출 | 불안정한 테스트 |
| async Server Component 단위 테스트 시도 | Vitest/Jest 미지원 |

---

## 참조 문서

| 문서 | 용도 |
|------|------|
| `@../../rules/core/unit-test-conventions.md` | 테스트 구조/규칙 |
