# Axios / React Query 레벨별 패턴

> 2026년 4월 기준 | @tanstack/react-query v5 + axios v1.x

---

## Axios 레벨별 패턴

### 🟢 주니어 — 컴포넌트 직접 호출

```typescript
// 인스턴스 없이 컴포넌트에서 직접 호출
function UserList() {
  const [data, setData] = useState([])
  useEffect(() => {
    axios.get('https://api.example.com/users').then(res => setData(res.data))
  }, [])
}
```

### 🔵 미들 — services/instance.ts 분리 + named export 서비스 객체

```typescript
// services/instance.ts
import axios from 'axios'

const instance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10_000,
  headers: { 'Content-Type': 'application/json' },
})

instance.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

export default instance

// services/api/user.ts
import instance from '../instance'
export const userService = {
  getAll: () => instance.get<APIResponse<User[]>>('/users'),
  getById: (id: number) => instance.get<APIResponse<User>>(`/users/${id}`),
  create: (data: UserRequest) => instance.post<APIResponse<User>>('/users', data),
}
```

### 🔴 시니어 — 인터셉터 + 토큰 갱신 + queryOptions 팩토리

```typescript
// services/instance.ts
import axios from 'axios'

const instance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10_000,
})

// 요청 인터셉터: 토큰 자동 주입
instance.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 응답 인터셉터: 401 토큰 갱신 (무한 루프 방지: _retry 플래그)
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
```

---

## React Query 레벨별 패턴

### 🟢 주니어 — useEffect + axios (React Query 미사용)

```typescript
'use client'
function UserList() {
  const [data, setData] = useState<User[]>([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    axios.get('/api/users')
      .then(res => setData(res.data))
      .finally(() => setLoading(false))
  }, [])
}
```

### 🔵 미들 — queryOptions 팩토리 + useQuery

```typescript
// queries/types.ts
import type { QueryObserverOptions } from '@tanstack/react-query'
export type UseQueryOptionsBase<TData, TSelectData = TData> = Omit<
  QueryObserverOptions<TData, Error, TSelectData>,
  'queryKey' | 'queryFn'
>

// queries/user/index.ts
import { queryOptions, useQuery, useSuspenseQuery } from '@tanstack/react-query'
import { userService } from '@/services/api/user'
import type { UseQueryOptionsBase } from '@/queries/types'

export const userOptions = {
  list: (params?: UserListRequest, options?: UseQueryOptionsBase<UserListResponse>) =>
    queryOptions({
      queryKey: ['user', 'list', { params }],
      queryFn: () => userService.getAll(params),
      ...options,
    }),
  detail: <T = User>(id: number, options?: UseQueryOptionsBase<User, T>) =>
    queryOptions({
      queryKey: ['user', 'detail', { id }],
      queryFn: () => userService.getById(id),
      ...options,
    }),
}

// 리스트 — <Suspense> 필수
export const useUserList = (params?: UserListRequest) =>
  useSuspenseQuery(userOptions.list(params))

// 상세 — 조건부 enabled 가능
export const useUserDetail = (id: number) =>
  useQuery(userOptions.detail(id, { enabled: !!id }))
```

### 🔴 시니어 — queryOptions + Optimistic Update + prefetch

```typescript
// queries/user/mutations.ts
export function useUpdateUser() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UserRequest }) =>
      userService.update(id, data),
    // Optimistic Update: 즉시 UI 반영
    onMutate: async ({ id, data }) => {
      await queryClient.cancelQueries({ queryKey: ['user', 'detail', { id }] })
      const previous = queryClient.getQueryData(userOptions.detail(id).queryKey)
      queryClient.setQueryData(userOptions.detail(id).queryKey, data)
      return { previous }
    },
    onError: (_err, { id }, context) => {
      queryClient.setQueryData(userOptions.detail(id).queryKey, context?.previous)
    },
    onSettled: (_data, _err, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['user', 'detail', { id }] })
    },
  })
}

// 라우터에서 프리패치 (Next.js App Router)
// app/users/[id]/page.tsx
export default async function UserPage({ params }: { params: { id: string } }) {
  const queryClient = new QueryClient()
  await queryClient.prefetchQuery(userOptions.detail(Number(params.id)))
  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <UserDetailView id={Number(params.id)} />
    </HydrationBoundary>
  )
}
```

---

## 레이어 구조 요약

```
UI 컴포넌트
    ↕ (커스텀 훅)
React Query (@tanstack/react-query v5)
→ 캐싱, 동기화, 로딩/에러 상태, 백그라운드 리패치
    ↕ (queryFn 내부)
Axios (HTTP Client)
→ 실제 HTTP 요청, 인터셉터, 헤더, 타임아웃
    ↕
REST API 서버
```

> React Query는 데이터 패칭 라이브러리가 아닌 **비동기 상태 관리자**.
> axios가 Promise를 반환하면 React Query가 그 상태를 관리.
