{
  lib,
  pkgs,
  ...
}: {
  environment = {
    defaultPackages = [];
  };

  # Use the latest Linux kernel release
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
}
