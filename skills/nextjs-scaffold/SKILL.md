---
name: nextjs-scaffold
user-invocable: true
description: >
  Next.js 프로젝트에서 여러 레이어를 아우르는 도메인 전체를 스캐폴딩하거나, 파일 위치/폴더 구조를 안내할 때 사용.
  단일 컴포넌트·훅 생성은 component-creator를 사용. 이 스킬은 다음 상황에만 사용:
  "전체 도메인 추가" (service + query 훅 + view 한 번에),
  "API 서비스 파일 만들어" / "axios 인스턴스" / "서비스 레이어",
  "TanStack Query 훅 구조" / "queryOptions" / "useQuery 어디에 만들어",
  "views 폴더 구조" / "어디에 파일 만들어야 해?" / "폴더 구조 어떻게?",
  "view + hook 분리 패턴" / "도메인 스캐폴딩" / "모노레포 구조".
  CLAUDE.md 없는 새 프로젝트나 문서가 부족한 프로젝트에서 특히 유용하다.
---

# nextjs-scaffold

> Next.js 프로젝트에 일관된 폴더 구조와 코드 패턴을 적용하는 스킬.
> **이 스킬 자체가 패턴의 기준**이다 — CLAUDE.md에 의존하지 말고 이 스킬의 패턴을 따른다.
> 단, CLAUDE.md에 더 구체적인 프로젝트 패턴이 있다면 그것을 우선 참조한다.

---

## 워크플로우

### Step 1: 프로젝트 환경 파악

```bash
# 모노레포 여부 확인
ls packages/ 2>/dev/null && echo "Monorepo" || echo "Single app"

# App Router 여부 확인
ls src/app 2>/dev/null || ls app 2>/dev/null && echo "App Router" || echo "Pages Router"

# 스타일링 감지
grep -q '"@emotion' package.json 2>/dev/null && echo "Emotion" \
  || (ls tailwind.config.* 2>/dev/null && echo "Tailwind") \
  || echo "Other"

# 기존 services/queries 패턴 확인 (있으면 그 패턴을 따름)
ls src/services/api/ 2>/dev/null
ls src/queries/ 2>/dev/null
```

**판단 결과에 따라 분기:**
- 모노레포 + `packages/services` 존재 → `import Services from '@workspace/services'` 사용
- 단일 앱 → `src/services/instance.ts` + `services/api/{domain}.ts` named export 패턴
- App Router → `references/app-router.md` 참조
- Pages Router → `references/pages-router.md` 참조
- **Emotion 감지** → 컴포넌트 생성 시 `references/emotion.md` 참조

### Step 2: 기존 패턴 탐색 (신규 기능 전 필수)

새 도메인/파일을 만들기 전에 **유사한 기존 코드를 먼저 찾는다**. 기존 패턴이 있으면 그대로 따른다.

```bash
ls src/services/api/
ls src/queries/
ls src/views/
```

### Step 3: 요청 종류에 따라 생성 대상 결정

| 요청 키워드 | 생성 대상 | 비고 |
|---|---|---|
| 서비스, API, service, axios | `services/api/{domain}.ts` | |
| 쿼리, useQuery, TanStack, queryOptions | `queries/{domain}/` | |
| view, 뷰, view+hook 분리 | `views/{page}/` | |
| 전체 도메인, 도메인 추가 | services + queries + view + types 모두 | |
| 컴포넌트, 훅 단독 생성 | — | `component-creator` 스킬 사용 |

**schemas/ 폴더 구조가 포함되는 경우 → `../../rules/references/zod/zod-v4-project-patterns.md` 먼저 읽기**

### Step 4: 파일 생성 + 배럴 index.ts 즉시 업데이트

파일을 만든 즉시 해당 폴더의 `index.ts` 배럴 export를 업데이트한다.
배럴 미업데이트는 import 에러의 주요 원인이다.

---

## 폴더 구조 원칙

```
src/
├── components/          # 앱 공통 UI 컴포넌트
│   └── {Name}/
│       ├── index.tsx           # UI만 (로직 없음)
│       ├── styled.ts           # Emotion 사용 시 (스타일 분리)
│       └── use{Name}.ts        # 로직이 있으면 반드시 분리
├── hooks/               # 앱 공통 커스텀 훅
├── services/            # API 서비스
│   ├── instance.ts             # axios 인스턴스 (인터셉터 포함)
│   └── api/
│       ├── {domain}.ts         # named export 서비스 객체
│       └── index.ts            # 배럴 export
├── queries/             # TanStack Query
│   ├── types.ts                # UseQueryOptionsBase 공통 타입
│   ├── {domain}/
│   │   ├── index.ts            # {domain}Options + hooks ('use client' 필수)
│   │   └── mutations.ts        # mutation hooks
│   └── index.ts
├── types/
│   └── api/             # API 요청/응답 타입
├── lib/                 # 순수 함수 유틸리티
├── utils/               # 앱 유틸리티
└── provider/            # QueryProvider 등 전역 컨텍스트
```

