{
  lib,
  pkgs,
  ...
}:
{
  programs = {
    nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep 1 --no-gcroots";
      };
      flake = "/etc/nixos";
    };
    nix-ld = {
      enable = true;
      package = pkgs.nix-ld;
    };
    direnv.enable = true;
    git.config.init = {
      defaultBranch = "main";
    };
  };

  environment.shellAliases = {
    nhclean = "nh clean all -k 1 --no-gcroots";
  };

  services.timesyncd.enable = lib.mkDefault true;

  fonts = {
    packages = with pkgs; [
      nerd-fonts.meslo-lg
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fontconfig = {
      defaultFonts = {
        sansSerif = [ "MesloLGL Nerd Font" ];
        monospace = [ "MesloLGL Nerd Font Mono" ];
      };
    };
  };

  documentation.man.cache.enable = false;

  environment.systemPackages = lib.mkBefore (
    with pkgs;
    [
      nano
      vim
      btop
      nixfmt
      nixd
      nil
      git
      git-lfs
      screen
      sudo-rs
      nvd
      pciutils
      inetutils
      my-neovim
      tldr
      jq
      nixos-firewall-tool
    ]
  );

  networking.nameservers = [
    #"2606:4700:4700::1111"
    #"2606:4700:4700::1001"
    "1.1.1.1"
    "8.8.8.8"
  ];

  security = {
    sudo.enable = false;
    sudo-rs = {
      enable = true;
      package = pkgs.sudo-rs;
      execWheelOnly = true;
      wheelNeedsPassword = lib.mkDefault true;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      connect-timeout = 5;

      fallback = true;

      warn-dirty = false;

      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://cache.nixos-cuda.org?priority=11"
        "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };

    optimise = {
      automatic = true;
      dates = "weekly";
    };
  };
}
