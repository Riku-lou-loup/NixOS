{ pkgs, ... }:

{
  # Stable symlink so VSCode's plantuml extension can find the jar regardless of store hash
  home.file.".local/share/plantuml/plantuml.jar".source = "${pkgs.plantuml}/lib/plantuml.jar";

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    # Allow installing extensions via the UI as well
    mutableExtensionsDir = true;

    profiles.default.extensions = with pkgs.vscode-extensions; [
      # These need NixOS-patched versions (download native binaries otherwise)
      ms-python.python
      ms-python.vscode-pylance
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-vscode.cpptools

      # These work fine via nixpkgs
      eamodio.gitlens
      jebbs.plantuml
    ];

    profiles.default.userSettings = {
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'JetBrains Mono', monospace";
      "editor.fontSize" = 14;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "workbench.colorTheme" = "Default Dark Modern";
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "python.defaultInterpreterPath" = "/run/current-system/sw/bin/python";
      "jupyter.notebookFileRoot" = "\${workspaceFolder}";
      "plantuml.render" = "Local";
      "plantuml.java" = "/run/current-system/sw/bin/java";
      "plantuml.jar" = "/home/kyosho/.local/share/plantuml/plantuml.jar";
    };
  };
}