**모노레포 추가 구조:**
```
packages/
├── services/            # BaseServices (axios wrapper) — 앱에서 상속
└── ui/                  # shadcn/ui 공통 컴포넌트
apps/
└── {app-name}/src/      # 위 src/ 구조와 동일
```

---

## 핵심 패턴

### Services — 단일 앱 (axios instance + named export)

```typescript
// src/services/instance.ts
import axios from 'axios'

const instance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10_000,
  headers: { 'Content-Type': 'application/json' },
})

// 요청 인터셉터: 토큰 자동 주입
instance.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 응답 인터셉터: 401 토큰 갱신
instance.interceptors.response.use(
  (res) => res,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true
      try {
        const { data } = await axios.post('/auth/refresh',
          { token: localStorage.getItem('refreshToken') })
        localStorage.setItem('accessToken', data.accessToken)
        error.config.headers.Authorization = `Bearer ${data.accessToken}`
        return instance.request(error.config)
      } catch {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export default instance

// src/services/api/{domain}.ts
import instance from '../instance'
import type { APIResponse, {Type}, {TypeRequest} } from '@/types/api/{domain}'

export const {domain}Service = {
  getAll: (params?: {ListRequest}) =>
    instance.get<APIResponse<{Type}[]>>('/{domain}', { params }),
  getById: (id: number) =>
    instance.get<APIResponse<{Type}>>(`/{domain}/${id}`),
  create: (data: {TypeRequest}) =>
    instance.post<APIResponse<{Type}>>('/{domain}', data),
  update: (id: number, data: {TypeRequest}) =>
    instance.put<APIResponse<{Type}>>(`/{domain}/${id}`, data),
  remove: (id: number) =>
    instance.delete<APIResponse<void>>(`/{domain}/${id}`),
}
```

### Services — 모노레포 (BaseServices 상속)

```typescript
// src/services/api/{domain}.ts
import Services from '@workspace/services'
import type { {ResponseType} } from '@/types/api/{domain}'

class {Domain}Services extends Services {
  constructor() {
    super({ baseURL: '/api/{domain}' })
  }

  get{Resource}(params: {ParamsType}): Promise<{ResponseType}> {
    return this.get<{ResponseType}>('', params)
  }
}

export default new {Domain}Services() // 싱글턴
```

### TanStack Query — queryOptions 팩토리 (v5 공식 권장)

```typescript
// src/queries/types.ts
import type { QueryObserverOptions } from '@tanstack/react-query'

export type UseQueryOptionsBase<TData, TSelectData = TData> = Omit<
  QueryObserverOptions<TData, Error, TSelectData>,
  'queryKey' | 'queryFn'
>

// src/queries/{domain}/index.ts
'use client'

import { queryOptions, useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { {domain}Service } from '@/services/api/{domain}'
import type { UseQueryOptionsBase } from '@/queries/types'

export const {domain}Options = {
  list: (
    params: {ListRequest},
    options?: UseQueryOptionsBase<{ListResponse}>,
  ) => queryOptions({
    queryKey: ['{domain}', 'list', { params }],
    queryFn: () => {domain}Service.getAll(params),
    ...options,
  }),

  detail: <T = {DetailResponse}>(
    id: number,
    options?: UseQueryOptionsBase<{DetailResponse}, T>,
  ) => queryOptions({
    queryKey: ['{domain}', 'detail', { id }],
    queryFn: () => {domain}Service.getById(id),
    ...options,
  }),
}

// 훅 — 리스트: useSuspenseQuery + <Suspense> 필수
export const use{Domain}List = (params: {ListRequest}) =>
  useSuspenseQuery({domain}Options.list(params))

// 훅 — 상세: useQuery (enabled, select 조건부 가능)
export const use{Domain}Detail = (id: number) =>
  useQuery({domain}Options.detail(id, { enabled: !!id }))
```

queryOptions는 `useQuery`, `useSuspenseQuery`, `prefetchQuery`, `setQueryData` 어디서든 동일하게 쓰인다.
queryKey를 리터럴로 반복 작성하지 않아도 되므로 invalidate 불일치가 없다.

```typescript
// src/queries/{domain}/mutations.ts
'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { {domain}Service } from '@/services/api/{domain}'

export function useCreate{Domain}() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data: {CreateRequest}) => {domain}Service.create(data),
    onSuccess: () => queryClient.invalidateQueries({
      queryKey: ['{domain}', 'list'],
    }),
  })
}

export function useUpdate{Domain}() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: {TypeRequest} }) =>
      {domain}Service.update(id, data),
    onSuccess: () => queryClient.invalidateQueries({
      queryKey: ['{domain}', 'list'],
    }),
  })
}

export function useDelete{Domain}() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => {domain}Service.remove(id),
    onSuccess: () => queryClient.invalidateQueries({
      queryKey: ['{domain}', 'list'],
    }),
  })
}
```

