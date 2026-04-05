# 레벨 판별 루브릭

> Next.js 16 + React 19.2 기준 | 2026년 4월
> 각 레벨 체크리스트에서 8/12 이상이면 해당 레벨로 판별

---

## 🟢 주니어 시그니처 패턴 (12가지)

| ID | 패턴 | 설명 |
|----|------|------|
| J-01 | `'use client'` 남발 | 모든 컴포넌트 상단에 무조건 선언 |
| J-02 | `useEffect + fetch` 조합 | 서버 컴포넌트 대신 클라이언트에서 API 호출 |
| J-03 | `useState`로 로딩/에러 수동 관리 | `isLoading`, `error` state를 직접 선언 |
| J-04 | `any` 타입 사용 | `useState<any>`, 함수 파라미터 `any` |
| J-05 | props drilling 3단계 이상 | 컴포넌트 체인으로 props 전달 |
| J-06 | 단순/짧은 변수명 | `data`, `res`, `temp`, `item`, `val` |
| J-07 | 모든 컴포넌트를 `components/` 한 곳에 | 기능/도메인 분리 없는 평면 구조 |
| J-08 | `console.log` 디버깅 코드 잔존 | 삭제되지 않은 `console.log` |
| J-09 | 인라인 스타일 혼용 | Tailwind + `style={{ ... }}` 혼합 |
| J-10 | 에러 처리 없거나 단순 `alert` | try/catch 없거나 `alert(error.message)` |
| J-11 | `useEffect` 의존성 배열 누락/잘못됨 | `// eslint-disable-next-line` 주석 |
| J-12 | 한 컴포넌트에 너무 많은 역할 | 데이터 패칭 + 상태 + UI + 로직 전부 한 파일 |

### 주니어 의도적 실수 패턴
- API 호출 결과를 `await` 없이 사용 → Promise 객체가 렌더됨
- `key` prop으로 index 사용: `posts.map((p, i) => <li key={i}>)`
- 환경 변수를 클라이언트에서 `process.env.SECRET_KEY`로 직접 접근 시도
- `useEffect` 안에서 `async` 함수를 직접 선언 후 즉시 실행 (cleanup 없음)
- fetch 에러와 HTTP 에러를 구분하지 않음 (4xx를 성공으로 처리)
- TypeScript 에러를 `@ts-ignore`로 무시

---

## 🔵 미들 시그니처 패턴 (12가지)

| ID | 패턴 | 설명 |
|----|------|------|
| M-01 | async 서버 컴포넌트로 데이터 패칭 | `export default async function Page()` |
| M-02 | Server/Client 경계 의식적 분리 | 인터랙티브 부분만 `'use client'` |
| M-03 | App Router 파일 컨벤션 활용 | `loading.tsx`, `error.tsx`, `not-found.tsx` |
| M-04 | Route Groups 활용 | `(marketing)`, `(dashboard)` 그룹화 |
| M-05 | 기본 Server Actions 사용 | `'use server'` + form action 패턴 |
| M-06 | `revalidatePath` / `revalidateTag` | 뮤테이션 후 캐시 무효화 |
| M-07 | Custom Hooks 분리 | `useDebounce`, `useFetch` 등 로직 훅 |
| M-08 | 도메인 의미있는 변수명 | `userProfile`, `postList`, `isSubmitting` |
| M-09 | 기본 Zod 스키마 + 서버사이드 검증 | `z.object({ title: z.string().min(1) })` |
| M-10 | `useActionState` 기본 활용 | 폼 상태 + pending 표시 |
| M-11 | `<Suspense>` + 스켈레톤 UI | 로딩 상태를 선언적으로 처리 |
| M-12 | 컴포넌트/훅/유틸 폴더 분리 | `features/`, `hooks/`, `lib/` 구조 |

### 미들 흔한 미흡 패턴 (의도적 재현)
- Server Action에 인증 체크는 있지만 소유권 체크는 없음
- `use cache` 없이 모든 서버 컴포넌트가 매 요청마다 DB 조회
- 병렬로 가능한 fetch를 순차적으로 `await` (waterfall)
- Zod 검증을 클라이언트에서만 하고 서버에서 재검증 안 함
- 에러 바운더리를 페이지 최상단 하나만 설치

---

## 🔴 시니어 시그니처 패턴 (12가지)

