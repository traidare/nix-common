# Generate NixOS modules from wrappers
{
  config,
  inputs,
  lib,
  ...
}: let
  wlib = inputs.nix-wrapper-modules.lib;
in {
  imports = [inputs.nix-wrapper-modules.flakeModules.default];
  flake.nixosWrapperModules = lib.mapAttrs (name: value:
    wlib.getInstallModule {
      inherit name value;
      specialArgs = {inherit inputs lib;};
    })
  config.flake.wrapperModules;
}
