---
name: test
description: 단위 → 통합 → E2E 테스트를 순서대로 실행. "테스트 전체 실행", "전체 테스트", "/test" 입력 시 사용.
---

# /test - 전체 테스트 순차 실행

단위 → 통합 → E2E 순서로 테스트를 실행합니다. 각 단계 실패 시 원인 분류 후 재시도합니다.

**참조 스킬**:
- `@../skills/test-unit/SKILL.md`
- `@../skills/test-integration/SKILL.md`
- `@../skills/test-e2e/SKILL.md`

## 사용법

/test
/test --unit-only
/test --skip-e2e

## 진행 상황 추적

실행 시작 시 아래 항목을 TaskCreate로 등록한다. 각 Step 시작 시 `in_progress`, 완료 시 `completed`로 TaskUpdate한다.

- 단위 테스트
- 통합 테스트
- E2E 테스트

## 실행 흐름

### Step 1: 단위 테스트 (test-unit)

`test-unit` 스킬을 실행합니다.

통과 기준: 90% (statements + branches)
실패 루프: 최대 2회 (정책 재검토 → 재생성)
최종 실패 시: 중단 후 Step 2 진행하지 않음

### Step 2: 통합 테스트 (test-integration)

`--unit-only` 옵션이 없을 때만 실행합니다.

`test-integration` 스킬을 실행합니다.

통과 기준: 모든 테스트 pass
실패 루프: 최대 3회 (정책 재검토 → 재생성)
최종 실패 시: 중단 후 Step 3 진행하지 않음

### Step 3: E2E 테스트 (test-e2e)

`--unit-only` 또는 `--skip-e2e` 옵션이 없을 때만 실행합니다.

`test-e2e` 스킬을 실행합니다.

통과 기준: 핵심 플로우 100% pass
실패 루프: 최대 2회 (정책 재검토 → 재생성)
최종 실패 시: 스크린샷/트레이스 경로 출력 + 사람 인계

## 최종 결과 출력

모든 단계 완료 후 아래 포맷으로 출력합니다:

| 단계 | 결과 | 상태 |
|------|------|------|
| Unit | ✅ PASS / ❌ FAIL | 커버리지 {N}% |
| Integration | ✅ PASS / ❌ FAIL / ⏭️ SKIP | 전체 통과 / 실패 {N}건 |
| E2E | ✅ PASS / ❌ FAIL / ⏭️ SKIP | 핵심 플로우 {N}/{N} |

## 옵션

| 옵션 | 설명 |
|------|------|
| `--unit-only` | 단위 테스트만 실행 |
| `--skip-e2e` | 단위 + 통합만 실행 |
