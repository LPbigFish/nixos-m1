{ inputs, lib, ... }:
{
  imports = [
    inputs.apple-silicon.nixosModules.default
    inputs.aurora.nixosModules.default
    inputs.aurora.nixosModules.installed
  ];

  nixpkgs.overlays = lib.mkBefore [
    inputs.apple-silicon.overlays.default
    inputs.aurora.overlays.default
  ];

  aurora = {
    desktop = "gnome";
    update.flake = "/etc/nixos#m1";
    stage2.requiredBoards = [ "j293" ];
    wifiFirmware.followMacOS = false;
  };

  hardware.asahi = {
    enable = true;
    extractPeripheralFirmware = false;
  };
  hardware.apple.touchBar.enable = true;

  boot.extraModprobeConfig = ''
    options hid_apple iso_layout=1 fnmode=2 swap_opt_cmd=1 swap_fn_leftctrl=1
  '';
}
