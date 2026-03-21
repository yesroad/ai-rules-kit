# Claude Kit

<instructions>
@.claude/rules/core/thinking-model.md
@.claude/instructions/validation/required-behaviors.md
@.claude/instructions/validation/forbidden-patterns.md
</instructions>

<quick_ref>
| 상황 | 참조 |
|------|------|
| 작업 시작 | /start |
| 작업 완료+PR | /done |
| 커밋 | /commit |
| 에이전트 선택 | @.claude/instructions/multi-agent/agent-roster.md |
| 복잡도 판단 | @.claude/instructions/workflow-patterns/sequential-thinking.md |
</quick_ref>

<tech_stack>
Claude Kit은 .claude/ 보일러플레이트 시스템 (코드 없음).
주요 의존성: terminal-notifier, gh CLI
</tech_stack>
