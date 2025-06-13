{
  config,
  inputs,
  lib,
  withSystem,
  ...
}: {
  flake.lib = withSystem "x86_64-linux" ({pkgs, ...}: {
    dirToAttrs = dir:
      lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (
        builtins.readDir dir
      );

    versionGate = newPkg: stablePkg: let
      newVersion = lib.getVersion newPkg;
      stableVersion = lib.getVersion stablePkg;
    in
      if builtins.compareVersions newVersion stableVersion > 0
      then newPkg
      else lib.warn "Package ${lib.getName newPkg} reached version >=${newVersion} on stable - stable is now used" stablePkg;
    # TODO: create 'versionGate' function for just notifying - not switching to stable

    fromYAML = pkgs.callPackage ./from-yaml.nix {};
    toYAML = pkgs.callPackage ./to-yaml.nix {};
  });

  flake.flakeModules.default.lib = config.flake.lib;
}
