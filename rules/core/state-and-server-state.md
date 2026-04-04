# 상태 관리 경계 규칙

이 프로젝트는 세 가지 상태 관리 도구를 **명확한 경계**로 분리하여 사용한다.

---

## 상태 유형별 도구

| 상태 유형              | 도구                | 위치                     |
| ---------------------- | ------------------- | ------------------------ |
| 서버 상태 (API 데이터) | TanStack Query v5   | 프로파일별 쿼리 디렉토리 |
| 전역 UI/세션 상태      | Zustand             | `stores/`                |
| 폼 상태                | React Hook Form     | 컴포넌트 내부            |
| 로컬 UI 상태           | useState/useReducer | 컴포넌트 내부            |

### 판단 기준

- **서버에서 온 데이터인가?** → React Query
- **여러 컴포넌트가 공유해야 하는 UI 상태인가?** → Zustand
- **폼 입력값인가?** → React Hook Form
- **이 컴포넌트에서만 쓰는 상태인가?** → useState

---

## TanStack Query 구조

### 디렉토리 구조

```
src/
├── queries/
│   └── {도메인}/
│       ├── index.ts       # useXxxQuery, useXxxMutation 훅
│       └── queryKeys.ts   # 쿼리 키 정의
└── services/
    └── {도메인}/
        ├── index.ts       # API 호출 함수
        └── types.ts       # 요청/응답 타입
```

### 쿼리 키 패턴

```typescript
// queries/order/queryKeys.ts
export const orderKeys = {
  all: ['order'] as const,
  lists: () => [...orderKeys.all, 'list'] as const,
  list: (filters: OrderFilters) => [...orderKeys.lists(), filters] as const,
  details: () => [...orderKeys.all, 'detail'] as const,
  detail: (id: string) => [...orderKeys.details(), id] as const,
};
```

### 쿼리 훅 작성 규칙

```typescript
// queries/order/index.ts
'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { orderKeys } from './queryKeys';
import { orderService } from '@/services/order';

export const useOrderQuery = (orderId: string) => {
  return useQuery({
    queryKey: orderKeys.detail(orderId),
    queryFn: () => orderService.getOrder(orderId),
  });
};

export const useUpdateOrderMutation = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: orderService.updateOrder,
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: orderKeys.detail(variables.orderId),
      });
    },
  });
};
```

> **규칙**: 훅 파일 최상단에 `'use client'` 필수 (App Router 프로젝트)

---

## React Query v5 고급 패턴

### queryOptions API (v5 권장)

타입 안전하게 쿼리 옵션을 중앙 관리하고 재사용한다.

```typescript
// queries/order/index.ts
import { queryOptions } from '@tanstack/react-query'

export const orderQueries = {
  detail: (id: string) => queryOptions({
    queryKey: orderKeys.detail(id),
    queryFn: () => orderService.getOrder(id),
    staleTime: 10 * 60 * 1000,
  }),
  list: (filters: OrderFilters) => queryOptions({
    queryKey: orderKeys.list(filters),
    queryFn: () => orderService.getOrders(filters),
  }),
}

// 어디서든 타입 안전하게 재사용
const { data } = useQuery(orderQueries.detail(orderId))
queryClient.prefetchQuery(orderQueries.detail(orderId))  // 라우터 프리패치
```

### useSuspenseQuery

data가 항상 defined — undefined 체크 불필요.

```typescript
import { useSuspenseQuery } from '@tanstack/react-query'

function OrderDetail({ id }: { id: string }) {
  const { data } = useSuspenseQuery(orderQueries.detail(id))
  return <div>{data.title}</div>  // data는 항상 defined
}

// 상위에서 Suspense + ErrorBoundary 필수
<ErrorBoundary fallback={<ErrorFallback />}>
  <Suspense fallback={<Skeleton />}>
    <OrderDetail id={orderId} />
  </Suspense>
</ErrorBoundary>
```

---

## Zustand 사용 규칙

### 적합한 사용 사례

- 모달/사이드바 열림 상태
- 현재 선택된 탭/필터
- 사용자 세션 정보 (인증 후)
- 다크모드 등 UI 설정

### Store 정의 위치 및 패턴

```typescript
// stores/uiStore.ts
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

interface UIStore {
  sidebarOpen: boolean
  selectedTab: TabType
  toggleSidebar: () => void
  setSelectedTab: (tab: TabType) => void
}

export const useUIStore = create<UIStore>()(
  devtools(
    (set) => ({
      sidebarOpen: false,
      selectedTab: 'all',
      toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
      setSelectedTab: (tab) => set({ selectedTab: tab }),
    }),
    { name: 'ui-store' }
  )
)
```

### 도메인별 Store 분리

관련 없는 상태를 하나의 store에 몰아넣지 않는다:

```typescript
// ✅ 도메인별 분리
export const useUIStore = create<UIStore>()(...)    // UI 상태
export const useCartStore = create<CartStore>()(...)  // 장바구니
```

### 금지 사항

- 서버 데이터를 store에 저장하지 않는다
- store 내부에서 API 호출을 직접 하지 않는다

---

