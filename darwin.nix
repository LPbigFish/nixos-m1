{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  username = "lpbigfish";
  lightWallpaper = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/LPbigFish/nixos/refs/heads/main/.github/images/image_uw.jpg";
    sha256 = "0n20194xkwhlbizyva43698q0mmgdpdwrgrv3hmi7zbmx0lskrwc";
  };
  darkWallpaper = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/LPbigFish/nixos/refs/heads/main/.github/images/image_dark_uw.jpg";
    sha256 = "0y3wcdp954j3kc0wxg56mc5kmi5h8xpw1pv7vrq9qb60khw22h1m";
  };
  neovim = inputs.vim-conf.inputs.nvf.lib.neovimConfiguration {
    inherit pkgs;
    modules = [
      ./modules/nvim/nvf-configuration.nix
      {
        vim.clipboard.providers.wl-copy.enable = lib.mkForce false;
      }
    ];
  };
in
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "macbook";
  system.primaryUser = username;
  system.stateVersion = 7;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  fonts.packages = [ pkgs.nerd-fonts.meslo-lg ];

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      tilesize = 40;
      orientation = "bottom";
      show-recents = false;
      mru-spaces = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    casks = [
      "zed"
      "raycast"
      "rectangle"
      "alt-tab"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      home = {
        inherit username;
        homeDirectory = "/Users/${username}";
        stateVersion = "26.11";
        packages = with pkgs; [
          neovim.neovim
          opencode
          zsh-powerlevel10k
          nixfmt
          nixd
          nil
          git-lfs
          ripgrep
          fd
          jq
          wget
          zip
          unzip
        ];
        sessionVariables = {
          EDITOR = "nvim";
          SOPS_EDITOR = "nvim";
        };
        file = {
          ".p10k.zsh".source = ./modules/.p10k.zsh;
          ".local/share/wallpapers/light.jpg".source = lightWallpaper;
          ".local/share/wallpapers/dark.jpg".source = darkWallpaper;
        };
      };

      programs = {
        git = {
          enable = true;
          settings = {
            user = {
              email = "lpbyblock@gmail.com";
              name = "LPbigFish";
            };
            init.defaultBranch = "main";
          };
        };
        eza = {
          enable = true;
          enableZshIntegration = true;
        };
        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true;
          config.global.hide_env_diff = true;
        };
        zsh = {
          enable = true;
          syntaxHighlighting.enable = true;
          autosuggestion.enable = true;
          shellAliases.ls = "eza";
          initContent = ''
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
          '';
        };
        alacritty = {
          enable = true;
          package = pkgs.alacritty;
          settings = {
            general.import = [ "${pkgs.alacritty-theme}/share/alacritty-theme/one_dark.toml" ];
            window.opacity = 0.9;
            font = {
              normal.family = "MesloLGL Nerd Font Mono";
              size = 12;
            };
            keyboard.bindings = [
              {
                key = "N";
                mods = "Control|Shift";
                action = "CreateNewWindow";
              }
            ];
          };
        };
        zed-editor = {
          enable = true;
          package = null;
          extensions = [
            "nix"
            "elixir"
            "haskell"
          ];
          userSettings = {
            theme = "One Dark";
            buffer_font_family = "MesloLGL Nerd Font Mono";
          };
        };
      };

      launchd.agents.wallpaper = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.desktoppr}/bin/desktoppr"
            "${darkWallpaper}"
          ];
          RunAtLoad = true;
          LimitLoadToSessionType = "Aqua";
        };
      };
    };
  };
}
