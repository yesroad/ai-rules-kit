# Next.js App Router 규칙

> App Router (Next.js 13+) 프로젝트 전용 규칙
> Pages Router 프로젝트에서는 적용하지 않는다

---

## 적용 조건 확인

```bash
# package.json에서 Next.js 버전 확인
cat package.json | grep next

# App Router 사용 여부: app/ 디렉토리 존재 확인
ls src/app 또는 ls app
```

---

## Suspense 경계 전략

데이터 로딩이 필요한 컴포넌트를 Suspense로 격리하면 나머지 UI를 먼저 렌더링할 수 있다.

```typescript
// ❌ 안티패턴: 최상위에서 await → 전체 UI 블로킹
// app/dashboard/page.tsx
export default async function Page() {
  const data = await fetchSlowData(); // 전체 페이지 대기
  return <Dashboard data={data} />;
}

// ✅ Suspense로 격리 → 빠른 부분 먼저 표시
// app/dashboard/page.tsx
export default function Page() {
  return (
    <main>
      <Header /> {/* 즉시 렌더링 */}
      <Suspense fallback={<Skeleton />}>
        <SlowDataComponent /> {/* 독립적으로 로딩 */}
      </Suspense>
    </main>
  );
}

// SlowDataComponent.tsx (Server Component)
async function SlowDataComponent() {
  const data = await fetchSlowData();
  return <Dashboard data={data} />;
}
```

---

## Server Actions 인증

Server Action은 클라이언트에서 직접 호출 가능하므로 **각 Action 내부에서** 인증을 반드시 검증한다.
미들웨어나 레이아웃의 인증 처리에 의존하지 않는다.

```typescript
// ❌ 금지: 인증 없이 바로 처리
'use server';
export async function updateUserProfile(data: FormData) {
  await db.user.update({ ... }); // 누구나 호출 가능!
}

// ✅ 필수: Action 내부에서 직접 인증 검증
'use server';
export async function updateUserProfile(data: FormData) {
  const session = await getServerSession();
  if (!session?.user) {
    throw new Error('인증이 필요합니다');
  }
  // 추가로 권한 확인
  if (!canUpdateProfile(session.user, data)) {
    throw new Error('권한이 없습니다');
  }
  await db.user.update({ ... });
}
```

---

## RSC Props 직렬화 최소화

RSC(서버 컴포넌트)에서 클라이언트 컴포넌트로 전달하는 props는 직렬화 비용이 발생한다.
클라이언트에서 사용하지 않는 필드는 전달하지 않는다.

```typescript
// ❌ 금지: 전체 객체를 그대로 전달 (불필요한 필드 포함)
// ServerComponent.tsx
export async function UserCard() {
  const user = await db.user.findFirst(); // id, name, email, password, internalMeta, ...
  return <UserCardClient user={user} />; // 민감 정보 포함 가능성
}

// ✅ 필요한 필드만 선택해서 전달
export async function UserCard() {
  const user = await db.user.findFirst();
  return (
    <UserCardClient
      userId={user.id}
      displayName={user.name}
    />
  );
}
```

---

## Component Composition으로 병렬 데이터 패칭

React Server Component 트리 내 `await`은 순차 실행된다.
독립적인 데이터 패칭은 **컴포넌트 분리**로 병렬화한다.

```typescript
// ❌ 안티패턴: 순차 실행 (총 소요 시간 = A + B)
export default async function Page() {
  const userProfile = await fetchUserProfile(); // 500ms
  const userPosts = await fetchUserPosts();     // 300ms
  return <Layout profile={userProfile} posts={userPosts} />;
}

// ✅ 컴포넌트 분리로 병렬 실행 (총 소요 시간 = max(A, B))
export default function Page() {
  return (
    <Layout>
      <Suspense fallback={<ProfileSkeleton />}>
        <UserProfile />  {/* 독립적으로 fetchUserProfile 실행 */}
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <UserPosts />    {/* 독립적으로 fetchUserPosts 실행 */}
      </Suspense>
    </Layout>
  );
}
```

---

## React.cache()로 요청 중복 제거

동일한 요청 내에서 같은 데이터를 여러 컴포넌트가 필요로 할 때 `React.cache()`로 중복을 제거한다.

```typescript
// data/user.ts
import { cache } from 'react';

// 동일 요청 내에서 중복 호출 시 캐시 반환
export const getUser = cache(async (userId: string) => {
  return await db.user.findUnique({ where: { id: userId } });
});

// UserProfile.tsx
async function UserProfile({ userId }: { userId: string }) {
  const user = await getUser(userId); // DB 호출
  return <Profile user={user} />;
}

// UserPosts.tsx
async function UserPosts({ userId }: { userId: string }) {
  const user = await getUser(userId); // 캐시 반환 (DB 재호출 없음)
  return <Posts authorName={user.name} />;
}
```

---

## after()로 비차단 사이드 이펙트

로깅, 분석, 알림 등 응답에 영향을 주지 않는 작업은 `after()`로 응답 후에 실행한다.

```typescript
import { after } from 'next/server';

// ❌ 안티패턴: 사이드 이펙트가 응답을 차단
export async function POST(req: Request) {
  const data = await req.json();
  await db.event.create({ data }); // 핵심 처리
  await sendAnalyticsEvent(data);  // 로깅 때문에 응답 지연
  return Response.json({ success: true });
}

// ✅ after()로 응답 후 비동기 처리
export async function POST(req: Request) {
  const data = await req.json();
  await db.event.create({ data }); // 핵심 처리

  after(async () => {
    await sendAnalyticsEvent(data); // 응답 후 실행
  });

  return Response.json({ success: true }); // 즉시 응답
}
```

