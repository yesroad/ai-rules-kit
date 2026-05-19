# Emotion 스타일링 규칙

> @emotion/styled + @emotion/react 사용 시 적용. 설정(Q3=Emotion)에 따라 CLAUDE.md에 자동 주입됨.

---

## 파일 구조 원칙

```
components/{Name}/
├── index.tsx    # UI 로직 + prop → $prop 변환만
└── styled.ts    # 모든 styled 컴포넌트 (index.tsx에 인라인 금지)
```

---

## 셋업

**tsconfig.app.json:**
```json
{ "compilerOptions": { "jsxImportSource": "@emotion/react" } }
```

**vite.config.ts** (`@emotion/babel-plugin` — 빌드 최적화, 2025 권장):
```typescript
react({
  jsxImportSource: '@emotion/react',
  babel: { plugins: ['@emotion/babel-plugin'] },
})
```

**Next.js 사용 시:** Emotion 컴포넌트 파일 최상단에 `'use client'` 필수.
React Server Component에서는 Emotion 사용 불가 (런타임 CSS-in-JS).

---

## 핵심 패턴

### variant / size 딕셔너리 + CSSObject

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
  sm: { ...typography.body2, padding: '4px 12px' },
  md: { ...typography.body1, padding: '8px 16px' },
}

export const ButtonItem = styled.button<{ $variant: Variant; $size: Size }>`
  border-radius: 8px;
  cursor: pointer;
  ${({ $variant }) => variants[$variant]}
  ${({ $size }) => sizes[$size]}
  &:disabled { opacity: 0.4; cursor: not-allowed; }
`
```

### Transient Props — `$-prefix` 필수

```typescript
// components/{Name}/index.tsx
interface ButtonProps {
  variant?: Variant
  size?: Size
  children?: React.ReactNode
}

export function Button({ variant = 'primary', size = 'md', ...rest }: ButtonProps) {
  return <ButtonItem $variant={variant} $size={size} {...rest} />
}
```

`$-prefix` 없이 `variant`를 그대로 전달하면 DOM attribute 경고 발생.

### Object Style (타입 안전, 권장)

```typescript
// csstype 기반 타입 추론 — 오타 시 TS 오류
const cardStyle = css({
  borderRadius: '12px',
  boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
  '&:hover': { opacity: 0.9 },
})
```

### GlobalStyles

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
        -webkit-font-smoothing: antialiased;
      }
      button { cursor: pointer; border: none; background: none; }
      a { text-decoration: none; color: inherit; }
      img { display: block; max-width: 100%; }
    `} />
  )
}
```

---

## 디자인 토큰 구조

```
styles/tokens/
├── color.ts        # export const colors = { primary, white, border, background, dangerBg, dangerText, ... }
├── typography.ts   # export const typography = { display1, body1, body2, caption }
└── index.ts        # export * from './color'; export * from './typography'
```

모든 컴포넌트에서 `import { colors, typography } from '@/styles/tokens'` 사용. 값 하드코딩 금지.

> **ThemeProvider**: 단순 토큰 파일 구조로 충분하면 직접 import 사용.
> 다크모드·멀티 테마가 필요한 경우 `ThemeProvider` + `useTheme()` 도입 검토.

---

## 네이밍 규칙

| 항목 | 규칙 | 예 |
|---|---|---|
| styled 컴포넌트 | PascalCase + 역할명 | `ButtonItem`, `BadgeItem`, `Block`, `Container` |
| transient prop | `$-prefix` | `$variant`, `$size`, `$done`, `$isActive` |
| 토큰 import 경로 | `@/styles/tokens` | `import { colors } from '@/styles/tokens'` |

---

## 금지 패턴

| 금지 | 이유 | 대안 |
|---|---|---|
| `$-prefix` 없는 transient prop | DOM attribute 경고 발생 | `$variant`, `$size` |
| styled 코드를 `index.tsx`에 인라인 | UI/스타일 책임 혼재 | 별도 `styled.ts` 파일 |
| 색상·여백·폰트 하드코딩 | 토큰 일관성 파괴 | `colors.primary`, `typography.body1` |
| RSC에서 Emotion 직접 사용 | 런타임 CSS-in-JS 서버 미지원 | 파일 상단 `'use client'` 선언 |
| template literal에서 복잡한 로직 | 타입 추론 미작동 | `variants: Record<Variant, CSSObject>` 딕셔너리 |
