{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./modules/master.nix
    ./modules/gnome.nix
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  hardware.asahi = {
    enable = true;
    # Aurora reads this Mac's firmware.cpio from the booted ESP at runtime.
    extractPeripheralFirmware = false;
  };
  # Keep the known-working ESP firmware unchanged during the boot-chain migration.
  aurora.wifiFirmware.followMacOS = false;
  hardware.apple.touchBar.enable = true;
  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=1 fnmode=2 swap_opt_cmd=1 swap_fn_leftctrl=1
  '';

  boot.loader = {
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

      dedsec-theme = {
        enable = true;
        style = "comments";
        icon = "color";
        resolution = "1440p";
      };
    };
  };

  networking.hostName = "DESKTOP-349210";

  networking.networkmanager = {
    enable = true;
    # defaulted to wpa_sup.. eduroam is kind of crazy on iwd
    # wifi.backend = "iwd";
  };
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
    enable = true;
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
    vim
    wget
    btrfs-progs
    brightnessctl
    git
    nixfmt
    nixd
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
