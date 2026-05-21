{config, pkgs, ... }:

{
   wayland.windowManager.hyprland.settings = {
      "exec-once" = [
	 "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
	 "swww-daemon"
	 "${./scripts/apply_idle.sh}"
	 "${./scripts/apply_monitors.sh}"
	 "playerctld"
	 "wl-paste --type text --watch cliphist store" 
	 "wl-paste --type image --watch cliphist store"
	 "systemctl --user enable --now easyeffects"
	 "${./scripts/volume_listener.sh}"
	 "gsettings set org.gnome.desktop.interface cursor-theme 'ArcMidnight-Cursors'"
	 "gsettings set org.gnome.desktop.interface cursor-size 24"
	 "quickshell -p ~/.config/hypr/scripts/quickshell/Main.qml"
	 "quickshell -p ~/.config/hypr/scripts/quickshell/TopBar.qml"
	 "python3 ~/.config/hypr/scripts/quickshell/focustime/focus_daemon.py &"
	 "${./scripts/monitor-hotplug.sh}"
	 "${./scripts/battery-notify.sh}"
      ];
   };
}
