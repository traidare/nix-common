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
    ];
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
}
