# dotfiles

My dotfiles managed by [Chezmoi](https://www.chezmoi.io/).

## Machines

| Machine   | Device                | Shell | Packages        |
| --------- | --------------------- | ----- | --------------- |
| `macos`   | Laptop (macOS)        | fish  | Homebrew        |
| `termux`  | Phone (Termux)        | fish  | pkg + mise      |
| `truenas` | NAS (TrueNAS Scale)   | fish  | mise            |
| `fedora`  | Dev box (Fedora IoT)  | fish  | rpm-ostree + mise |

`chezmoi init` prompts once for the machine (with a sensible default detected
from the environment) and everything else derives from that answer: the shell
config to lay down, the mise tool list, and the package hooks.

## Bootstrap

### macos

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
chezmoi init --apply onedr0p/dotfiles
```

The brew bundle hook installs everything in the brewfile on first apply.
Afterwards, make fish the login shell:

```sh
echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/fish"
```

### termux

```sh
pkg install chezmoi git mise fish
chezmoi init --apply onedr0p/dotfiles
chsh -s fish
```

mise is not bootstrapped by a hook on termux; it must come from pkg (as above)
or the mise-install hook silently skips and no declared tools get installed.
Prompt niceties (starship, zoxide, atuin, bat, lsd) also come from pkg; the
fish config skips whichever are missing.

### truenas

TrueNAS Scale has no usable package manager (the base OS is reset on updates),
so install chezmoi to `~/.local/bin` with the official script:

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply onedr0p/dotfiles
```

TrueNAS Scale mounts `/tmp` noexec, which breaks chezmoi script hooks and mise
installs. A post-init script must exist to remount it with exec (System →
Advanced Settings → Init/Shutdown Scripts, type Command, when Post Init):

```sh
mount -o remount,exec /tmp
```

mise is bootstrapped automatically and the declared tools are installed during
the first apply. Afterwards, set the login shell to zsh in the TrueNAS UI:
fish comes from mise and can't be registered in `/etc/shells` (the base OS is
sealed), so `.zshrc` execs into fish for interactive sessions instead.
Re-run `chezmoi apply` after major TrueNAS updates.

### fedora

Fedora IoT is an immutable `rpm-ostree` system: `/usr` is read-only, so the
base tools (`fish`, `git`, `mise`) are layered into the OS image and activated
with a reboot. The `terra-release` repo provides `mise`:

```sh
sudo curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
  | sudo tee /etc/yum.repos.d/terra.repo
sudo rpm-ostree install --idempotent terra-release
sudo rpm-ostree install --idempotent --assumeyes fish git mise
sudo systemctl reboot
```

fish is a real login shell here (it is in `/etc/shells`), so there is no zsh
layer — set it with `chsh -s /usr/bin/fish` if it is not already your shell.

chezmoi itself is not layered; install it to `~/.local/bin` with the official
script (as on truenas), then let the first apply take over. mise then manages
chezmoi going forward (it is in the fedora tool list):

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply onedr0p/dotfiles
```

Pick `fedora` at the machine prompt (it is the default on Fedora). The
mise-install hook installs the declared tools into `~/.local`; nothing else is
layered onto the OS image. Re-run `chezmoi apply` after pulling changes.

### Fish plugins

`~/.config/fish/fish_plugins` is managed by chezmoi, and the `update-fisher`
hook bootstraps [fisher](https://github.com/jorgebucaran/fisher) and re-runs
`fisher update` whenever the plugin list changes.

## Notes

- The machine answer is stored in the local chezmoi config
  (`~/.config/chezmoi/chezmoi.yaml`), not in this repo. To change it later,
  remove the `machine` entry from that file and re-run `chezmoi init`.
- `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` are symlinks to
  `~/.config/agents/AGENTS.md`, so Claude Code and Codex share one set of
  global agent instructions.
