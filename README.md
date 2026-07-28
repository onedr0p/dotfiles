# dotfiles

My dotfiles managed by [mise](https://mise.jdx.dev/dotfiles.html).

## Layout

- `mise.toml` - shared config: `[dotfiles]` entries, the nanorc syntax repo,
  and the fisher bootstrap task. Symlinked to `~/.config/mise/config.toml` on
  apply, so it is also the global mise config.
- `mise.<machine>.toml` - per-machine overlays: `[tools]`, machine-only
  dotfiles, packages, and the `machine` template var. Selected via `MISE_ENV`.
- `home/` - the dotfile sources. Most are symlinked into `$HOME`
  (`symlink-each` for `~/.config`); `*.tmpl` files are rendered with the mise
  template engine (`~/.gitconfig`, `~/.ssh/config`, two fish functions).

## Machines

| Machine   | Device                | Shell | Packages        |
| --------- | --------------------- | ----- | --------------- |
| `macos`   | Laptop (macOS)        | fish  | Homebrew        |
| `termux`  | Phone (Termux)        | fish  | pkg + mise      |
| `truenas` | NAS (TrueNAS Scale)   | fish  | mise            |
| `fedora`  | Dev box (Fedora IoT)  | fish  | rpm-ostree + mise |

The machine is pinned once per host in `~/.config/mise/miserc.toml` (untracked):

```sh
mkdir -p ~/.config/mise
printf 'env = ["fedora"]\n' > ~/.config/mise/miserc.toml   # or macos/termux/truenas
```

It selects the `mise.<machine>.toml` overlay, which determines the shell
config to lay down, the mise tool list, and the package hooks. Git identity
defaults live in `[vars]` in `mise.toml`; override them per host in an
untracked `mise.local.toml` next to `mise.toml`.

## Bootstrap

Common flow, after the machine-specific preparation below:

```sh
git clone https://github.com/onedr0p/dotfiles ~/.dotfiles
cd ~/.dotfiles
mise trust
mkdir -p ~/.config/mise
printf 'env = ["<machine>"]\n' > ~/.config/mise/miserc.toml
mise bootstrap --yes
chmod 600 ~/.ssh/config
```

`mise bootstrap` clones the declared repos, applies the dotfiles (including
symlinking this repo's `mise.toml` into `~/.config/mise/config.toml`),
installs the declared `[tools]`, and runs the fisher task. Re-run it (or
`mise dotfiles apply`) after pulling changes. The `chmod` is needed because
git does not track the 0600 mode on the ssh config source.

### macos

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install mise
```

Then run the common flow. The post-dotfiles hook installs everything in the
brewfile on each bootstrap (`--no-upgrade`, so it only installs what is
missing). Afterwards, make fish the login shell:

```sh
echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
chsh -s "$(brew --prefix)/bin/fish"
```

### termux

```sh
pkg install git mise fish
chsh -s fish
```

Then run the common flow. Prompt niceties (starship, zoxide, atuin, bat, lsd)
also come from pkg; the fish config skips whichever are missing.

### truenas

TrueNAS Scale has no usable package manager (the base OS is reset on updates),
so install mise to `~/.local/bin` with the official script:

```sh
curl https://mise.run | MISE_INSTALL_PATH="$HOME/.local/bin/mise" sh
```

TrueNAS Scale mounts `/tmp` noexec, which breaks mise installs. A post-init
script must exist to remount it with exec (System → Advanced Settings →
Init/Shutdown Scripts, type Command, when Post Init):

```sh
mount -o remount,exec /tmp
```

Then run the common flow. Afterwards, set the login shell to zsh in the
TrueNAS UI: fish comes from mise and can't be registered in `/etc/shells`
(the base OS is sealed), so `.zshrc` execs into fish for interactive sessions
instead. Re-run `mise bootstrap --yes` after major TrueNAS updates.

### fedora

Fedora IoT is an immutable `rpm-ostree` system: `/usr` is read-only, so system
packages are layered into the OS image and activated with a reboot. The
`terra-release` repo provides packages including `1password-cli`, `kopia`,
`mise`, `sops`, and `starship`.

**0. Passwordless sudo** (optional, dev box only — the provisioning below is
sudo-heavy). Add a `wheel` NOPASSWD drop-in, validated with `visudo` so a typo
can't lock you out of sudo:

```sh
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/10-wheel-nopasswd
sudo chmod 0440 /etc/sudoers.d/10-wheel-nopasswd
sudo visudo -cf /etc/sudoers.d/10-wheel-nopasswd   # must print "... parsed OK"
```

Your user must be in the `wheel` group (`id -nG | grep -qw wheel`); add it with
`sudo usermod -aG wheel "$USER"` and re-login if not.

**1. Host provisioning** (needs `sudo`; ends in a reboot that activates the
layered packages, permissive SELinux, and the disabled firewall):

```sh
# Terra repo -> mise + starship
sudo curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
  | sudo tee /etc/yum.repos.d/terra.repo
sudo rpm-ostree install --idempotent terra-release
# libatomic is a runtime dependency for the mise-managed node build.
# systemd-networkd supports the optional network setup in step 2 below.
sudo rpm-ostree install --idempotent --assumeyes \
  1password-cli age atuin autoconf automake bat bind-utils binutils btop \
  croc docker expect fastfetch fd-find fish fzf gcc gcc-c++ gh git \
  gum helm htop just kopia kustomize libatomic libtool lm_sensors lsd make \
  mise moreutils nano net-tools netcat nmap nvme-cli patch pciutils procs \
  qemu-guest-agent qemu-system-x86-core qemu-user-static-aarch64 ripgrep \
  rsync runc smartmontools sops spacer starship systemd-networkd tcpdump \
  telnet tree usbutils wget yq zoxide

# Permissive SELinux + no host firewall (dev box)
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
sudo systemctl disable --now firewalld.service

sudo systemctl reboot
```

**2. Network — switch to systemd-networkd** (optional; Fedora IoT defaults to
NetworkManager, which is fine to keep). Do this *after* the reboot and ideally
from the console: dropping NetworkManager kills any in-flight SSH session.
`systemd-networkd` does nothing until it has a `.network` file, so write the
config **first**, enable networkd, and disable NetworkManager **last** — the
reverse order leaves the box with no networking.

```sh
# Replicate the current DHCP setup on the wired link (adjust the interface name)
printf '[Match]\nName=ens2\n\n[Network]\nDHCP=yes\n' \
  | sudo tee /etc/systemd/network/20-wired.network

# Bring networkd + DNS up, hand /etc/resolv.conf to systemd-resolved
sudo systemctl enable --now systemd-networkd systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Only now retire NetworkManager
sudo systemctl disable --now NetworkManager
```

**3. Per-user setup** (after the reboot):

```sh
# Pull your SSH public keys from GitHub for remote login
export GITHUB_USER="onedr0p"
curl https://github.com/$GITHUB_USER.keys > ~/.ssh/authorized_keys

# fish is a real login shell here (it is in /etc/shells), so no zsh layer
chsh -s /usr/bin/fish
```

**4. Dotfiles.** mise is layered by the rpm-ostree command in step 1, so run
the common flow with `fedora` in `miserc.toml`. The bootstrap installs the
remaining declared tools into `~/.local`.

### Fish plugins

`~/.config/fish/fish_plugins` is a managed symlink, and the `bootstrap` task
bootstraps [fisher](https://github.com/jorgebucaran/fisher) and runs
`fisher update` on every `mise bootstrap`.

## Notes

- Machine identity lives in `~/.config/mise/miserc.toml`; git identity
  overrides live in `mise.local.toml`. Neither is tracked in this repo.
- Most deployed files are symlinks into the repo, so editing the deployed file
  edits the repo checkout. Rendered templates (`~/.gitconfig`, `~/.ssh/config`,
  `ms.fish`, `tf.fish`) need `mise dotfiles apply` after editing their
  `.tmpl` source.
- `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md` are symlinks to the same
  agents file as `~/.config/agents/AGENTS.md`, so Claude Code and Codex share
  one set of global agent instructions.
- `mise dotfiles status` shows what is applied, missing, or drifted;
  `mise bootstrap status` covers packages, repos, and tools too.
