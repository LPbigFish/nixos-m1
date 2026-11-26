{ pkgs }:
let
  extensions = with pkgs.gnomeExtensions; [
    caffeine
    blur-my-shell
    dash-to-dock
    clipboard-indicator
    user-themes
    gsconnect
    add-to-desktop
    emoji-copy
    lockscreen-extension
    customize-clock-on-lock-screen
    appindicator
    bluetooth-quick-connect
    hide-top-bar
    tiling-assistant
  ];

  extensionUuidList = map (x: x.extensionUuid) extensions;
in
{
  inherit extensions extensionUuidList;
}
