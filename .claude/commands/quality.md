---
name: quality
description: 포맷 → 린트 → 타입 체크 순서로 실행하고 오류 자동 수정.
---

**참조 규칙**: `@../skills/code-quality/SKILL.md`

**[즉시 실행]** code-quality 스킬을 실행하여 포맷 → 린트 → 타입 체크를 순서대로 수행한다.

**옵션**: $ARGUMENTS

| 옵션            | 설명                            |
| --------------- | ------------------------------- |
| `--format-only` | 포맷(Prettier)만 실행           |
| `--lint-only`   | 린트(ESLint)만 실행             |
| `--type-only`   | 타입 체크만 실행                |
| `--no-fix`      | 자동 수정 없이 오류 목록만 출력 |
