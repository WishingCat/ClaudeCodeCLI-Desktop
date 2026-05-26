# CCDesktop

A clickable macOS launcher for [Claude Code CLI](https://docs.claude.com/en/docs/claude-code/overview).

Double-click `CCDesktop.app` in Finder (or pin it to the Dock) and a Terminal window opens straight into Claude Code, with the working directory set to your Desktop. No more `cmd+space → Terminal → claude`.

## How it works

Three thin layers — that's the whole project:

```
CCDesktop.app  (AppleScript applet)
      │
      ▼  do shell script "open ~/.claude_launcher.command"
      │
~/.claude_launcher.command  (zsh script)
      │
      ▼  cd ~/Desktop && exec claude --dangerously-skip-permissions
      │
   claude CLI
```

1. `CCDesktop.app/Contents/Resources/Scripts/main.scpt` — a one-line AppleScript that runs `open` on the launcher command file.
2. `~/.claude_launcher.command` — a shebanged zsh script Finder treats as executable. It `cd`s into a working directory and `exec`s the `claude` binary.
3. The `claude` CLI takes over the Terminal window.

The launcher passes `--dangerously-skip-permissions`, which skips Claude Code's per-tool permission prompts. **Only keep that flag if you understand what it means** — see the security note below.

## Installation

### Prerequisites

- macOS
- [Claude Code CLI](https://docs.claude.com/en/docs/claude-code/setup) installed and on your `$PATH`

### Steps

1. Clone this repo somewhere convenient:
   ```sh
   git clone https://github.com/WishingCat/ClaudeCodeCLI-Desktop.git
   cd ClaudeCodeCLI-Desktop
   ```

2. Install the launcher script into your home directory:
   ```sh
   cp claude_launcher.command ~/.claude_launcher.command
   chmod +x ~/.claude_launcher.command
   ```

3. Open `~/.claude_launcher.command` and adjust the two paths to match your machine:
   - Working directory (default `~/Desktop`)
   - Full path to the `claude` binary (run `which claude` to find it)

4. **The bundled `CCDesktop.app` has my username hardcoded** (`/Users/wishingcat/.claude_launcher.command`). You have two options:

   **Option A — rebuild the app for your own user (recommended).** From this repo's directory:
   ```sh
   rm -rf CCDesktop.app
   osacompile -o CCDesktop.app -e 'do shell script "open ~/.claude_launcher.command"'
   ```
   The `~` is expanded by the shell that AppleScript invokes, so the new bundle works for any user.

   **Option B — patch in place.** Edit the existing AppleScript without recompiling the bundle:
   ```sh
   osacompile -o CCDesktop.app/Contents/Resources/Scripts/main.scpt \
     -e 'do shell script "open ~/.claude_launcher.command"'
   ```

5. (Optional) Drag `CCDesktop.app` to `/Applications` and pin it to the Dock.

That's it — clicking the app should now drop you into a Claude Code session.

## Customizing

Edit `~/.claude_launcher.command` to taste:

- **Change the working directory** — replace `~/Desktop` with whichever folder you want Claude Code to open in.
- **Drop the `--dangerously-skip-permissions` flag** if you'd rather keep Claude Code's permission prompts on.
- **Pass extra CLI flags** — `--model`, `--print`, etc.
- **Add env vars** before the `exec`, e.g. `export ANTHROPIC_API_KEY=...`.

You don't need to touch the `.app` again after that — the applet just opens the command file, so any change to the script takes effect on the next launch.

## Security note

`--dangerously-skip-permissions` tells Claude Code to skip its built-in permission prompts. That means tools like `Bash`, `Edit`, and `Write` run without asking you first. It's convenient for solo workflows on machines you fully control, but it does mean a prompt-injected agent can take destructive actions silently. If you're not sure, **remove the flag** from `~/.claude_launcher.command` and let Claude Code ask.

## Repo contents

| Path | Purpose |
| --- | --- |
| `CCDesktop.app/` | The compiled AppleScript applet bundle. Uses absolute path; see install step 4. |
| `claude_launcher.command` | Template launcher script — copy to `~/.claude_launcher.command`. |
| `README.md` | This file. |

## License

MIT.
