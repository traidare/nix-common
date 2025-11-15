{lib, ...}: {
  environment.shellAliases = {
    ls = lib.mkForce "ls -F --sort=extension";
    ll = lib.mkForce "ls -lh";
    l = lib.mkForce "ls -lhA";
  };

  programs.command-not-found.enable = false;

  programs.fish = {
    enable = lib.mkDefault true;
    shellAbbrs = {
      j = lib.mkDefault "journalctl";
      s = lib.mkDefault "systemctl";
      us = lib.mkDefault "systemctl --user";
      v = lib.mkDefault "nvim";
    };
  };
  programs.zoxide.enable = lib.mkDefault true;
}
