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

## Install

```sh
chezmoi init --apply onedr0p/dotfiles
```

On `truenas`, mise is bootstrapped automatically and the declared tools are
installed on first apply; set the login shell to zsh in the TrueNAS UI.

The answer is stored in the local chezmoi config (`~/.config/chezmoi/chezmoi.yaml`),
not in this repo. To change it later, remove the `machine` entry from that file
and re-run `chezmoi init`.
