{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "pi" = {
        hostname = "ssh.gomile.delivery";
        user = "dangddk";
        proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
      };
    };
  };
}
