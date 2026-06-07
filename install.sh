#!/usr/bin/env bash
#
# jarvis installer — Machine in the Loop
# https://github.com/pinguding/Project-Machine-in-the-loop
#
# 사용법:
#   ./install.sh                 # 현재 디렉토리(프로젝트)에 설치 → .claude/skills/
#   ./install.sh ../my-project   # 지정한 프로젝트에 설치
#   ./install.sh --global        # ~/.claude/skills/ 에 전역 설치 (모든 프로젝트에서 /jarvis)
#   ./install.sh --help
#
# 레포 밖에서 한 줄로:
#   curl -fsSL https://raw.githubusercontent.com/pinguding/Project-Machine-in-the-loop/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --global
#
set -euo pipefail

REPO_URL="https://github.com/pinguding/Project-Machine-in-the-loop.git"
SKILLS=(jarvis jarvis-once jarvis-pause jarvis-resume jarvis-stop)

# ---- 색 ----
if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; C=$'\033[36m'; Y=$'\033[33m'; D=$'\033[2m'; R=$'\033[0m'; else B=; G=; C=; Y=; D=; R=; fi
say(){ printf '%s\n' "$*"; }
ok(){  printf '  %s✓%s %s\n' "$G" "$R" "$*"; }
info(){ printf '  %s·%s %s\n' "$D" "$R" "$*"; }

usage(){
  cat <<EOF
${B}jarvis installer${R} — Machine in the Loop

  ${C}./install.sh${R}              현재 디렉토리에 설치 (.claude/skills/)
  ${C}./install.sh <path>${R}       지정한 프로젝트에 설치
  ${C}./install.sh --global${R}     ~/.claude/skills/ 전역 설치
  ${C}./install.sh --help${R}

설치되는 스킬: ${SKILLS[*]}
EOF
}

# ---- 인자 파싱 ----
MODE="project"; TARGET="."
while [ $# -gt 0 ]; do
  case "$1" in
    -g|--global) MODE="global"; shift;;
    -h|--help)   usage; exit 0;;
    -*)          say "${Y}알 수 없는 옵션: $1${R}"; usage; exit 1;;
    *)           TARGET="$1"; shift;;
  esac
done

# ---- 소스 확보 (로컬 레포 or 임시 clone) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
SRC=""
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/.claude/skills/jarvis" ]; then
  SRC="$SCRIPT_DIR"
  info "소스: 로컬 레포 ($SRC)"
else
  command -v git >/dev/null 2>&1 || { say "${Y}git이 필요합니다 (원격 설치 시).${R}"; exit 1; }
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  info "소스: 원격에서 clone 중…"
  git clone --depth 1 -q "$REPO_URL" "$TMP/repo"
  SRC="$TMP/repo"
fi

# ---- 대상 결정 ----
if [ "$MODE" = "global" ]; then
  DEST="$HOME/.claude/skills"
  say ""
  say "${B}전역 설치${R} → ${C}$DEST${R}"
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
  DEST="$TARGET/.claude/skills"
  say ""
  say "${B}프로젝트 설치${R} → ${C}$TARGET${R}"
fi

# ---- 스킬 복사 ----
mkdir -p "$DEST"
for s in "${SKILLS[@]}"; do
  rm -rf "${DEST:?}/$s"
  cp -R "$SRC/.claude/skills/$s" "$DEST/$s"
  ok "skill: $s"
done

# ---- 프로젝트 전용: focus 디렉토리 + .gitignore ----
if [ "$MODE" = "project" ]; then
  FOCUS="$TARGET/.claude/jarvis/focus"
  if [ ! -e "$FOCUS/README.md" ]; then
    mkdir -p "$FOCUS"
    cp "$SRC/.claude/jarvis/focus/README.md" "$FOCUS/README.md"
    ok "집중 영역 디렉토리: .claude/jarvis/focus/"
  else
    info "집중 영역 디렉토리 이미 있음 — 보존"
  fi

  GI="$TARGET/.gitignore"
  if [ ! -f "$GI" ] || ! grep -qE '^\.jarvis/?$' "$GI" 2>/dev/null; then
    printf '\n# jarvis watch-loop local state (per-clone, never committed)\n.jarvis/\n' >> "$GI"
    ok ".gitignore에 .jarvis/ 추가"
  else
    info ".gitignore에 .jarvis/ 이미 있음"
  fi
fi

# ---- 안내 ----
say ""
say "${G}${B}설치 완료.${R}"
say ""
if [ "$MODE" = "global" ]; then
  say "  이제 ${C}아무 프로젝트${R}에서나 ${C}/jarvis${R} 로 워치를 켤 수 있습니다."
else
  say "  설치한 프로젝트에서 Claude Code를 열고 ${C}/jarvis${R} 를 입력하세요."
fi
cat <<EOF

  ${C}/jarvis${R}                    최초 1회 강도를 묻고 워치 시작
  ${C}/jarvis strength=high${R}      작은 변화도 자주 점검
  ${C}/jarvis mirror=off${R}         gray zone 거울 끄기
  ${C}/jarvis-pause${R} ${D}|${R} ${C}-resume${R} ${D}|${R} ${C}-stop${R}

  개인화:
  ${D}·${R} .claude/skills/jarvis-once/persona.md   내비게이터 성격·집중점 (빈 채로 제공)
  ${D}·${R} .claude/jarvis/focus/                   이 프로젝트에서 특히 볼 것

  키보드는 당신이 잡습니다. 기계가 루프를 돕습니다.
EOF
