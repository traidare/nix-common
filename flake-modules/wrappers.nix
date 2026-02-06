# Flake module that generates NixOS modules from wrapperModules
{
  inputs,
  config,
  ...
}: let
  wlib = inputs.nix-wrapper-modules.lib;

  installMods =
    builtins.mapAttrs (name: value: {
      inherit name value;
      __functor = wlib.mkInstallModule;
    })
    config.flake.wrapperModules;
in {
  flake.nixosWrapperModules = installMods;
}
