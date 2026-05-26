#!/bin/zsh
# Launcher script for CCDesktop.app.
# Install at: ~/.claude_launcher.command  (chmod +x)
#
# Adjust the two values below for your machine:
#   - working directory you want Claude Code to start in
#   - full path to your `claude` binary (find it with: which claude)

cd "$HOME/Desktop"
exec "$HOME/.local/bin/claude" --dangerously-skip-permissions
