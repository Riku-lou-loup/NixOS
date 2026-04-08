{ config, pkgs, ... }:

let
  programsDir = ./config/programs;
  files = builtins.readDir programsDir;
  directories = builtins.filter
    (name: files.${name} == "directory")
    (builtins.attrNames files);
  programImports = map (name: programsDir + "/${name}") directories;
in
{
  imports = [
    ./config/sessions/hyprland/default.nix
  ] ++ programImports;

  home.username = "kyosho";
  home.homeDirectory = "/home/kyosho";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    adwaita-icon-theme
    adw-gtk3
    uv  
];

  # Set cursor
  home.pointerCursor =
  let
    getFrom = url: hash: name: {
      gtk.enable = true;
      x11.enable = true;
      name = name;
      size = 24;
      package =
        pkgs.runCommand "moveUp" {} ''
          mkdir -p $out/share/icons
          ln -s ${pkgs.fetchzip {
            url = url;
            hash = hash;
          }}/dist $out/share/icons/${name}
        '';
    };
  in
    getFrom
      "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE="
      "ArcMidnight-Cursors";

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };

  home.sessionVariables = {};

  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  home.file.".npmrc".text = ''
    prefix = ''${HOME}/.npm-global
  '';

  services.easyeffects.enable = true;

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-theme-name = "adw-gtk3-dark";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  programs.home-manager.enable = true;

  fonts.fontconfig.enable = true;

  home.file = {
    ".local/share/fonts/" = {
      source = config/fonts;
      recursive = true;
    };
  };
}
