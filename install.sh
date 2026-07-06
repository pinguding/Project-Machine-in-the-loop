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
#   ./install.sh --version 1.0.0      # install a specific tag/branch/commit
#   ./install.sh --help
#
# One line from outside the repo (self-clones):
#   curl -fsSL https://raw.githubusercontent.com/pinguding/Project-Machine-in-the-loop/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --lang en --global
#   curl -fsSL .../install.sh | bash -s -- --version 1.0.0
#
set -euo pipefail

REPO_URL="https://github.com/pinguding/Project-Machine-in-the-loop.git"
SKILLS=(jarvis jarvis-once jarvis-plan jarvis-reset)

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
  ${C}./install.sh --version <ref>${R}     install a specific tag, branch, or commit
  ${C}./install.sh --no-settings${R}       skip auto-configuring settings.json (statusline/hook/perms)
  ${C}./install.sh --help${R}

  ${D}<ref> is any git tag (e.g. 1.0.0), branch (main), or commit SHA.${R}
  ${D}Specifying a version always fetches it from the remote.${R}

Installs skills: ${SKILLS[*]}
EOF
}

# ---- args ----
MODE="project"; TARGET="."; LANGSEL=""; VERSION=""; SETTINGS=1
while [ $# -gt 0 ]; do
  case "$1" in
    -g|--global)        MODE="global"; shift;;
    -l|--lang)          LANGSEL="${2:-}"; shift 2;;
    --lang=*)           LANGSEL="${1#*=}"; shift;;
    --en)               LANGSEL="en"; shift;;
    --ko)               LANGSEL="ko"; shift;;
    -v|--version|--ref) VERSION="${2:-}"; shift 2;;
    --version=*|--ref=*) VERSION="${1#*=}"; shift;;
    --no-settings)      SETTINGS=0; shift;;
    -h|--help)          usage; exit 0;;
    -*)                 say "${Y}Unknown option: $1${R}"; usage; exit 1;;
    *)                  TARGET="$1"; shift;;
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
# A pinned --version always fetches from the remote so the exact ref is used
# (and the user's local working tree is never checked out / mutated).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
SRC=""
if [ -z "$VERSION" ] && [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/skills/$LANGSEL/jarvis" ]; then
  SRC="$SCRIPT_DIR"
  info "source: local repo ($SRC)"
else
  command -v git >/dev/null 2>&1 || { say "${Y}git is required (for remote install).${R}"; exit 1; }
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  if [ -n "$VERSION" ]; then
    info "source: cloning ${C}$VERSION${R}${D} from remote…"
    # Fast path works for tags & branches; fall back to a full clone + checkout
    # so a raw commit SHA also works.
    if ! git clone --depth 1 --branch "$VERSION" -q "$REPO_URL" "$TMP/repo" 2>/dev/null; then
      git clone -q "$REPO_URL" "$TMP/repo" || { say "${Y}Clone failed.${R}"; exit 1; }
      git -C "$TMP/repo" checkout -q "$VERSION" 2>/dev/null \
        || { say "${Y}Version '$VERSION' not found (not a tag, branch, or commit).${R}"; exit 1; }
    fi
  else
    info "source: cloning from remote…"
    git clone --depth 1 -q "$REPO_URL" "$TMP/repo"
  fi
  SRC="$TMP/repo"
  [ -d "$SRC/skills/$LANGSEL/jarvis" ] \
    || { say "${Y}This version has no skills/$LANGSEL — try another version or --lang.${R}"; exit 1; }
fi

# ---- destination ----
VERLABEL=""; [ -n "$VERSION" ] && VERLABEL=" ${D}@${R} ${C}$VERSION${R}"
if [ "$MODE" = "global" ]; then
  DEST="$HOME/.claude/skills"
  say ""
  say "${B}Global install${R} (${C}$LANGSEL${R})${VERLABEL} → ${C}$DEST${R}"
else
  mkdir -p "$TARGET"
  TARGET="$(cd "$TARGET" && pwd)"
  DEST="$TARGET/.claude/skills"
  say ""
  say "${B}Project install${R} (${C}$LANGSEL${R})${VERLABEL} → ${C}$TARGET${R}"
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

# ---- configure settings.json (statusline + stop hook + benign-command allowlist) ----
# Absolute command paths so they resolve from any cwd/context.
SL_CMD="bash $DEST/jarvis/assets/statusline.sh"
HK_CMD="bash $DEST/jarvis/assets/loop-watch-hook.sh"
if [ "$MODE" = "global" ]; then
  SETTINGS_FILE="$HOME/.claude/settings.json"
else
  # project: personal, never-committed settings (matches .jarvis being gitignored)
  SETTINGS_FILE="$TARGET/.claude/settings.local.json"
fi
# Commands the watch runs every tick — allow them so the loop runs unattended.
PERMS='Bash(git:*) Bash(cat:*) Bash(date:*) Bash(echo:*) Bash(printf:*) Bash(mkdir:*) Bash(wc:*) Bash(sed:*) Bash(awk:*) Bash(grep:*)'

CONFIGURED=""; SETTINGS_WARN=""
if [ "$SETTINGS" = "1" ] && command -v python3 >/dev/null 2>&1; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  # Write the merge script to a temp file (heredoc-inside-$() is unreliable on bash 3.2/macOS).
  PYTMP="$(mktemp)"
  cat > "$PYTMP" <<'PY'
import json, os, sys
path   = sys.argv[1]
sl_cmd = os.environ["SL_CMD"]; hk_cmd = os.environ["HK_CMD"]
perms  = os.environ["PERMS"].split()

data = {}
if os.path.exists(path):
    with open(path) as f:
        txt = f.read().strip()
    if txt:
        try:
            data = json.loads(txt)
            if not isinstance(data, dict): data = {}
        except Exception:
            print("PARSE_ERROR"); sys.exit(0)   # malformed → leave untouched

msgs = []

# Match our assets by path fragment so ~ / absolute / relative variants don't duplicate.
SL_MARK = "jarvis/assets/statusline.sh"
HK_MARK = "jarvis/assets/loop-watch-hook.sh"

# statusLine — never clobber a user's existing one
sl = data.get("statusLine")
sl_now = sl.get("command", "") if isinstance(sl, dict) else ""
if sl is None:
    data["statusLine"] = {"type": "command", "command": sl_cmd}; msgs.append("statusLine: set")
elif SL_MARK in sl_now:
    msgs.append("statusLine: already set")
else:
    msgs.append("statusLine: kept existing (compose jarvis statusline.sh in by hand if wanted)")

# hooks — append ours if absent, preserve any others
hooks = data.setdefault("hooks", {})
def ensure(event):
    arr = hooks.setdefault(event, [])
    if not isinstance(arr, list): return False
    for g in arr:
        for h in (g or {}).get("hooks", []):
            if HK_MARK in (h or {}).get("command", ""): return False
    arr.append({"hooks": [{"type": "command", "command": hk_cmd}]}); return True
added_hook = ensure("Stop") | ensure("StopFailure")
msgs.append("hooks: Stop/StopFailure " + ("added" if added_hook else "already set"))

# permissions.allow — union, no duplicates
p = data.setdefault("permissions", {})
allow = p.setdefault("allow", [])
if isinstance(allow, list):
    added = [r for r in perms if r not in allow]
    allow.extend(added)
    msgs.append(("permissions.allow: +%d" % len(added)) if added else "permissions.allow: already set")

with open(path, "w") as f:
    json.dump(data, f, indent=2); f.write("\n")
print("\n".join(msgs))
PY
  MERGE_OUT="$(SL_CMD="$SL_CMD" HK_CMD="$HK_CMD" PERMS="$PERMS" python3 "$PYTMP" "$SETTINGS_FILE" 2>/dev/null)" || MERGE_OUT="PARSE_ERROR"
  rm -f "$PYTMP"
  if [ "$MERGE_OUT" = "PARSE_ERROR" ] || [ -z "$MERGE_OUT" ]; then
    SETTINGS_WARN="$SETTINGS_FILE is not valid JSON — left untouched"
  else
    CONFIGURED="$MERGE_OUT"
  fi
fi

# ---- done ----
say ""
say "${G}${B}Done.${R}"
say ""
if [ "$MODE" = "global" ]; then
  say "  You can now start the watch with ${C}/loop /jarvis${R} in ${C}any project${R}."
else
  say "  Open Claude Code in that project and run ${C}/loop /jarvis${R}."
fi
cat <<EOF

  ${C}/loop /jarvis${R}                 asks for strength once, then starts the watch
  ${C}/loop /jarvis strength=high${R}   check small changes often
  ${C}/loop /jarvis mirror=off${R}      turn off the gray-zone mirror

  stop/pause  ${D}→${R} interrupt the loop (Esc)
  resume      ${D}→${R} ${C}/loop /jarvis${R} again (restores saved settings)
  full reset  ${D}→${R} ${C}/jarvis-reset${R}
EOF

if [ -n "$CONFIGURED" ]; then
  say ""
  ok "settings configured → ${C}$SETTINGS_FILE${R}"
  printf '%s\n' "$CONFIGURED" | while IFS= read -r line; do info "$line"; done
  info "restart Claude Code (hooks & statusLine load at session start)"
else
  say ""
  if [ "$SETTINGS" = "0" ]; then
    info "settings.json left untouched (--no-settings). Enable liveness manually:"
  elif [ -n "$SETTINGS_WARN" ]; then
    info "$SETTINGS_WARN. Enable liveness manually:"
  else
    info "python3 not found — settings.json not auto-configured. Add manually:"
  fi
  printf '    %s"statusLine": { "type": "command", "command": "%s" }%s\n' "$D" "$SL_CMD" "$R"
  printf '    %s"hooks": { "Stop": [ { "hooks": [ { "type":"command","command":"%s" } ] } ],%s\n' "$D" "$HK_CMD" "$R"
  printf '    %s          "StopFailure": [ { "hooks": [ { "type":"command","command":"%s" } ] } ] }%s\n' "$D" "$HK_CMD" "$R"
fi

cat <<EOF

  Personalize:
  ${D}·${R} .claude/skills/jarvis-once/persona.md   navigator's character & focus (ships empty)
  ${D}·${R} .claude/jarvis/focus/                   what to watch especially in this project

  You hold the keyboard. The machine works the loop.
EOF
