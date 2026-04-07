{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.size = 10000;
    history.path = "$HOME/.zsh_history";
    history.ignoreAllDups = true;

    initContent = (builtins.readFile ./zsh-init.sh) + ''
      source ~/.p10k.zsh
      zstyle ':completion:*' matcher-list 'm:{a-z}=A-Z'
      setopt CORRECT
      setopt CORRECT_ALL
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    shellAliases = {
      edit = "sudo -E code -n";
      update = "sudo nixos-rebuild switch";
      stop = "shutdown now";
      edconf = "sudo -E nvim /etc/nixos/configuration.nix";
      out = "loginctl terminate-user kyosho";
    };
  };

  home.sessionVariables = {
      hypr = "/etc/nixos/config/sessions/hyprland/";  
      programs = "/etc/nixos/config/programs";
    };

}
