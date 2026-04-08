{ config, lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-2, 2880x1800@120, 0x0, 1.0"
      "DP-2, 1920x1080@144, 2880x0, 1.0"
      ", preferred, auto, 1.0"
    ];
  };
}
