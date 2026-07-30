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

| Machine   | Device                | Shell | Packages                     |
| --------- | --------------------- | ----- | ---------------------------- |
| `macos`   | Laptop (macOS)        | fish  | Homebrew                     |
| `termux`  | Phone (Termux)        | fish  | pkg + mise                   |
| `truenas` | NAS (TrueNAS Scale)   | fish  | mise                         |
| `fedora`  | Dev box (Fedora IoT)  | fish  | rpm-ostree + Homebrew + mise |

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

mise itself is always installed with the official installer, on every
platform - never through a package manager. Package-manager copies (brew,
pkg, rpm-ostree) can't `mise self-update`, lag behind releases, and on
Fedora IoT live on a read-only `/usr`. The installer puts the binary at
`~/.local/bin/mise` (override with `MISE_INSTALL_PATH`), and the shell
configs in this repo already put `~/.local/bin` first on `PATH`.

Common flow, after the machine-specific preparation below:

```sh
curl https://mise.run | sh   # installs ~/.local/bin/mise
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

Homebrew is still needed for the brewfile, but not for mise:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
pkg install git fish
chsh -s fish
```

Then run the common flow. Note the install path: `$HOME` on Termux is
`/data/data/com.termux/files/home`, so the installer places the binary at
`/data/data/com.termux/files/home/.local/bin/mise` - keep that in mind when
referencing it outside the shell (the proot-wrapped `ms` function, scripts,
Termux widgets). Prompt niceties (starship, zoxide, atuin, bat, lsd) still
come from pkg; the fish config skips whichever are missing.

### truenas

TrueNAS Scale has no usable package manager (the base OS is reset on
updates), so the installer flow is the only option here anyway.

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
packages are layered into the OS image and activated with a reboot. Because
every added package costs a reboot, the rpm layer stays thin: it carries only
what must live in the OS image (the login shell, the container and qemu stack,
hardware utilities, and the toolchain Homebrew builds against), and Homebrew
provides the CLI tooling from `home/fedora/homebrew/brewfile`. Neither mise nor
Homebrew is layered, so both can update themselves without an rpm-ostree deploy.

No third-party rpm repo is needed. fish comes from Fedora's own repos, and
everything that used to come from Terra is now a Homebrew entry: starship,
kopia, sops, and `1password-cli`. That last one is a cask, which installs on
linuxbrew because its only artifact is a `binary` rather than a macOS `.app` -
the same reason the `claude-code@latest` and `codex` casks work here. Terra's
`1password-cli` rpm also pulled in the 1Password desktop app as a dependency,
which is dead weight on a headless box.

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
# autoconf/automake/binutils/gcc/gcc-c++/libtool/make/patch are the toolchain
# Homebrew builds against; git is needed to clone this repo before brew exists;
# fish must be layered because a login shell has to be in /etc/shells. Homebrew
# covers everything else except telnet (no linuxbrew bottle, source-only Tier
# 3), tcpdump's tcpslice, expect's mkpasswd-expect, and lm_sensors, whose brew
# counterpart is only present as a dependency. logrotate and which are not in
# the Fedora IoT base image either, so they have to be requested explicitly.
# systemd-networkd supports the optional network setup in step 2 below.
sudo rpm-ostree install --idempotent --assumeyes \
  autoconf automake bind-utils binutils docker expect fish gcc gcc-c++ git \
  libtool lm_sensors logrotate make net-tools nvme-cli patch pciutils \
  qemu-guest-agent qemu-system-x86-core qemu-user-static-aarch64 runc \
  smartmontools systemd-networkd tcpdump telnet usbutils which

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

**4. Homebrew.** The common flow already installs mise, so only Homebrew is
left. It is not layered either, and owns all the CLI tooling:

```sh
NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**5. Dotfiles.** Run the common flow with `fedora` in `miserc.toml`. The
`post-dotfiles` hook seeds `unzip`, krew's plugin index and the tap trust store,
then runs `brew bundle install --no-upgrade` against the brewfile symlinked to
`~/.config/homebrew/brewfile`, so it only installs what is missing. The seeding
matters because `brew bundle` does not order entry types against each other, so
anything an entry's installer needs must already exist or that entry fails.

`mise.fedora.toml` declares no `[tools]` - Homebrew covers every global tool,
including the ones that look macOS-only. A cask whose sole artifact is a
`binary` installs fine on linuxbrew, which is how `claude-code@latest`,
`codex` and `1password-cli` arrive, and the Kagi CLI comes from a tap formula
with an `on_linux` block.

`node` (which ships `npm`) and `python` are global, from Homebrew, on both
fedora and macos. Other language runtimes are declared per project in that
project's own mise config rather than installed globally.

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
