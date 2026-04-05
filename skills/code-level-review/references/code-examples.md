# 레벨별 대조 코드 예제

> 동일 기능을 주니어/미들/시니어로 구현한 대조 예제

---

## 예제 A: 게시글 목록 조회 (데이터 패칭)

### 🟢 주니어

```tsx
'use client'
import { useState, useEffect } from 'react'

export default function PostList() {
  const [data, setData] = useState([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    setIsLoading(true)
    fetch('/api/posts')
      .then(res => res.json())
      .then(data => { setData(data); setIsLoading(false) })
      .catch(err => { setError(err); setIsLoading(false) })
  }, [])

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error!</div>

  return (
    <ul>
      {data.map((item: any, i: number) => (
        <li key={i}>{item.title}</li>
      ))}
    </ul>
  )
}
```

### 🔵 미들

```tsx
import { Suspense } from 'react'
import PostListSkeleton from './_components/PostListSkeleton'

export default function PostsPage() {
  return (
    <Suspense fallback={<PostListSkeleton />}>
      <PostList />
    </Suspense>
  )
}

interface Post { id: string; title: string; createdAt: string }

async function PostList() {
  const res = await fetch('/api/posts', { next: { revalidate: 60 } })
  const posts: Post[] = await res.json()

  return (
    <ul>
      {posts.map(post => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### 🔴 시니어

```tsx
import { cache } from 'react'
import { cacheLife, cacheTag } from 'next/cache'
import { db } from '@/infrastructure/db'

export type Post = { id: string; title: string; authorId: string; createdAt: Date }

export const getPosts = cache(async (): Promise<Post[]> => {
  return db.post.findMany({ orderBy: { createdAt: 'desc' } })
})

async function PostList() {
  'use cache'
  cacheLife('minutes')
  cacheTag('posts')

  const posts = await getPosts()
  return (
    <ul className="divide-y">
      {posts.map(post => (
        <li key={post.id}><PostItem post={post} /></li>
      ))}
    </ul>
  )
}

export default function PostsPage() {
  return (
    <Suspense fallback={<PostListSkeleton />}>
      <PostList />
    </Suspense>
  )
}
```

---

## 예제 B: 게시글 작성 폼 (뮤테이션 + 유효성 검증)

### 🟢 주니어

```tsx
'use client'
import { useState } from 'react'

export default function CreatePostForm() {
  const [title, setTitle] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: any) => {
    e.preventDefault()
    if (!title) { alert('제목을 입력하세요'); return }
    setLoading(true)
    try {
      await fetch('/api/posts', { method: 'POST', body: JSON.stringify({ title }) })
      alert('작성 완료!')
    } catch (err) {
      console.log(err)
    }
    setLoading(false)
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={title} onChange={e => setTitle(e.target.value)}
        style={{ border: '1px solid gray' }} />
      <button disabled={loading}>Submit</button>
    </form>
  )
}
```

### 🔵 미들

```tsx
// app/posts/actions.ts
'use server'
import { z } from 'zod'
import { revalidatePath } from 'next/cache'

const createPostSchema = z.object({
  title: z.string().min(1, '제목을 입력하세요').max(100),
})

export async function createPost(prevState: { error?: string } | null, formData: FormData) {
  const parsed = createPostSchema.safeParse({ title: formData.get('title') })
  if (!parsed.success) return { error: parsed.error.errors[0].message }
  await db.post.create({ data: parsed.data })
  revalidatePath('/posts')
}

// 클라이언트 컴포넌트
'use client'
import { useActionState } from 'react'
import { createPost } from '../actions'

export default function NewPostPage() {
  const [state, action, isPending] = useActionState(createPost, null)
  return (
    <form action={action}>
      {state?.error && <p className="text-red-500">{state.error}</p>}
      <input name="title" className="border rounded p-2" />
      <button type="submit" disabled={isPending}>
        {isPending ? '저장 중...' : '작성'}
      </button>
    </form>
  )
}
```

### 🔴 시니어

```tsx
// shared/lib/result.ts
export type ActionResult<T = void> =
  | { ok: true; data: T }
  | { ok: false; error: string; fieldErrors?: Record<string, string[]> }

// features/posts/schemas.ts
export const createPostSchema = z.object({
  title: z.string().min(1).max(100),
  content: z.string().min(10).max(10000),
})
export type CreatePostInput = z.infer<typeof createPostSchema>

// features/posts/actions.ts
'use server'
import 'server-only'
import { auth } from '@/lib/auth'

