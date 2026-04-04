---
name: test-integration
description: Route Handler, Server Actions 통합 테스트 생성. "통합 테스트", "API 테스트", "Route Handler 테스트", "Server Action 테스트", "integration test" 언급 시 반드시 이 스킬을 활성화. node 환경, BDD(Given-When-Then) 방식.
user-invocable: true
allowed-tools: Read, Grep, Glob, Write, Bash
metadata:
  version: "1.0.0"
  category: testing
  priority: medium
---

# Test Integration

> Route Handler, Server Actions 통합 테스트 생성. node 환경, BDD(Given-When-Then) 방식.

---

## 진행 상황 출력

각 Phase 시작 시 반드시 아래 형식으로 출력한다:

```
[🔍 분석 중...] Route Handler / Server Action 파악
[📋 시나리오 도출 중...] GWT 변환
[⚙️ 테스트 생성 중...] .integration.test.ts 작성
[▶️ 테스트 실행 중...] node 환경
[✅ 완료] 또는 [❌ 실패 - 원인 분류 중...]
[🔄 재시도 N/3] 정책 재검토 후 재생성 중...
```

---

## 통합 테스트란

단위 테스트와의 경계:

| 구분 | 단위 테스트 | 통합 테스트 |
|------|------------|------------|
| 대상 | 컴포넌트, 유틸 함수, Hook | Route Handler, Server Actions |
| 환경 | jsdom | node (실제 서버 환경) |
| 외부 의존성 | 전부 모킹 | DB/인증 모킹 선택 |
| 파일 네이밍 | `*.test.ts` | `*.integration.test.ts` |

---

## Phase 0: ARGUMENTS 확인

- `$ARGUMENTS` 없으면 "어떤 Route Handler 또는 Server Action의 통합 테스트를 작성할까요?" 질문
- 있으면 바로 Phase 1 진행

---

## Phase 1: 프레임워크 감지 + 대상 분석 [🔍 분석 중...]

### 프레임워크 감지 (순서대로 확인)

1. `package.json` devDependencies에서 `vitest` 키 → Vitest
2. `jest` 키 → Jest
3. `vitest.config.*` 설정 파일 존재 여부 확인
4. `jest.config.*` 설정 파일 존재 여부 확인
5. `package.json` scripts 패턴 확인
6. 기본값: Vitest

### 환경 설정 확인

`vitest.config.*` 또는 `jest.config.*`에서 integration 프로젝트/환경 설정 여부 확인.
없으면 설정 추가 안내 (node 환경 분리 필요):

```typescript
// vitest.config.ts — integration 프로젝트 설정 예시 (없으면 추가 안내)
{
  test: {
    name: 'integration',
    include: ['**/*.integration.test.ts'],
    environment: 'node',
  }
}
```

### 대상 파일 분석

- `app/api/**/route.ts` → Route Handler
- `'use server'` 지시어 → Server Actions
- DB 의존성 파악 (`@/lib/db`, `prisma` 등)
- 인증 의존성 파악 (`next/headers`, `cookies()`, `headers()`)
- Zod 스키마 사용 여부

---

## Phase 2: GWT 시나리오 도출 [📋 시나리오 도출 중...]

### Route Handler 시나리오 유형

- **Happy Path**: 올바른 요청 → 200/201 응답
- **Error Case**: DB 오류 → 500, 인증 없음 → 401, 없는 리소스 → 404
- **Validation**: 잘못된 입력 → 400
- **Edge Case**: 빈 목록, 페이지네이션 경계

### Server Action 시나리오 유형

- **Happy Path**: 올바른 FormData → 성공 반환
- **Validation Fail**: 필드 누락/형식 오류 → errors 반환
- **DB Error**: 생성/수정 실패 → 에러 처리
- **Side Effects**: revalidatePath 호출 여부

시나리오 계획 출력 후 사용자 확인.

---

## Phase 3: 테스트 파일 생성 [⚙️ 테스트 생성 중...]

### 파일 위치: 소스 파일과 동일 폴더에 co-location

```
app/api/users/route.ts
app/api/users/route.integration.test.ts  ← 생성 위치

app/actions/user.ts
app/actions/user.integration.test.ts
```

### Route Handler 테스트 패턴

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { NextRequest } from 'next/server'
import { GET, POST } from './route'

// DB 모킹
vi.mock('@/lib/db', () => ({
  db: {
    user: {
      findMany: vi.fn(),
      create: vi.fn(),
      findUnique: vi.fn(),
    },
  },
}))

import { db } from '@/lib/db'

