# Global Agent Instructions

Default instructions for AI coding agents (Claude Code, Codex, etc.).
Project-level AGENTS.md / CLAUDE.md files take precedence over this file.

## Environment & Shell

- **Shell**: The user uses `fish`. ALWAYS generate fish-compatible commands if a command is intended to be run by the user. Shell scripts can use bash/sh syntax.
  - Use `(cmd)` for substitution, not `$(cmd)`.
  - Use `set -gx VAR val` for exports.
  - Use `and`/`or` for logic.
- Both macOS and Linux are in use — anything written for the shell must work on both.
- Dotfiles are managed with chezmoi (source: `~/.local/share/chezmoi`). Edit dotfiles in the chezmoi source, not the rendered files in `$HOME`.

## Preferred Tools

The following modern tools are available and preferred over their traditional counterparts:

- **Search**: `rg` (ripgrep) instead of `grep`.
- **Find**: `fd` instead of `find`.
- **List**: `lsd` instead of `ls`.
- **Processes**: `procs` instead of `ps`.
- **Text Replace**: `sd` instead of `sed`.
- **Data**: `jq` for JSON, `yq` for YAML.
- **Pod Logs**: `stern` instead of `kubectl logs`.

## Git

- Sign off commits (`git commit -s`).
- Prefer `--force-with-lease` over `--force` when force-pushing.
- Do not commit or push unless asked.
