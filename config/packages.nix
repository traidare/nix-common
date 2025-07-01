{
  lib,
  pkgs,
  ...
}: {
  environment = {
    defaultPackages = [];
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
}
