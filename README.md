# NixOS and macOS configuration

The existing Linux targets remain `nixosConfigurations.m1` and
`homeConfigurations.lpbigfish`. The Apple Silicon macOS target is
`darwinConfigurations.macbook`, configured in [`darwin.nix`](./darwin.nix).

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
nix build .#darwinConfigurations.macbook.system --no-link
nix flake check
nix flake update
```

`nix flake update` updates this shared flake's Linux inputs too. To update only
nix-darwin, use `nix flake update nix-darwin`. A full Darwin build/activation
requires macOS; `nix flake check` on Linux alone does not validate the Mac target.