## React Hook Form 사용 규칙

### 적합한 사용 사례

- 사용자 입력 폼
- 검증 로직이 필요한 입력
- 여러 필드가 있는 복잡한 폼

### 기본 패턴

```typescript
import { useForm } from 'react-hook-form';

interface OrderFormData {
  productName: string;
  quantity: number;
}

const OrderForm = () => {
  const { register, handleSubmit, formState: { errors } } = useForm<OrderFormData>();

  const onSubmit = (data: OrderFormData) => {
    // mutation 호출
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('productName', { required: true })} />
      {errors.productName && <span>필수 입력</span>}
    </form>
  );
};
```

---

## 캐시 무효화 패턴

### 도메인별 캐시 정리 훅 사용

```typescript
// ✅ 좋은 예: 도메인 훅 사용
import { useClearListCache } from '@/queries/order';

const Component = () => {
  const clearCache = useClearListCache();

  const handleRefresh = () => {
    clearCache();
  };
};
```

```typescript
// ❌ 나쁜 예: queryClient 직접 조작
const Component = () => {
  const queryClient = useQueryClient();

  const handleRefresh = () => {
    queryClient.invalidateQueries({ queryKey: ['order', 'list'] });
  };
};
```

### 캐시 정리 훅 작성

```typescript
// queries/order/index.ts
export const useClearListCache = () => {
  const queryClient = useQueryClient();

  return useCallback(() => {
    queryClient.invalidateQueries({
      queryKey: orderKeys.lists(),
    });
  }, [queryClient]);
};
```

---

## 안티패턴과 대안

### 1. useEffect 남용

```typescript
// ❌ 안티패턴: useEffect로 데이터 페칭
const [data, setData] = useState(null);
const [loading, setLoading] = useState(true);

useEffect(() => {
  fetchData()
    .then(setData)
    .finally(() => setLoading(false));
}, []);
```

```typescript
// ✅ 대안: React Query 사용
const { data, isLoading } = useQuery({
  queryKey: ['data'],
  queryFn: fetchData,
});
```

---

### 2. 파생 상태를 위한 useEffect

```typescript
// ❌ 안티패턴: 파생 상태에 useEffect 사용
const [items, setItems] = useState([]);
const [filteredItems, setFilteredItems] = useState([]);

useEffect(() => {
  setFilteredItems(items.filter((item) => item.active));
}, [items]);
```

```typescript
// ✅ 대안: useMemo로 파생 계산
const filteredItems = useMemo(() => items.filter((item) => item.active), [items]);
```

---

### 3. Store 남용 — 관련 없는 상태 몰아넣기

```typescript
// ❌ 안티패턴: 관련 없는 상태를 하나의 store에
export const useAppStore = create((set) => ({
  user: null,
  posts: [],
  theme: 'light',
  cart: [],
}))
```

```typescript
// ✅ 대안: 도메인별 store 분리
export const useUIStore = create<UIStore>()(...)
export const useCartStore = create<CartStore>()(...)
```

---

### 4. 불안정한 쿼리 키

```typescript
// ❌ 안티패턴: 인라인 객체로 쿼리 키 생성 (매번 새 참조)
useQuery({
  queryKey: ['order', { id: orderId, options: { includeDetails: true } }],
  queryFn: ...,
});
```

```typescript
// ✅ 대안: queryKeys 파일의 팩토리 함수 사용
useQuery({
  queryKey: orderKeys.detail(orderId),
  queryFn: ...,
});
```

---

### 5. 서버 상태와 클라이언트 상태 혼합

```typescript
// ❌ 안티패턴: 서버 데이터를 store에 동기화
const useOrdersStore = create((set) => ({ orders: [] }))

// 컴포넌트에서
const { data } = useItemListQuery();
const setOrders = useOrdersStore((s) => s.setOrders);

useEffect(() => {
  if (data) setOrders(data);
}, [data]);
```

```typescript
// ✅ 대안: React Query를 단일 진실 공급원으로
const { data: orders } = useItemListQuery();

// 필터링이 필요하면 컴포넌트에서 직접 처리
const activeOrders = useMemo(() => orders?.filter((o) => o.status === 'active'), [orders]);
```

---

## Query Client 설정

```typescript
// 프로젝트 기본 설정 (변경하지 않는다)
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false, // 자동 재시도 없음
      staleTime: 0, // 항상 stale 상태
      refetchOnWindowFocus: false,
    },
  },
});
```

---

## 체크리스트

새로운 상태를 추가할 때 아래를 확인한다:

- [ ] 이 데이터는 서버에서 오는가? → React Query
- [ ] 여러 컴포넌트에서 공유되는가?
  - 서버 데이터 → React Query (이미 전역)
  - UI 상태 → Zustand
- [ ] 폼 입력인가? → React Hook Form
- [ ] 이 컴포넌트에서만 쓰이는가? → useState
- [ ] 쿼리 키가 queryKeys 파일에 정의되어 있는가?
- [ ] 캐시 무효화 로직이 도메인 훅으로 캡슐화되어 있는가?
- [ ] Zustand store가 도메인별로 분리되어 있는가?