### View (UI와 로직 분리)

뷰를 UI와 로직으로 분리하는 이유: 로직만 단독으로 테스트할 수 있고,
UI 변경 시 로직을 건드리지 않아도 된다.

```typescript
// src/views/{page}/use{Page}View.ts
'use client'

import { useState, useCallback } from 'react'
import { use{Domain}List } from '@/queries/{domain}'

export function use{Page}View() {
  const [params, setParams] = useState<{ListRequest}>({})
  const { data } = use{Domain}List(params) // useSuspenseQuery — 항상 defined

  const handleSearch = useCallback((value: string) => {
    setParams((prev) => ({ ...prev, search: value }))
  }, [])

  return { data, params, handleSearch }
}

// src/views/{page}/index.tsx
'use client'

import { Suspense } from 'react'
import { use{Page}View } from './use{Page}View'
import {Domain}Skeleton from '@/components/{Domain}Skeleton'

function {Page}Content() {
  const { data, handleSearch } = use{Page}View()
  return (
    <main>
      {/* UI만 — 비즈니스 로직 없음 */}
    </main>
  )
}

export default function {Page}View() {
  return (
    <Suspense fallback={<{Domain}Skeleton />}>
      <{Page}Content />
    </Suspense>
  )
}
```

### Component (로직 있으면 훅 분리)

```typescript
// src/components/{Name}/use{Name}.ts
import { useState, useCallback } from 'react'

export function use{Name}() {
  const [state, setState] = useState(false)
  const handleAction = useCallback(() => setState((prev) => !prev), [])
  return { state, handleAction }
}

// src/components/{Name}/index.tsx
import { use{Name} } from './use{Name}'

interface {Name}Props { /* props */ }

export default function {Name}(props: {Name}Props) {
  const { state, handleAction } = use{Name}()
  return <div>{/* UI */}</div>
}
```

**Emotion 사용 시** → `references/emotion.md` 참조 (styled.ts 분리 패턴)

---

## 주요 금지 패턴

| 금지 | 이유 | 대안 |
|---|---|---|
| queryKey 리터럴 직접 작성 | invalidate 시 불일치 위험 | `{domain}Options.list(params).queryKey` |
| BaseServices 클래스 (단일 앱) | 단일 앱에 불필요한 복잡성 | `instance.ts` + named export |
| `useEffect` + axios 직접 패칭 | 캐싱·동기화 미작동 | `useQuery` / `useSuspenseQuery` |
| `useState(() => localStorage.getItem(...))` | SSR에서 ReferenceError | `useEffect`에서 로드 |
| `any` 타입 | 런타임 에러 미감지 | 명시적 `interface`/`type` |
| 배럴 index.ts 미업데이트 | import 경로 불일치 | 파일 생성 즉시 추가 |
| 뷰에 비즈니스 로직 직접 작성 | UI/로직 책임 혼재 | `use{Page}View` 훅으로 분리 |
| 훅 파일 상단에 `'use client'` 누락 | TanStack Query 서버 실행 오류 | 모든 훅 파일 최상단에 추가 |

---

## 새 도메인 추가 체크리스트

- [ ] `types/api/{domain}.ts` — 요청/응답 타입 + `APIResponse<T>`
- [ ] `services/api/{domain}.ts` — named export 서비스 객체
- [ ] `services/api/index.ts` — 배럴 업데이트
- [ ] `queries/types.ts` — `UseQueryOptionsBase` (최초 1회)
- [ ] `queries/{domain}/index.ts` — `{domain}Options` + hooks (`'use client'` 필수)
- [ ] `queries/{domain}/mutations.ts` — mutation hooks
- [ ] `queries/index.ts` — 배럴 업데이트
- [ ] `views/{page}/use{Page}View.ts` — 로직 훅
- [ ] `views/{page}/index.tsx` — UI + Suspense boundary
- [ ] App Router: `app/{route}/page.tsx` 에서 뷰 위임

---

## 상세 참조

| 파일 | 내용 |
|---|---|
| `references/app-router.md` | App Router 전용 패턴 (Server Component, Suspense 등) |
| `references/pages-router.md` | Pages Router 전용 패턴 |
| `references/boilerplate-templates.md` | 복사 즉시 사용 가능한 전체 보일러플레이트 |
| `references/emotion.md` | Emotion 스타일링 패턴 (Q3=Emotion 시) |
| `../component-creator/SKILL.md` | 단일 컴포넌트/훅 생성 |
| `../../rules/references/zod/zod-v4-project-patterns.md` | Zod 스키마 폴더 구조 및 파일 작성 패턴 |