| ID | 패턴 | 설명 |
|----|------|------|
| S-01 | `use cache` + `cacheLife` / `cacheTag` | PPR 기반 세밀한 캐싱 전략 |
| S-02 | `Promise.allSettled` 병렬 패칭 | waterfall 방지 + 부분 실패 허용 |
| S-03 | `React.cache()` 요청 중복 제거 | 동일 요청 내 memoization |
| S-04 | `useEffectEvent` | Effect 의존성 버그 해결 |
| S-05 | `<Activity />` 상태 보존 | 탭/모달 등 UI 상태 보존 + 선제 렌더링 |
| S-06 | `useOptimistic` 낙관적 업데이트 | 즉각적 UI 피드백 + 자동 롤백 |
| S-07 | `server-only` + 환경 오염 방지 | 클라이언트 번들 노출 방지 |
| S-08 | Result 타입 패턴 | `{ ok: true, data } \| { ok: false, error }` |
| S-09 | React Compiler 점진적 도입 | `"use no memo"` opt-out 전략 포함 |
| S-10 | 인증/인가 이중 검증 | 세션 확인 + 소유권 확인 (Server Action 내) |
| S-11 | `queryOptions` API + `useSuspenseQuery` | React Query v5 타입 안전 패턴 |
| S-12 | 도메인 레이어 분리 | repository 패턴, infrastructure 추상화 |

---

## 레벨별 코드 외적 특징

### 네이밍 스타일

| 요소 | 주니어 | 미들 | 시니어 |
|------|--------|------|--------|
| 컴포넌트 | `Card`, `List` | `PostCard`, `UserList` | `PostFeedCard`, `UserFollowList` |
| 변수 | `data`, `res` | `posts`, `userData` | `publishedPosts`, `authenticatedUser` |
| 함수 | `handleClick`, `doThing` | `handleSubmit`, `fetchPosts` | `handlePostLike`, `invalidatePostCache` |
| 타입 | 없거나 `any` | `Post`, `User` | `CreatePostInput`, `PostWithAuthor` |

### 파일 분리 기준

| 레벨 | 기준 |
|------|------|
| 주니어 | 파일이 300줄 넘어도 분리 안 함 |
| 미들 | 100줄 넘으면 분리 고려, 컴포넌트/훅/유틸 분리 |
| 시니어 | 단일 책임 원칙, 20~80줄 유지 |

### 주석 스타일

```tsx
// 주니어: 코드를 설명하는 주석
// 데이터 가져오기
const res = await fetch('/api/posts')

// 미들: 이유 설명
// 로그인 사용자만 접근 가능
if (!session) redirect('/login')

// 시니어: 컨텍스트 + 트레이드오프
// React.cache()는 요청 스코프 memoization — 요청 간 공유 불가
// 요청 간 공유가 필요하면 Redis 캐시 사용 필요
export const getUser = cache(async (id: string) => { ... })
```

---

## 자가 검증 체크리스트

### 주니어 검증 (8/12 이상 = 주니어)
- [ ] `'use client'`가 3개 이상의 컴포넌트에 있는가?
- [ ] `useEffect + fetch` 조합이 있는가?
- [ ] `any` 타입이 1개 이상 있는가?
- [ ] `isLoading`/`error`를 `useState`로 수동 관리하는가?
- [ ] 변수명이 `data`, `res`, `item` 수준인가?
- [ ] `console.log`가 있는가?
- [ ] `key`에 index를 사용하는가?
- [ ] 에러 처리가 비어있거나 `alert`인가?
- [ ] 한 파일이 200줄 이상인가?
- [ ] Server Component를 전혀 활용하지 않는가?
- [ ] 인라인 스타일이 혼용되는가?
- [ ] 한 컴포넌트에 데이터+상태+UI+로직이 모두 있는가?

### 미들 검증 (8/12 이상 = 미들)
- [ ] async 서버 컴포넌트로 데이터 패칭하는가?
- [ ] `'use client'`가 인터랙티브 컴포넌트에만 있는가?
- [ ] `loading.tsx` 또는 `<Suspense>`를 활용하는가?
- [ ] `Server Action + useActionState`를 사용하는가?
- [ ] `revalidatePath` / `revalidateTag`를 사용하는가?
- [ ] Zod로 서버사이드 검증을 하는가?
- [ ] Custom Hook으로 로직을 분리했는가?
- [ ] `features/` 또는 도메인별 폴더 구조인가?
- [ ] 도메인 의미있는 변수명을 사용하는가?
- [ ] TypeScript 타입이 명시적으로 선언됐는가?
- [ ] Route Groups를 활용하는가?
- [ ] `error.tsx`로 에러 바운더리를 설정했는가?

### 시니어 검증 (8/12 이상 = 시니어)
- [ ] `'use cache'` + `cacheLife`/`cacheTag`를 사용하는가?
- [ ] `Promise.allSettled()`로 병렬 패칭하는가?
- [ ] `React.cache()`로 요청 중복을 제거하는가?
- [ ] `useOptimistic`으로 낙관적 업데이트를 하는가?
- [ ] Result 타입 패턴을 사용하는가?
- [ ] `server-only`로 모듈 오염을 방지하는가?
- [ ] Server Action에서 인증 + 소유권 이중 검증하는가?
- [ ] `queryOptions` API를 사용하는가?
- [ ] repository 패턴으로 DB 접근을 추상화하는가?
- [ ] `updateTag`/`cacheTag` 기반 온디맨드 무효화인가?
- [ ] 접근성 속성(`aria-*`)이 자연스럽게 포함됐는가?
- [ ] 파일당 80줄 이하의 단일 책임인가?
