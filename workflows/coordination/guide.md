# Multi-Agent Coordination Guide

> 멀티 에이전트 병렬 실행으로 작업 효율 극대화

---

## 핵심 원칙

| 원칙           | 방법                                  | 효과               |
| -------------- | ------------------------------------- | ------------------ |
| **TEAM FIRST** | 복잡한 병렬 작업은 Agent Teams 우선   | 협업 + 수명주기    |
| **PARALLEL**   | 독립 작업은 단일 메시지에서 동시 호출 | 5-10배 속도 향상   |
| **BACKGROUND** | 긴 작업은 백그라운드로 실행           | 메인 컨텍스트 보호 |
| **DELEGATE**   | 전문 에이전트에 즉시 위임             | 품질 향상          |

```typescript
// ✅ 병렬 실행 — 단일 메시지에서 동시 호출
Task(subagent_type="explore", model="haiku", prompt="파일 구조 분석");
Task(subagent_type="explore", model="haiku", prompt="API 패턴 분석");
```

---

## Agent Teams vs Task 선택 기준

> Agent Teams는 Claude Code Max 플랜 전용. 미가용 시 Task 병렬 호출로 폴백.

| 조건                      | 실행 방식                     |
| ------------------------- | ----------------------------- |
| 3개+ 에이전트 병렬 협업   | **Agent Teams** (TeamCreate)  |
| 에이전트 간 통신 필요     | **Agent Teams** (SendMessage) |
| 2개 이하 독립 작업        | Task 병렬 호출 (팀 불필요)    |
| Agent Teams 미가용 (플랜) | Task 병렬 호출 (폴백)         |

---

## 에이전트 타입 선택 기준

구현이 필요한 서브에이전트는 **항상 `general-purpose`로 spawn**한다.
역할별 전문 지식은 **프롬프트에서 스킬/규칙 파일 읽기를 지시**하여 주입한다.

| 작업 유형          | 에이전트 타입       | 이유                       |
| ------------------ | ------------------- | -------------------------- |
| 읽기 전용 탐색     | `explore`           | 빠르고 가볍다              |
| 린트/타입 수정만   | `lint-fixer`        | 규칙 기반 단순 수정        |
| 구현이 필요한 작업 | **general-purpose** | Write/Edit/Bash 필요       |
| 스킬 지식 필요     | **general-purpose** | 스킬 파일 읽기 + 구현 동시 |

### 역할별 필수 참조 파일

| 역할      | 스킬 파일                          | 규칙 파일                                           |
| --------- | ---------------------------------- | --------------------------------------------------- |
| UI 구현   | -                                  | `.claude/rules/core/react-conventions.md`           |
| API 연동  | -                                  | `.claude/rules/core/state-and-server-state.md`      |
| 리팩토링  | `.claude/skills/refactor/SKILL.md` | `.claude/rules/core/unit-test-conventions.md`       |
| 버그 수정 | `.claude/skills/bug-fix/SKILL.md`  | -                                                   |

---

## 모델 선택 기준

| 복잡도     | 모델       | 사용 케이스                                               |
| ---------- | ---------- | --------------------------------------------------------- |
| **LOW**    | haiku      | 파일 탐색, 단순 검색, 린트 수정, 커밋/브랜치 관리        |
| **MEDIUM** | sonnet     | 코드 리뷰, 테스트 생성, 구현 (기본값)                    |
| **HIGH**   | opus       | 아키텍처 설계, 복잡한 버그, 리팩토링 분석                |

**비즈니스 로직이 포함되면 상향 조정:**

| 작업 성격                             | 최소 모델  |
| ------------------------------------- | ---------- |
| 날짜/금액/수량 계산, 상태 전이        | **opus**   |
| 조건부 렌더링, disabled/readonly 조건 | **sonnet** |
| 필터/정렬/검색 로직                   | **sonnet** |
| 아키텍처 변경, 모듈 간 의존성 재설계  | **opus**   |

> 불확실하면 **sonnet(MEDIUM)** — haiku 미달보다 sonnet 과잉이 안전하다.

---

## Agent Teams 워크플로우

```
1. TeamCreate({ team_name: 'sprint-team', description: '...' })
2. Task(subagent_type='general-purpose', team_name='sprint-team', name='ui-implementor', model='sonnet', prompt=`...`)
   Task(subagent_type='general-purpose', team_name='sprint-team', name='api-integrator', model='sonnet', prompt=`...`)
3. 팀원: 스킬/규칙 읽기 → 구현 → done-process.md 수행 → SendMessage 보고
4. 팀 리드: 결과 취합 → 충돌 해결 → 통합 린트/빌드 검증
5. release-gate 기준 PASS 확인
6. evaluation.md 기준 팀원 평가 → shutdown_request → TeamDelete
```

### 팀 리드 완료 체크리스트

```
□ 1. 각 팀원의 done-process.md done 프로세스 수행 확인
     - 미수행 시 SendMessage로 재요청 (shutdown 전에 반드시 완료)
□ 2. git log로 각 팀원 커밋 존재 확인
□ 3. {패키지매니저} lint/build 통합 검증
□ 4. release-gate 기준 최종 PASS 확인
□ 5. evaluation.md 기준 팀원 평가 작성 → 사용자 공유
□ 6. shutdown_request → TeamDelete
```

> shutdown/TeamDelete를 먼저 실행하면 팀원 컨텍스트가 소실되어 보완 불가.

---

## 에러 핸들링

실패 감지 시 **3회 루프를 먼저 실행하고, 소진 전까지 사람에게 보고하지 않는다.**

| 유형              | 판단 기준                    | 대응                      |
| ----------------- | ---------------------------- | ------------------------- |
| SCOPE_TOO_LARGE   | 컨텍스트 초과, 타임아웃      | 작업 분할 후 재시도       |
| ENV_ERROR         | 경로 오류, 파일 없음         | 경로/환경 재확인 후 재시도|
| LOGIC_ERROR       | 타입 에러, 빌드/테스트 실패  | 다른 접근법으로 재시도    |

- **2회차**: 모델 업그레이드 (`haiku→sonnet`, `sonnet→opus`) 후 재시도
- **3회차**: 루프 종료 → 사람에게 보고 (실패 유형, 시도 방법, 에러 메시지)
- **병렬 부분 실패**: 성공 결과만 활용 + 실패 작업 재시도. 전체 실패 시 순차 실행으로 전환.

---

## 참조 문서

| 문서               | 경로                                  |
| ------------------ | ------------------------------------- |
| 에이전트 목록      | `./roster.md`                         |
| 팀원 Done 프로세스 | `./done-process.md`                   |
| 팀 평가 템플릿     | `./evaluation.md`                     |
| 금지 패턴          | `../quality-gates/anti-patterns.md`   |
