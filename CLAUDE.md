# Claude Kit

<tech_stack>
cc-kit은 Claude Code용 AI 코딩 하네스 플러그인입니다.
에이전트 = 모델 + 하네스 (오케스트레이션 + 스캐폴딩 + 가드레일 + 피드백 루프 + 메모리)
주요 의존성: terminal-notifier, gh CLI
</tech_stack>

<dev_rules>

## 구조 변경 시 문서 동기화 필수

스킬·커맨드·에이전트·워크플로·룰을 추가·수정·삭제할 때:

1. `Grep "변경 대상명"` → 모든 참조 위치 파악
2. 아래 문서에서 해당 항목 업데이트:

| 문서                                 | 업데이트 내용                        |
| ------------------------------------ | ------------------------------------ |
| `commands/setup.md`                  | 결정표, quick_ref 예시               |
| `workflows/coordination/roster.md`   | 에이전트/스킬 카탈로그, 연결 흐름    |
| `README.md`                          | 목록 테이블, 디렉토리 구조           |
| `FILE-MAP.md`                        | 섹션별 항목, 흐름 다이어그램         |
| `scripts/verify-install.sh`          | 파일 수·이름 배열                    |
| `CHANGELOG.md`                       | 버전·변경 이력 추가                  |

</dev_rules>
