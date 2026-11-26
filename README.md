# Nix config

My M1 setup: Aurora NixOS with GNOME, Home Manager, and nix-darwin for macOS.

## Linux

The repo lives at `/etc/nixos`. System and Home Manager are applied separately:

```sh
sudo nixos-rebuild boot --flake /etc/nixos#m1 --no-update-lock-file
home-manager switch --flake /etc/nixos#lpbigfish --no-update-lock-file
```

The system changes take effect on the next reboot.

## macOS

With Nix (flakes enabled) and Homebrew installed, bootstrap from the repo:

```sh
sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#macbook
```

After that:

```sh
sudo darwin-rebuild switch --flake .#macbook
```

Home Manager is included here, so no separate switch.

## Updates

```sh
nix flake update aurora                              # Linux system
nix flake update home-nixpkgs home-manager nix-darwin  # Home Manager and macOS
```

Check without building:

```sh
nix flake check --no-build --no-update-lock-file
```

## Files

- `configuration.nix` and `modules/`: Linux system.
- `home/`: Linux apps, shell, and GNOME preferences.
- `darwin.nix`: macOS, including Home Manager.
- `modules/nvim/`: shared Neovim config.
- `flake.nix`: inputs and targets.
