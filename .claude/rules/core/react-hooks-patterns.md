# React Hook 성능 패턴

> `coding-standards.md` 보완 규칙 - Hook 관련 성능 안티패턴 및 권장 패턴

---

## useMemo 과용 금지

단순 primitive 계산에 `useMemo`를 사용하면 오히려 메모이제이션 오버헤드가 계산 비용을 초과한다.

```typescript
// ❌ 금지: 단순 계산에 useMemo 낭비
const isActive = useMemo(() => status === 'active', [status]);
const fullName = useMemo(() => `${firstName} ${lastName}`, [firstName, lastName]);
const count = useMemo(() => items.length, [items]);

// ✅ 허용: 렌더링 중 직접 계산
const isActive = status === 'active';
const fullName = `${firstName} ${lastName}`;
const count = items.length;
```

**useMemo가 필요한 경우:**

```typescript
// ✅ 비싼 계산 (대량 데이터 필터링/정렬)
const filteredItems = useMemo(
  () => items.filter((item) => item.category === selectedCategory),
  [items, selectedCategory],
);

// ✅ 참조 안정성이 필요한 객체/배열 (자식 컴포넌트 props)
const config = useMemo(() => ({ theme, locale }), [theme, locale]);
```

---

## useState 지연 초기화

초기값 계산이 비싼 경우, `useState`에 값 대신 **함수**를 전달한다.
초기화 함수는 최초 마운트 시 한 번만 실행된다.

```typescript
// ❌ 안티패턴: 매 렌더링마다 expensiveFn() 실행 (반환값은 무시됨)
const [data, setData] = useState(expensiveFn());

// ✅ 지연 초기화: 최초 마운트 시 한 번만 실행
const [data, setData] = useState(() => expensiveFn());

// ✅ localStorage 읽기도 동일하게 적용
const [token, setToken] = useState(() => localStorage.getItem('token') ?? '');
```

---

## useRef - 리렌더를 유발하지 않는 값

렌더링 결과에 영향을 주지 않는 값은 `useState` 대신 `useRef`로 관리한다.
`useRef` 값 변경은 리렌더를 유발하지 않는다.

```typescript
// ❌ 안티패턴: 렌더링에 사용되지 않는 값을 useState로 관리
const [timerId, setTimerId] = useState<ReturnType<typeof setTimeout> | null>(null);
const [prevValue, setPrevValue] = useState(initialValue);

// ✅ 렌더링 불필요한 값은 useRef
const timerIdRef = useRef<ReturnType<typeof setTimeout> | null>(null);
const prevValueRef = useRef(initialValue);
```

**useRef가 적합한 사례:**

| 사례 | 설명 |
|------|------|
| 타이머 ID | setTimeout/setInterval 반환값 |
| 이전 값 추적 | 이전 렌더의 props/state 저장 |
| DOM 측정값 | scrollTop, clientHeight 등 |
| 이벤트 핸들러 ref | effect 내부에서 재구독 방지 |

```typescript
// ✅ 이벤트 핸들러를 ref에 저장 (effect 재구독 방지)
const onScrollRef = useRef(onScroll);
useEffect(() => {
  onScrollRef.current = onScroll;
});

useEffect(() => {
  const handler = () => onScrollRef.current();
  window.addEventListener('scroll', handler);
  return () => window.removeEventListener('scroll', handler);
}, []); // onScroll 변경 시 재구독 없음
```

---

## 참조 문서

| 문서 | 용도 |
|------|------|
| `coding-standards.md` | 기본 TypeScript/React 표준 |
| `state-and-server-state.md` | 상태 관리 경계 |
