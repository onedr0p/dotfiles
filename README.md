# dotfiles

My dotfiles managed by [Chezmoi](https://www.chezmoi.io/).

## Machines

| Machine   | Device                | Shell | Packages        |
| --------- | --------------------- | ----- | --------------- |
| `macos`   | Laptop (macOS)        | fish  | Homebrew        |
| `termux`  | Phone (Termux)        | fish  | pkg + mise      |
| `truenas` | NAS (TrueNAS Scale)   | zsh   | mise            |

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

### termux

```sh
pkg install chezmoi git
chezmoi init --apply onedr0p/dotfiles
```

### truenas

TrueNAS Scale has no usable package manager (the base OS is reset on updates),
so install chezmoi to `~/.local/bin` with the official script:

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply onedr0p/dotfiles
```

mise is bootstrapped automatically and the declared tools are installed during
the first apply. Afterwards, set the login shell to zsh in the TrueNAS UI.
Re-run `chezmoi apply` after major TrueNAS updates.

## Notes

The machine answer is stored in the local chezmoi config
(`~/.config/chezmoi/chezmoi.yaml`), not in this repo. To change it later,
remove the `machine` entry from that file and re-run `chezmoi init`.
