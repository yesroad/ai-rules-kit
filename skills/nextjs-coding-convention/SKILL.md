---
name: nextjs-coding-convention
description: >
  Next.js + React 코드 작성 시 시니어 기준 컨벤션 적용 및 레벨 진단.
  "코드 리뷰해줘", "이 패턴 맞아?", "더 좋은 방법", "시니어 패턴으로", "nextjs 컨벤션",
  "이 코드 수준이 어때?", "주니어 패턴", "미들 수준" 등이 언급될 때 반드시 사용.
  코드 작성 시에는 시니어 기준 패턴을 기본으로 적용하고,
  코드 리뷰 요청 시에는 레벨(주니어/미들/시니어)을 진단하고 개선 포인트를 제시한다.
user-invocable: true
---

# nextjs-coding-convention

> Next.js + React 코드를 시니어 기준으로 작성하고, 기존 코드의 레벨을 진단한다.
> **기술 스택**: Next.js 16 + React 19.2 + TypeScript + Zustand + React Query v5 + Axios

---

## 두 가지 모드

### 모드 A: 코드 작성
사용자가 코드 작성을 요청하면 시니어 기준 패턴을 적용한다.

**시니어 패턴 우선순위:**
1. 서버 컴포넌트 우선 — `'use client'`는 꼭 필요한 곳에만
2. `use cache` + `cacheTag` — 서버 컴포넌트 캐싱
3. `useOptimistic` — 즉각적 UI 피드백
4. `Result 타입` — `{ ok: true, data } | { ok: false, error }`
5. `server-only` — 서버 전용 모듈 보호
6. 인증 + 소유권 이중 검증 — Server Action 내부
7. `queryOptions` API — React Query v5 타입 안전 패턴
8. `lib/axios.ts` 인스턴스 — 인터셉터 포함

**참조**: `references/code-examples.md` (레벨별 대조 예제)

---

### 모드 B: 코드 리뷰 (레벨 진단)
사용자가 코드를 보여주며 리뷰를 요청하면:

1. **레벨 판별** — 루브릭 기준으로 주니어/미들/시니어 진단
2. **근거 제시** — 어떤 패턴이 해당 레벨을 나타내는지 설명
3. **개선 포인트** — 다음 레벨로 올리는 핵심 변경사항 제시

**출력 형식:**
```
## 코드 레벨 진단

**현재 레벨: 🔵 미들**

**근거:**
- ✅ async 서버 컴포넌트 사용 (M-01)
- ✅ Suspense + 스켈레톤 UI (M-11)
- ⚠️ use cache 미적용 — 매 요청마다 DB 조회
- ⚠️ 병렬 fetch 가능한 곳에 순차 await 사용

**시니어로 올리려면:**
1. `'use cache'` + `cacheTag()` 추가
2. `Promise.allSettled()`로 병렬 패칭
3. Server Action에 소유권 검증 추가
```

**참조**: `references/level-rubric.md` (판별 기준), `references/code-examples.md` (대조 예제)

---

## 기술 스택별 컨벤션

### 상태 관리
- 서버 상태 → React Query (`queryOptions` + `useSuspenseQuery`)
- 전역 UI 상태 → Zustand (devtools 미들웨어 포함)
- 폼 상태 → React Hook Form + Zod
- 로컬 상태 → useState

### HTTP 클라이언트
- `lib/axios.ts` 인스턴스 분리 필수
- 인터셉터로 토큰 자동 주입 + 에러 중앙 처리

**참조**: `references/axios-react-query.md`

---

## 참조 문서

| 파일 | 내용 |
|------|------|
| `references/level-rubric.md` | 주니어/미들/시니어 판별 루브릭 |
| `references/code-examples.md` | 레벨별 대조 코드 예제 4세트 |
| `references/axios-react-query.md` | Axios/React Query 레벨 패턴 |
| `../../rules/core/nextjs-app-router.md` | App Router 상세 규칙 |
| `../../rules/core/state-and-server-state.md` | 상태 관리 상세 규칙 |
