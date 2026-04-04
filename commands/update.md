---
name: update
description: cc-kit 플러그인 파일을 최신 버전으로 업데이트합니다. CLAUDE.md와 커스텀 파일은 건드리지 않습니다.
---

cc-kit 플러그인 파일을 최신 버전으로 업데이트합니다.

## 업데이트 대상

| 업데이트됨 | 건드리지 않음 |
|-----------|-------------|
| `rules/core/` | `CLAUDE.md` |
| `rules/optional/` | `rules/custom/` (프로젝트 전용 rules) |
| `agents/` | `.mcp.json` |
| `skills/` | `settings.json`, `settings.local.json` |
| `commands/` | 플러그인 소스에 없는 모든 파일 |
| `instructions/` | |
| `hooks/` | |
| `scripts/` | |

---

## 1단계: 플러그인 소스 위치 확인

```bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT" ]; then
  PLUGIN_ROOT="$HOME/.claude/plugins/cache/cc-kit"
fi

if [ ! -d "$PLUGIN_ROOT" ]; then
  echo "GitHub에서 cc-kit 최신 버전을 가져옵니다..."
  git clone --depth 1 https://github.com/yesroad/cc-kit.git /tmp/cc-kit_update
  PLUGIN_ROOT="/tmp/cc-kit_update"
fi

echo "📦 플러그인 소스: $PLUGIN_ROOT"
```

---

## 2단계: 파일별 비교 및 업데이트

아래 디렉토리에 대해 파일 하나씩 비교한다:

```bash
UPDATE_DIRS="rules instructions agents skills commands hooks scripts"
```

각 파일에 대해:

### 케이스 A — 새 파일 (설치본에 없음)
플러그인에 새로 추가된 파일 → **자동으로 복사**, 사용자에게 보고

```
✅ 새로 추가: rules/optional/tailwindcss-v4.md
```

### 케이스 B — 동일 (변경 없음)
플러그인 파일과 설치본이 동일 → **건너뜀**, 보고 생략

### 케이스 C — 변경 감지 (플러그인이 업데이트됨)
플러그인 파일과 설치본이 다름 → **diff를 보여주고 사용자에게 질문**:

```
⚠️  변경 감지: rules/core/nextjs-app-router.md

--- 설치본 (현재)
+++ 플러그인 (최신)
@@ ... @@
- 기존 내용
+ 새로운 내용

이 파일을 업데이트할까요?
  y — 플러그인 최신 버전으로 교체
  n — 현재 설치본 유지
```

사용자가 `y` → 복사 후 `✅ 업데이트: {파일경로}` 출력  
사용자가 `n` → 건너뜀 후 `⏭️  유지: {파일경로}` 출력

### 케이스 D — 플러그인에서 제거된 파일
플러그인 소스에는 없고 설치본에만 있는 파일 → **건드리지 않음**  
(프로젝트 커스텀 파일일 수 있으므로 자동 삭제 금지)

---

## 3단계: hooks 실행 권한 갱신

```bash
[ -f ".claude/hooks/notify.sh" ] && chmod +x .claude/hooks/notify.sh
```

---

## 4단계: 임시 파일 정리

```bash
[ "$PLUGIN_ROOT" = "/tmp/cc-kit_update" ] && rm -rf /tmp/cc-kit_update
```

---

## 5단계: 업데이트 결과 보고

```
✅ cc-kit 업데이트 완료

📋 결과 요약:
  추가됨  : N개
  업데이트: N개
  유지됨  : N개
  건너뜀  : N개

⚠️  CLAUDE.md는 업데이트되지 않았습니다.
   플러그인 규칙 변경이 있을 경우 CLAUDE.md의 @참조를 직접 확인하세요.
```
