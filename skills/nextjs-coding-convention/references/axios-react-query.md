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

### 🔵 미들 — lib/axios.ts 인스턴스 분리

```typescript
// lib/axios.ts
import axios from 'axios'

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
})

export default api

// services/api/user.ts
import api from '@/lib/axios'
export const userService = {
  getUsers: () => api.get<User[]>('/users').then(r => r.data),
  getUser: (id: number) => api.get<User>(`/users/${id}`).then(r => r.data),
}
```

### 🔴 시니어 — 인터셉터 + 토큰 갱신 + 에러 중앙 처리

```typescript
// lib/axios.ts
import axios from 'axios'

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10000,
})

// 요청 인터셉터: 토큰 자동 주입
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 응답 인터셉터: 에러 코드별 중앙 처리
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // refresh token으로 재발급 시도
      try {
        const { data } = await axios.post('/auth/refresh', { token: localStorage.getItem('refreshToken') })
        localStorage.setItem('accessToken', data.accessToken)
        error.config.headers.Authorization = `Bearer ${data.accessToken}`
        return api.request(error.config)
      } catch {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export default api
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

### 🔵 미들 — useQuery + queryKey 팩토리

```typescript
// queries/userQueries.ts
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  detail: (id: number) => [...userKeys.all, 'detail', id] as const,
}

export const useUsers = () =>
  useQuery({
    queryKey: userKeys.lists(),
    queryFn: () => api.get<User[]>('/users').then(r => r.data),
    staleTime: 5 * 60 * 1000,
  })

export const useCreateUser = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (data: CreateUserDto) => api.post('/users', data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: userKeys.lists() }),
  })
}
```

### 🔴 시니어 — queryOptions API + useSuspenseQuery + Optimistic Update

```typescript
// queries/userQueries.ts
import { queryOptions } from '@tanstack/react-query'

export const userQueries = {
  detail: (id: number) => queryOptions({
    queryKey: ['users', id],
    queryFn: () => api.get<User>(`/users/${id}`).then(r => r.data),
    staleTime: 10 * 60 * 1000,
  }),
  list: () => queryOptions({
    queryKey: ['users', 'list'],
    queryFn: () => api.get<User[]>('/users').then(r => r.data),
  }),
}

// useSuspenseQuery — data는 항상 defined
const UserProfile = ({ id }: { id: number }) => {
  const { data } = useSuspenseQuery(userQueries.detail(id))
  return <div>{data.name}</div>
}

// 어디서든 타입 안전하게 재사용
queryClient.prefetchQuery(userQueries.detail(userId))  // 라우터 프리패치
queryClient.setQueryData(userQueries.detail(userId).queryKey, newUser)  // 캐시 직접 업데이트

// Optimistic Update
const useUpdateUser = () => {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (user: UpdateUserDto) => api.put(`/users/${user.id}`, user),
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: ['users', newUser.id] })
      const previous = queryClient.getQueryData(['users', newUser.id])
      queryClient.setQueryData(['users', newUser.id], newUser)
      return { previous }
    },
    onError: (_err, newUser, context) => {
      queryClient.setQueryData(['users', newUser.id], context?.previous)
    },
    onSettled: (_data, _err, newUser) => {
      queryClient.invalidateQueries({ queryKey: ['users', newUser.id] })
    },
  })
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
