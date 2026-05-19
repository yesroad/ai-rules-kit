# 보일러플레이트 템플릿 모음

> 복사해서 즉시 사용 가능한 코드 스니펫
> `{Domain}`, `{domain}`, `{Type}` 등은 실제 이름으로 치환

---

## 1. services/instance.ts — axios 인스턴스 + 인터셉터

```typescript
// src/services/instance.ts
import axios from 'axios'

const instance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10_000,
  headers: { 'Content-Type': 'application/json' },
})

// 요청 인터셉터: accessToken 자동 주입
instance.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 응답 인터셉터: 401 시 refreshToken으로 재발급
instance.interceptors.response.use(
  (res) => res,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true
      try {
        const { data } = await axios.post('/auth/refresh', {
          token: localStorage.getItem('refreshToken'),
        })
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
```

---

## 2. services/api/{domain}.ts — named export 서비스 객체

```typescript
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

// src/services/api/index.ts (배럴 — 추가분)
export * from './{domain}'
```

---

## 3. types/api/{domain}.ts — 도메인 타입

```typescript
// src/types/api/{domain}.ts

export interface APIResponse<T> {
  code: number
  message?: string
  data?: T
}

export interface {Type} {
  id: number
  // 필드
  createdAt: string
  updatedAt: string
}

export interface {Type}Request {
  // 생성/수정 필드
}

export interface {Type}ListRequest {
  page?: number
  pageSize?: number
  search?: string
}

export interface {Type}ListResponse {
  items: {Type}[]
  total: number
  page: number
  pageSize: number
}
```

---

## 4. queries/types.ts — UseQueryOptionsBase 공통 타입

```typescript
// src/queries/types.ts
import type { QueryObserverOptions } from '@tanstack/react-query'

export type UseQueryOptionsBase<TData, TSelectData = TData> = Omit<
  QueryObserverOptions<TData, Error, TSelectData>,
  'queryKey' | 'queryFn'
>
```

---

## 5. queries/{domain}/index.ts — queryOptions 팩토리 + hooks

```typescript
// src/queries/{domain}/index.ts
'use client'

import { queryOptions, useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { {domain}Service } from '@/services/api/{domain}'
import type { UseQueryOptionsBase } from '@/queries/types'
import type { {Type}ListRequest, {Type}ListResponse, {Type} } from '@/types/api/{domain}'

export const {domain}Options = {
  list: (
    params: {Type}ListRequest,
    options?: UseQueryOptionsBase<{Type}ListResponse>,
  ) =>
    queryOptions({
      queryKey: ['{domain}', 'list', { params }],
      queryFn: () => {domain}Service.getAll(params),
      ...options,
    }),

  detail: <T = {Type}>(
    id: number,
    options?: UseQueryOptionsBase<{Type}, T>,
  ) =>
    queryOptions({
      queryKey: ['{domain}', 'detail', { id }],
      queryFn: () => {domain}Service.getById(id),
      ...options,
    }),
}

// 리스트 — useSuspenseQuery (<Suspense> 필수)
export const use{Domain}List = (params: {Type}ListRequest) =>
  useSuspenseQuery({domain}Options.list(params))

// 상세 — useQuery (enabled, select 조건부 가능)
export const use{Domain}Detail = (id: number) =>
  useQuery({domain}Options.detail(id, { enabled: !!id }))

// src/queries/index.ts (배럴 — 추가분)
export * from './{domain}'
```

---

## 6. queries/{domain}/mutations.ts — mutation hooks

```typescript
// src/queries/{domain}/mutations.ts
'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { {domain}Service } from '@/services/api/{domain}'
import type { {Type}Request } from '@/types/api/{domain}'

export function useCreate{Domain}() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data: {Type}Request) => {domain}Service.create(data),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['{domain}', 'list'] }),
  })
}

export function useUpdate{Domain}() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: {Type}Request }) =>
      {domain}Service.update(id, data),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['{domain}', 'list'] }),
  })
}

export function useDelete{Domain}() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => {domain}Service.remove(id),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ['{domain}', 'list'] }),
  })
}
```

---

## 7. views/{page}/use{Page}View.ts — 로직 훅

```typescript
// src/views/{page}/use{Page}View.ts
'use client'

import { useState, useCallback } from 'react'
import { use{Domain}List } from '@/queries/{domain}'
import type { {Type}ListRequest } from '@/types/api/{domain}'

export function use{Page}View() {
  const [params, setParams] = useState<{Type}ListRequest>({})
  const { data } = use{Domain}List(params)

  const handleSearch = useCallback((search: string) => {
    setParams((prev) => ({ ...prev, search }))
  }, [])

  return { data, params, handleSearch }
}
```

---

## 8. views/{page}/index.tsx — UI (Suspense 포함)

```typescript
// src/views/{page}/index.tsx
'use client'

import { Suspense } from 'react'
import { use{Page}View } from './use{Page}View'

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
    <Suspense fallback={<div>로딩 중...</div>}>
      <{Page}Content />
    </Suspense>
  )
}
```

---

## 9. App Router page.tsx 템플릿

```typescript
// src/app/{route}/page.tsx
import type { Metadata } from 'next'
import {Page}View from '@/views/{page}'

export const metadata: Metadata = {
  title: '{페이지 제목}',
  description: '{설명}',
}

export default function Page() {
  return <{Page}View />
}
```

---

## 10. Pages Router page.tsx 템플릿

```typescript
// pages/{route}/index.tsx
import type { NextPage } from 'next'
import {Page}View from '@/views/{page}'

const {Page}Page: NextPage = () => {
  return <{Page}View />
}

export default {Page}Page
```

---

## 11. QueryProvider 템플릿

```typescript
// src/provider/QueryProvider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 5 * 60 * 1000, // 5분
            retry: 1,
          },
        },
      })
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {process.env.NODE_ENV === 'development' && (
        <ReactQueryDevtools initialIsOpen={false} />
      )}
    </QueryClientProvider>
  )
}
```

---

## 12. SSR-safe localStorage Hook

```typescript
// src/hooks/useLocalStorage.ts
import { useState, useEffect, useCallback } from 'react'

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(initialValue)

  useEffect(() => {
    try {
      const item = localStorage.getItem(key)
      if (item) setStoredValue(JSON.parse(item))
    } catch (error) {
      console.error(`localStorage 읽기 실패 [${key}]:`, error)
    }
  }, [key])

  const setValue = useCallback(
    (value: T | ((prev: T) => T)) => {
      try {
        const valueToStore =
          value instanceof Function ? value(storedValue) : value
        setStoredValue(valueToStore)
        localStorage.setItem(key, JSON.stringify(valueToStore))
      } catch (error) {
        console.error(`localStorage 저장 실패 [${key}]:`, error)
      }
    },
    [key, storedValue]
  )

  return [storedValue, setValue] as const
}
```

---

## 13. 모노레포 BaseServices 템플릿 (모노레포 전용)

```typescript
// src/services/api/{domain}.ts
import Services from '@workspace/services'
import type { {ResponseType} } from '@/types/api/{domain}'

class {Domain}Services extends Services {
  constructor() {
    super({ baseURL: '/api/{domain}' })
  }

  get{Resource}(param: string): Promise<{ResponseType}> {
    return this.get<{ResponseType}>('', { param })
  }

  create{Resource}(body: {CreateType}): Promise<{ResponseType}> {
    return this.post<{ResponseType}>('', body)
  }
}

export default new {Domain}Services()

// src/services/api/index.ts (배럴 — 추가분)
export { default as {domain}Services } from './{domain}'
```
