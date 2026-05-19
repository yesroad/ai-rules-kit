# Emotion 스타일링 패턴

> @emotion/styled + @emotion/react 사용 시 참조. Q3=Emotion 감지 시 SKILL.md에서 이 파일을 로드한다.

---

## 셋업

**tsconfig.app.json:**
```json
{ "compilerOptions": { "jsxImportSource": "@emotion/react" } }
```

**vite.config.ts** (`@emotion/babel-plugin` — 빌드 최적화, 2025 권장):
```typescript
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [
    react({
      jsxImportSource: '@emotion/react',
      babel: { plugins: ['@emotion/babel-plugin'] },
    }),
  ],
})
```

**Next.js 사용 시:** Emotion 컴포넌트 파일 최상단에 `'use client'` 필수.
React Server Component는 런타임 CSS-in-JS를 지원하지 않는다.

---

## 파일 구조

```
components/{Name}/
├── index.tsx    # UI 로직 + prop → $prop 변환만
└── styled.ts    # 모든 styled 컴포넌트
```

styled 코드를 `index.tsx`에 인라인하지 않는다 — UI/스타일 책임 분리.

---

## 핵심 패턴

### 1. variant / size 딕셔너리 + CSSObject

```typescript
// components/{Name}/styled.ts
import styled from '@emotion/styled'
import type { CSSObject } from '@emotion/react'
import { colors, typography } from '@/styles/tokens'

type Variant = 'primary' | 'danger' | 'secondary'
type Size = 'sm' | 'md'

const variants: Record<Variant, CSSObject> = {
  primary:   { background: colors.primary, color: colors.white },
  danger:    { background: colors.dangerBg, color: colors.dangerText },
  secondary: { background: 'transparent', border: `1px solid ${colors.border}` },
}

const sizes: Record<Size, CSSObject> = {
  sm: { ...typography.body2, padding: '4px 12px', borderRadius: '6px' },
  md: { ...typography.body1, padding: '8px 16px', borderRadius: '8px' },
}

export const ButtonItem = styled.button<{ $variant: Variant; $size: Size }>`
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  transition: opacity 0.15s;
  ${({ $variant }) => variants[$variant]}
  ${({ $size }) => sizes[$size]}
  &:hover:not(:disabled) { opacity: 0.85; }
  &:disabled { opacity: 0.4; cursor: not-allowed; }
`
```

### 2. Transient Props — `$-prefix` 필수

```typescript
// components/{Name}/index.tsx
import { ButtonItem } from './styled'

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: Size
}

export function Button({ variant = 'primary', size = 'md', ...rest }: ButtonProps) {
  return <ButtonItem $variant={variant} $size={size} {...rest} />
}
```

`$-prefix` 없이 `variant`를 그대로 전달하면 DOM attribute 경고 발생.

### 3. Object Style (타입 안전, 권장)

```typescript
import { css } from '@emotion/react'

// csstype 기반 타입 추론 — 오타 시 TS 오류
const cardStyle = css({
  padding: '20px',
  borderRadius: '12px',
  boxShadow: '0 1px 4px rgba(0, 0, 0, 0.06)',
  '&:hover': { opacity: 0.9 },
})
```

Template literal도 유효하지만 object style이 TypeScript 자동완성과 타입 검사가 더 정확하다.

### 4. Badge — 단순 색상 variant 예시

```typescript
// components/Badge/styled.ts
import styled from '@emotion/styled'
import type { CSSObject } from '@emotion/react'
import { colors, typography } from '@/styles/tokens'

type BadgeVariant = 'default' | 'primary' | 'warning' | 'danger' | 'done'

const variants: Record<BadgeVariant, CSSObject> = {
  default:  { background: colors.background, color: colors.textPrimary, border: `1px solid ${colors.border}` },
  primary:  { background: colors.primaryLight, color: colors.primary },
  warning:  { background: '#FEF3C7', color: colors.warningStrong },
  danger:   { background: colors.dangerBg, color: colors.dangerText },
  done:     { background: '#F0FDF4', color: '#16A34A' },
}

export const BadgeItem = styled.span<{ $variant: BadgeVariant }>`
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 9999px;
  ${typography.caption}
  font-weight: 500;
  ${({ $variant }) => variants[$variant]}
