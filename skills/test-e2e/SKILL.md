---
name: test-e2e
description: Playwright 기반 E2E(End-to-End) 테스트 생성. "e2e 테스트", "playwright", "end-to-end", "사용자 시나리오 테스트", "브라우저 테스트", "전체 흐름 테스트" 언급 시 반드시 이 스킬을 활성화. async Server Component, 미들웨어, 인증 플로우 등 단위/통합 테스트로 커버 불가한 영역 담당.
user-invocable: true
allowed-tools: Read, Grep, Glob, Write, Bash
metadata:
  version: "1.0.0"
  category: testing
  priority: medium
---

## E2E 테스트가 필요한 경우

단위/통합 테스트로 커버 불가한 영역:

| 항목 | 이유 |
|------|------|
| async Server Component | Vitest/Jest 단위 테스트 불가 |
| Middleware | Edge Runtime 의존 |
| 라우팅/네비게이션 | 실제 페이지 전환 필요 |
| 인증 플로우 전체 | 쿠키/세션/리다이렉트 통합 검증 |
| SEO/메타 태그 | 렌더링 결과 검증 필요 |

---

## 진행 상황 출력

각 Phase 시작 시 반드시 출력한다:

```
[🔍 분석 중...] 핵심 사용자 플로우 파악
[📋 시나리오 도출 중...] 사용자 여정 → spec 변환
[⚙️ 테스트 생성 중...] e2e/*.spec.ts 작성
[▶️ 테스트 실행 중...] Playwright 브라우저 실행
[✅ 완료] 또는 [❌ 실패 - 원인 분류 중...]
[🔄 재시도 N/2] 정책 재검토 후 재생성 중...
```

---

## Phase 0: 환경 감지 + ARGUMENTS 확인

**Playwright/Cypress 감지**:

```bash
# playwright.config.ts 존재 확인
# package.json에서 @playwright/test 또는 cypress 확인
```

- `@playwright/test` → Playwright (이하 본 스킬은 Playwright 기준)
- `cypress` → "현재 프로젝트는 Cypress를 사용합니다. Playwright 마이그레이션을 권장하지만, 기존 패턴에 맞춰 생성합니다." 안내
- 둘 다 없음 → Playwright 설치 안내 출력:
  ```
  pnpm create playwright
  ```

**playwright.config.ts 없으면** 기본 설정 생성 제안:

```typescript
// playwright.config.ts 기본 설정 (제안)
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html', { outputFolder: 'playwright-report' }], ['list']],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
})
```

**$ARGUMENTS 없으면**: "어떤 사용자 플로우의 E2E 테스트를 작성할까요? (예: 로그인, 상품 구매, 회원가입)" 질문

---

## Phase 1: 핵심 사용자 플로우 파악 [🔍 분석 중...]

분석 대상:

- 페이지 구조 (`app/` 디렉토리)
- 핵심 사용자 여정 파악 (로그인 필요 여부, 권한 분기 등)
- 기존 E2E 테스트 패턴 (`e2e/` 폴더 있으면 참고)
- 인증 방식 파악 (세션 쿠키, JWT, OAuth 등)

---

## Phase 2: 시나리오 도출 [📋 시나리오 도출 중...]

시나리오 유형:

- **핵심 플로우**: 사용자가 가장 자주 하는 핵심 경로
- **인증 플로우**: 로그인/로그아웃/권한 분기
- **Error 플로우**: API 실패, 잘못된 입력
- **async Server Component**: 서버 렌더링 결과 검증

시나리오 계획 출력 후 사용자 확인.

---

## Phase 3: 테스트 파일 생성 [⚙️ 테스트 생성 중...]

**파일 구조**:

```
e2e/
├── auth.setup.ts           ← 인증 셋업 (있는 경우)
├── pages/
│   ├── login.spec.ts
│   ├── dashboard.spec.ts
│   └── checkout.spec.ts
└── fixtures/
    └── index.ts            ← 커스텀 fixture (POM)
```

**Locator 우선순위** (Testing Library와 동일):

1. `getByRole('button', { name: '로그인' })` — 접근성 role
2. `getByLabel('이메일')` — label 텍스트
3. `getByPlaceholder(...)` — placeholder
4. `getByText(...)` — 텍스트 내용
5. `getByAltText(...)` — alt 텍스트
6. `getByTestId(...)` — 최후 수단 (data-testid)

CSS 선택자는 DOM 구조에 취약하므로 지양.

**기본 spec 패턴**:

```typescript
// e2e/pages/login.spec.ts
import { test, expect } from '@playwright/test'

test.describe('로그인', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
  })

  test('올바른 정보로 로그인하면 대시보드로 이동한다', async ({ page }) => {
    // Given: 로그인 페이지
    // When
    await page.getByLabel('이메일').fill('user@example.com')
    await page.getByLabel('비밀번호').fill('password123')
    await page.getByRole('button', { name: '로그인' }).click()

    // Then
    await expect(page).toHaveURL('/dashboard')
  })

  test('잘못된 비밀번호로 로그인하면 에러를 표시한다', async ({ page }) => {
    await page.getByLabel('이메일').fill('user@example.com')
    await page.getByLabel('비밀번호').fill('wrong')
    await page.getByRole('button', { name: '로그인' }).click()

    await expect(page.getByRole('alert')).toContainText('이메일 또는 비밀번호가 올바르지 않습니다')
  })
})
```

