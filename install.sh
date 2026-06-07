#!/usr/bin/env bash
#
# jarvis installer — Machine in the Loop
# https://github.com/pinguding/Project-Machine-in-the-loop
#
# Usage / 사용법:
#   ./install.sh                      # current project, asks for language
#   ./install.sh --lang en            # English skills, no prompt
#   ./install.sh --lang ko ../proj    # Korean skills into ../proj
#   ./install.sh --global --lang en   # ~/.claude/skills/ (every project)
#   ./install.sh --help
#
# One line from outside the repo (self-clones):
#   curl -fsSL https://raw.githubusercontent.com/pinguding/Project-Machine-in-the-loop/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --lang en --global
#
set -euo pipefail

REPO_URL="https://github.com/pinguding/Project-Machine-in-the-loop.git"
SKILLS=(jarvis jarvis-once jarvis-pause jarvis-resume jarvis-stop)

# ---- colors ----
if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; C=$'\033[36m'; Y=$'\033[33m'; D=$'\033[2m'; R=$'\033[0m'; else B=; G=; C=; Y=; D=; R=; fi
say(){ printf '%s\n' "$*"; }
ok(){  printf '  %s✓%s %s\n' "$G" "$R" "$*"; }
info(){ printf '  %s·%s %s\n' "$D" "$R" "$*"; }

usage(){
  cat <<EOF
${B}jarvis installer${R} — Machine in the Loop

  ${C}./install.sh${R}                     current project (asks for language)
  ${C}./install.sh <path>${R}              a specific project
  ${C}./install.sh --global${R}            ~/.claude/skills/ (every project)
  ${C}./install.sh --lang en|ko${R}        pick skill language (skip the prompt)
  ${C}./install.sh --help${R}

Installs skills: ${SKILLS[*]}
EOF
}

# ---- args ----
MODE="project"; TARGET="."; LANGSEL=""
while [ $# -gt 0 ]; do
  case "$1" in
    -g|--global)   MODE="global"; shift;;
    -l|--lang)     LANGSEL="${2:-}"; shift 2;;
    --lang=*)      LANGSEL="${1#*=}"; shift;;
    --en)          LANGSEL="en"; shift;;
    --ko)          LANGSEL="ko"; shift;;
    -h|--help)     usage; exit 0;;
    -*)            say "${Y}Unknown option: $1${R}"; usage; exit 1;;
    *)             TARGET="$1"; shift;;
  esac
done

# ---- language selection ----
if [ -z "$LANGSEL" ]; then
  if [ -e /dev/tty ]; then
    printf '%s\n' "${B}Choose skill language / 스킬 언어 선택:${R}"
    printf '  %s1)%s English\n  %s2)%s 한국어\n' "$C" "$R" "$C" "$R"
    printf '> '
    read -r choice < /dev/tty || choice=""
    case "$choice" in 2|ko|KO|한국어|kr) LANGSEL="ko";; *) LANGSEL="en";; esac
  else
    LANGSEL="en"
    info "non-interactive — defaulting to language 'en' (override with --lang ko)"
  fi
fi
case "$LANGSEL" in en|ko) ;; *) say "${Y}Unknown language '$LANGSEL' — use en or ko.${R}"; exit 1;; esac

# ---- source (local repo or temp clone) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
SRC=""
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/skills/$LANGSEL/jarvis" ]; then
  SRC="$SCRIPT_DIR"
  info "source: local repo ($SRC)"
else
  command -v git >/dev/null 2>&1 || { say "${Y}git is required (for remote install).${R}"; exit 1; }
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  info "source: cloning from remote…"
  git clone --depth 1 -q "$REPO_URL" "$TMP/repo"
  SRC="$TMP/repo"
fi

# ---- destination ----
if [ "$MODE" = "global" ]; then
  DEST="$HOME/.claude/skills"
  say ""
  say "${B}Global install${R} (${C}$LANGSEL${R}) → ${C}$DEST${R}"
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
  DEST="$TARGET/.claude/skills"
  say ""
  say "${B}Project install${R} (${C}$LANGSEL${R}) → ${C}$TARGET${R}"
fi

# ---- copy skills ----
mkdir -p "$DEST"
for s in "${SKILLS[@]}"; do
  rm -rf "${DEST:?}/$s"
  cp -R "$SRC/skills/$LANGSEL/$s" "$DEST/$s"
  ok "skill: $s"
done

# ---- project only: focus dir + .gitignore ----
if [ "$MODE" = "project" ]; then
  FOCUS="$TARGET/.claude/jarvis/focus"
  if [ ! -e "$FOCUS/README.md" ]; then
    mkdir -p "$FOCUS"
    cp "$SRC/focus/$LANGSEL/README.md" "$FOCUS/README.md"
    ok "focus directory: .claude/jarvis/focus/"
  else
    info "focus directory already exists — preserved"
  fi

  GI="$TARGET/.gitignore"
  if [ ! -f "$GI" ] || ! grep -qE '^\.jarvis/?$' "$GI" 2>/dev/null; then
    printf '\n# jarvis watch-loop local state (per-clone, never committed)\n.jarvis/\n' >> "$GI"
    ok ".jarvis/ added to .gitignore"
  else
    info ".jarvis/ already in .gitignore"
  fi
fi

# ---- done ----
say ""
say "${G}${B}Done.${R}"
say ""
if [ "$MODE" = "global" ]; then
  say "  You can now start the watch with ${C}/jarvis${R} in ${C}any project${R}."
else
  say "  Open Claude Code in that project and run ${C}/jarvis${R}."
fi
cat <<EOF

  ${C}/jarvis${R}                    asks for strength once, then starts the watch
  ${C}/jarvis strength=high${R}      check small changes often
  ${C}/jarvis mirror=off${R}         turn off the gray-zone mirror
  ${C}/jarvis-pause${R} ${D}|${R} ${C}-resume${R} ${D}|${R} ${C}-stop${R}

  Personalize:
  ${D}·${R} .claude/skills/jarvis-once/persona.md   navigator's character & focus (ships empty)
  ${D}·${R} .claude/jarvis/focus/                   what to watch especially in this project

  You hold the keyboard. The machine works the loop.
EOF
