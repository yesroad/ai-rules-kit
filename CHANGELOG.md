# Changelog

이 프로젝트는 [Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다.

---

## [1.1.0] - 2026-04-05

### Added

- **`/work` 커맨드 신규**: 계획 기반 구현 + 계획 대비 검증 + FAIL 시 재작업 루프
- **`plansDirectory` 설정**: `/setup` 시 settings.json에 추가, Plan Mode 계획 파일을 프로젝트 로컬(`.claude/plans/`)에 저장

### Changed

- **`/start` 커맨드**: Plan Mode 자동 진입(`EnterPlanMode`), 계획만 수행하고 구현은 `/work`로 분리
- **워크플로우**: `/start` → `/work` → `/done` 3단계 사이클로 변경
- **Commands 수**: 7개 → 8개

---

## [1.0.0] - 2026-04-05

### 포함 항목

- **Agents** (5개): explorer, code-reviewer, nextjs-reviewer, lint-fixer, git-operator
- **Skills** (15개): bug-fix, code-quality, commit-helper, component-creator, directive-generator, docs-creator, migration-helper, nextjs-scaffold, code-level-review, pr-responder, refactor, test-unit, test-integration, test-e2e, web-design
- **Commands** (7개): /setup, /start, /done, /commit, /test, /setup-notifier, /update-cc-kit
- **Rules**: core 8개 + optional 2개 + references 8개
- **Workflows**: coordination(4), quality-gates(3), thinking(1), git(1)
- **Hooks**: guard-check.sh (8패턴), notify.sh, hooks.json
- **Scripts**: verify-install.sh

### 주요 설계

- CLAUDE.md 25줄 유지 (하네스 원칙 준수)
- `/done` 파이프라인: quality → test(확인) → review → Safety Gate → commit → PR
- TaskCreate 진행 상황 추적: 커맨드 6개 + 독립 스킬 6개
- guard-check.sh 8패턴: any, @ts-ignore, 자격증명, useState+fetch, console.log, eslint-disable, as any, useEffect([])
- 에이전트 모델 분리: haiku(탐색·git·lint) / sonnet(리뷰) / opus(Plan)
- 스킬 트리거 기반 on-demand 컨텍스트 로딩
