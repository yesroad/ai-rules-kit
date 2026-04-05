# Claude Kit

<tech_stack>
cc-kit은 Claude Code용 AI 코딩 하네스 플러그인입니다.
에이전트 = 모델 + 하네스 (오케스트레이션 + 스캐폴딩 + 가드레일 + 피드백 루프 + 메모리)
주요 의존성: terminal-notifier, gh CLI
</tech_stack>

<dev_rules>

## 스킬/커맨드 변경 시 문서 동기화 필수

스킬을 추가·수정·삭제할 때:

1. `Grep "스킬명"` → 모든 참조 위치 파악
2. 아래 4개 문서에서 해당 스킬 항목 업데이트:

| 문서                                       | 업데이트 내용                   |
| ------------------------------------------ | ------------------------------- |
| `commands/setup.md`                        | 스킬 결정표, quick_ref 예시     |
| `instructions/multi-agent/agent-roster.md` | 스킬 카탈로그, 연결 흐름        |
| `README.md`                                | 스킬 목록 테이블, 디렉토리 구조 |
| `FILE-MAP.md`                              | Skills 섹션, 흐름 다이어그램    |

```
# 예: test-unit 스킬 추가 시
commands/setup.md                              ← 결정표 + quick_ref 예시에 추가
instructions/multi-agent/agent-roster.md       ← 스킬 카탈로그 테이블에 추가
README.md                                      ← 스킬 목록 + 디렉토리 구조에 추가
FILE-MAP.md                                    ← Skills 섹션 + 흐름 다이어그램에 추가
```

</dev_rules>
