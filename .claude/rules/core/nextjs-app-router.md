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

## 체크리스트

App Router 코드 작성 시:

- [ ] Server Component vs Client Component 구분이 명확한가?
- [ ] 독립적인 데이터 패칭은 컴포넌트 분리로 병렬화했는가?
- [ ] Server Action 내부에 인증 검증이 있는가?
- [ ] RSC props에 불필요한 필드가 포함되지 않았는가?
- [ ] 동일 요청 내 반복 호출은 React.cache()로 중복 제거했는가?
- [ ] 로깅/분석 등 사이드 이펙트는 after()로 분리했는가?

---

## 참조 문서

| 문서 | 용도 |
|------|------|
| `react-nextjs-conventions.md` | 공통 React/Next.js 컨벤션 |
| `state-and-server-state.md` | 상태 관리 경계 |
