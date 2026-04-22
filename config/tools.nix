{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    lr
    p.wrappers.btop
    ripgrep
    ripgrep-all
    rsync
    tree
    xe
  ];
  environment.shellAliases = {
    ls = lib.mkForce "ls -F --sort=extension";
    ll = lib.mkForce "ls -lh";
    l = lib.mkForce "ls -lhA";
  };

  programs.fish = {
    enable = lib.mkDefault true;
    shellInit = ''
      set -U fish_greeting
    '';
    shellAliases = {
      hdel = "history delete";
    };
    shellAbbrs = {
      j = lib.mkDefault "journalctl";
      s = lib.mkDefault "systemctl";
      us = lib.mkDefault "systemctl --user";
      v = lib.mkDefault "nvim";
    };
  };
  programs.zoxide.enable = lib.mkDefault true;

  programs.vim = {
    enable = lib.mkForce false;
    defaultEditor = lib.mkForce false;
  };
  environment.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
    VISUAL = lib.mkDefault "nvim";
  };

  programs.less.envVariables.LESS = "-j10 -i -A -R";

  programs.command-not-found.enable = false;
}
