# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, ... }:

{
  # Imports
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  home-manager.backupFileExtension = "backup";

  # System packages
  environment.systemPackages = with pkgs; [
    wget
    taskwarrior3
    file
    git
    killall
    btop
    matugen
    neovim
    fzf
    direnv
    python311
    ffmpeg
    (wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) {})
    telegram-desktop
    kitty
    libreoffice-qt
    hunspell
    hunspellDicts.ru_RU
    hunspellDicts.en_US
    obsidian
    obs-studio
    p7zip
    papers
    fastfetch
    jetbrains.idea-community
    quickshell
    gnome-shell-extensions
    grim
    playerctl
    networkmanager-openvpn
    satty
    yq-go
    xdg-desktop-portal-gtk
    eww
    swappy
    slurp
    mpvpaper
    gnome-tweaks
    pkgsCross.mingwW64.stdenv.cc
    wmctrl
    bottles
    qbittorrent
    power-profiles-daemon
    jdk8
    steam-run
    nodejs
    vscode
    gnome-control-center
  ];

  environment.pathsToLink = [ "/share/gsettings-schemas" ];

  # User accounts and security
  users.users.kyosho = {
    isNormalUser = true;
    description = "kyosho";
    extraGroups = [ "networkmanager" "wheel" "video" "adbusers" "libvirtd" ];
    packages = with pkgs; [];
    useDefaultShell = true;
    shell = pkgs.zsh;
  };

  users.defaultUserShell = pkgs.zsh;
  system.userActivationScripts.zshrc = "touch .zshrc";

  security.sudo.extraRules = [
    {
      users = [ "kyosho" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };

  # Program configurations
  programs.zsh.enable = true;
  programs.adb.enable = true;
  programs.firefox.enable = true;
  programs.dconf.enable = true;  

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # Home manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.kyosho = {
    imports = [ ./home.nix ];
  };

  # Desktop environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Hyprland
  programs.hyprland.enable = true;

  # XDG Portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru,fr";
    variant = ",,azerty";
  };

  # Fonts
  fonts.packages = with pkgs; [
    udev-gothic-nf
    noto-fonts
    liberation_ttf
    nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig = {
    enable = true;
    hinting.style = "slight";
    subpixel.rgba = "rgb";
  };

  # Flatpak
  services.flatpak.enable = true;

  # Networking and time
  networking.hostName = "nixos";

  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    plugins = with pkgs; [ networkmanager-openvpn ];
  };

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.blueman.enable = true;

  services.printing.enable = true;
  services.openssh.enable = true;
  services.power-profiles-daemon.enable = true;

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };

  boot = {
    plymouth = {
      enable = true;
      theme = "simple";
      themePackages = [
        (pkgs.stdenv.mkDerivation {
          pname = "plymouth-theme-simple";
          version = "1.0";
          src = /etc/nixos/config/programs/plymouth/simple;
          installPhase = ''
            mkdir -p $out/share/plymouth/themes/simple
            cp -r * $out/share/plymouth/themes/simple/
            substituteInPlace $out/share/plymouth/themes/simple/simple.plymouth \
              --replace "@out@" "$out"
          '';
        })
      ];
    };

    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "amd_pstate=active"
      "tsc=reliable"
      "asus_wmi"
    ];
  };

  # Virtualization
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Bootloader and kernel
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.cpu.amd.updateMicrocode = true;

  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.core.wmem_max" = 1073741824;
    "net.core.rmem_max" = 1073741824;
    "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
    "net.ipv4.tcp_wmem" = "4096 87380 1073741824";
  };

  powerManagement.cpuFreqGovernor = "performance";

  # GPU / Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # NVIDIA: 01:00.0 -> PCI:1:0:0
      # AMD:   65:00.0 -> PCI:101:0:0
      nvidiaBusId = "PCI:1:0:0";
      amdgpuBusId = "PCI:101:0:0";
    };
  };

  system.stateVersion = "25.11";
}