describe('GET /api/users', () => {
  beforeEach(() => { vi.clearAllMocks() })

  it('사용자 목록을 JSON으로 반환한다', async () => {
    // Given
    const mockUsers = [{ id: 1, name: '홍길동' }]
    vi.mocked(db.user.findMany).mockResolvedValue(mockUsers)
    const request = new NextRequest('http://localhost:3000/api/users')

    // When
    const response = await GET(request)
    const data = await response.json()

    // Then
    expect(response.status).toBe(200)
    expect(data).toEqual(mockUsers)
  })

  it('DB 오류 시 500을 반환한다', async () => {
    // Given
    vi.mocked(db.user.findMany).mockRejectedValue(new Error('DB connection failed'))
    const request = new NextRequest('http://localhost:3000/api/users')

    // When
    const response = await GET(request)

    // Then
    expect(response.status).toBe(500)
  })
})
```

### 동적 라우트 파라미터 (Next.js v15+)

```typescript
// params가 Promise 타입
const context = { params: Promise.resolve({ id: '1' }) }
const response = await GET(request, context)
```

### next/headers 모킹 (cookies, headers)

```typescript
vi.mock('next/headers', () => ({
  cookies: vi.fn(),
  headers: vi.fn(),
}))

// 테스트에서
vi.mocked(cookies).mockResolvedValue({
  get: vi.fn().mockReturnValue({ value: 'valid-token' }),
} as any)
```

### next/cache 모킹 (revalidatePath)

```typescript
vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
}))
```

### Server Actions 테스트 패턴

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { createUser } from './actions'

vi.mock('@/lib/db', () => ({
  db: { user: { create: vi.fn() } },
}))

vi.mock('next/cache', () => ({
  revalidatePath: vi.fn(),
}))

import { db } from '@/lib/db'
import { revalidatePath } from 'next/cache'

// FormData 헬퍼
function createFormData(data: Record<string, string>): FormData {
  const formData = new FormData()
  Object.entries(data).forEach(([key, value]) => formData.append(key, value))
  return formData
}

describe('createUser', () => {
  beforeEach(() => { vi.clearAllMocks() })

  it('올바른 입력으로 사용자를 생성한다', async () => {
    // Given
    vi.mocked(db.user.create).mockResolvedValue({ id: 1, name: '홍길동', email: 'hong@test.com' })
    const formData = createFormData({ name: '홍길동', email: 'hong@test.com' })

    // When
    const result = await createUser(null, formData)

    // Then
    expect(result.success).toBe(true)
    expect(revalidatePath).toHaveBeenCalledWith('/users')
  })

  it('이름이 없으면 errors를 반환한다', async () => {
    // Given
    const formData = createFormData({ name: '', email: 'hong@test.com' })

    // When
    const result = await createUser(null, formData)

    // Then
    expect(result.errors?.name).toBeDefined()
  })
})
```

---

## Phase 4: 테스트 실행 [▶️ 테스트 실행 중...]

```bash
# Vitest (Phase 1에서 Vitest 감지된 경우)
{패키지매니저} test --project integration

# Jest (Phase 1에서 Jest 감지된 경우)
{패키지매니저} test -- --testPathPattern="integration.test"
```

**통과 기준**: 모든 테스트 pass (숫자 커버리지 측정 X)

### 실패 처리 루프 (최대 3회)

```
[❌ 실패 - 원인 분류 중...]

원인 분류:
├─ 테스트 설계 문제 (mock 설정 오류, 잘못된 Request 구성, 정책 오해)
│     → [🔄 재시도 N/3] 정책 문서 재검토 → 시나리오 재도출 → 재생성
│
├─ 코드 버그 (Route Handler/Server Action 구현 오류)
│     → 루프 중단: "⚠️ 코드에 버그가 발견됐습니다: {내용}"
│
└─ 환경 문제 (node 환경 미설정, DB 연결, 인증 설정)
      → 루프 중단:
        체크리스트:
        - [ ] vitest.config.ts에 integration 프로젝트 설정 있나요?
        - [ ] @/lib/db mock이 올바른 경로인가요?
        - [ ] next/headers mock이 설정됐나요?
```

---

## Phase 5: 완료 요약 출력

```markdown
## 통합 테스트 생성 완료

### 생성된 파일
- {파일 경로}

### 테스트 케이스
| 대상 | Happy Path | Error | Validation | 합계 |
|------|:----------:|:-----:|:----------:|:----:|
| {이름} | {N} | {N} | {N} | {N} |

### 결과
| 테스트 | 결과 |
|--------|------|
| 전체 | {N}/{N} 통과 ✅ |
```

---

## 금지 패턴

| 금지 | 이유 |
|------|------|
| 실제 DB/외부 API 호출 | 불안정, 부작용 |
| jsdom 환경에서 실행 | Route Handler는 node 환경 필수 |
| 실제 서버 기동 후 HTTP 요청 | E2E 범주, 통합 테스트 아님 |
