{lib, ...}: {
  nix = {
    channel.enable = false;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      use-xdg-base-directories = lib.mkDefault true;
    };
  };
  programs.nh = {
    enable = true;
    clean = {
      enable = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      extraArgs = lib.mkDefault "--keep 5 --keep-since 7d";
    };
  };
}
