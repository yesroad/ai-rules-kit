# React & Next.js 컨벤션

Next.js 버전 및 Router 방식(Pages Router / App Router)은 프로젝트에 설치된 버전을 따른다.

> **App Router 전용 규칙**: `nextjs-app-router.md` 참조
> **Hook 성능 패턴**: `react-hooks-patterns.md` 참조

---

## Import 순서

아래 순서를 반드시 지킨다. ESLint 규칙으로도 강제된다.

```typescript
// 1. 외부 라이브러리
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';

// 2. 내부 패키지 / @/ alias
import { Button } from '@/components';
import { useOrderQuery } from '@/queries/order';

// 3. 상대 경로
import { OrderHeader } from './components/OrderHeader';
import { formatPrice } from '../utils/format';
```

---

## 컴포넌트 작성 규칙

### 함수 선언 방식

- 페이지 컴포넌트: 프로젝트 규칙에 따른 타입 적용
- 일반 컴포넌트: `const ComponentName = () => {}` 또는 `function ComponentName() {}`

### Props 타입 정의

- 컴포넌트와 동일 파일에 정의한다
- 별도 types 파일 분리는 복잡한 경우에만 한다

```typescript
// 좋은 예
interface OrderCardProps {
  order: Order;
  onSelect: (id: string) => void;
}

const OrderCard = ({ order, onSelect }: OrderCardProps) => { ... };
```

---

## 스타일링 (Emotion)

### 기본 규칙

- `@emotion/styled` 또는 `css` prop을 사용한다
- 프로젝트의 디자인 시스템 컴포넌트를 우선 사용한다

### 스타일 컴포넌트 위치

- 간단한 스타일: 컴포넌트 파일 하단에 정의
- 복잡한 스타일: `styled.ts` 파일로 분리

```typescript
// 좋은 예: 컴포넌트 파일 하단
const Container = styled.div`
  padding: 16px;
`;

// 복잡한 경우: 별도 파일 (styled.ts)
// components/OrderCard/styled.ts
export const Container = styled.div`...`;
export const Header = styled.div`...`;

// 사용 (index.tsx) - named import 사용 (프로젝트 기존 패턴)
import { Container, Header } from './styled';
// <Container>...</Container>
```

---

## 기존 코드 패턴 참조 규칙

### 필수: 유사 구현 탐색

새로운 기능을 구현하기 전에 반드시 기존 코드에서 유사 패턴을 찾는다:

```bash
# 유사 컴포넌트 검색
rg "ComponentName" src/

# 유사 훅 검색
rg "useHookName" src/

# 유사 타입 검색
rg "TypeName" src/
```

### 타입 재사용

기존에 정의된 타입이 있으면 재사용한다:

```typescript
// ✅ 좋은 예: 기존 타입 재사용
import { Status, Item } from '../types';

// ❌ 나쁜 예: 중복 타입 정의
interface MyStatus {
  code: string;
  label: string;
}
```

### 패턴 참조 체크리스트

새 코드 작성 전:

- [ ] 디자인 시스템에 해당 컴포넌트가 있는가?
- [ ] 유사한 컴포넌트/훅이 기존에 있는가?
- [ ] 재사용 가능한 타입이 있는가?

---

## 금지/권장 예시

### 예시 1: 페이지 컴포넌트 구조

> Pages Router 예시. App Router는 `nextjs-app-router.md` 참조. **원칙은 동일**: 페이지는 얇게, 로직은 Container로 분리.

```typescript
// ❌ 나쁜 예: 페이지에 로직이 모두 포함됨
// pages/order/[orderId].tsx (Pages Router)
const OrderPage = () => {
  const { orderId } = useRouter().query;
  const { data } = useQuery(...);
  const [state, setState] = useState(...);

  const handleSubmit = async () => { ... };

  return (
    <div>
      {/* 수백 줄의 JSX */}
    </div>
  );
};
```

```typescript
// ✅ 좋은 예: 페이지는 얇게, 로직은 Container로 분리
// pages/order/[orderId].tsx (Pages Router)
import { OrderContainer } from '@/order/containers/OrderContainer';

const OrderPage = () => {
  return <OrderContainer />;
};

export default OrderPage;
```

---

### 예시 2: Import 순서

```typescript
// ❌ 나쁜 예: 순서가 뒤섞임
import { OrderHeader } from './OrderHeader';
import { useState } from 'react';
import { Button } from '@/components';
import axios from 'axios';
```

```typescript
// ✅ 좋은 예: 외부 → 내부 패키지 → 상대경로
import { useState } from 'react';
import axios from 'axios';

import { Button } from '@/components';

import { OrderHeader } from './OrderHeader';
```

---

### 예시 3: 컴포넌트 Props 처리

```typescript
// ❌ 나쁜 예: any 사용, 타입 정의 없음
const OrderCard = (props: any) => {
  return <div>{props.data.title}</div>;
};
```

```typescript
// ✅ 좋은 예: 명시적 타입 정의
interface OrderCardProps {
  order: Order;
  isSelected?: boolean;
}

const OrderCard = ({ order, isSelected = false }: OrderCardProps) => {
  return (
    <Container isSelected={isSelected}>
      {order.title}
    </Container>
  );
};
```

---

### 예시 4: API 라우트 프록시

```typescript
// ❌ 나쁜 예: 프론트엔드에서 직접 외부 API 호출
const data = await axios.get('https://api.example.com/orders');
```

```typescript
// ✅ 좋은 예: /api 프록시 경유 (Next.js API Routes)
// 설정된 프록시가 NEXT_PUBLIC_API_URL로 전달
const data = await api.get('/api/orders');
```

---

## 파일 명명 규칙

| 유형     | 규칙                     | 예시                              |
| -------- | ------------------------ | --------------------------------- |
| 페이지   | kebab-case 또는 [param]  | `order-list.tsx`, `[orderId].tsx` |
| 컴포넌트 | PascalCase               | `OrderCard.tsx`                   |
| 훅       | camelCase, use 접두사    | `useOrderStatus.ts`               |
| 유틸리티 | camelCase                | `formatDate.ts`                   |
| 타입     | PascalCase, types 접미사 | `order.types.ts`                  |
| 스타일   | styled                   | `styled.ts`                       |

---

## Portal 사용

오버레이 UI(모달, 토스트, 다이얼로그)는 프로젝트에서 지정한 Portal을 사용한다. 임의의 Portal을 추가하지 않는다.