export async function createPostAction(
  _prev: ActionResult | null,
  formData: FormData
): Promise<ActionResult<{ id: string }>> {
  const session = await auth()
  if (!session?.user) return { ok: false, error: 'Unauthorized' }

  const parsed = createPostSchema.safeParse(Object.fromEntries(formData))
  if (!parsed.success) return {
    ok: false, error: '입력값을 확인해주세요',
    fieldErrors: parsed.error.flatten().fieldErrors,
  }

  const post = await postRepository.create({ ...parsed.data, authorId: session.user.id })
  revalidateTag('posts')
  return { ok: true, data: { id: post.id } }
}
```

---

## 예제 C: 좋아요 버튼 (낙관적 업데이트)

### 🟢 주니어

```tsx
'use client'
export default function LikeButton({ postId, initialLikes }: any) {
  const [likes, setLikes] = useState(initialLikes)
  const handleLike = async () => {
    const res = await fetch(`/api/posts/${postId}/like`, { method: 'POST' })
    const data = await res.json()
    setLikes(data.likes) // 응답 올 때까지 UI 업데이트 없음
  }
  return <button onClick={handleLike}>❤ {likes}</button>
}
```

### 🔵 미들

```tsx
'use client'
export function LikeButton({ postId, initialLikes, initialLiked }: {
  postId: string; initialLikes: number; initialLiked: boolean
}) {
  const [likes, setLikes] = useState(initialLikes)
  const [liked, setLiked] = useState(initialLiked)
  const [isPending, setIsPending] = useState(false)

  const handleClick = async () => {
    setIsPending(true)
    const result = await toggleLike(postId)
    if (result.ok) { setLikes(result.data.likes); setLiked(result.data.liked) }
    setIsPending(false)
  }

  return (
    <button onClick={handleClick} disabled={isPending}>
      {liked ? '❤' : '🤍'} {likes}
    </button>
  )
}
```

### 🔴 시니어

```tsx
'use client'
import { useOptimistic, startTransition } from 'react'

type LikeState = { likes: number; liked: boolean }

export function LikeButton({ postId, initialLikes, initialLiked }: {
  postId: string; initialLikes: number; initialLiked: boolean
}) {
  const [optimistic, updateOptimistic] = useOptimistic<LikeState, boolean>(
    { likes: initialLikes, liked: initialLiked },
    (current, newLiked) => ({
      liked: newLiked,
      likes: current.likes + (newLiked ? 1 : -1),
    })
  )

  const handleClick = () => {
    const newLiked = !optimistic.liked
    startTransition(async () => {
      updateOptimistic(newLiked)
      await toggleLikeAction(postId, newLiked) // 실패 시 자동 롤백
    })
  }

  return (
    <button onClick={handleClick} aria-pressed={optimistic.liked}
      aria-label={`좋아요 ${optimistic.likes}개`}>
      <span aria-hidden>{optimistic.liked ? '❤' : '🤍'}</span>
      <span>{optimistic.likes}</span>
    </button>
  )
}
```

---

## 예제 D: 상태 관리 (전역 상태 + URL 상태)

### 🟢 주니어

```tsx
'use client'
const AppContext = createContext<any>(null)

export function AppProvider({ children }: any) {
  const [user, setUser] = useState(null)
  const [posts, setPosts] = useState([])
  const [theme, setTheme] = useState('light')
  const [cart, setCart] = useState([])
  // 관련없는 상태들을 하나의 Context에 몰아넣음
  return (
    <AppContext.Provider value={{ user, setUser, posts, setPosts, theme, setTheme, cart, setCart }}>
      {children}
    </AppContext.Provider>
  )
}
```

### 🔵 미들

```tsx
// Zustand로 전역 상태 관리
import { create } from 'zustand'

export const useCartStore = create<CartStore>((set) => ({
  items: [],
  addItem: (item) => set(state => ({ items: [...state.items, item] })),
  removeItem: (id) => set(state => ({ items: state.items.filter(i => i.id !== id) })),
}))

// URL 상태: useSearchParams로 필터/페이지 관리
'use client'
export function PostFilter() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const category = searchParams.get('category') ?? 'all'
  return (
    <select value={category} onChange={e => router.push(`?category=${e.target.value}`)}>
      <option value="all">전체</option>
      <option value="tech">기술</option>
    </select>
  )
}
```

### 🔴 시니어

```tsx
// nuqs로 타입 안전한 URL 상태
import { createSearchParamsCache, parseAsString, parseAsInteger } from 'nuqs/server'

export const searchParamsCache = createSearchParamsCache({
  category: parseAsString.withDefault('all'),
  page: parseAsInteger.withDefault(1),
})

// 서버 컴포넌트에서 타입 안전 파싱
export default async function PostsPage({ searchParams }) {
  const { category, page } = searchParamsCache.parse(await searchParams)
  return (
    <Suspense fallback={<PostListSkeleton />}>
      <PostList category={category} page={page} />
    </Suspense>
  )
}

// 클라이언트 UI 상태만 Zustand (최소화)
import { devtools } from 'zustand/middleware'

export const useUIStore = create<UIStore>()(
  devtools(
    set => ({ sidebarOpen: false, toggleSidebar: () => set(s => ({ sidebarOpen: !s.sidebarOpen })) }),
    { name: 'ui-store' }
  )
)
```
