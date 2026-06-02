# AI CLI Desktop Launchers

Clickable macOS launchers for terminal-based AI coding agents. Double-click an app in Finder (or pin it to the Dock) and a Terminal window opens straight into the agent, working directory set to your Desktop. No more `cmd+space → Terminal → type the command`.

| App | Launches | Icon |
| --- | --- | --- |
| `CCDesktop.app` | [Claude Code CLI](https://docs.claude.com/en/docs/claude-code/overview) — `claude --dangerously-skip-permissions` | default applet |
| `CodexDesktop.app` | [Codex CLI](https://github.com/openai/codex) — `codex --yolo` | 🐱 (`assets/codex-icon-source.jpg`) |

## How it works

Each app is the same three thin layers — an AppleScript applet that opens a `.command` file, which `cd`s somewhere and `exec`s the agent binary:

```
<App>.app  (AppleScript applet)
      │
      ▼  do shell script "open ~/.<agent>_launcher.command"
      │
~/.<agent>_launcher.command  (zsh script)
      │
      ▼  cd ~/Desktop && exec <agent> <flags>
      │
   agent CLI takes over the Terminal window
```

The applet is intentionally dumb — it only opens the `.command` file. All the real configuration lives in the launcher script in your home directory, so you can tweak flags, working directory, or env vars without ever recompiling the `.app`.

---

## CodexDesktop

Double-click `CodexDesktop.app` → Terminal opens on your Desktop running `codex --yolo`.

> `--yolo` is Codex's alias for `--dangerously-bypass-approvals-and-sandbox`: **no approval prompts and no sandbox**. Every model-generated command runs immediately with your full user privileges. Only use it on a machine and in a directory you trust. To keep guardrails, drop the flag (or use `--ask-for-approval`) in the launcher.

### A wrinkle: `codex` is a shell wrapper, not a bare binary

On the machine this was built for, `codex` is not a plain executable — `~/.zshrc` defines a wrapper function that points Codex at a third-party (mindracode) endpoint:

```zsh
codex() { CODEX_HOME="$HOME/.codex-cli" MINDRA_API_KEY="<secret>" command codex "$@"; }
```

A double-clicked `.command` runs a **non-interactive** shell, which does **not** source `~/.zshrc`, so that wrapper (and its env vars) wouldn't be available. The launcher therefore reproduces what the wrapper does:

```zsh
cd "$HOME/Desktop"
export CODEX_HOME="$HOME/.codex-cli"
export MINDRA_API_KEY="$(sed -n 's/.*MINDRA_API_KEY="\([^"]*\)".*/\1/p' "$HOME/.zshrc" | head -1)"
exec /opt/homebrew/bin/codex --yolo
```

**No API key is stored in this repo.** The launcher reads the key out of your `~/.zshrc` wrapper at launch time, so the secret lives in exactly one place on your machine and survives key rotation. If you *don't* use the `.zshrc` wrapper, replace that line with a plain `export MINDRA_API_KEY="<your-key>"` (or remove both env lines entirely if you run vanilla Codex against your own ChatGPT/OpenAI auth).

### Install

```sh
git clone https://github.com/WishingCat/ClaudeCodeCLI-Desktop.git
cd ClaudeCodeCLI-Desktop

cp codex_launcher.command ~/.codex_launcher.command
chmod +x ~/.codex_launcher.command
```

Then open `~/.codex_launcher.command` and check the two machine-specific bits:

- the path to the real `codex` binary (default `/opt/homebrew/bin/codex` — Apple-silicon Homebrew install)
- how `MINDRA_API_KEY` / `CODEX_HOME` are sourced (see above)

Double-click `CodexDesktop.app`. The bundled app already uses a `~`-relative path, so it works for any user without recompiling.

### Rebuilding the app (e.g. to change the icon or flags)

The `.app` is a compiled AppleScript applet. To regenerate it from scratch:

```sh
# 1) compile the applet (portable ~ path)
rm -rf CodexDesktop.app
osacompile -o CodexDesktop.app -e 'do shell script "open ~/.codex_launcher.command"'

# 2) build a .icns from any square-ish image and swap it in
#    (forces real PNG encoding so iconutil accepts the frames)
SRC=assets/codex-icon-source.jpg
TMP=$(mktemp -d); ICON=$TMP/icon.iconset; mkdir -p "$ICON"
sips -s format png -c 1062 1062 "$SRC" --out "$TMP/sq.png"
for s in 16 32 128 256 512; do
  sips -s format png -z $s        $s        "$TMP/sq.png" --out "$ICON/icon_${s}x${s}.png"
  sips -s format png -z $((s*2))  $((s*2))  "$TMP/sq.png" --out "$ICON/icon_${s}x${s}@2x.png"
done
sips -s format png -z 1024 1024 "$TMP/sq.png" --out "$ICON/icon_512x512@2x.png"
iconutil -c icns "$ICON" -o CodexDesktop.app/Contents/Resources/applet.icns

# 3) modern osacompile also drops an asset-catalog icon that overrides the .icns —
#    remove it so the classic .icns path wins, then re-sign ad-hoc
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" CodexDesktop.app/Contents/Info.plist 2>/dev/null
rm -f CodexDesktop.app/Contents/Resources/Assets.car
codesign --force --deep -s - CodexDesktop.app
```

---

## CCDesktop

Double-click `CCDesktop.app` → Terminal opens on your Desktop running `claude --dangerously-skip-permissions`.

> `--dangerously-skip-permissions` skips Claude Code's per-tool permission prompts — `Bash`, `Edit`, `Write`, etc. run without asking. Convenient on a machine you fully control; remove the flag from the launcher if you'd rather keep the prompts.

### Install

```sh
cp claude_launcher.command ~/.claude_launcher.command
chmod +x ~/.claude_launcher.command
```

Open `~/.claude_launcher.command` and set the working directory and the full path to your `claude` binary (`which claude`).

**Heads-up:** the bundled `CCDesktop.app` has an absolute path baked in (`/Users/wishingcat/.claude_launcher.command`). To make it portable for your own user, recompile it the same way as CodexDesktop:

```sh
rm -rf CCDesktop.app
osacompile -o CCDesktop.app -e 'do shell script "open ~/.claude_launcher.command"'
```

---

## Repo contents

| Path | Purpose |
| --- | --- |
| `CodexDesktop.app/` | Compiled applet → `~/.codex_launcher.command`. Portable `~` path, cat icon. |
| `CCDesktop.app/` | Compiled applet → `~/.claude_launcher.command`. Absolute path; see note above. |
| `codex_launcher.command` | Template launcher for Codex — copy to `~/.codex_launcher.command`. Contains **no secret**. |
| `claude_launcher.command` | Template launcher for Claude Code — copy to `~/.claude_launcher.command`. |
| `assets/codex.icns` | Built icon for CodexDesktop. |
| `assets/codex-icon-source.jpg` | Source image the icon was generated from. |

## Security notes

- These launchers run their agents with the safety flags **off** (`--yolo`, `--dangerously-skip-permissions`) for a frictionless one-click flow. That trades away the prompts/sandbox that would otherwise catch a destructive or prompt-injected action. Use only where you trust the working directory, and drop the flags if you want the guardrails back.
- No API keys are committed. `CodexDesktop` reads its key from your local `~/.zshrc` at launch; nothing secret lives in this repo.

## License

MIT.
