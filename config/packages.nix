{
  lib,
  pkgs,
  ...
}: {
  environment = {
    defaultPackages = [];
    systemPackages = with pkgs; [
      curl
      dash
      htop
      lr
      ripgrep
      ripgrep-all
      rsync
      tree
      xe
    ];
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
}
