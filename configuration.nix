{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.dedsec-grub-theme.nixosModule
    ./modules/asahi.nix
    ./modules/master.nix
    ./modules/gnome.nix
    ./hardware-configuration.nix
  ];

  boot.loader = {
    timeout = 10;

    efi = {
      canTouchEfiVariables = false;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;

      configurationLimit = 10;

      timeoutStyle = "menu";
      font = "${pkgs.grub2}/share/grub/unicode.pf2";

      dedsec-theme = {
        enable = true;
        style = "comments";
        icon = "color";
        resolution = "1440p";
      };
    };
  };

  networking.hostName = "DESKTOP-349210";

  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Prague";

  services.printing.enable = true;

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    xone.enable = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.lpbigfish = {
    isNormalUser = true;
    initialPassword = "1234567890";
    createHome = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  programs.direnv = {
    nix-direnv = {
      enable = true;
    };
    settings = {
      global = {
        hide_env_diff = true;
      };
    };
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.enableExcludeWrapper = true;
  services.mullvad-vpn.gui.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    brightnessctl
    zip
    unzip
    podman-compose
    openssl
  ];

  fileSystems = {
    "/".options = [
      "compress=zstd:3"
      "noatime"
    ];
    "/nix".options = [
      "compress=zstd:3"
      "noatime"
    ];
    "/home".options = [
      "compress=zstd:3"
      "noatime"
    ];
    "/swap".options = [ "noatime" ];
    "/boot".options = [ "umask=0077" ];
  };

  services.btrfs.autoScrub.enable = true;
  services.fstrim.enable = true;

  zramSwap.enable = true;
  zramSwap.memoryPercent = 25;

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 8192;
      priority = 10;
    }
  ];

  system.stateVersion = "26.11";
}
