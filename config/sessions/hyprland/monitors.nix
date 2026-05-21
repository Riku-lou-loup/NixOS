{ config, lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-2, 2880x1800@120, 0x0, 1.0"
      ", highrr, auto, 1.0"
    ];
  };
}
