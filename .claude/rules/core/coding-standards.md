# 코딩 표준 & 모범 사례

> CLAUDE.md, react-nextjs-conventions.md 보완 규칙

---

## 핵심 원칙

| 원칙            | 설명               | 적용                   |
| --------------- | ------------------ | ---------------------- |
| **KISS**        | 가장 단순한 해결책 | 과도한 엔지니어링 지양 |
| **DRY**         | 중복 코드 금지     | 공통 로직 함수 추출    |
| **YAGNI**       | 필요할 때만 구현   | 추측성 일반화 금지     |
| **Readability** | 읽기 쉬운 코드     | 자기 설명적 변수명     |

---

## TypeScript 표준

### 변수 네이밍

```typescript
// ✅ 좋은 예: 설명적 이름
const marketSearchQuery = "election";
const isUserAuthenticated = true;
const totalRevenue = 1000;

// ❌ 나쁜 예: 불명확한 이름
const q = "election";
const flag = true;
const x = 1000;
```

### 함수 네이밍

```typescript
// ✅ 좋은 예: 동사-명사 패턴
async function fetchOrderData(orderId: string) {}
function calculateDiscountPrice(price: number, rate: number) {}
function isValidOrderStatus(status: string): boolean {}

// ❌ 나쁜 예: 불명확하거나 명사만
async function order(id: string) {}
function discount(a, b) {}
function status(s) {}
```

### Immutability (필수)

```typescript
// ✅ 항상 spread 연산자 사용
const updatedOrder = {
  ...order,
  status: "completed",
};

const updatedItems = [...items, newItem];

// ❌ 직접 변형 금지
order.status = "completed"; // 금지
items.push(newItem); // 금지

// ✅ 불변 정렬: toSorted() 사용 (원본 배열 유지)
const sorted = items.toSorted((a, b) => a.name.localeCompare(b.name));

// ❌ sort()는 원본 배열을 변형함
const sorted = items.sort((a, b) => a.name.localeCompare(b.name)); // 금지
```

---

## 에러 처리

### API 호출

```typescript
// ✅ 좋은 예: 포괄적 에러 처리
async function fetchOrderDetail(orderId: string) {
  try {
    const response = await api.get(`/api/orders/${orderId}`);

    if (!response.data.success) {
      throw new Error(response.data.message);
    }

    return response.data;
  } catch (error) {
    console.error("Order fetch failed:", error);
    throw new Error("주문 정보를 불러올 수 없습니다");
  }
}

// ❌ 나쁜 예: 에러 처리 없음
async function fetchOrderDetail(orderId: string) {
  const response = await api.get(`/api/orders/${orderId}`);
  return response.data;
}
```

### Async/Await

```typescript
// ✅ 좋은 예: 병렬 실행
const [orders, affiliates, stats] = await Promise.all([
  fetchOrders(),
  fetchAffiliates(),
  fetchStats(),
]);

// ❌ 나쁜 예: 불필요한 순차 실행
const orders = await fetchOrders();
const affiliates = await fetchAffiliates();
const stats = await fetchStats();
```

---

## 타입 안전성

### 명시적 타입 정의

```typescript
// ✅ 좋은 예: 적절한 타입
interface Order {
  id: string;
  status: "pending" | "active" | "completed" | "cancelled";
  createdAt: Date;
  items: OrderItem[];
}

function getOrder(id: string): Promise<Order> {
  // 구현
}

// ❌ 나쁜 예: any 사용
function getOrder(id: any): Promise<any> {
  // 구현
}
```

### null/undefined 처리

```typescript
// ✅ 좋은 예: Optional chaining
const userName = user?.profile?.name ?? "알 수 없음";

// ❌ 나쁜 예: 체크 없이 접근
const userName = user.profile.name; // 런타임 에러 가능
```

---

## React 패턴

### 상태 업데이트

```typescript
// ✅ 좋은 예: 함수형 업데이트
const [count, setCount] = useState(0);
setCount((prev) => prev + 1);

// ❌ 나쁜 예: 직접 참조 (stale 가능)
setCount(count + 1);
```

### 조건부 렌더링

```typescript
// ✅ 좋은 예: 명확한 조건
{isLoading && <Loading />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}

// ❌ 나쁜 예: 삼항 지옥
{isLoading ? <Loading /> : error ? <ErrorMessage error={error} /> : data ? <DataDisplay data={data} /> : null}
```

### Early Return

```typescript
// ✅ 좋은 예: Early return
function OrderCard({ order }: Props) {
  if (!order) return null;
  if (order.status === 'cancelled') return <CancelledBadge />;

  return <ActiveOrderCard order={order} />;
}

// ❌ 나쁜 예: 깊은 중첩
function OrderCard({ order }: Props) {
  if (order) {
    if (order.status !== 'cancelled') {
      return <ActiveOrderCard order={order} />;
    } else {
      return <CancelledBadge />;
    }
  }
  return null;
}
```

---

## Code Smell 감지

| Smell         | 기준           | 해결               |
| ------------- | -------------- | ------------------ |
| **긴 함수**   | 50줄 이상      | 작은 함수로 분할   |
| **긴 파일**   | 300줄 이상     | 컴포넌트/로직 분리 |
| **깊은 중첩** | 4레벨 이상     | Early return       |
| **매직 넘버** | 설명 없는 숫자 | 상수로 추출        |
| **중복 코드** | 3회 이상 반복  | 함수로 추출        |

---

## 매직 넘버 처리

```typescript
// ❌ 나쁜 예: 설명 없는 숫자
if (retryCount > 3) {
}
setTimeout(callback, 500);

// ✅ 좋은 예: 명명된 상수
const MAX_RETRIES = 3;
const DEBOUNCE_DELAY_MS = 500;

if (retryCount > MAX_RETRIES) {
}
setTimeout(callback, DEBOUNCE_DELAY_MS);
```

