---
name: update-cc-kit
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
| `references/` | |

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

## 2단계: manifest.json 로드

`.claude/manifest.json`의 `cc-kit.files` 배열을 읽어 **cc-kit이 설치한 파일 목록**을 파악한다.

```bash
# manifest가 없으면 빈 목록으로 진행 (최초 업데이트 또는 구버전 설치)
MANIFEST_FILES=$(python3 -c "
import json, sys
try:
    m = json.load(open('.claude/manifest.json'))
    print('\n'.join(m.get('cc-kit', {}).get('files', [])))
except:
    pass
" 2>/dev/null || true)
```

---

## 3단계: 파일별 비교 및 업데이트

아래 디렉토리에 대해 파일 하나씩 비교한다:

```bash
UPDATE_DIRS="rules instructions agents skills commands hooks scripts references"
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
플러그인 소스에는 없고 설치본에만 있는 파일 → **manifest 기반으로 자동 판단**:

| 조건 | 동작 |
|------|------|
| manifest에 있음 → cc-kit이 설치한 파일 | **자동 삭제** 후 `🗑️  삭제: {파일경로}` 출력 |
| manifest에 없음 → 사용자가 직접 만든 파일 | **조용히 건너뜀** (보고 생략) |

> manifest가 없는 경우(구버전 설치): 케이스 D 파일 모두 건너뜀. 업데이트 완료 후 manifest가 새로 생성되므로 다음 업데이트부터 정상 동작.

---

## 4단계: hooks 실행 권한 갱신

```bash
[ -f ".claude/hooks/notify.sh" ] && chmod +x .claude/hooks/notify.sh
```

---

## 5단계: manifest.json 갱신

파일 추가/업데이트/삭제가 완료된 후 `.claude/manifest.json`의 `cc-kit` 키를 최신 상태로 갱신한다.

```bash
PLUGIN_ROOT="$PLUGIN_ROOT" python3 - <<'PYEOF'
import json, os
from datetime import date
from pathlib import Path

plugin_root = os.environ["PLUGIN_ROOT"]

# plugin.json에서 버전 읽기
plugin_json_path = os.path.join(plugin_root, "plugin.json")
version = "unknown"
if os.path.exists(plugin_json_path):
    with open(plugin_json_path) as f:
        version = json.load(f).get("version", "unknown")

# 현재 설치된 파일 목록 수집
managed_dirs = ["rules", "instructions", "agents", "skills", "commands", "hooks", "scripts"]
files = []
for d in managed_dirs:
    dir_path = Path(".claude") / d
    if dir_path.exists():
        for p in sorted(dir_path.rglob("*")):
            if p.is_file():
                files.append(str(p.relative_to(".claude")))

# 기존 manifest.json 로드 또는 빈 구조 생성
manifest_path = ".claude/manifest.json"
manifest = {}
if os.path.exists(manifest_path):
    with open(manifest_path) as f:
        manifest = json.load(f)

manifest["cc-kit"] = {
    "version": version,
    "updatedAt": str(date.today()),
    "files": files
}

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"📋 manifest.json 갱신 완료 — {len(files)}개 파일 기록")
PYEOF
```

---

## 6단계: 임시 파일 정리

```bash
[ "$PLUGIN_ROOT" = "/tmp/cc-kit_update" ] && rm -rf /tmp/cc-kit_update
```

---

## 7단계: 업데이트 결과 보고

```
✅ cc-kit 업데이트 완료

📋 결과 요약:
  추가됨  : N개
  업데이트: N개
  삭제됨  : N개
  유지됨  : N개
  건너뜀  : N개

⚠️  CLAUDE.md는 업데이트되지 않았습니다.
   플러그인 규칙 변경이 있을 경우 CLAUDE.md의 @참조를 직접 확인하세요.
```
