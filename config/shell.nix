{lib, ...}: {
  environment.shellAliases = {
    ls = lib.mkForce "ls -F --sort=extension";
    ll = lib.mkForce "ls -lh";
    l = lib.mkForce "ls -lhA";
  };

  programs.command-not-found.enable = false;
}