---

## 배럴 Export (index.ts)

같은 폴더 안에 export가 2개 이상이면 `index.ts`를 만들어 한 곳에서 내보낸다.

```typescript
// ✅ 좋은 예: src/components/index.ts
export { default as SearchBar } from "./SearchBar";
export { default as VideoCard } from "./VideoCard";
export { default as RecipeModal } from "./RecipeModal";
export { default as IngredientChip } from "./IngredientChip";

// 사용하는 곳에서 깔끔하게 import
import { SearchBar, VideoCard } from "@/components";

// ❌ 나쁜 예: 개별 경로로 분산 import
import SearchBar from "@/components/SearchBar";
import VideoCard from "@/components/VideoCard";
import RecipeModal from "@/components/RecipeModal";
```

**적용 대상 폴더:**

| 폴더          | 예시                   |
| ------------- | ---------------------- |
| `components/` | UI 컴포넌트 모음       |
| `queries/`    | TanStack Query 훅 모음 |
| `services/`   | API 서비스 함수 모음   |
| `types/`      | 타입 정의 모음         |
| `lib/`        | 유틸리티 함수 모음     |

**규칙:**

- 폴더 내 export가 2개 이상이면 `index.ts` 생성
- 새 파일 추가 시 해당 폴더의 `index.ts`에도 즉시 추가
- `index.ts` 내부에서는 로직 작성 금지 — re-export만 허용

---

## services / queries 폴더 구조 규칙

### services 구조

**모노레포 환경** (`@workspace/services`가 있는 경우):

```
packages/services/          ← HTTP 클라이언트 베이스 (axios wrapper)
  core/base.ts              ← BaseServices 클래스
  core/interceptors.ts      ← 공통 인터셉터
  index.ts                  ← Services 클래스 export

apps/{app}/src/services/api/  ← 도메인별 서비스 (BaseServices 상속)
  search.ts
  recipe.ts
  coupang.ts
  index.ts                  ← re-export 배럴
```

도메인 서비스는 반드시 `@workspace/services`를 상속받아 작성한다:

```typescript
// ✅ services/api/search.ts
import Services from "@workspace/services";

class SearchServices extends Services {
  constructor() {
    super({ baseURL: "/api/search" });
  }

  getSearchVideos(query: string, pageToken?: string) {
    return this.get<SearchResult>("", { q: query, pageToken });
  }
}

export default new SearchServices(); // 싱글턴으로 export
```

**비모노레포 환경** (`@workspace/services`가 없는 경우):

```
src/services/
  core/base.ts              ← BaseServices 클래스 (직접 정의)
  core/interceptors.ts
  api/
    search.ts
    recipe.ts
    index.ts                ← re-export 배럴
  index.ts                  ← 전체 re-export
```

---

### queries 구조

TanStack Query 훅은 도메인별 폴더로 분리한다. 각 폴더는 훅과 쿼리 키를 함께 관리한다:

```
src/queries/
  {domain}/
    index.ts        ← useXxxQuery, useXxxMutation 훅
    queryKeys.ts    ← 쿼리 키 팩토리
  index.ts          ← 전체 re-export 배럴 (선택)
```

**queryKeys.ts 패턴:**

```typescript
// queries/search/queryKeys.ts
export const searchKeys = {
  all: ["search"] as const,
  list: (query: string) => [...searchKeys.all, "list", query] as const,
};
```

**index.ts 패턴:**

```typescript
// queries/search/index.ts
'use client';

import { useInfiniteQuery } from '@tanstack/react-query';
import searchServices from '@/services/api/search';
import { searchKeys } from './queryKeys';

export function useInfiniteSearchQuery(query: string) {
  return useInfiniteQuery({ ... });
}
```

**규칙 요약:**

| 규칙        | 내용                                               |
| ----------- | -------------------------------------------------- |
| 도메인 분리 | 1도메인 = 1폴더 (`search/`, `recipe/`, `coupang/`) |
| 파일 분리   | 훅(`index.ts`) + 쿼리 키(`queryKeys.ts`) 항상 분리 |
| 서비스 연결 | 훅 내부에서 `services/api/{domain}` 직접 호출      |
| Client 선언 | 훅 파일 최상단에 `'use client'` 필수               |

---

## enum 타입 호환성

### 다중 모듈 enum 충돌

같은 이름의 enum이 여러 모듈에 정의되어 있을 수 있다. TypeScript는 이름이 같아도 다른 모듈의 enum을 호환하지 않는다.

```typescript
// ❌ 금지: 잘못된 모듈에서 import
// payment/types.ts에서 PaymentMethodType을 사용하는 코드인데
import { PaymentMethodType } from "@/shared/constants/order"; // 다른 모듈의 enum

// ✅ 올바른 방법: 서비스/타입이 정의된 모듈에서 직접 import
import { PaymentMethodType } from "@/payment/types"; // 실제 사용 모듈
```

**규칙**:

- 서비스 타입(`*Service.ts`, `types.ts`)에서 정의한 enum을 사용할 때는 해당 파일에서 직접 import
- 같은 이름의 enum이 여럿 존재할 경우, IDE 자동완성 import에 의존하지 말고 import 경로를 명시적으로 확인
- 새 enum 정의 전에 기존 동일 이름 enum이 있는지 `rg "enum PaymentMethodType"` 으로 검색

---

## 참조

| 문서                          | 용도               |
| ----------------------------- | ------------------ |
| `react-nextjs-conventions.md` | React/Next.js 규칙 |
| `react-hooks-patterns.md`     | Hook 성능 패턴     |
| `state-and-server-state.md`   | 상태 관리 경계     |
| `forbidden-patterns.md`       | 금지 패턴          |
