{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on; sleep 2; hyprctl dispatch dpms off DP-2; sleep 1; hyprctl dispatch dpms on DP-2";
      };

      listener = [
        {
          timeout = 900;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1800;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on; sleep 1; hyprctl dispatch dpms off DP-2; sleep 0.5; hyprctl dispatch dpms on DP-2";
        }
      ];
    };
  };
}
