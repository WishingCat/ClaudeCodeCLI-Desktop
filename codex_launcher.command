#!/bin/zsh
# Launcher for 一只小Codex.app — opens a Terminal straight into `codex --yolo`.
# Install at: ~/.codex_launcher.command   (and: chmod +x ~/.codex_launcher.command)
#
# On this machine `codex` is NOT a plain binary: ~/.zshrc defines a wrapper
# function that points Codex at a third-party (mindracode) endpoint via
# CODEX_HOME + MINDRA_API_KEY. A double-clicked .command runs a NON-interactive
# shell, which does not source ~/.zshrc, so we reproduce that wrapper here.

cd "$HOME/Desktop"

# Greeting shown the moment the app opens. Codex's full-screen TUI takes over
# the terminal on launch (alternate screen), so we pause briefly to let the
# message be read before Codex clears the screen.
print -P "%F{cyan}你好～ 我是一只小 Codex%f"
sleep 1.5

# Codex CLI config/state lives here (third-party mindracode profile).
export CODEX_HOME="$HOME/.codex-cli"

# Single source of truth for the secret: read the API key straight out of the
# ~/.zshrc wrapper at launch time. The key therefore lives in exactly one place
# and is never copied into this repo. If you don't use the .zshrc wrapper,
# replace the line below with:  export MINDRA_API_KEY="<your-mindracode-key>"
export MINDRA_API_KEY="$(sed -n 's/.*MINDRA_API_KEY="\([^"]*\)".*/\1/p' "$HOME/.zshrc" | head -1)"

# --yolo == --dangerously-bypass-approvals-and-sandbox (no prompts, no sandbox).
exec /opt/homebrew/bin/codex --yolo