**인증 셋업 패턴** (인증이 필요한 경우):

```typescript
// e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test'
import path from 'path'

const authFile = path.join(__dirname, '../playwright/.auth/user.json')

setup('일반 사용자 인증', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('이메일').fill(process.env.TEST_USER_EMAIL!)
  await page.getByLabel('비밀번호').fill(process.env.TEST_USER_PASSWORD!)
  await page.getByRole('button', { name: '로그인' }).click()
  await page.waitForURL('/dashboard')
  await page.context().storageState({ path: authFile })
})
```

**Page Object Model (POM)** — 테스트가 3개 이상이고 같은 페이지를 반복 사용할 때:

```typescript
// e2e/pages/LoginPage.ts
import { type Page, type Locator, expect } from '@playwright/test'

export class LoginPage {
  readonly page: Page
  readonly emailInput: Locator
  readonly passwordInput: Locator
  readonly submitButton: Locator

  constructor(page: Page) {
    this.page = page
    this.emailInput = page.getByLabel('이메일')
    this.passwordInput = page.getByLabel('비밀번호')
    this.submitButton = page.getByRole('button', { name: '로그인' })
  }

  async goto() { await this.page.goto('/login') }
  async login(email: string, password: string) {
    await this.emailInput.fill(email)
    await this.passwordInput.fill(password)
    await this.submitButton.click()
  }
}
```

**네트워크 모킹** (외부 API나 오류 케이스):

```typescript
// 외부 결제 API 오류 시뮬레이션
await page.route('**/api/payment/charge', async route => {
  await route.fulfill({ status: 503, json: { error: '결제 서버 오류' } })
})
```

**async Server Component 검증**:

```typescript
test('서버에서 렌더링된 사용자 목록이 표시된다', async ({ page }) => {
  await page.goto('/users')
  await expect(page.getByRole('heading', { name: '사용자 목록' })).toBeVisible()
  await expect(page.getByRole('article')).not.toHaveCount(0)
})
```

---

## Phase 4: 테스트 실행 [▶️ 테스트 실행 중...]

```bash
# 전체 실행
pnpm exec playwright test

# 특정 파일
pnpm exec playwright test e2e/pages/login.spec.ts

# UI 모드 (로컬 디버깅)
pnpm exec playwright test --ui

# 트레이스 보기
pnpm exec playwright show-trace test-results/trace.zip
```

**통과 기준**: 핵심 플로우 100% pass (Playwright 내장 `retries: 2` 활용)

**실패 처리 루프 (최대 2회)**:

```
[❌ 실패 - 원인 분류 중...]

원인 분류:
├─ 테스트 시나리오 설계 문제 (잘못된 Locator, 정책 오해, 타이밍 이슈)
│     → [🔄 재시도 N/2] 정책 재검토 → 시나리오 재도출 → 재생성
│
├─ 코드/UI 버그 (실제 구현 오류)
│     → 루프 중단:
│       "⚠️ 버그 발견: {내용}"
│       스크린샷: test-results/{파일명}/screenshot.png
│       트레이스: test-results/{파일명}/trace.zip
│       (pnpm exec playwright show-trace 로 확인)
│
└─ 환경 문제 (서버 미기동, 인증 만료, baseURL 설정 오류)
      → 루프 중단:
        체크리스트:
        - [ ] Next.js 서버가 실행 중인가요? (pnpm dev)
        - [ ] playwright.config.ts의 baseURL이 올바른가요?
        - [ ] .env에 TEST_USER_EMAIL, TEST_USER_PASSWORD가 설정됐나요?
        - [ ] playwright/.auth/ 폴더가 .gitignore에 있나요?
```

> E2E는 실행 비용이 크므로 루프 상한을 2회로 제한합니다.

---

## Phase 5: 완료 요약 출력

```markdown
## E2E 테스트 생성 완료

### 생성된 파일
- {파일 경로}

### 테스트 시나리오
| 플로우 | 시나리오 수 | 결과 |
|--------|:----------:|------|
| {플로우명} | {N} | ✅ 전체 통과 |

### 핵심 플로우 커버리지
- [x] {핵심 플로우 1}
- [x] {핵심 플로우 2}

### 리포트
pnpm exec playwright show-report
```

---

## .gitignore 추가 권고

```
playwright/.auth/
playwright-report/
test-results/
```

---

## 금지 패턴

| 금지 | 이유 |
|------|------|
| CSS 선택자 직접 사용 | DOM 구조 변경에 취약 |
| `page.waitForTimeout(ms)` | 임의 대기 → 불안정한 테스트 |
| 매 테스트마다 UI 로그인 | storageState 재사용으로 성능 확보 |
| 하드코딩된 테스트 계정 | 환경변수로 관리 |
