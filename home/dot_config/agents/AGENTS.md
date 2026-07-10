# Global Agent Instructions

Default instructions for AI coding agents (Claude Code, Codex, etc.).
Project-level AGENTS.md / CLAUDE.md files take precedence over this file.

## Environment

- Primary shell is fish, on both macOS and Linux — anything written for the shell must work on both.
- Dotfiles are managed with chezmoi (source: `~/.local/share/chezmoi`). Edit dotfiles in the chezmoi source, not the rendered files in `$HOME`.

## Git

- Sign off commits (`git commit -s`).
- Prefer `--force-with-lease` over `--force` when force-pushing.
- Do not commit or push unless asked.