---

## `use cache` + PPR 전략 (Next.js 16+)

컴포넌트 단위로 캐시 생명주기를 제어한다. 페이지 단위 SSR/SSG 구분 시대에서 컴포넌트 단위 캐시 전략으로 이동.

```tsx
// ✅ 컴포넌트 레벨 캐싱
async function BlogPosts() {
  'use cache'
  cacheLife('hours')   // 1시간 캐시
  cacheTag('posts')    // 태그 기반 무효화

  const posts = await db.post.findMany()
  return <PostList posts={posts} />
}

// ✅ 온디맨드 무효화 (Server Action에서)
import { revalidateTag } from 'next/cache'

export async function createPostAction(formData: FormData) {
  'use server'
  await db.post.create({ data: parsed.data })
  revalidateTag('posts')  // 'posts' 태그 캐시 전체 무효화
}
```

**cacheLife 프리셋:**
| 프리셋 | 기간 | 용도 |
|--------|------|------|
| `'seconds'` | 0~1분 | 실시간성 필요 |
| `'minutes'` | 1~10분 | 자주 변하는 데이터 |
| `'hours'` | 1시간 | 일반 컨텐츠 |
| `'days'` | 1일 | 정적에 가까운 데이터 |

**PPR 렌더링 전략:**
```tsx
// 정적 shell + 동적 스트리밍 혼합
export default function Page() {
  return (
    <>
      <StaticHeader />  {/* 빌드 시 prerender */}
      <CachedPosts />   {/* use cache — 정적 shell 포함 */}
      <Suspense fallback={<Skeleton />}>
        <UserPersonalized />  {/* 요청 시 스트리밍 */}
      </Suspense>
    </>
  )
}
```

---

## useEffectEvent — Effect 의존성 버그 해결 (React 19.2+)

Effect 내부에서 항상 최신 값을 참조해야 하지만, 의존성 배열에 포함하면 불필요한 재실행이 발생할 때 사용.

```tsx
import { useEffectEvent } from 'react'

// ❌ 기존 방식: theme 변경마다 채팅방 재연결 버그
useEffect(() => {
  const conn = connect(roomId)
  conn.on('connected', () => showNotification('연결됨', theme))
  return () => conn.disconnect()
}, [roomId, theme]) // theme 변경 시 불필요한 재연결

// ✅ useEffectEvent: theme을 의존성에서 분리
function ChatRoom({ roomId, theme }) {
  const onConnected = useEffectEvent(() => {
    showNotification('연결됨', theme) // 항상 최신 theme 참조
  })

  useEffect(() => {
    const conn = connect(roomId)
    conn.on('connected', onConnected)
    return () => conn.disconnect()
  }, [roomId]) // roomId만 의존성 ✅
}
```

---

## `<Activity />` — UI 상태 보존 (React 19.2+)

탭, 모달 등을 숨길 때 상태(입력값, 스크롤 위치 등)를 보존한다. `hidden` 모드에서 effects는 언마운트되지만 상태는 유지.

```tsx
import { Activity } from 'react'

function TabLayout({ activeTab }: { activeTab: string }) {
  return (
    <>
      <Activity mode={activeTab === 'home' ? 'visible' : 'hidden'}>
        <HomePage />
      </Activity>
      <Activity mode={activeTab === 'profile' ? 'visible' : 'hidden'}>
        <ProfilePage /> {/* 탭 전환 시 입력값 등 상태 유지 */}
      </Activity>
    </>
  )
}
```

---

## React Compiler — 점진적 도입 (Next.js 15.3.1+)

수동 메모이제이션(`useMemo`, `useCallback`, `React.memo`)을 빌드 타임에 자동화. 단, 전체 코드베이스에 한 번에 적용하지 않는다.

```ts
// next.config.ts
const nextConfig = {
  experimental: {
    reactCompiler: true,
  },
}
```

**점진적 도입 전략:**
```tsx
// 컴파일러 적용할 컴포넌트 (opt-in)
function SafeComponent() {
  'use memo'
}

// 문제가 생긴 컴포넌트 즉시 제외 (opt-out)
function ProblematicComponent() {
  'use no memo'
}
```

**알려진 이슈 (2026.04 기준):**
- `eslint-plugin-react-hooks`의 `exhaustive-deps`와 충돌 가능
- `try/finally` 패턴 최적화 미지원
- Rules of React 위반 코드가 있으면 무한 렌더 루프 발생 가능
- 기존 프로젝트: ESLint로 Rules of React 위반 먼저 정리 후 도입 권장

---

## 체크리스트

App Router 코드 작성 시:

- [ ] Server Component vs Client Component 구분이 명확한가?
- [ ] 독립적인 데이터 패칭은 컴포넌트 분리로 병렬화했는가?
- [ ] Server Action 내부에 인증 검증이 있는가?
- [ ] RSC props에 불필요한 필드가 포함되지 않았는가?
- [ ] 동일 요청 내 반복 호출은 React.cache()로 중복 제거했는가?
- [ ] 로깅/분석 등 사이드 이펙트는 after()로 분리했는가?
- [ ] 캐시가 필요한 Server Component에 `use cache` + `cacheLife`/`cacheTag`를 적용했는가?
- [ ] `useEffectEvent`로 해결 가능한 Effect 의존성 버그가 없는가?
- [ ] React Compiler 도입 시 문제 컴포넌트에 `"use no memo"`를 적용했는가?

---

## 참조 문서

| 문서 | 용도 |
|------|------|
| `react-nextjs-conventions.md` | 공통 React/Next.js 컨벤션 |
| `state-and-server-state.md` | 상태 관리 경계 |