`
```

### 5. GlobalStyles

```typescript
// styles/GlobalStyles.ts
import { Global, css } from '@emotion/react'
import { colors } from '@/styles/tokens'

export function GlobalStyles() {
  return (
    <Global styles={css`
      *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        font-family: 'Noto Sans KR', sans-serif;
        background: ${colors.background};
        color: ${colors.textPrimary};
        -webkit-font-smoothing: antialiased;
      }
      button { cursor: pointer; border: none; background: none; font: inherit; }
      a { text-decoration: none; color: inherit; }
      img { display: block; max-width: 100%; }
      input, textarea, select { font: inherit; }
    `} />
  )
}
```

---

## 디자인 토큰 구조

```
styles/tokens/
├── color.ts
│     export const colors = {
│       primary: '#1B65E3',
│       primaryLight: '#EBF1FD',
│       white: '#ffffff',
│       background: '#F9FAFB',
│       textPrimary: '#111827',
│       gray: '#9CA3AF',
│       border: '#E5E7EB',
│       dangerBg: '#FEEAEA',
│       dangerBorder: '#FEB2B2',
│       dangerText: '#C53030',
│       warningStrong: '#F59E0B',
│       warningDeep: '#F97316',
│     }
├── typography.ts
│     export const typography = {
│       display1: { fontSize: '24px', fontWeight: 700 },
│       body1:    { fontSize: '14px', fontWeight: 400 },
│       body2:    { fontSize: '13px', fontWeight: 400 },
│       caption:  { fontSize: '12px', fontWeight: 400 },
│     }
└── index.ts
      export * from './color'
      export * from './typography'
```

모든 컴포넌트에서 `import { colors, typography } from '@/styles/tokens'` — 값 하드코딩 금지.

> **ThemeProvider**: 단일 테마라면 직접 import가 심플하다.
> 다크모드·멀티 테마가 필요하면 `ThemeProvider` + `useTheme()` 도입 검토.

---

## 네이밍 규칙

| 항목 | 규칙 | 예 |
|---|---|---|
| styled 컴포넌트 | PascalCase + 역할명 | `ButtonItem`, `BadgeItem`, `Block`, `Container` |
| transient prop | `$-prefix` | `$variant`, `$size`, `$done`, `$isActive` |
| 토큰 import | `@/styles/tokens` | `import { colors } from '@/styles/tokens'` |

---

## 새 Emotion 컴포넌트 체크리스트

- [ ] `components/{Name}/styled.ts` — variant/size 딕셔너리 + CSSObject + transient props
- [ ] `components/{Name}/index.tsx` — prop → `$prop` 변환 후 styled 컴포넌트에 전달
- [ ] 토큰 import 경로: `@/styles/tokens`
- [ ] Next.js: 파일 상단 `'use client'` 선언 여부 확인

---

## 금지 패턴

| 금지 | 이유 | 대안 |
|---|---|---|
| `$-prefix` 없는 transient prop | DOM attribute 경고 발생 | `$variant`, `$size` |
| styled 코드를 `index.tsx`에 인라인 | UI/스타일 책임 혼재 | 별도 `styled.ts` |
| 색상·여백·폰트 하드코딩 | 토큰 일관성 파괴 | `colors.primary`, `typography.body1` |
| RSC에서 Emotion 직접 사용 | 런타임 CSS-in-JS 서버 미지원 | 파일 상단 `'use client'` |
| template literal에서 복잡한 삼항 조건 | 가독성·타입 추론 저하 | `Record<Variant, CSSObject>` 딕셔너리 |
