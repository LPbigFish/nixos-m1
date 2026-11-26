# Apple Silicon configuration

Aurora NixOS on an M1/J293, standalone Linux Home Manager, and nix-darwin for
macOS.

| Target | Platform | Configuration |
| --- | --- | --- |
| `nixosConfigurations.m1` | `aarch64-linux` | GNOME, Aurora/Asahi hardware support, GRUB |
| `homeConfigurations.lpbigfish` | `aarch64-linux` | Desktop preferences, applications, shell and editors |
| `darwinConfigurations.macbook` | `aarch64-darwin` | macOS defaults, Homebrew and integrated Home Manager |

## Repository layout

- [`flake.nix`](./flake.nix): locked inputs, local overlays and target wiring.
- [`configuration.nix`](./configuration.nix): Linux host, boot menu, services,
  account and storage settings.
- [`modules/asahi.nix`](./modules/asahi.nix): Apple Silicon and Aurora modules,
  ordered upstream overlays, J293 validation, firmware policy and keyboard mapping.
- [`hardware-configuration.nix`](./hardware-configuration.nix): generated
  filesystem and hardware declarations.
- [`modules/master.nix`](./modules/master.nix): shared Linux tools, Nix settings,
  fonts and cleanup policy.
- [`modules/gnome.nix`](./modules/gnome.nix): system GNOME services.
- [`modules/gnome-extensions.nix`](./modules/gnome-extensions.nix): extension
  packages and their generated enabled-extension list.
- [`home/home.nix`](./home/home.nix): Linux Home Manager configuration.
- [`home/dconf.nix`](./home/dconf.nix): GNOME preferences, including complete
  Blur My Shell pipelines and Dash-to-Dock settings.
- [`darwin.nix`](./darwin.nix): macOS and its integrated Home Manager configuration.
- [`modules/nvim/`](./modules/nvim): shared Neovim configuration.
- [`packages/orchis-theme.nix`](./packages/orchis-theme.nix): local Orchis theme
  package, exposed through [`overlays/generic-overlay.nix`](./overlays/generic-overlay.nix).

## Linux

Keep this checkout at `/etc/nixos`: both NH and Aurora's updater target that path.
Home Manager is a separate target, not integrated into the NixOS system.

Build without activation:

```sh
nix build --no-update-lock-file --out-link result-aurora \
  .#nixosConfigurations.m1.config.system.build.toplevel
nix build --no-update-lock-file --out-link result-home \
  .#homeConfigurations.lpbigfish.activationPackage
```

These commands do not activate services or install boot files. Root-level
`result` and `result-*` links are ignored by Git.

Apply deliberately:

```sh
sudo nixos-rebuild boot --flake /etc/nixos#m1 --no-update-lock-file
home-manager switch --flake /etc/nixos#lpbigfish --no-update-lock-file
```

The first command installs the next boot configuration, including GRUB/EFI and
the shared Stage 2 bundle; it does not switch running services or reboot. Check
ESP space and retain the recovery material before bootloader changes.

The DedSec theme remains `comments` / `color` / `1440p`. Its explicit GRUB font
enables graphical terminal output, overriding Aurora's font-less default.
Firmware comes from the existing ESP archive; automatic macOS Wi-Fi firmware
refresh remains disabled.

The blur configuration includes all nine current pipelines, including
**Better liquid** and **Liquid Dock** (`blur_radius = 8`). Home Manager reapplies
these saved values on activation; subsequent GUI edits need syncing back into
`home/dconf.nix`. Removing previously managed dconf keys can reset them on the
next activation, so do not treat the export's window or pairing state as
automatically safe to delete.

Automatic NH cleanup is scheduled daily once the system configuration is
activated. Both scheduled cleanup and the manual `nhclean` alias retain at least
10 generations and 30 days and exclude GC roots, including the Asahi recovery
root.

The migration record and separate kernel/Stage 2 recovery procedures are in
[AURORA-MIGRATION.md](./AURORA-MIGRATION.md). Preserve the Asahi recovery root,
firmware, ESP backups and recovery directory.

## Validation

```sh
git diff --check
nix flake check --no-build --no-update-lock-file
nix eval --raw .#nixosConfigurations.m1.config.system.build.toplevel.drvPath
nix eval --raw .#homeConfigurations.lpbigfish.activationPackage.drvPath
nix eval --raw .#darwinConfigurations.macbook.system.drvPath
```

New module files must be tracked by Git to be included in a Git-backed flake.
Evaluation is not a hardware test or a Darwin build; a full Darwin
build/activation requires macOS.

## Inputs

NixOS follows Aurora's coordinated Nixpkgs and Apple Silicon inputs. Linux Home
Manager and nix-darwin use the separate `home-nixpkgs` input. Keep those package
sets separate when making cosmetic configuration changes.

Updates are explicit and change `flake.lock`:

```sh
nix flake update aurora
nix flake update home-nixpkgs home-manager nix-darwin
```

Use only the relevant update command. A bare `nix flake update` updates the
shared flake's Linux and macOS inputs. Review the build plan after updates,
especially kernel/Mesa substitutions and GNOME extension compatibility.

## macOS setup

1. Install Nix with flakes enabled and install [Homebrew](https://brew.sh/)
   separately. The configuration assumes a standard Nix installation managed by
   nix-darwin. If using Determinate Nix, set `nix.enable = false;` in `darwin.nix`
   so Determinate continues to manage Nix itself.
2. Clone this repository on the Mac. Change `username` in `darwin.nix` to your
   existing account's short name (`id -un`) if it is not `lpbigfish`. For an Intel
   Mac, also change `nixpkgs.hostPlatform` to `x86_64-darwin`. If working with
   uncommitted changes, track the new module with `git add darwin.nix` so Nix
   includes it in the flake.
3. Bootstrap nix-darwin from the repository directory:

   ```sh
   sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#macbook
   ```

   Home Manager is integrated into this target; do not apply the Linux
   `homeConfigurations.lpbigfish` on macOS. Back up existing shell/editor config
   files if Home Manager reports a conflict; it will not overwrite them silently.
4. Open Raycast, Rectangle, and AltTab once, enable their launch-at-login options,
   and approve the permissions macOS requests. Rectangle and AltTab need
   Accessibility access; AltTab may also request Screen Recording. Enable
   Raycast's clipboard history if desired. Set its launcher shortcut in Raycast
   (and disable the conflicting Spotlight shortcut if using Command-Space).

The Mac uses the native bottom Dock, dark mode, Mission Control, and a wallpaper
agent that applies the existing dark wallpaper at login. Both wallpaper variants
are also linked under `~/.local/share/wallpapers`. Zsh/Powerlevel10k, the existing
Neovim configuration (without Linux clipboard tools), direnv, Meslo Nerd Font,
and One Dark Alacritty/Zed settings provide the familiar development environment.
Alacritty is installed and managed by Nix; the other GUI apps come from Homebrew.
Homebrew activation does not auto-update, upgrade, or remove unrelated packages;
cask versions are not pinned by `flake.lock`.

## macOS maintenance

Run these commands on the Mac from this repository:

```sh
sudo darwin-rebuild switch --flake .#macbook
nix build .#darwinConfigurations.macbook.system --no-link --no-update-lock-file
nix flake check --no-build --no-update-lock-file
```

To update only nix-darwin, use `nix flake update nix-darwin`.
