---
name: start
description: 작업 시작. Plan Mode 진입 → 코드 분석 → 작업 계획 생성.
---

**참조 규칙**:

- `@../workflows/thinking/model.md` (복잡도 판단)
- `@../workflows/coordination/roster.md` (에이전트 선택)

**[즉시 실행]** 이 메시지를 받으면 아래 단계를 바로 실행하세요.
이 커맨드는 **계획만 수행**합니다. 구현은 `/work`에서 진행합니다.

**작업 내용**: $ARGUMENTS

---

## Step 0. Plan Mode 진입

`EnterPlanMode`를 호출하여 Plan Mode로 전환한다.

> Plan Mode에서는 read-only 제약이 적용되어 실수로 코드를 수정하는 것을 방지한다.
> 유일하게 허용되는 Write는 plan 파일뿐이다.

---

## 진행 상황 추적

실행 시작 시 아래 항목을 TaskCreate로 등록한다. 각 Step 시작 시 `in_progress`, 완료 시 `completed`로 TaskUpdate한다.

- 입력 유형 판별
- 작업 내용 파악
- 디자인 분석
- 코드 분석
- 작업 계획 출력
- 복잡도 판단

---

## /start에서 메모리 조회 (Basic Memory MCP 설치 시)

작업 분석 전 `recent_activity` 또는 `search`로 이 프로젝트 관련 메모리를 조회한다.

- 결과 있으면 → 작업 계획에 반영 (이전 오류, 특이사항, 해결책 참고)
- 결과 없으면 → 스킵

---

## Step 1. 입력 유형 판별

`$ARGUMENTS`가 있는 경우, 아래 규칙으로 유형을 자동 판별한다:

| 패턴                 | 판별                | 예시                         |
| -------------------- | ------------------- | ---------------------------- |
| `[A-Z]+-[0-9]+` 형식 | Jira 티켓           | `ABC-123`, `PROJ-456`        |
| `.md` 확장자 포함    | MD 파일             | `task-spec.md`, `feature.md` |
| 그 외                | **사용자에게 확인** | `my-feature`, `user-profile` |

**애매한 경우 사용자에게 질문:**

> "'$ARGUMENTS'는 Jira 티켓인가요, MD 파일인가요?"

판별 후 진행:

- **Jira ��켓** → Atlassian MCP `get_issue` 도구로 내용 조회 (MCP 미설치 시 URL 안내)
- **MD 파일** → 해당 파일을 읽어 작업 내용 파악

---

## Step 2. 작업 내용 파악

1단계 판별 결과에 따라 작업 내용을 확인한다:

→ 제목, 설명, 디자인 링크 추출
→ 작업 범위 파악

---

## Step 3. 작업 환경 준비

작업 대상 경로와 관련 파일을 파악한다.

---

## Step 4. 디자인 분석 (필요 시)

디자인 파일(Figma, Image 등)이 있는 경우 분석한다:

- 컴포넌트 상태별 UI (기본/hover/active/disabled/선택)
- 레이아웃 구조 (flex-direction, gap, wrap)
- 아이콘/이미지 유무 및 위치
- 반응형 동작 여부

---

## Step 5. 코드 분석

**대규모 분석 시 explore 에이전트 병렬 호출:**

```typescript
Task(
  (subagent_type = "explore"),
  (model = "haiku"),
  (prompt = "변경 대상 컴포넌트/훅 구조 분석"),
);
Task(
  (subagent_type = "explore"),
  (model = "haiku"),
  (prompt = "기존 디자인 시스템 패턴 분석"),
);
Task(
  (subagent_type = "explore"),
  (model = "haiku"),
  (prompt = "관련 API/서비스 파악"),
);
```

작업 내용을 기반으로 변경할 파일/경로를 파악한다.

---

## Step 6. 작업 계획 작성

아래 형식으로 **plan 파일에 Write**한다:

```markdown
## 작업: $ARGUMENTS - {제목}

### 디자인

{디자인 URL (있는 경우)}

### 작업 내용

1. {작업 항목}
2. {추가 작업}

### 변경 파일

- {파일 목록}

### 검증 방법

- {테스트 전략}

### 완료 조건

- [ ] {작업 항목 1} 구현
- [ ] {작업 항목 2} 구현
- [ ] `{패키지매니저} tsc --noEmit` PASS
- [ ] `{패키지매니저} lint` PASS
- [ ] 정책 변경 포함 시: 관련 테스트 PASS
```

---

## Step 7. 복잡도 판단

> **복잡도 판단**: `@../workflows/thinking/model.md` 참조 (LOW/MEDIUM/HIGH 기준)

복잡도 결과를 plan 파일 상단에 기록한다.

**HIGH 복잡도 시 Plan 에이전트 활용:**

```typescript
Task(
  (subagent_type = "Plan"),
  (model = "opus"),
  (prompt = `
  작업: $ARGUMENTS
  요구사항: {요약된 요구사항}
  디자인 분석: {분석 결과}
  기존 패턴: {확인된 패턴}

  구현 계획 수립 요청
`),
);
```

---

## Step 8. ExitPlanMode 호출 및 안내

`ExitPlanMode`를 호출하여 사용자에게 계획을 제시한다.

사용자가 계획을 승인하면 아래 안내를 출력한다:

> 계획이 `.claude/plans/`에 저장되었습니다. `/work`로 구현을 시작하세요.

---

## [참고] 서브태스크 분리 기준

| 작업 유형      | 분리 | 예시                |
| -------------- | ---- | ------------------- |
| 새 컴포���트    | O    | 신규 UI 컴포넌트    |
| API 연동       | O    | 목록/상세 조회 연동 |
| 상태 관리 추가 | O    | 전역 상태 추가      |
| 로직 변경      | O    | 계산/변환 함수 수정 |
| 스타일 수정    | X    | 색상, 간격 수정     |
| 텍스트 변경    | X    | 라벨, 메시지 수정   |

**분리 체크리스트**:

- 새로 만드는 컴포넌트 → 각각 작업
- API 연동 → 별도 작업
- 상태 관리 변경 → 별도 작업
- 로직 변경 → 별도 작업
- 200줄 이상 변경 → 분리
